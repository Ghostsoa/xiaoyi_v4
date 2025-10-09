import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import '../services/character_service.dart';
import '../../../widgets/custom_toast.dart';
import '../../../widgets/text_editor_page.dart';
import '../../../services/webview_pool_service.dart';
import '../../../services/html_template_cache_service.dart';

class ChatWebView extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final String sessionId;
  final Function(String msgId, String newContent) onMessageEdit;
  final Function(String msgId) onMessageDeleted;
  final Function(String msgId) onMessageRevoked;
  final Function(String msgId) onMessageRegenerate;
  final VoidCallback? onLoadMore; // 添加分页回调
  final bool isLoadingMore; // 添加加载状态
  final double fontSize;
  final Color bubbleColor;
  final double bubbleOpacity;
  final Color textColor;
  final Color userBubbleColor;
  final double userBubbleOpacity;
  final Color userTextColor;
  final String formatMode;

  const ChatWebView({
    super.key,
    required this.messages,
    required this.sessionId,
    required this.onMessageEdit,
    required this.onMessageDeleted,
    required this.onMessageRevoked,
    required this.onMessageRegenerate,
    this.onLoadMore,
    this.isLoadingMore = false,
    required this.fontSize,
    required this.bubbleColor,
    required this.bubbleOpacity,
    required this.textColor,
    required this.userBubbleColor,
    required this.userBubbleOpacity,
    required this.userTextColor,
    required this.formatMode,
  });

  @override
  State<ChatWebView> createState() => _ChatWebViewState();
}

