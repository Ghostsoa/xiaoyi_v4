import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import '../dao/user_dao.dart';
import '../pages/login/login_page.dart';
import '../services/network_monitor_service.dart';

/// HTTP客户端，处理所有网络请求
/// 不包含任何节点选择或切换逻辑，完全依赖NetworkMonitorService来管理节点
class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  late Dio _dio;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// 初始化标记
  bool _initialized = false;
  
  /// 上次更新节点的时间戳
  int _lastEndpointUpdateTime = 0;
  
  /// 节点更新的最小间隔（毫秒）
  static const int _minEndpointUpdateInterval = 5000; // 5秒
  
  /// 获取实例的工厂方法（单例模式）
  factory HttpClient() => _instance;

  HttpClient._internal() {
    _initClient();
  }
  
  /// 确保HttpClient已经完全初始化
  /// 如果尚未初始化，会同步完成初始化
  /// 如果已经初始化，确保有可用的API节点
  Future<void> ensureInitialized() async {
    // 等待初始化完成
    if (!_initialized) {
      debugPrint('[HttpClient] 正在初始化HttpClient...');
      await _initCompleter.future;
    }
    
    // 即使已初始化，也确保有可用的API节点
    await _updateApiEndpoint(forceRefresh: true);
    
    // 确认baseUrl不为空
    if (_dio.options.baseUrl.isEmpty) {
      throw Exception('HttpClient初始化失败: 无法获取有效的API节点');
    }
    
    debugPrint('[HttpClient] HttpClient已完全初始化，使用节点: ${_dio.options.baseUrl}');
  }
  
  /// 异步初始化完成标记
  final Completer<void> _initCompleter = Completer<void>();
  
  /// 初始化客户端
  Future<void> _initClient() async {
    try {
      // 创建Dio实例，先使用空的baseUrl，后续会更新
      _dio = Dio(BaseOptions(
        baseUrl: '',  // 初始化时不设置baseUrl，等待获取节点
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ));
  
      // 添加缓存拦截器
      final cacheOptions = CacheOptions(
        store: MemCacheStore(),
        policy: CachePolicy.request,
        hitCacheOnErrorExcept: [],
        maxStale: const Duration(days: 1),
        priority: CachePriority.normal,
      );
      _dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
  
      // 添加日志拦截器
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
  
      // 添加错误处理拦截器（只处理身份验证错误，不做节点切换）
      _dio.interceptors.add(InterceptorsWrapper(
        onError: (DioException error, handler) async {
          // 仅处理令牌失效的情况
          if (error.response?.data is Map<String, dynamic>) {
            final responseData = error.response?.data as Map<String, dynamic>;
            if (responseData['code'] == 1019 ||
                responseData['msg']?.toString().contains('令牌失效') == true) {
              _handleTokenExpired();
            }
          }
          
          return handler.next(error);
        },
        onResponse: (response, handler) {
          // 检查响应中的特定code，无论状态码是多少
          if (response.data is Map<String, dynamic>) {
            final responseData = response.data as Map<String, dynamic>;
            if (responseData['code'] == 1019 ||
                (response.statusCode != 200 &&
                    responseData['msg']?.toString().contains('令牌失效') == true)) {
              _handleTokenExpired();
            }
          }
          
          return handler.next(response);
        },
      ));
  
      // 异步获取初始API节点
      await _updateApiEndpoint(forceRefresh: true);
      
      // 标记初始化完成
      _initialized = true;
      
      // 完成初始化Completer
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e) {
      debugPrint('[HttpClient] 初始化失败: $e');
      // 如果初始化失败，也标记Completer为完成状态，避免永久阻塞
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
      // 不重新抛出异常，让后续操作有机会重试
    }
  }
  
  /// 更新API节点（从NetworkMonitorService获取）
  Future<void> _updateApiEndpoint({bool forceRefresh = false}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // 如果不是强制刷新，且距上次更新时间不足最小间隔，则跳过更新
    if (!forceRefresh && now - _lastEndpointUpdateTime < _minEndpointUpdateInterval) {
      return;
    }
    
    try {
      // 从网络监控服务获取可用节点
      final apiEndpoint = await NetworkMonitorService().getApiEndpoint();
      
      // 确保返回的节点是字符串类型
      if (apiEndpoint is! String || apiEndpoint.isEmpty) {
        debugPrint('[HttpClient] 获取到的API节点无效: $apiEndpoint');
        return;
      }
      
      // 设置baseUrl
      final apiBaseUrl = '$apiEndpoint/api/v1';
      
      // 只在baseUrl不同时更新，避免不必要的日志
      if (_dio.options.baseUrl != apiBaseUrl) {
        _dio.options.baseUrl = apiBaseUrl;
        debugPrint('[HttpClient] 已设置API节点: $apiBaseUrl');
      }
      
      // 更新时间戳
      _lastEndpointUpdateTime = now;
    } catch (e) {
      debugPrint('[HttpClient] 获取API节点失败: $e');
      // 出错时不做处理，让请求失败，可能会触发上层重试
    }
  }

  /// 处理令牌失效
  void _handleTokenExpired() async {
    // 清除用户信息
    final userDao = UserDao();
    await userDao.clearUserInfo();

    // 使用navigatorKey导航到登录页面
    if (navigatorKey.currentContext != null) {
      Navigator.pushAndRemoveUntil(
        navigatorKey.currentContext!,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  /// 刷新节点 - 在请求失败时可由上层调用
  Future<void> refreshApiEndpoint() async {
    try {
      // 请求NetworkMonitorService切换到下一个可用节点
      final newEndpoint = await NetworkMonitorService().switchToNextEndpoint();
      
      // 更新baseUrl
      final apiBaseUrl = '$newEndpoint/api/v1';
      _dio.options.baseUrl = apiBaseUrl;
      
      // 更新时间戳
      _lastEndpointUpdateTime = DateTime.now().millisecondsSinceEpoch;
      
      debugPrint('[HttpClient] 已切换到新节点: $apiBaseUrl');
    } catch (e) {
      debugPrint('[HttpClient] 切换节点失败: $e');
    }
  }

  /// 确保API节点已设置
  Future<void> _ensureApiEndpoint() async {
    // 如果baseUrl为空，尝试更新API节点
    if (_dio.options.baseUrl.isEmpty) {
      await _updateApiEndpoint(forceRefresh: true);
    } else {
      // 即使有baseUrl，也定期检查更新
      await _updateApiEndpoint();
    }
  }

  /// GET请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool autoRefreshEndpointOnFail = true,
  }) async {
    // 确保已设置baseUrl
    await _ensureApiEndpoint();
    
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      // 如果是网络错误且允许自动刷新节点，尝试切换节点并重试一次
      if (autoRefreshEndpointOnFail && _isNetworkError(e)) {
        debugPrint('[HttpClient] GET请求失败，尝试切换节点后重试: ${e.message}');
        await refreshApiEndpoint();
        
        // 重试请求
        try {
          return await _dio.get(
            path,
            queryParameters: queryParameters,
            options: options,
            cancelToken: cancelToken,
          );
        } on DioException catch (retryError) {
          return _handleError(retryError);
        }
      }
      
      return _handleError(e);
    }
  }

  /// POST请求
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    Duration? timeout,
    bool autoRefreshEndpointOnFail = true,
  }) async {
    // 确保已设置baseUrl
    await _ensureApiEndpoint();
    
    Options requestOptions = options ?? Options();
    if (timeout != null) {
      requestOptions = requestOptions.copyWith(
        sendTimeout: timeout,
        receiveTimeout: timeout,
      );
    }

    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      // 如果是网络错误且允许自动刷新节点，尝试切换节点并重试一次
      if (autoRefreshEndpointOnFail && _isNetworkError(e)) {
        debugPrint('[HttpClient] POST请求失败，尝试切换节点后重试: ${e.message}');
        await refreshApiEndpoint();
        
        // 重试请求
        try {
          return await _dio.post(
            path,
            data: data,
            queryParameters: queryParameters,
            options: requestOptions,
            cancelToken: cancelToken,
          );
        } on DioException catch (retryError) {
          return _handleError(retryError);
        }
      }
      
      return _handleError(e);
    }
  }

  /// PUT请求
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool autoRefreshEndpointOnFail = true,
  }) async {
    // 确保已设置baseUrl
    await _ensureApiEndpoint();
    
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      // 如果是网络错误且允许自动刷新节点，尝试切换节点并重试一次
      if (autoRefreshEndpointOnFail && _isNetworkError(e)) {
        debugPrint('[HttpClient] PUT请求失败，尝试切换节点后重试: ${e.message}');
        await refreshApiEndpoint();
        
        // 重试请求
        try {
          return await _dio.put(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
            cancelToken: cancelToken,
          );
        } on DioException catch (retryError) {
          return _handleError(retryError);
        }
      }
      
      return _handleError(e);
    }
  }

  /// DELETE请求
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool autoRefreshEndpointOnFail = true,
  }) async {
    // 确保已设置baseUrl
    await _ensureApiEndpoint();
    
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      // 如果是网络错误且允许自动刷新节点，尝试切换节点并重试一次
      if (autoRefreshEndpointOnFail && _isNetworkError(e)) {
        debugPrint('[HttpClient] DELETE请求失败，尝试切换节点后重试: ${e.message}');
        await refreshApiEndpoint();
        
        // 重试请求
        try {
          return await _dio.delete(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
            cancelToken: cancelToken,
          );
        } on DioException catch (retryError) {
          return _handleError(retryError);
        }
      }
      
      return _handleError(e);
    }
  }
  
  /// 流式请求 - 特殊处理，用于聊天等场景
  Future<Response> stream(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool autoRefreshEndpointOnFail = true,
  }) async {
    // 流式请求使用更长的超时时间
    Options streamOptions = options ?? Options();
    streamOptions = streamOptions.copyWith(
      responseType: ResponseType.stream,
      receiveTimeout: const Duration(minutes: 10),
    );
    
    // 确保已设置baseUrl
    await _ensureApiEndpoint();
    
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: streamOptions,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      // 如果是网络错误且允许自动刷新节点，尝试切换节点并重试一次
      if (autoRefreshEndpointOnFail && _isNetworkError(e)) {
        debugPrint('[HttpClient] 流式请求失败，尝试切换节点后重试: ${e.message}');
        await refreshApiEndpoint();
        
        // 重试请求
        try {
          return await _dio.post(
            path,
            data: data,
            queryParameters: queryParameters,
            options: streamOptions,
            cancelToken: cancelToken,
          );
        } on DioException catch (retryError) {
          return _handleError(retryError);
        }
      }
      
      return _handleError(e);
    }
  }

  /// 判断是否是网络错误（可能需要切换节点的错误类型）
  bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.type == DioExceptionType.unknown && 
         error.error is SocketException);
  }

  /// 设置授权令牌
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// 清除授权令牌
  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// 创建不缓存的选项
  Options getNoCacheOptions() {
    return Options(
      extra: {'dio_cache_mode': 'refresh'}, // 强制从服务器刷新数据
    );
  }

  /// 错误处理
  Response _handleError(DioException e) {
    if (e.response != null) {
      // 在返回错误响应前，检查是否是令牌失效
      if (e.response?.data is Map<String, dynamic>) {
        final responseData = e.response?.data as Map<String, dynamic>;
        if (responseData['code'] == 1019 ||
            responseData['msg']?.toString().contains('令牌失效') == true) {
          _handleTokenExpired();
        }
      }
      // 返回服务器原始响应
      return e.response!;
    } else {
      // 如果没有响应对象，创建一个包含错误信息的响应
      return Response(
        requestOptions: e.requestOptions,
        statusCode: HttpStatus.serviceUnavailable,
        statusMessage: '网络连接失败',
        data: {
          'code': -1,
          'msg': e.message ?? '网络连接失败',
        },
      );
    }
  }
}
