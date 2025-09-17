import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

/// WebView对象池服务
/// 预创建和管理WebView实例，提高性能和资源复用
class WebViewPoolService {
  static final WebViewPoolService _instance = WebViewPoolService._internal();
  factory WebViewPoolService() => _instance;
  WebViewPoolService._internal();

  // 对象池配置
  static const int _poolSize = 3; // 池大小
  static const int _maxPoolSize = 5; // 最大池大小
  
  // 对象池
  final List<WebViewController> _availableControllers = [];
  final List<WebViewController> _usedControllers = [];
  
  // 初始化状态
  bool _isInitialized = false;
  bool _isInitializing = false;
  Completer<void>? _initCompleter;

  /// 异步初始化对象池
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      return _initCompleter?.future ?? Future.value();
    }

    _isInitializing = true;
    _initCompleter = Completer<void>();

    try {
      debugPrint('[WebViewPool] 开始初始化WebView对象池...');
      
      // 预创建WebView控制器
      for (int i = 0; i < _poolSize; i++) {
        final controller = await _createWebViewController();
        _availableControllers.add(controller);
        debugPrint('[WebViewPool] 创建WebView控制器 ${i + 1}/$_poolSize');
      }

      _isInitialized = true;
      debugPrint('[WebViewPool] WebView对象池初始化完成，池大小: $_poolSize');
      
      _initCompleter!.complete();
    } catch (e) {
      debugPrint('[WebViewPool] WebView对象池初始化失败: $e');
      _initCompleter!.completeError(e);
    } finally {
      _isInitializing = false;
    }
  }

  /// 创建WebView控制器
  Future<WebViewController> _createWebViewController() async {
    final controller = WebViewController();
    
    // 基础配置
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(Colors.transparent);
    
    // 设置用户代理
    await controller.setUserAgent(
      'Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36'
    );

    return controller;
  }

  /// 获取WebView控制器（从池中获取或创建新的）
  Future<WebViewController> getController() async {
    // 确保池已初始化
    if (!_isInitialized) {
      await initialize();
    }

    WebViewController? controller;

    // 从可用池中获取
    if (_availableControllers.isNotEmpty) {
      controller = _availableControllers.removeAt(0);
      _usedControllers.add(controller);
      debugPrint('[WebViewPool] 从池中获取WebView控制器，剩余: ${_availableControllers.length}');
    } else {
      // 池为空，创建新的控制器
      controller = await _createWebViewController();
      _usedControllers.add(controller);
      debugPrint('[WebViewPool] 池为空，创建新的WebView控制器，使用中: ${_usedControllers.length}');
    }

    return controller;
  }

  /// 归还WebView控制器到池中
  Future<void> returnController(WebViewController controller) async {
    if (!_usedControllers.contains(controller)) {
      debugPrint('[WebViewPool] 警告：尝试归还未从池中获取的控制器');
      return;
    }

    _usedControllers.remove(controller);

    // 如果池未满，归还到池中
    if (_availableControllers.length < _maxPoolSize) {
      // 清理控制器状态
      try {
        await controller.loadHtmlString('<!DOCTYPE html><html><body></body></html>');
        _availableControllers.add(controller);
        debugPrint('[WebViewPool] 控制器已归还到池中，可用: ${_availableControllers.length}');
      } catch (e) {
        debugPrint('[WebViewPool] 清理控制器失败，将被丢弃: $e');
      }
    } else {
      debugPrint('[WebViewPool] 池已满，控制器将被丢弃');
    }
  }

  /// 预热WebView控制器（加载基础HTML）
  Future<void> warmupController(WebViewController controller, String htmlContent) async {
    try {
      await controller.loadHtmlString(htmlContent);
      debugPrint('[WebViewPool] WebView控制器预热完成');
    } catch (e) {
      debugPrint('[WebViewPool] WebView控制器预热失败: $e');
    }
  }

  /// 获取池状态信息
  Map<String, int> getPoolStatus() {
    return {
      'available': _availableControllers.length,
      'used': _usedControllers.length,
      'total': _availableControllers.length + _usedControllers.length,
      'initialized': _isInitialized ? 1 : 0,
    };
  }

  /// 清理对象池
  Future<void> dispose() async {
    debugPrint('[WebViewPool] 开始清理WebView对象池...');
    
    _availableControllers.clear();
    _usedControllers.clear();
    _isInitialized = false;
    _isInitializing = false;
    _initCompleter = null;
    
    debugPrint('[WebViewPool] WebView对象池已清理');
  }
}