class _ChatWebViewState extends State<ChatWebView> {
  WebViewController? _controller;
  bool _isWebViewReady = false;
  bool _isFromPool = false; // 标记控制器是否来自对象池
  final CharacterService _characterService = CharacterService();
  final HtmlTemplateCacheService _htmlTemplateCacheService = HtmlTemplateCacheService();

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    // 只有来自对象池的控制器才需要归还
    if (_controller != null && _isFromPool) {
      WebViewPoolService().returnController(_controller!).then((_) {
        debugPrint('[ChatWebView] WebView控制器已归还到对象池');
      }).catchError((e) {
        debugPrint('[ChatWebView] 归还WebView控制器失败: $e');
      });
    }
    super.dispose();
  }

  void _initializeWebView() async {
    try {
      debugPrint('[ChatWebView] 开始初始化WebView，尝试从对象池获取...');

      // 从对象池获取WebView控制器
      _controller = await WebViewPoolService().getController();
      _isFromPool = true;

      final htmlContent = await _loadHtmlFromAssets();

      // 配置控制器
      await _controller!.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isWebViewReady = true;
            });
            _updateMessages();
          },
        ),
      );

      await _controller!.addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptMessage(message.message);
        },
      );

      await _controller!.loadHtmlString(htmlContent);

      debugPrint('[ChatWebView] WebView初始化完成，使用对象池控制器');
    } catch (e) {
      debugPrint('[ChatWebView] 从对象池获取控制器失败，创建新控制器: $e');

      // 如果对象池失败，回退到传统方式
      final htmlContent = await _loadHtmlFromAssets();

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              setState(() {
                _isWebViewReady = true;
              });
              _updateMessages();
            },
          ),
        )
        ..addJavaScriptChannel(
          'FlutterBridge',
          onMessageReceived: (JavaScriptMessage message) {
            _handleJavaScriptMessage(message.message);
          },
        )
        ..loadHtmlString(htmlContent);
    }
  }

  Future<String> _loadHtmlFromAssets() async {
    try {
      String htmlContent = await rootBundle.loadString('assets/html/chat_webview_vue.html');



      return htmlContent;
    } catch (e) {
      debugPrint('Error loading HTML from assets: $e');
      // 如果加载失败，返回一个简单的HTML
      return '''
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Chat</title>
        </head>
        <body>
            <div id="messages-container">
                <p>HTML 文件加载失败</p>
            </div>
        </body>
        </html>
      ''';
    }
  }

  void _handleJavaScriptMessage(String message) {
    try {
      debugPrint('Flutter收到JavaScript消息: $message');
      final data = jsonDecode(message);
      final action = data['action'] as String;
      final msgId = data['msgId'] as String?;

      debugPrint('解析后的action: $action, msgId: $msgId');

      switch (action) {
        case 'editMessage':
          if (msgId != null) {
            final content = data['content'] as String;
            _handleEditMessage(msgId, content);
          }
          break;
        case 'deleteMessage':
          if (msgId != null) {
            _handleDeleteMessage(msgId);
          }
          break;
        case 'revokeMessage':
          if (msgId != null) {
            _handleRevokeMessage(msgId);
          }
          break;
        case 'regenerateMessage':
          if (msgId != null) {
            widget.onMessageRegenerate(msgId);
          }
          break;
        case 'copyMessage':
          final content = data['content'] as String?;
          if (content != null) {
            _handleCopyMessage(content);
          }
          break;
        case 'webViewReady':
          debugPrint('WebView 已准备就绪');
          break;
        case 'loadMore':
          debugPrint('WebView请求加载更多消息');
          if (widget.onLoadMore != null) {
            widget.onLoadMore!();
          }
          break;
        case 'getTemplate':
          // 支持 templateId 和 template_id 两种格式
          final templateId = (data['templateId'] ?? data['template_id']) as int?;
          if (templateId != null) {
            _handleGetTemplate(templateId);
          }
          break;
        default:
          debugPrint('Unknown action: $action');
      }
    } catch (e) {
      debugPrint('Error handling JavaScript message: $e');
    }
  }

  Future<void> _handleDeleteMessage(String msgId) async {
    try {
      debugPrint('WebView删除消息: $msgId');
      await _characterService.deleteMessage(
        int.parse(widget.sessionId),
        msgId,
      );

      // 删除成功后调用回调
      widget.onMessageDeleted(msgId);

      if (mounted) {
        CustomToast.show(
          context,
          message: '消息已删除',
          type: ToastType.success,
        );
      }
    } catch (e) {
      debugPrint('WebView删除消息失败: $e');

      // 检查是否是幽灵消息（未找到指定消息）
      final errorString = e.toString();
      final isGhostMessage = errorString.contains('未找到指定消息');

      if (isGhostMessage) {
        // 幽灵消息：触发回调让对话页面删除本地缓存
        widget.onMessageDeleted(msgId);

        if (mounted) {
          CustomToast.show(
            context,
            message: '消息不存在，已从本地移除',
            type: ToastType.warning,
          );
        }
      } else {
        // 其他错误：正常显示错误信息
        if (mounted) {
          CustomToast.show(
            context,
            message: e.toString(),
            type: ToastType.error,
          );
        }
      }
    }
  }

  Future<void> _handleRevokeMessage(String msgId) async {
    try {
      debugPrint('WebView撤销消息: $msgId');
      await _characterService.revokeMessageAndAfter(
        int.parse(widget.sessionId),
        msgId,
      );

      // 撤销成功后调用回调
      widget.onMessageRevoked(msgId);

      if (mounted) {
        CustomToast.show(
          context,
          message: '消息已撤销',
          type: ToastType.success,
        );
      }
    } catch (e) {
      debugPrint('WebView撤销消息失败: $e');

      // 检查是否是幽灵消息（未找到指定消息）
      final errorString = e.toString();
      final isGhostMessage = errorString.contains('未找到指定消息');

      if (isGhostMessage) {
        // 幽灵消息：触发回调让对话页面删除本地缓存
        widget.onMessageRevoked(msgId);

        if (mounted) {
          CustomToast.show(
            context,
            message: '消息不存在，已从本地移除',
            type: ToastType.warning,
          );
        }
      } else {
        // 其他错误：正常显示错误信息
        if (mounted) {
          CustomToast.show(
            context,
            message: e.toString(),
            type: ToastType.error,
          );
        }
      }
    }
  }

  Future<void> _handleEditMessage(String msgId, String content) async {
    try {
      debugPrint('WebView编辑消息: $msgId');

      // 打开原生编辑页面
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => TextEditorPage(
            title: '编辑消息',
            initialText: content,
            hintText: '请输入消息内容...',
            maxLength: null, // 移除字数限制
          ),
        ),
      );

      if (result != null && result != content) {
        // 用户保存了新内容，调用编辑回调
        widget.onMessageEdit(msgId, result);

        if (mounted) {
          CustomToast.show(
            context,
            message: '消息已编辑',
            type: ToastType.success,
          );
        }
      }
    } catch (e) {
      debugPrint('编辑消息失败: $e');
      if (mounted) {
        CustomToast.show(
          context,
          message: '编辑失败: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _handleCopyMessage(String content) async {
    try {
      // 复制原始内容到剪贴板
      await Clipboard.setData(ClipboardData(text: content));
      
      if (mounted) {
        CustomToast.show(
          context,
          message: '已复制到剪贴板',
          type: ToastType.success,
        );
      }
    } catch (e) {
      debugPrint('复制消息失败: $e');
      if (mounted) {
        CustomToast.show(
          context,
          message: '复制失败',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _handleGetTemplate(int templateId) async {
    try {
      debugPrint('WebView请求获取模板: $templateId');
      
      // 从缓存获取模板
      final htmlTemplate = await _htmlTemplateCacheService.getTemplate(templateId);
      
      if (htmlTemplate != null) {
        debugPrint('成功获取模板，长度: ${htmlTemplate.length}');
        
        // 返回模板给 WebView
        final response = jsonEncode({
          'templateId': templateId,
          'htmlTemplate': htmlTemplate,
        });
        
        // 调用 JavaScript 回调函数
        final jsCode = 'window.receiveTemplate($response);';
        _controller?.runJavaScript(jsCode);
      } else {
        debugPrint('模板 $templateId 不存在或未缓存');
        
        // 通知 WebView 获取失败
        final response = jsonEncode({
          'templateId': templateId,
          'error': '模板不存在',
        });
        
        final jsCode = 'window.receiveTemplate($response);';
        _controller?.runJavaScript(jsCode);
      }
    } catch (e) {
      debugPrint('获取模板失败: $e');
      
      // 通知 WebView 获取失败
      final response = jsonEncode({
        'templateId': templateId,
        'error': e.toString(),
      });
      
      final jsCode = 'window.receiveTemplate($response);';
      _controller?.runJavaScript(jsCode);
    }
  }

  void _updateMessages() {
    if (!_isWebViewReady || _controller == null) {
      return;
    }

    // 直接传递原始消息，不做模板处理
    final messagesData = widget.messages.map((message) {
      final msgId = message['msgId'];
      final isUser = message['isUser'] ?? false;
      final content = message['content'] ?? '';

      return {
        'content': _sanitizeString(content), // 传递原始内容
        'isUser': isUser,
        'isLoading': message['isLoading'] ?? false,
        'msgId': msgId,
        'fontSize': widget.fontSize,
        'bubbleColor': _colorToHex(widget.bubbleColor),
        'bubbleOpacity': widget.bubbleOpacity,
        'textColor': _colorToHex(widget.textColor),
        'userBubbleColor': _colorToHex(widget.userBubbleColor),
        'userBubbleOpacity': widget.userBubbleOpacity,
        'userTextColor': _colorToHex(widget.userTextColor),
      };
    }).toList();

    final jsCode = 'updateMessages(${jsonEncode(messagesData)}, false);';
    _controller!.runJavaScript(jsCode);
  }

  String _sanitizeString(String input) {
    // 移除或替换可能导致UTF-16错误的字符
    return input.replaceAll(RegExp(r'[\uFFFE\uFFFF]'), '').replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }



  @override
  void didUpdateWidget(ChatWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMessages();
  }



  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return WebViewWidget(controller: _controller!);
  }
}
