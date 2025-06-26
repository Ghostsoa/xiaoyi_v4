import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import '../net/http_client.dart';

/// 网络监控服务，管理API节点的可用性、选择和切换
/// 对外只提供两个主要接口:
/// 1. getApiEndpoint() - 获取可用API节点，从数据库获取，没有则强制刷新
/// 2. switchToNextEndpoint() - 切换到下一个可用节点
class NetworkMonitorService {
  /// API节点列表
  static const List<String> _apiEndpoints = [
    'https://hk2.xiaoyi.ink',
    'https://jp.xiaoyi.ink',
  ];

  /// 日本节点相关配置
  static const String _jpEndpoint = 'https://jp.xiaoyi.ink';
  static const double _jpWeightFactor = 0.9; // 日本节点权重因子，略微降低权重
  
  /// 节点健康检查超时设置
  static const Duration _healthCheckTimeout = Duration(seconds: 3);
  
  /// SharedPreferences键名
  static const String _keyCurrentApiUrl = 'current_api_url';
  static const String _keyApiStatus = 'api_status';
  static const String _keyLastUpdated = 'api_last_updated';
  
  /// 单例实例
  static final NetworkMonitorService _instance = NetworkMonitorService._internal();
  factory NetworkMonitorService() => _instance;

  /// 用于节点管理的私有变量
  final _readLock = Lock();
  final _writeLock = Lock();
  late final Dio _dio;
  Timer? _backgroundMonitorTimer;
  
  /// 初始化标记
  bool _initialized = false;
  Completer<void> _initCompleter = Completer<void>();
  
  /// 节点状态记录
  Map<String, dynamic> _nodeStatusMap = {};
  
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
      await _loadNodeStatusFromStorage();
      
      // 如果没有可用节点或数据过期，强制刷新，但不阻塞等待它完成
      if (_needRefresh()) {
        debugPrint('[网络监控] 需要刷新节点状态');
        // 不等待刷新完成，让它在后台进行
        _refreshNodeStatus().then((_) {
          debugPrint('[网络监控] 后台刷新节点状态完成');
        }).catchError((e) {
          debugPrint('[网络监控] 后台刷新节点状态出错: $e');
        });
      } else {
        debugPrint('[网络监控] 使用缓存的节点状态，不需要刷新');
      }

      // 启动后台监控
      _startBackgroundMonitor();
      
