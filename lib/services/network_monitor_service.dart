import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

/// 节点信息结构
class EndpointInfo {
  final String url;
  String name;
  final bool isDefault;

  EndpointInfo({
    required this.url,
    required this.name,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'name': name,
        'isDefault': isDefault,
      };

  factory EndpointInfo.fromJson(Map<String, dynamic> json) {
    return EndpointInfo(
      url: json['url'],
      name: json['name'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  @override
  String toString() => '$name ($url)';
}

/// 网络监控服务，管理API节点的可用性与状态
/// 对外提供主要接口:
/// 1. getCurrentEndpoint() - 获取当前选中的API节点，从数据库获取
/// 2. setCurrentEndpoint(String endpoint) - 手动设置当前使用的API节点
/// 3. refreshEndpointStatus() - 刷新所有节点状态，更新延迟值
/// 4. getAllEndpointStatus() - 获取所有节点状态，用于UI显示
/// 5. addCustomEndpoint(String url, String name) - 添加自定义节点
/// 6. removeCustomEndpoint(String url) - 删除自定义节点
/// 7. getAllEndpoints() - 获取所有节点信息（默认+自定义）
/// 8. updateEndpointName(String url, String newName) - 更新节点名称
class NetworkMonitorService {
  /// 默认API节点列表
  static final List<EndpointInfo> defaultEndpoints = [
    EndpointInfo(url: 'https://hk2.xiaoyi.ink', name: '香港线路', isDefault: true),
    EndpointInfo(url: 'https://jp.xiaoyi.ink', name: '日本线路', isDefault: true),
    EndpointInfo(url: 'https://mg1.xiaoyi.ink', name: '美国线路', isDefault: true),
  ];

  /// 节点健康检查超时设置
  static const Duration _healthCheckTimeout = Duration(seconds: 3);

  /// SharedPreferences键名
  static const String _keyCurrentApiUrl = 'current_api_url';
  static const String _keyApiStatus = 'api_status';
  static const String _keyLastUpdated = 'api_last_updated';
  static const String _keyCustomEndpoints = 'custom_endpoints';

  /// 单例实例
  static final NetworkMonitorService _instance =
      NetworkMonitorService._internal();
  factory NetworkMonitorService() => _instance;

// 使用可重入锁，防止在同一个异步流程中嵌套调用 synchronized 方法时产生死锁
  final _lock = Lock(reentrant: true);
  late final Dio _dio;

  /// 初始化标记
  bool _initialized = false;
  Completer<void> _initCompleter = Completer<void>();

  /// 节点状态记录
  Map<String, dynamic> _endpointStatusMap = {};

  /// 用户自定义节点列表
  List<EndpointInfo> _customEndpoints = [];

  /// 私有构造函数
  NetworkMonitorService._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: _healthCheckTimeout,
      receiveTimeout: _healthCheckTimeout,
      sendTimeout: _healthCheckTimeout,
    ));

    // 后台初始化
    _initAsync();
  }

  /// 异步初始化
  void _initAsync() {
    Future.microtask(() async {
      try {
        await _initializeService();
      } catch (e) {
        debugPrint('[网络监控] 初始化出错: $e');
      } finally {
        // 无论成功失败都标记为完成初始化
        if (!_initCompleter.isCompleted) {
          _initCompleter.complete();
        }
        _initialized = true;
      }
    });
  }

  /// 初始化服务
  Future<void> _initializeService() async {
    try {
      await _loadCustomEndpoints();
      await _loadEndpointStatusFromStorage();

      // 在初始化时刷新所有节点状态，但不阻塞等待它完成
      refreshEndpointStatus().then((_) {
        debugPrint('[网络监控] 初始化刷新节点状态完成');
      }).catchError((e) {
        debugPrint('[网络监控] 初始化刷新节点状态出错: $e');
      });

      debugPrint('[网络监控] 服务初始化完成');
    } catch (e) {
      debugPrint('[网络监控] 服务初始化出错: $e');
      // 即使出错也继续，确保应用能启动
    }
  }

  /// 从存储加载自定义节点列表
  Future<void> _loadCustomEndpoints() async {
    return _lock.synchronized(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final customEndpointsJson = prefs.getString(_keyCustomEndpoints);

        if (customEndpointsJson != null) {
          final List<dynamic> jsonList = jsonDecode(customEndpointsJson);
          _customEndpoints =
              jsonList.map((json) => EndpointInfo.fromJson(json)).toList();
          debugPrint('[网络监控] 从存储加载自定义节点: $_customEndpoints');
        } else {
          _customEndpoints = [];
          debugPrint('[网络监控] 没有保存的自定义节点');
        }
      } catch (e) {
        debugPrint('[网络监控] 加载自定义节点出错: $e');
        _customEndpoints = [];
      }
    });
  }

  /// 保存自定义节点列表到存储
  Future<void> _saveCustomEndpoints() async {
    return _lock.synchronized(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonList = _customEndpoints.map((e) => e.toJson()).toList();
        await prefs.setString(_keyCustomEndpoints, jsonEncode(jsonList));
        debugPrint('[网络监控] 自定义节点已保存到存储');
      } catch (e) {
        debugPrint('[网络监控] 保存自定义节点出错: $e');
      }
    });
  }

  /// 从存储加载节点状态
  Future<void> _loadEndpointStatusFromStorage() async {
    return _lock.synchronized(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final statusJson = prefs.getString(_keyApiStatus);

        if (statusJson != null) {
          final decodedJson = jsonDecode(statusJson);
          _endpointStatusMap = Map<String, dynamic>.from(decodedJson);
          debugPrint('[网络监控] 从存储加载节点状态: $_endpointStatusMap');
        } else {
          final allEndpointUrls = getAllEndpointUrls();
          _endpointStatusMap = {
            'currentEndpoint':
                allEndpointUrls.isNotEmpty ? allEndpointUrls.first : null,
            'endpoints': <String, dynamic>{},
            'lastUpdated': DateTime.now().millisecondsSinceEpoch
          };
          debugPrint('[网络监控] 没有保存的节点状态，将创建新状态');
        }

        // 确保有当前节点
        final allEndpointUrls = getAllEndpointUrls();
        if (_endpointStatusMap['currentEndpoint'] == null &&
            allEndpointUrls.isNotEmpty) {
          _endpointStatusMap['currentEndpoint'] = allEndpointUrls.first;
        } else if (!allEndpointUrls
            .contains(_endpointStatusMap['currentEndpoint'])) {
          // 如果当前节点不在节点列表中，重置为第一个可用节点
          _endpointStatusMap['currentEndpoint'] =
              allEndpointUrls.isNotEmpty ? allEndpointUrls.first : null;
        }
      } catch (e) {
        debugPrint('[网络监控] 加载节点状态出错: $e');
        final allEndpointUrls = getAllEndpointUrls();
        _endpointStatusMap = {
          'currentEndpoint':
              allEndpointUrls.isNotEmpty ? allEndpointUrls.first : null,
          'endpoints': <String, dynamic>{},
          'lastUpdated': DateTime.now().millisecondsSinceEpoch
        };
      }
    });
  }

  /// 保存节点状态到存储
  Future<void> _saveEndpointStatusToStorage() async {
    return _lock.synchronized(() async {
      try {
        // 更新时间戳
        _endpointStatusMap['lastUpdated'] =
            DateTime.now().millisecondsSinceEpoch;

        final prefs = await SharedPreferences.getInstance();
        final statusJson = jsonEncode(_endpointStatusMap);

        await prefs.setString(_keyApiStatus, statusJson);

        // 同时更新currentApiUrl
        final currentEndpoint = _endpointStatusMap['currentEndpoint'];
        if (currentEndpoint != null) {
          await prefs.setString(_keyCurrentApiUrl, currentEndpoint);
        }

        debugPrint('[网络监控] 节点状态已保存到存储');
      } catch (e) {
        debugPrint('[网络监控] 保存节点状态出错: $e');
      }
    });
  }

  /// 检查端点健康状态
  Future<Map<String, dynamic>> _checkEndpointHealth(String endpoint) async {
    final result = <String, dynamic>{
      'endpoint': endpoint,
      'available': false,
      'responseTime': 9999,
      'lastChecked': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final stopwatch = Stopwatch()..start();

      final response = await _dio.get(
        '$endpoint/health',
        options: Options(
          receiveTimeout: _healthCheckTimeout,
          sendTimeout: _healthCheckTimeout,
        ),
      );

      stopwatch.stop();

      if (response.statusCode == 200 &&
          response.data.toString().contains('healthy')) {
        result['available'] = true;
        result['responseTime'] = stopwatch.elapsedMilliseconds;
      }
    } catch (e) {
      String errorType = "未知错误";
      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
            errorType = "连接超时";
            break;
          case DioExceptionType.receiveTimeout:
            errorType = "接收超时";
            break;
          case DioExceptionType.sendTimeout:
            errorType = "发送超时";
            break;
          default:
            errorType = "网络错误 ${e.type}";
        }
      }

      debugPrint('[网络监控] 节点 $endpoint 检查失败: $errorType');
    }

    return result;
  }

  /// 根据URL获取节点名称
  String getEndpointName(String url) {
    // 先检查默认节点
    for (final endpoint in defaultEndpoints) {
      if (endpoint.url == url) {
        return endpoint.name;
      }
    }

    // 再检查自定义节点
    for (final endpoint in _customEndpoints) {
      if (endpoint.url == url) {
        return endpoint.name;
      }
    }

    // 如果没有找到，返回URL作为名称
    return url;
  }

  /// 获取所有节点URL列表（仅URL）
  List<String> getAllEndpointUrls() {
    final result = <String>[];
    for (final endpoint in defaultEndpoints) {
      result.add(endpoint.url);
    }
    for (final endpoint in _customEndpoints) {
      result.add(endpoint.url);
    }
    return result;
  }

  //---------------------------------------------------------------------
  // 公共API
  //---------------------------------------------------------------------

  /// 获取当前选中的API节点
  /// 返回完整的API基础URL (例如: https://example.com)
  Future<String> getCurrentEndpoint() async {
    // 如果服务尚未初始化，等待初始化完成（加入超时保护）
    if (!_initialized) {
      debugPrint('[网络监控] 等待初始化完成');
      try {
        await _initCompleter.future.timeout(Duration(seconds: 5),
            onTimeout: () {
          debugPrint('[网络监控] 初始化等待超时，将继续流程');
          _initialized = true;
        });
      } catch (e) {
        debugPrint('[网络监控] 初始化等待出错: $e，将继续流程');
        _initialized = true;
      }
    }

    return _lock.synchronized(() async {
      // 从状态映射获取当前节点
      String? currentEndpoint =
          _endpointStatusMap['currentEndpoint'] as String?;
      final allEndpointUrls = getAllEndpointUrls();

      // 如果没有当前节点或当前节点不在列表中，使用默认节点
      if (currentEndpoint == null ||
          !allEndpointUrls.contains(currentEndpoint)) {
        currentEndpoint = allEndpointUrls.isNotEmpty
            ? allEndpointUrls.first
            : defaultEndpoints.first.url;
        _endpointStatusMap['currentEndpoint'] = currentEndpoint;
        await _saveEndpointStatusToStorage();
      }

      return currentEndpoint;
    });
  }

  /// 设置当前使用的API节点
  Future<void> setCurrentEndpoint(String endpoint) async {
    // 验证输入的endpoint是否在列表中
    final allEndpointUrls = getAllEndpointUrls();
    if (!allEndpointUrls.contains(endpoint)) {
      throw Exception('无效的API节点: $endpoint');
    }

    return _lock.synchronized(() async {
      _endpointStatusMap['currentEndpoint'] = endpoint;
      await _saveEndpointStatusToStorage();
      debugPrint('[网络监控] 已设置当前节点为: $endpoint');
    });
  }

  /// 刷新所有节点状态
  Future<void> refreshEndpointStatus() async {
    return _lock.synchronized(() async {
      debugPrint('[网络监控] 开始刷新所有节点状态');

      try {
        // 获取所有节点URL
        final allEndpointUrls = getAllEndpointUrls();

        // 检查所有节点，收集结果
        final futureResults = <Future<Map<String, dynamic>>>[];

        for (final endpoint in allEndpointUrls) {
          futureResults.add(_checkEndpointHealth(endpoint));
        }

        // 等待所有结果
        final results = await Future.wait(futureResults);

        // 更新节点状态映射
        final endpointsMap =
            _endpointStatusMap['endpoints'] as Map<String, dynamic>? ?? {};

        for (final result in results) {
          final endpoint = result['endpoint'] as String;
          endpointsMap[endpoint] = result;

          final available = result['available'] as bool;
          final responseTime = result['responseTime'] as int;
          debugPrint(
              '[网络监控] $endpoint - 可用: $available, 响应时间: ${responseTime}ms');
        }

        // 更新状态映射
        _endpointStatusMap['endpoints'] = endpointsMap;
        _endpointStatusMap['lastUpdated'] =
            DateTime.now().millisecondsSinceEpoch;

        // 保存状态
        await _saveEndpointStatusToStorage();

        debugPrint('[网络监控] 节点状态刷新完成');
      } catch (e) {
        debugPrint('[网络监控] 刷新节点状态出错: $e');
      }
    });
  }

  /// 获取所有节点状态（用于UI显示）
  Future<Map<String, dynamic>> getAllEndpointStatus() async {
    // 如果服务尚未初始化，等待初始化完成
    if (!_initialized) {
      await _initCompleter.future.timeout(Duration(seconds: 5), onTimeout: () {
        debugPrint('[网络监控] 获取状态时，初始化等待超时');
        _initialized = true;
      });
    }

    return _lock.synchronized(() async {
      // 深拷贝状态映射，避免外部修改
      final statusMap = Map<String, dynamic>.from(_endpointStatusMap);

      // 添加节点名称信息
      final endpointsMap =
          statusMap['endpoints'] as Map<String, dynamic>? ?? {};
      for (final url in endpointsMap.keys) {
        final endpointData = endpointsMap[url] as Map<String, dynamic>;
        endpointData['name'] = getEndpointName(url);
      }

      return statusMap;
    });
  }

  /// 获取所有节点信息（默认+自定义）
  List<EndpointInfo> getAllEndpoints() {
    final List<EndpointInfo> allEndpoints = [];
    allEndpoints.addAll(defaultEndpoints);
    allEndpoints.addAll(_customEndpoints);
    return allEndpoints;
  }

  /// 添加自定义节点
  /// [url] 节点URL，例如：https://example.com
  /// [name] 节点名称，例如：自定义节点1
  /// 返回true表示添加成功，false表示节点已存在或无效
  Future<bool> addCustomEndpoint(String url, String name) async {
    // 验证URL格式
    if (!_isValidUrl(url)) {
      debugPrint('[网络监控] 无效的URL格式: $url');
      return false;
    }

    // 确保以https://或http://开头
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    // 去除URL末尾的斜杠
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    return _lock.synchronized(() async {
      // 检查是否已存在（默认或自定义）
      final allEndpointUrls = getAllEndpointUrls();
      if (allEndpointUrls.contains(url)) {
        debugPrint('[网络监控] 节点已存在: $url');
        return false;
      }

      // 添加到自定义节点列表
      final newEndpoint = EndpointInfo(url: url, name: name);
      _customEndpoints.add(newEndpoint);
      await _saveCustomEndpoints();

      // 检查新节点状态
      final result = await _checkEndpointHealth(url);

      // 更新节点状态映射
      final endpointsMap =
          _endpointStatusMap['endpoints'] as Map<String, dynamic>? ?? {};
      endpointsMap[url] = result;
      _endpointStatusMap['endpoints'] = endpointsMap;
      await _saveEndpointStatusToStorage();

      debugPrint('[网络监控] 已添加自定义节点: $name ($url)');
      return true;
    });
  }

  /// 删除自定义节点
  /// 注意：只能删除自定义节点，默认节点不能删除
  Future<bool> removeCustomEndpoint(String url) async {
    return _lock.synchronized(() async {
      // 检查是否为默认节点
      for (final endpoint in defaultEndpoints) {
        if (endpoint.url == url) {
          debugPrint('[网络监控] 默认节点不能删除: $url');
          return false;
        }
      }

      // 检查是否为自定义节点
      bool found = false;
      for (final endpoint in _customEndpoints) {
        if (endpoint.url == url) {
          found = true;
          break;
        }
      }
      if (!found) {
        debugPrint('[网络监控] 自定义节点不存在: $url');
        return false;
      }

      // 从自定义节点列表中移除
      _customEndpoints.removeWhere((endpoint) => endpoint.url == url);
      await _saveCustomEndpoints();

      // 从节点状态映射中移除
      final endpointsMap =
          _endpointStatusMap['endpoints'] as Map<String, dynamic>? ?? {};
      endpointsMap.remove(url);
      _endpointStatusMap['endpoints'] = endpointsMap;

      // 如果当前节点是被删除的节点，重置为第一个可用节点
      if (_endpointStatusMap['currentEndpoint'] == url) {
        final allEndpointUrls = getAllEndpointUrls();
        _endpointStatusMap['currentEndpoint'] =
            allEndpointUrls.isNotEmpty ? allEndpointUrls.first : null;
      }

      await _saveEndpointStatusToStorage();

      debugPrint('[网络监控] 已删除自定义节点: $url');
      return true;
    });
  }

  /// 更新节点名称
  /// 可以更新默认节点或自定义节点的名称
  Future<bool> updateEndpointName(String url, String newName) async {
    return _lock.synchronized(() async {
      // 检查是否为默认节点
      for (final endpoint in defaultEndpoints) {
        if (endpoint.url == url) {
          endpoint.name = newName;
          debugPrint('[网络监控] 已更新默认节点名称: $url -> $newName');
          return true;
        }
      }

      // 检查是否为自定义节点
      for (var i = 0; i < _customEndpoints.length; i++) {
        if (_customEndpoints[i].url == url) {
          _customEndpoints[i].name = newName;
          await _saveCustomEndpoints();
          debugPrint('[网络监控] 已更新自定义节点名称: $url -> $newName');
          return true;
        }
      }

      debugPrint('[网络监控] 节点不存在，无法更新名称: $url');
      return false;
    });
  }

  /// 获取自定义节点列表
  List<EndpointInfo> getCustomEndpoints() {
    return List<EndpointInfo>.from(_customEndpoints);
  }

  /// 获取默认节点列表
  List<EndpointInfo> getDefaultEndpoints() {
    return List<EndpointInfo>.from(defaultEndpoints);
  }

  /// 验证URL格式
  bool _isValidUrl(String url) {
    try {
      // 添加协议如果没有
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }
}
