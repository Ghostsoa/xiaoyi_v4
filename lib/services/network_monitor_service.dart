import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    'https://xjp.xiaoyi.ink',
  ];

  // 默认线路（如果都不可用时使用）
  static const String _defaultEndpoint = 'https://hk2.xiaoyi.ink';

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

  // 初始化并开始监控
  Future<void> initialize() async {
    // 初始化线路状态
    for (final endpoint in _apiEndpoints) {
      _endpointAvailability[endpoint] = false;
      _endpointResponseTimes[endpoint] = 9999;
    }

    // 先执行一次检测，设置初始URL
    await _checkNetworkQuality();
    _isInitialized = true;

    // 开始定期监控
    startMonitoring();
  }

  // 获取当前最佳线路，如果尚未初始化则执行一次检测
  Future<String> getBestApiEndpoint() async {
    if (!_isInitialized) {
      // 如果尚未初始化，执行一次检测
      await _checkNetworkQuality();
      _isInitialized = true;
    }
    return _currentApiUrl;
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
    final results = await Future.wait(
      _apiEndpoints.map((endpoint) => _checkEndpointHealth(endpoint)),
    );

    // 更新线路状态
    final availableEndpoints = <String>[];
    final statusInfo = StringBuffer('[网络监控] 线路状态: ');

    for (int i = 0; i < _apiEndpoints.length; i++) {
      final endpoint = _apiEndpoints[i];
      final responseTime = results[i];

      // 更新可用性和响应时间
      _endpointAvailability[endpoint] = responseTime > 0;
      if (responseTime > 0) {
        _endpointResponseTimes[endpoint] = responseTime;
        availableEndpoints.add(endpoint);
        statusInfo.write('$endpoint(${responseTime}ms) ');
      } else {
        statusInfo.write('$endpoint(不可用) ');
      }
    }

    // 选择最佳线路
    String bestEndpoint = _selectBestEndpoint(availableEndpoints);

    // 如果当前线路与最佳线路不同，则切换
    if (_currentApiUrl != bestEndpoint) {
      _switchApiEndpoint(bestEndpoint);
      statusInfo.write('- 切换到: $bestEndpoint');
    } else {
      statusInfo.write('- 保持: $_currentApiUrl');
    }

    // 输出一条简单的状态日志
    debugPrint(statusInfo.toString());
  }

  // 选择最佳线路
  String _selectBestEndpoint(List<String> availableEndpoints) {
    // 如果有可用线路，选择最快的
    if (availableEndpoints.isNotEmpty) {
      availableEndpoints.sort((a, b) =>
          _endpointResponseTimes[a]!.compareTo(_endpointResponseTimes[b]!));
      return availableEndpoints.first;
    }

    // 如果没有可用线路，返回默认线路
    return _defaultEndpoint;
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
  String getCurrentApiUrl() {
    return _currentApiUrl;
  }

  // 获取所有线路状态
  Map<String, dynamic> getEndpointsStatus() {
    final result = <String, dynamic>{};
    for (final endpoint in _apiEndpoints) {
      result[endpoint] = {
        'available': _endpointAvailability[endpoint] ?? false,
        'responseTime': _endpointResponseTimes[endpoint] ?? -1,
        'isCurrent': endpoint == _currentApiUrl,
      };
    }
    return result;
  }

  // 手动设置API线路
  void setApiEndpoint(String endpoint) {
    if (_apiEndpoints.contains(endpoint)) {
      _switchApiEndpoint(endpoint);
    }
  }

  // 手动刷新线路状态
  Future<void> refreshEndpointsStatus() async {
    await _checkNetworkQuality();
  }
}