      debugPrint('[网络监控] 服务初始化完成');
    } catch (e) {
      debugPrint('[网络监控] 服务初始化出错: $e');
      // 即使出错也继续，确保应用能启动
    }
  }
  
  /// 判断是否需要刷新节点状态
  bool _needRefresh() {
    // 获取当前可用节点
    final availableNodes = _getAvailableNodes();

    // 如果没有可用节点，需要刷新
    if (availableNodes.isEmpty) {
      return true;
    }
    
    // 检查数据是否过期(超过5分钟)
    final lastUpdated = _nodeStatusMap['lastUpdated'] as int?;
    if (lastUpdated == null) {
      return true;
    }
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final fiveMinutes = 5 * 60 * 1000; // 5分钟
    return (now - lastUpdated) > fiveMinutes;
  }

  /// 从存储加载节点状态
  Future<void> _loadNodeStatusFromStorage() async {
    return _readLock.synchronized(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final statusJson = prefs.getString(_keyApiStatus);
        
        if (statusJson != null) {
          final decodedJson = jsonDecode(statusJson);
          _nodeStatusMap = Map<String, dynamic>.from(decodedJson);
          debugPrint('[网络监控] 从存储加载节点状态: $_nodeStatusMap');
                } else {
          _nodeStatusMap = {'nodes': <String, dynamic>{}};
          debugPrint('[网络监控] 没有保存的节点状态，将创建新状态');
        }
      } catch (e) {
        debugPrint('[网络监控] 加载节点状态出错: $e');
        _nodeStatusMap = {'nodes': <String, dynamic>{}};
      }
    });
  }

  /// 保存节点状态到存储
  Future<void> _saveNodeStatusToStorage() async {
    return _writeLock.synchronized(() async {
      try {
        // 更新时间戳
        _nodeStatusMap['lastUpdated'] = DateTime.now().millisecondsSinceEpoch;
        
        final prefs = await SharedPreferences.getInstance();
        final statusJson = jsonEncode(_nodeStatusMap);
        
        await prefs.setString(_keyApiStatus, statusJson);
        
        // 如果有当前节点，同时更新currentApiUrl
        final currentNode = _getCurrentNode();
        if (currentNode != null) {
          await prefs.setString(_keyCurrentApiUrl, currentNode);
        }

        debugPrint('[网络监控] 节点状态已保存到存储');
      } catch (e) {
        debugPrint('[网络监控] 保存节点状态出错: $e');
      }
    });
  }

  /// 启动后台监控
  void _startBackgroundMonitor() {
    // 取消现有定时器
    _backgroundMonitorTimer?.cancel();
    
    // 每5分钟检查一次节点状态
    _backgroundMonitorTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _refreshNodeStatus();
    });
  }

  /// 刷新节点状态
  Future<void> _refreshNodeStatus() async {
    return _writeLock.synchronized(() async {
      debugPrint('[网络监控] 开始刷新节点状态');
      
      try {
        // 检查所有节点，收集结果
        final futureResults = <Future<Map<String, dynamic>>>[];
        
      for (final endpoint in _apiEndpoints) {
          futureResults.add(_checkEndpointHealth(endpoint));
        }
        
        // 等待所有结果
        final results = await Future.wait(futureResults);
        
        // 更新节点状态映射
        final nodesMap = <String, dynamic>{};
        final availableNodes = <String>[];
        
        for (final result in results) {
          final endpoint = result['endpoint'] as String;
          final available = result['available'] as bool;
          final responseTime = result['responseTime'] as int;
          
          // 计算加权响应时间
          int weightedResponseTime = responseTime;
          if (available && endpoint == _jpEndpoint) {
            weightedResponseTime = (responseTime * _jpWeightFactor).toInt();
          }
          
          nodesMap[endpoint] = <String, dynamic>{
            'available': available,
            'responseTime': responseTime,
            'weightedResponseTime': weightedResponseTime,
            'lastChecked': DateTime.now().millisecondsSinceEpoch,
          };
          
          if (available) {
            availableNodes.add(endpoint);
          }
        }
        
        // 更新状态映射
        _nodeStatusMap['nodes'] = nodesMap;
        
        // 如果当前节点不可用，选择一个新节点
        final currentNode = _getCurrentNode();
        if (currentNode == null || !_isNodeAvailable(currentNode)) {
          final bestNode = _selectBestNode();
          if (bestNode != null) {
            _nodeStatusMap['currentNode'] = bestNode;
            debugPrint('[网络监控] 当前节点不可用，已切换到: $bestNode');
          }
        }
        
        // 保存状态 - 防止阻塞，使用Future而不等待它完成
        // 这是一个关键修改：不再等待保存完成，允许初始化流程继续
        _saveNodeStatusToStorage().catchError((e) {
          debugPrint('[网络监控] 保存节点状态出错: $e');
        });
        
        debugPrint('[网络监控] 节点状态刷新完成');
      for (final endpoint in _apiEndpoints) {
          final nodeStatus = nodesMap[endpoint] as Map<String, dynamic>?;
          if (nodeStatus != null) {
            final available = nodeStatus['available'] as bool? ?? false;
            final responseTime = nodeStatus['responseTime'] as int? ?? 9999;
            final weightedTime = nodeStatus['weightedResponseTime'] as int? ?? 9999;
            
            debugPrint('[网络监控] $endpoint - 可用: $available, 响应时间: ${responseTime}ms, 加权时间: ${weightedTime}ms');
          }
        }
        
        final current = _getCurrentNode();
        debugPrint('[网络监控] 当前节点: $current');
        debugPrint('[网络监控] 状态刷新完成，继续应用初始化流程');
      } catch (e) {
        debugPrint('[网络监控] 刷新节点状态出错: $e');
        // 即使出错也要继续，允许应用初始化
      }
    });
  }

  /// 检查端点健康状态
  Future<Map<String, dynamic>> _checkEndpointHealth(String endpoint) async {
    final result = <String, dynamic>{
      'endpoint': endpoint,
      'available': false,
      'responseTime': 9999,
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
  
  /// 获取当前节点
  String? _getCurrentNode() {
    return _nodeStatusMap['currentNode'] as String?;
  }
  
  /// 检查节点是否可用
  bool _isNodeAvailable(String endpoint) {
    final nodes = _nodeStatusMap['nodes'];
    if (nodes is! Map<String, dynamic>) return false;
    
    final nodesMap = nodes;
    final nodeData = nodesMap[endpoint];
    if (nodeData is! Map<String, dynamic>) return false;
    
    final nodeInfo = nodeData;
    return nodeInfo['available'] as bool? ?? false;
  }

  /// 获取所有可用节点
  List<String> _getAvailableNodes() {
    final result = <String>[];
    
    final nodes = _nodeStatusMap['nodes'];
    if (nodes is! Map<String, dynamic>) return result;
    
    final nodesMap = nodes;
    
    for (final endpoint in _apiEndpoints) {
      final nodeData = nodesMap[endpoint];
      if (nodeData is! Map<String, dynamic>) continue;
      
      final nodeInfo = nodeData;
      if (nodeInfo['available'] as bool? ?? false) {
        result.add(endpoint);
      }
    }
    
    return result;
  }
  
  /// 选择最佳节点
  String? _selectBestNode() {
    final availableNodes = _getAvailableNodes();
    if (availableNodes.isEmpty) return null;
    if (availableNodes.length == 1) return availableNodes.first;
    
    // 根据加权响应时间选择最佳节点
    String? bestNode;
    int bestResponseTime = 999999;
    
    final nodes = _nodeStatusMap['nodes'];
    if (nodes is! Map<String, dynamic>) {
      debugPrint('[网络监控] 节点数据格式不正确，无法选择最佳节点');
      return availableNodes.first; // 无法比较，返回第一个可用节点
    }
    
    final nodesMap = nodes;
    
    for (final endpoint in availableNodes) {
      final nodeData = nodesMap[endpoint];
      if (nodeData is! Map<String, dynamic>) continue;
      
      final nodeInfo = nodeData;
      final weightedTime = nodeInfo['weightedResponseTime'] as int? ?? 999999;
      
      if (weightedTime < bestResponseTime) {
        bestResponseTime = weightedTime;
        bestNode = endpoint;
      }
    }
    
    return bestNode ?? availableNodes.first;
        }
  
  //---------------------------------------------------------------------
  // 公共API
  //---------------------------------------------------------------------
  
  /// 获取可用的API节点
  /// 如果数据库中有可用节点，直接返回
  /// 如果没有可用节点，会强制刷新并同步等待
  /// 返回完整的API基础URL (例如: https://example.com)
  Future<String> getApiEndpoint() async {
    // 添加超时保护，避免永久阻塞
    debugPrint('[网络监控] 开始获取API节点');
    
    // 如果服务尚未初始化，等待初始化完成（加入超时保护）
    if (!_initialized) {
      debugPrint('[网络监控] 等待初始化完成');
      try {
        await _initCompleter.future.timeout(Duration(seconds: 10), 
          onTimeout: () {
            debugPrint('[网络监控] 初始化等待超时，将继续流程');
            _initialized = true;
          });
      } catch (e) {
        debugPrint('[网络监控] 初始化等待出错: $e，将继续流程');
        _initialized = true;
      }
    }
    
    // 从状态映射获取当前节点
    String? currentNode = _getCurrentNode();
    debugPrint('[网络监控] 当前节点状态: $currentNode');
    
    // 检查数据库中是否有可用节点并且确实可用
    final hasValidNodeInDatabase = currentNode != null && _isNodeAvailable(currentNode);
    
    if (hasValidNodeInDatabase) {
      debugPrint('[网络监控] 使用数据库中的可用节点: $currentNode');
      return currentNode;
    }
    
    // 如果没有可用节点或当前节点不可用，强制刷新
    debugPrint('[网络监控] 数据库中无可用节点，强制刷新节点状态');
    
    try {
      // 添加超时保护
      await _refreshNodeStatus().timeout(Duration(seconds: 10), 
        onTimeout: () {
          debugPrint('[网络监控] 刷新节点状态超时，将使用默认节点');
        });
    } catch (e) {
      debugPrint('[网络监控] 刷新节点状态出错: $e，将使用默认节点');
    }
    
    // 再次获取当前节点
    currentNode = _getCurrentNode();
    
    // 如果仍然没有可用节点，使用默认节点（避免抛出异常）
    if (currentNode == null) {
      debugPrint('[网络监控] 没有找到可用节点，使用默认节点');
      return _apiEndpoints.first; // 使用列表中的第一个节点作为默认
    }
    
    debugPrint('[网络监控] 返回当前节点: $currentNode');
    return currentNode;
  }

  /// 切换到下一个可用节点
  /// 返回新的API节点，如果没有其他可用节点则返回原节点
  Future<String> switchToNextEndpoint() async {
    return _writeLock.synchronized(() async {
      // 如果服务尚未初始化，等待初始化完成
      if (!_initialized) {
        await _initCompleter.future;
      }
      
      debugPrint('[网络监控] 尝试切换到下一个可用节点');
      
      // 获取当前节点
      final currentNode = _getCurrentNode();
      if (currentNode == null) {
        // 如果没有当前节点，强制刷新并返回新节点
        await _refreshNodeStatus();
        final newNode = _getCurrentNode();
        if (newNode != null) {
          return newNode;
        }
        throw Exception('没有可用的API节点');
      }
      
      // 获取所有可用节点
      final availableNodes = _getAvailableNodes();
      
      // 如果没有可用节点，强制刷新
      if (availableNodes.isEmpty) {
        await _refreshNodeStatus();
        
        // 再次获取可用节点
        final newAvailableNodes = _getAvailableNodes();
        if (newAvailableNodes.isEmpty) {
          throw Exception('没有可用的API节点');
        }
        
        // 设置新节点
        final newNode = newAvailableNodes.first;
        _nodeStatusMap['currentNode'] = newNode;
        await _saveNodeStatusToStorage();
        
        debugPrint('[网络监控] 切换到新节点: $newNode');
        return newNode;
      }
      
      // 如果有多个可用节点，选择当前节点以外的节点
      final otherNodes = availableNodes.where((node) => node != currentNode).toList();
      if (otherNodes.isNotEmpty) {
        // 从其他可用节点中选择响应时间最短的
        String? bestNode;
        int bestResponseTime = 999999;
        
        final nodesMap = _nodeStatusMap['nodes'] as Map<String, dynamic>;
        
        for (final endpoint in otherNodes) {
          final nodeInfo = nodesMap[endpoint] as Map<String, dynamic>;
          final weightedTime = nodeInfo['weightedResponseTime'] as int? ?? 999999;
          
          if (weightedTime < bestResponseTime) {
            bestResponseTime = weightedTime;
            bestNode = endpoint;
          }
        }
        
        if (bestNode != null) {
          _nodeStatusMap['currentNode'] = bestNode;
          await _saveNodeStatusToStorage();
          
          debugPrint('[网络监控] 切换到新节点: $bestNode');
          return bestNode;
        }
      }
      
      // 如果没有其他可用节点，返回当前节点
      return currentNode;
    });
  }
  
  /// 获取所有节点状态（用于UI显示）
  Future<Map<String, dynamic>> getAllNodeStatus() async {
    // 如果服务尚未初始化，等待初始化完成
    if (!_initialized) {
      await _initCompleter.future;
    }
    
    return _readLock.synchronized(() async {
      // 深拷贝状态映射，避免外部修改
      return Map<String, dynamic>.from(_nodeStatusMap);
    });
  }
}
