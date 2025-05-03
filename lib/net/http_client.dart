import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dao/user_dao.dart';
import '../pages/login/login_page.dart';

class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  late Dio _dio;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // 单例模式
  factory HttpClient() => _instance;

  HttpClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://hk1.xiaoyi.ink/api/v1', // 替换为实际的API基础URL
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ));

    _initializeSSLCertificate();

    // 添加缓存拦截器
    final cacheOptions = CacheOptions(
      store: MemCacheStore(),
      policy: CachePolicy.request,
      hitCacheOnErrorExcept: [], // 不进行异常排除，让所有响应都经过拦截器处理
      maxStale: const Duration(days: 1),
      priority: CachePriority.normal,
    );
    _dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

    // 添加日志拦截器
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    // 添加响应拦截器处理令牌失效情况
    _dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) {
        // 检查响应中的特定code，无论状态码是多少
        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (responseData['code'] == 1019 ||
              (response.statusCode != 200 &&
                  responseData['msg']?.toString().contains('令牌失效') == true)) {
            // 令牌失效，清除用户信息并返回登录页面
            _handleTokenExpired();
          }
        }
        return handler.next(response);
      },
      onError: (DioException error, handler) {
        // 处理错误响应
        if (error.response?.data is Map<String, dynamic>) {
          final responseData = error.response?.data as Map<String, dynamic>;
          if (responseData['code'] == 1019 ||
              responseData['msg']?.toString().contains('令牌失效') == true) {
            // 令牌失效，清除用户信息并返回登录页面
            _handleTokenExpired();
          }
        }
        return handler.next(error);
      },
    ));
  }

  // 初始化SSL证书
  Future<void> _initializeSSLCertificate() async {
    try {
      // 读取证书文件
      ByteData certData = await rootBundle.load('assets/certificates/cert.pem');

      // 配置Dio的HttpClientAdapter
      (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
          (client) {
        // 设置证书验证
        client.badCertificateCallback = (cert, host, port) {
          // 这里可以添加自定义的证书验证逻辑
          // 例如：验证证书指纹、域名等

          // 如果需要完全信任自签名证书，可以返回true
          // 如果需要验证证书，返回false
          return true; // 在开发环境可以设置为true，生产环境建议设置为false并进行proper验证
        };

        return client;
      };

      // 如果需要，可以设置自定义证书
      (_dio.httpClientAdapter as IOHttpClientAdapter).validateCertificate =
          (cert, host, port) {
        // 这里可以实现自定义的证书验证逻辑
        // 例如：验证证书内容、过期时间等
        return true; // 同样，生产环境建议实现proper验证
      };
    } catch (e) {
      debugPrint('SSL证书初始化失败: $e');
      // 可以在这里添加错误处理逻辑
    }
  }

  // 处理令牌失效
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

  // GET请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // POST请求
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // PUT请求
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // DELETE请求
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // 设置授权令牌
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // 清除授权令牌
  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  // 设置基础URL
  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  // 创建不缓存的选项
  Options getNoCacheOptions() {
    return Options(
      extra: {'dio_cache_mode': 'refresh'}, // 强制从服务器刷新数据
    );
  }

  // 错误处理
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
