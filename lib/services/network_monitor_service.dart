import 'dart:async';
import 'dart:convert';
import 'dart:math';
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
  // 权重更高，因为带宽更大
  static const double _jpWeightFactor = 0.6;

  // 添加新的响应时间阈值常量
  static const int _responseTimeLowThreshold = 1000; // 1000ms
  static const int _responseTimeHighThreshold = 1500; // 1500ms
  static const double _jpWeightFactorMedium = 0.9; // 1000-1500ms范围内的权重因子
  static const double _jpWeightFactorHigh = 0.8; // 大于1500ms的权重因子

  // 添加延迟差距阈值
  static const double _delayDifferenceThreshold = 0.30; // 30%

  // 切换阈值 - 只有当新线路比当前线路快20%以上或至少100ms才切换
  static const double _switchThresholdPercent = 0.20; // 20%
  static const int _switchThresholdAbsolute = 100; // 100ms

  // 默认线路（如果都不可用时使用）
  static const String _defaultEndpoint = 'https://hk2.xiaoyi.ink';

  // SharedPreferences键名
  static const String _keyCurrentApiUrl = 'current_api_url';
  static const String _keyEndpointStatus = 'endpoint_status';
  static const String _keyLastUpdated = 'endpoints_last_updated';
  static const String _keyEndpointFailCount = 'endpoint_fail_count';

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
  // 添加失败计数器，用于实现更智能的故障转移
  final Map<String, int> _endpointFailCount = {};
  
  // 添加稳定性跟踪
  final Map<String, List<int>> _responseTimeHistory = {};
  static const int _historyMaxLength = 5; // 保留最近5次的响应时间

  // 初始化是否完成
  bool _isInitialized = false;

  // 监控频率（秒）- 根据网络稳定性动态调整
  int _monitorIntervalSeconds = 15;
  static const int _minMonitorInterval = 5; // 最小5秒
  static const int _maxMonitorInterval = 30; // 最大30秒

  // 连续失败阈值，超过此值认为端点不可用
  static const int _maxConsecutiveFailures = 3;

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
        _endpointFailCount[endpoint] = 0;
        _responseTimeHistory[endpoint] = [];
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
                
                // 初始化响应时间历史记录
                _responseTimeHistory[endpoint] = [];
                if (status.containsKey('responseTimeHistory')) {
                  final history = status['responseTimeHistory'] as List<dynamic>?;
                  if (history != null) {
                    _responseTimeHistory[endpoint] = 
                        history.map((e) => e as int).toList();
                  }
                }
              }
            }

            // 加载失败计数
            final failCountJson = prefs.getString(_keyEndpointFailCount);
            if (failCountJson != null) {
              final Map<String, dynamic> failCountMap = 
                  jsonDecode(failCountJson) as Map<String, dynamic>;
              for (final endpoint in _apiEndpoints) {
                if (failCountMap.containsKey(endpoint)) {
                  _endpointFailCount[endpoint] = failCountMap[endpoint] as int;
                } else {
                  _endpointFailCount[endpoint] = 0;
                }
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
            'responseTimeHistory': _responseTimeHistory[endpoint] ?? [],
          };
        }

        final statusJson = await compute<Map<String, dynamic>, String>(
            (map) => jsonEncode(map), statusMap);
        await prefs.setString(_keyEndpointStatus, statusJson);
        
        // 保存失败计数
        final failCountMap = <String, dynamic>{};
        for (final endpoint in _apiEndpoints) {
          failCountMap[endpoint] = _endpointFailCount[endpoint] ?? 0;
        }
        await prefs.setString(_keyEndpointFailCount, jsonEncode(failCountMap));

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
    // 定时器，根据当前监控间隔检查
    _monitorTimer?.cancel();
    _monitorTimer =
        Timer.periodic(Duration(seconds: _monitorIntervalSeconds), (_) {
      _checkNetworkQuality();
    });
  }

  // 停止监控
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  // 根据网络稳定性调整监控间隔
  void _adjustMonitorInterval() {
    // 计算网络稳定性分数
    int stabilityScore = 0;
    int availableEndpoints = 0;
    
    for (final endpoint in _apiEndpoints) {
      if (_endpointAvailability[endpoint] == true) {
        availableEndpoints++;
        
        // 检查响应时间历史的稳定性
        final history = _responseTimeHistory[endpoint];
        if (history != null && history.length > 1) {
          int variations = 0;
          for (int i = 1; i < history.length; i++) {
            final diff = (history[i] - history[i-1]).abs();
            final percent = history[i-1] > 0 ? diff / history[i-1] : 0;
            if (percent < 0.1) { // 变化小于10%
              stabilityScore++;
            } else {
              variations++;
            }
          }
        }
      }
    }
    
    // 根据稳定性分数和可用端点数调整监控间隔
    if (availableEndpoints == 0) {
      // 没有可用端点，缩短间隔以快速恢复
      _monitorIntervalSeconds = _minMonitorInterval;
    } else if (stabilityScore > 3) {
      // 网络稳定，延长间隔
      _monitorIntervalSeconds = _maxMonitorInterval;
    } else {
      // 网络不太稳定，使用中等间隔
      _monitorIntervalSeconds = (_minMonitorInterval + _maxMonitorInterval) ~/ 2;
    }
    
    // 重启监控定时器
    if (_monitorTimer != null) {
      _monitorTimer!.cancel();
      _monitorTimer = Timer.periodic(
        Duration(seconds: _monitorIntervalSeconds), 
        (_) => _checkNetworkQuality()
      );
    }
    
    debugPrint('[网络监控] 调整监控间隔为 $_monitorIntervalSeconds 秒');
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
      
      // 用于存储所有可用端点的响应时间
      final Map<String, int> availableResponseTimes = {};

      // 对每个端点进行健康检查
      for (final endpoint in _apiEndpoints) {
        final future = _checkEndpointHealth(endpoint).then((responseTime) {
          // 更新可用性和响应时间
          final bool isNowAvailable = responseTime > 0;
          
          // 更新失败计数
          if (!isNowAvailable) {
            _endpointFailCount[endpoint] = (_endpointFailCount[endpoint] ?? 0) + 1;
            // 只有连续失败超过阈值才标记为不可用
            if (_endpointFailCount[endpoint]! >= _maxConsecutiveFailures) {
              _endpointAvailability[endpoint] = false;
            }
          } else {
            // 重置失败计数
            _endpointFailCount[endpoint] = 0;
            _endpointAvailability[endpoint] = true;
            
            // 更新响应时间
            _endpointResponseTimes[endpoint] = responseTime;
            availableResponseTimes[endpoint] = responseTime;
            
            // 更新响应时间历史
            final history = _responseTimeHistory[endpoint] ?? [];
            history.add(responseTime);
            if (history.length > _historyMaxLength) {
              history.removeAt(0);
            }
            _responseTimeHistory[endpoint] = history;
            
            availableEndpoints.add(endpoint);
            hasFoundHealthyEndpoint = true;
          }
        });

        checkFutures.add(future);
      }

      // 等待所有健康检查完成
      await Future.wait(checkFutures);
      
      // 如果只有一个可用端点，直接选择它
      if (availableEndpoints.length == 1) {
        bestEndpoint = availableEndpoints.first;
        debugPrint('[网络监控] 只有一个可用端点: $bestEndpoint');
      } 
      // 如果有多个可用端点，根据新规则计算权重
      else if (availableEndpoints.length > 1) {
        // 首先检查所有端点是否都在1000ms以内
        bool allUnder1000ms = true;
        for (final endpoint in availableEndpoints) {
          if (availableResponseTimes[endpoint]! > _responseTimeLowThreshold) {
            allUnder1000ms = false;
            break;
          }
        }
        
        // 如果所有端点都在1000ms以内，随机选择节点
        if (allUnder1000ms) {
          // 随机选择一个可用节点
          final random = Random();
          final randomIndex = random.nextInt(availableEndpoints.length);
          bestEndpoint = availableEndpoints[randomIndex];
          bestWeightedResponseTime = availableResponseTimes[bestEndpoint]?.toDouble();
          debugPrint('[网络监控] 所有端点都在1000ms以内，随机选择: $bestEndpoint (${availableResponseTimes[bestEndpoint]}ms)');
        } 
        // 否则，应用权重规则
        else {
          // 计算加权响应时间
          for (final endpoint in availableEndpoints) {
            final responseTime = availableResponseTimes[endpoint]!;
            double weightedTime = responseTime.toDouble();
            
            // 应用日本节点的权重规则
            if (endpoint == _jpEndpoint) {
              if (responseTime <= _responseTimeLowThreshold) {
                // 1000ms以内，不应用权重
                weightedTime = responseTime.toDouble();
              } else if (responseTime <= _responseTimeHighThreshold) {
                // 1000-1500ms之间，应用中等权重
                weightedTime = responseTime * _jpWeightFactorMedium;
                debugPrint('[网络监控] JP线路中等权重: 原始${responseTime}ms, 加权后${weightedTime.toInt()}ms');
              } else {
                // 大于1500ms，应用高权重
                weightedTime = responseTime * _jpWeightFactorHigh;
                debugPrint('[网络监控] JP线路高权重: 原始${responseTime}ms, 加权后${weightedTime.toInt()}ms');
              }
            }
            
            // 更新最佳端点
            if (bestWeightedResponseTime == null || weightedTime < bestWeightedResponseTime) {
              bestEndpoint = endpoint;
              bestWeightedResponseTime = weightedTime;
            }
          }
        }
      }

      // 如果找到了健康端点，考虑是否需要切换
      if (hasFoundHealthyEndpoint && bestEndpoint != null) {
        // 只有当前端点不可用，或者新端点明显更快时才切换
        final currentEndpointAvailable = _endpointAvailability[_currentApiUrl] ?? false;
        
        if (!currentEndpointAvailable) {
          debugPrint('[网络监控] 当前端点不可用，切换到: $bestEndpoint');
          _switchApiEndpoint(bestEndpoint);
        } else if (bestEndpoint != _currentApiUrl) {
          // 获取当前端点和最佳端点的响应时间
          final currentResponseTime = _endpointResponseTimes[_currentApiUrl] ?? 9999;
          final bestResponseTime = _endpointResponseTimes[bestEndpoint] ?? 9999;
          
          // 计算加权响应时间
          double currentWeightedTime = currentResponseTime.toDouble();
          double bestWeightedTime = bestResponseTime.toDouble();
          
          // 应用权重规则
          if (_currentApiUrl == _jpEndpoint) {
            if (currentResponseTime <= _responseTimeLowThreshold) {
              currentWeightedTime = currentResponseTime.toDouble();
            } else if (currentResponseTime <= _responseTimeHighThreshold) {
              currentWeightedTime = currentResponseTime * _jpWeightFactorMedium;
            } else {
              currentWeightedTime = currentResponseTime * _jpWeightFactorHigh;
            }
          }
          
          if (bestEndpoint == _jpEndpoint) {
            if (bestResponseTime <= _responseTimeLowThreshold) {
              bestWeightedTime = bestResponseTime.toDouble();
            } else if (bestResponseTime <= _responseTimeHighThreshold) {
              bestWeightedTime = bestResponseTime * _jpWeightFactorMedium;
            } else {
              bestWeightedTime = bestResponseTime * _jpWeightFactorHigh;
            }
          }
          
          // 只有当新线路比当前线路快30%以上才切换
          final bool shouldSwitch = 
              (currentWeightedTime - bestWeightedTime) > _switchThresholdAbsolute || 
              bestWeightedTime < (currentWeightedTime * (1 - _delayDifferenceThreshold));
          
          if (shouldSwitch) {
            debugPrint('[网络监控] 切换线路: 从 $_currentApiUrl 到 $bestEndpoint!');
            debugPrint('[网络监控] 切换原因: 新端点更快 (当前: ${currentWeightedTime.toInt()}ms, 新: ${bestWeightedTime.toInt()}ms)');
            _switchApiEndpoint(bestEndpoint);
          }
        }
      }

      // 构建状态信息
      for (final endpoint in _apiEndpoints) {
        final responseTime = _endpointResponseTimes[endpoint];
        final isAvailable = _endpointAvailability[endpoint] ?? false;
        final failCount = _endpointFailCount[endpoint] ?? 0;

        if (isAvailable && responseTime != null) {
          if (endpoint == _jpEndpoint) {
            double weightedTime;
            if (responseTime <= _responseTimeLowThreshold) {
              weightedTime = responseTime.toDouble();
            } else if (responseTime <= _responseTimeHighThreshold) {
              weightedTime = responseTime * _jpWeightFactorMedium;
            } else {
              weightedTime = responseTime * _jpWeightFactorHigh;
            }
            
            statusInfo
                .write('$endpoint(${responseTime}ms, 加权: ${weightedTime.toInt()}ms, 失败: $failCount) ');
          } else {
            statusInfo.write('$endpoint(${responseTime}ms, 失败: $failCount) ');
          }
        } else {
          statusInfo.write('$endpoint(不可用, 失败: $failCount) ');
        }
      }

      // 添加当前使用的端点信息
      statusInfo.write('- 当前: $_currentApiUrl');

      // 输出一条简单的状态日志
      debugPrint(statusInfo.toString());
      
      // 调整监控间隔
      _adjustMonitorInterval();

      // 保存状态到本地存储
      await _saveState();
    });
  }

  // 检查线路健康状态，返回响应时间（毫秒），如果不可用则返回-1
  Future<int> _checkEndpointHealth(String endpoint) async {
    // 实现重试逻辑
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final stopwatch = Stopwatch()..start();
        final response = await _dio.get(
          '$endpoint/health',
          options: Options(
            receiveTimeout: const Duration(seconds: 3),
            sendTimeout: const Duration(seconds: 3),
          ),
        );
        stopwatch.stop();

        // 检查响应状态和内容
        if (response.statusCode == 200 &&
            response.data.toString().contains('healthy')) {
          return stopwatch.elapsedMilliseconds;
        }
        
        // 如果响应成功但内容不符合预期，等待短暂时间后重试
        if (attempt < 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        // 区分不同类型的错误
        String errorType = "未知错误";
        if (e is DioException) {
          switch (e.type) {
            case DioExceptionType.connectionTimeout:
              errorType = "连接超时";
              break;
            case DioExceptionType.sendTimeout:
              errorType = "发送超时";
              break;
            case DioExceptionType.receiveTimeout:
              errorType = "接收超时";
              break;
            case DioExceptionType.badResponse:
              errorType = "服务器错误 ${e.response?.statusCode}";
              break;
            default:
              errorType = "网络错误 ${e.type}";
          }
        }
        
        debugPrint('[网络监控] 端点 $endpoint 检查失败: $errorType');
        
        // 如果不是最后一次尝试，等待短暂时间后重试
        if (attempt < 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    
    return -1; // 所有尝试都失败
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
          final history = _responseTimeHistory[endpoint] ?? [];
          final failCount = _endpointFailCount[endpoint] ?? 0;
          
          // 计算加权响应时间
          double weightedResponseTime = responseTime.toDouble();
          double weightFactor = 1.0;
          
          if (isJpEndpoint && responseTime > 0) {
            if (responseTime <= _responseTimeLowThreshold) {
              weightFactor = 1.0; // 1000ms以内不加权
            } else if (responseTime <= _responseTimeHighThreshold) {
              weightFactor = _jpWeightFactorMedium; // 1000-1500ms使用中等权重
            } else {
              weightFactor = _jpWeightFactorHigh; // 大于1500ms使用高权重
            }
            weightedResponseTime = responseTime * weightFactor;
          }

          result[endpoint] = {
            'available': _endpointAvailability[endpoint] ?? false,
            'responseTime': responseTime,
            'weightedResponseTime': weightedResponseTime.toInt(),
            'isCurrent': endpoint == _currentApiUrl,
            'isWeighted': isJpEndpoint,
            'failCount': failCount,
            'history': history,
            'weightFactor': weightFactor,
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
        'weightedResponseTime': isJpEndpoint ? 300 : 300, // 假设的加权响应时间
        'isCurrent': endpoint == _defaultEndpoint,
        'isWeighted': isJpEndpoint,
        'failCount': 0,
        'history': [],
        'weightFactor': isJpEndpoint ? _jpWeightFactor : 1.0,
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
