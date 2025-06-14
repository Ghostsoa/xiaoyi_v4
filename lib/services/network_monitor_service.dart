import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import '../net/http_client.dart';

class NetworkMonitorService {
  static final NetworkMonitorService _instance =
      NetworkMonitorService._internal();
  factory NetworkMonitorService() => _instance;

  NetworkMonitorService._internal();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    sendTimeout: const Duration(seconds: 5),
  ));

  static const List<String> _apiEndpoints = [
    'https://hk2.xiaoyi.ink',
    'https://jp.xiaoyi.ink',
  ];

  // 定义日本节点常量，用于权重比较
  static const String _jpEndpoint = 'https://jp.xiaoyi.ink';

  // 日本节点权重因子 (小于1，使其响应时间看起来更快)
  static const double _jpWeightFactor = 0.7;

  // 默认线路（如果都不可用时使用）
  static const String _defaultEndpoint = 'https://hk2.xiaoyi.ink';

  // SharedPreferences键名
  static const String _keyCurrentApiUrl = 'current_api_url';
  static const String _keyEndpointStatus = 'endpoint_status';
  static const String _keyLastUpdated = 'endpoints_last_updated';

  // 读写锁
  final Lock _readLock = Lock();
  final Lock _writeLock = Lock();

  // 初始化状态跟踪
  final Completer<void> _initCompleter = Completer<void>();
  bool _initStarted = false;

  // 获取默认线路的公共方法
  static String getDefaultEndpoint() {
    return _defaultEndpoint;
  }

  // 当前使用的线路
  String _currentApiUrl = _defaultEndpoint;
  Timer? _monitorTimer;

  // 线路状态记录
  final Map<String, bool> _endpointAvailability = {};
  final Map<String, int> _endpointResponseTimes = {};

  // 初始化是否完成
  bool _isInitialized = false;

  // 监控频率（秒）
  static const int _monitorIntervalSeconds = 15;

  // 非阻塞初始化方法 - 在后台启动初始化过程
  void initializeAsync() {
    // 防止重复初始化
    if (_initStarted) return;
    _initStarted = true;

    // 在后台异步执行初始化
    Future.microtask(() async {
      try {
        await initialize();
        _initCompleter.complete();
      } catch (e) {
        debugPrint('[网络监控] 初始化异常: $e');
        // 即使有异常也标记为完成，避免永久阻塞
        if (!_initCompleter.isCompleted) {
          _initCompleter.complete();
        }
      }
    });
  }

  // 等待初始化完成的方法（如果需要确保操作在初始化之后）
  Future<void> waitForInitialization() async {
    if (!_initStarted) {
      initializeAsync();
    }
    return _initCompleter.future;
  }

  // 初始化并开始监控 - 保留原有方法以兼容
  Future<void> initialize() async {
    // 从SharedPreferences加载保存的状态
    await _loadSavedState();

    // 如果没有加载到保存的状态，则初始化线路状态
    if (!_isInitialized) {
      for (final endpoint in _apiEndpoints) {
        _endpointAvailability[endpoint] = false;
        _endpointResponseTimes[endpoint] = 9999;
      }

      // 执行一次检测，设置初始URL
      await _checkNetworkQuality();
    }

    _isInitialized = true;

    // 开始定期监控
    startMonitoring();
  }

  // 从SharedPreferences加载保存的状态
  Future<void> _loadSavedState() async {
    return _readLock.synchronized(() async {
      try {
        final prefs = await SharedPreferences.getInstance();

        // 加载当前API URL
        final savedApiUrl = prefs.getString(_keyCurrentApiUrl);
        if (savedApiUrl != null && _apiEndpoints.contains(savedApiUrl)) {
          _currentApiUrl = savedApiUrl;

          // 立即更新HttpClient的baseUrl
          HttpClient().setBaseUrl('$_currentApiUrl/api/v1');
        }

        // 加载端点状态
        final statusJson = prefs.getString(_keyEndpointStatus);
        if (statusJson != null) {
          try {
            final Map<String, dynamic> statusMap = Map<String, dynamic>.from(
                // ignore: unnecessary_cast
                await compute<String, Map<String, dynamic>>(
                    (json) => json.isNotEmpty
                        ?
                        // ignore: unnecessary_cast
                        Map<String, dynamic>.from(jsonDecode(json) as Map)
                            as Map<String, dynamic>
                        : <String, dynamic>{},
                    statusJson));

            for (final endpoint in _apiEndpoints) {
              if (statusMap.containsKey(endpoint)) {
                final status = statusMap[endpoint] as Map<String, dynamic>;
                _endpointAvailability[endpoint] =
                    status['available'] as bool? ?? false;
                _endpointResponseTimes[endpoint] =
                    status['responseTime'] as int? ?? 9999;
              }
            }

            // 检查上次更新时间，如果超过30分钟，强制刷新
            final lastUpdated = prefs.getInt(_keyLastUpdated) ?? 0;
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - lastUpdated > 30 * 60 * 1000) {
              // 30分钟
              // 后台立即检测线路质量，不等待结果
              _checkNetworkQuality(); // 不使用await，让它在后台运行
              debugPrint('[网络监控] 加载的缓存数据已过期，在后台刷新');
            } else {
              _isInitialized = true;
              debugPrint('[网络监控] 成功从本地加载线路状态');
            }
          } catch (e) {
            debugPrint('[网络监控] 解析保存的状态时出错: $e');
          }
        }
      } catch (e) {
        debugPrint('[网络监控] 加载保存的状态时出错: $e');
      }
    });
  }

  // 获取当前最佳线路，优先从本地加载，不会阻塞应用启动
  Future<String> getBestApiEndpoint() async {
    // 如果已经初始化，直接返回最佳线路
    if (_isInitialized) {
      return _currentApiUrl;
    }

    // 如果没有初始化但已经开始，尝试从本地快速加载
    try {
      // 使用超短超时的非阻塞方式获取SharedPreferences中保存的URL
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(milliseconds: 200));
      final savedApiUrl = prefs.getString(_keyCurrentApiUrl);
      if (savedApiUrl != null && _apiEndpoints.contains(savedApiUrl)) {
        return savedApiUrl;
      }
    } catch (e) {
      // 超时或出错时忽略，使用默认线路
    }

    // 开始初始化过程（如果尚未开始）
    if (!_initStarted) {
      initializeAsync();
    }

    // 返回默认线路，保证不阻塞调用方
    return _defaultEndpoint;
  }

  // 保存状态到SharedPreferences
  Future<void> _saveState() async {
    return _writeLock.synchronized(() async {
      try {
        final prefs = await SharedPreferences.getInstance();

        // 保存当前API URL
        await prefs.setString(_keyCurrentApiUrl, _currentApiUrl);

        // 保存端点状态
        final statusMap = <String, dynamic>{};
        for (final endpoint in _apiEndpoints) {
          statusMap[endpoint] = {
            'available': _endpointAvailability[endpoint] ?? false,
            'responseTime': _endpointResponseTimes[endpoint] ?? 9999,
          };
        }

        final statusJson = await compute<Map<String, dynamic>, String>(
            (map) => jsonEncode(map), statusMap);
        await prefs.setString(_keyEndpointStatus, statusJson);

        // 保存更新时间
        await prefs.setInt(
            _keyLastUpdated, DateTime.now().millisecondsSinceEpoch);

        debugPrint('[网络监控] 线路状态已保存到本地');
      } catch (e) {
        debugPrint('[网络监控] 保存状态时出错: $e');
      }
    });
  }

  // 开始监控
  void startMonitoring() {
    // 定时器，每15秒检查一次
    _monitorTimer?.cancel();
    _monitorTimer =
        Timer.periodic(const Duration(seconds: _monitorIntervalSeconds), (_) {
      _checkNetworkQuality();
    });
  }

  // 停止监控
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  // 检查网络质量并切换线路
  Future<void> _checkNetworkQuality() async {
    return _writeLock.synchronized(() async {
      final statusInfo = StringBuffer('[网络监控] 线路状态: ');
      final availableEndpoints = <String>[];
      bool hasFoundHealthyEndpoint = false;
      String? bestEndpoint;
      double? bestWeightedResponseTime;

      // 创建一个List来存储所有端点检查的Future
      List<Future<void>> checkFutures = [];

      // 对每个端点进行健康检查
      for (final endpoint in _apiEndpoints) {
        final future = _checkEndpointHealth(endpoint).then((responseTime) {
          // 更新可用性和响应时间
          _endpointAvailability[endpoint] = responseTime > 0;

          if (responseTime > 0) {
            _endpointResponseTimes[endpoint] = responseTime;
            availableEndpoints.add(endpoint);

            // 计算加权响应时间 (日本线路有更高权重)
            double weightedResponseTime = responseTime.toDouble();
            if (endpoint == _jpEndpoint) {
              weightedResponseTime *= _jpWeightFactor; // 日本线路响应时间加权
              debugPrint(
                  '[网络监控] JP线路加权: 原始${responseTime}ms, 加权后${weightedResponseTime.toInt()}ms');
            }

            // 检查是否是第一个健康的端点或比现有最快端点还快
            if (!hasFoundHealthyEndpoint ||
                weightedResponseTime < (bestWeightedResponseTime ?? 9999)) {
              hasFoundHealthyEndpoint = true;
              bestEndpoint = endpoint;
              bestWeightedResponseTime = weightedResponseTime;

              // 立即切换到这个健康端点
              if (_currentApiUrl != endpoint) {
                _switchApiEndpoint(endpoint);
                debugPrint(
                    '[网络监控] 切换到线路: $endpoint (原始: ${responseTime}ms, 加权: ${weightedResponseTime.toInt()}ms)');
              }
            }
          }
        });

        checkFutures.add(future);
      }

      // 等待所有健康检查完成，用于记录完整状态
      await Future.wait(checkFutures);

      // 构建状态信息
      for (final endpoint in _apiEndpoints) {
        final responseTime = _endpointResponseTimes[endpoint];
        final isAvailable = _endpointAvailability[endpoint] ?? false;

        if (isAvailable && responseTime != null) {
          if (endpoint == _jpEndpoint) {
            final weightedTime = (responseTime * _jpWeightFactor).toInt();
            statusInfo
                .write('$endpoint(${responseTime}ms, 加权: ${weightedTime}ms) ');
          } else {
            statusInfo.write('$endpoint(${responseTime}ms) ');
          }
        } else {
          statusInfo.write('$endpoint(不可用) ');
        }
      }

      // 添加当前使用的端点信息
      statusInfo.write('- 当前: $_currentApiUrl');

      // 输出一条简单的状态日志
      debugPrint(statusInfo.toString());

      // 保存状态到本地存储
      await _saveState();
    });
  }

  // 检查线路健康状态，返回响应时间（毫秒），如果不可用则返回-1
  Future<int> _checkEndpointHealth(String endpoint) async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await _dio.get('$endpoint/health');
      stopwatch.stop();

      // 检查响应状态和内容
      if (response.statusCode == 200 &&
          response.data.toString().contains('healthy')) {
        return stopwatch.elapsedMilliseconds;
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  // 切换API线路
  void _switchApiEndpoint(String newEndpoint) {
    _currentApiUrl = newEndpoint;

    // 更新HttpClient的baseUrl
    HttpClient().setBaseUrl('$_currentApiUrl/api/v1');
  }

  // 获取当前API线路
  Future<String> getCurrentApiUrl() async {
    // 如果已经初始化，直接返回
    if (_isInitialized) {
      return _currentApiUrl;
    }

    // 尝试快速从SharedPreferences获取
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(milliseconds: 200));
      final savedApiUrl = prefs.getString(_keyCurrentApiUrl);
      if (savedApiUrl != null && _apiEndpoints.contains(savedApiUrl)) {
        return savedApiUrl;
      }
    } catch (e) {
      // 超时或出错时忽略
    }

    // 返回默认值以避免阻塞
    return _defaultEndpoint;
  }

  // 获取所有线路状态
  Future<Map<String, dynamic>> getEndpointsStatus() async {
    // 如果已经初始化，返回当前状态
    if (_isInitialized) {
      return _readLock.synchronized(() async {
        final result = <String, dynamic>{};
        for (final endpoint in _apiEndpoints) {
          final isJpEndpoint = endpoint == _jpEndpoint;
          final responseTime = _endpointResponseTimes[endpoint] ?? -1;

          result[endpoint] = {
            'available': _endpointAvailability[endpoint] ?? false,
            'responseTime': responseTime,
            'weightedResponseTime': isJpEndpoint && responseTime > 0
                ? (responseTime * _jpWeightFactor).toInt()
                : responseTime,
            'isCurrent': endpoint == _currentApiUrl,
            'isWeighted': isJpEndpoint,
          };
        }
        return result;
      });
    }

    // 如果未初始化，返回基于默认值的状态
    final result = <String, dynamic>{};
    for (final endpoint in _apiEndpoints) {
      final isJpEndpoint = endpoint == _jpEndpoint;

      result[endpoint] = {
        'available': true, // 假设所有端点可用
        'responseTime': isJpEndpoint ? 500 : 300, // 假设的响应时间
        'weightedResponseTime': isJpEndpoint ? 350 : 300, // 假设的加权响应时间
        'isCurrent': endpoint == _defaultEndpoint,
        'isWeighted': isJpEndpoint,
      };
    }

    // 开始初始化过程（如果尚未开始）
    if (!_initStarted) {
      initializeAsync();
    }

    return result;
  }

  // 手动设置API线路
  Future<void> setApiEndpoint(String endpoint) async {
    return _writeLock.synchronized(() async {
      if (_apiEndpoints.contains(endpoint)) {
        _switchApiEndpoint(endpoint);
        await _saveState();
      }
    });
  }

  // 手动刷新线路状态
  Future<void> refreshEndpointsStatus() async {
    // 如果已初始化，执行刷新
    if (_isInitialized) {
      await _checkNetworkQuality();
    } else {
      // 如果未初始化，先等待初始化完成
      if (!_initStarted) {
        initializeAsync();
      }
    }
  }

  // 用于导入JSON库
  dynamic jsonEncode(dynamic object) => json.encode(object);

  dynamic jsonDecode(String source) => json.decode(source);
}
