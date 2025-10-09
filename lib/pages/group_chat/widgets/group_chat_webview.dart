import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import '../../../services/webview_pool_service.dart';
import '../../../services/html_template_cache_service.dart';
import '../../../widgets/custom_toast.dart';
import '../../../widgets/text_editor_page.dart';

class GroupChatWebView extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final double fontSize;
  final Color bubbleColor;
  final double bubbleOpacity;
  final Color textColor;
  final Color userBubbleColor;
  final double userBubbleOpacity;
  final Color userTextColor;
  final VoidCallback? onLoadMore; // 加载更多的回调
  final VoidCallback? onWebViewReady; // WebView 准备就绪的回调
  final Function(String msgId, String newContent)? onMessageEdit; // 编辑消息的回调
  final Function(String msgId)? onMessageDeleted; // 删除消息的回调
  final Function(String msgId)? onMessageRevoked; // 撤销消息的回调

  const GroupChatWebView({
    super.key,
    required this.messages,
    required this.fontSize,
    required this.bubbleColor,
    required this.bubbleOpacity,
    required this.textColor,
    required this.userBubbleColor,
    required this.userBubbleOpacity,
    required this.userTextColor,
    this.onLoadMore,
    this.onWebViewReady,
    this.onMessageEdit,
    this.onMessageDeleted,
    this.onMessageRevoked,
  });

  @override
  State<GroupChatWebView> createState() => _GroupChatWebViewState();
}

class _GroupChatWebViewState extends State<GroupChatWebView> {
  WebViewController? _controller;
  bool _isWebViewReady = false;
  bool _isFromPool = false; // 标记控制器是否来自对象池
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
      WebViewPoolService().returnController(_controller!).catchError((e) {
        // 静默失败
      });
    }
    super.dispose();
  }

  void _initializeWebView() async {
    try {

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
    } catch (e) {

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
      String htmlContent = await rootBundle.loadString('assets/html/group_chat_webview.html');
      return htmlContent;
    } catch (e) {
      // 如果加载失败，返回一个简单的HTML
      return '''
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>群聊</title>
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
      final data = jsonDecode(message);
      final action = data['action'] as String;
      final msgId = data['msgId'] as String?;

      switch (action) {
        case 'webViewReady':
          if (widget.onWebViewReady != null) {
            widget.onWebViewReady!();
          }
          break;
        case 'loadMore':
          if (widget.onLoadMore != null) {
            widget.onLoadMore!();
          }
          break;
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
        case 'copyMessage':
          final content = data['content'] as String?;
          if (content != null) {
            _handleCopyMessage(content);
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
          break;
      }
    } catch (e) {
      // 静默失败
    }
  }

  /// 处理编辑消息
  Future<void> _handleEditMessage(String msgId, String content) async {
    try {

      // 打开原生编辑页面
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => TextEditorPage(
            title: '编辑消息',
            initialText: content,
            hintText: '请输入消息内容...',
            maxLength: null,
          ),
        ),
      );

      if (result != null && result != content) {
        // 用户保存了新内容，调用编辑回调
        if (widget.onMessageEdit != null) {
          widget.onMessageEdit!(msgId, result);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '编辑失败',
          type: ToastType.error,
        );
      }
    }
  }

  /// 处理删除消息
  Future<void> _handleDeleteMessage(String msgId) async {
    try {
      if (widget.onMessageDeleted != null) {
        widget.onMessageDeleted!(msgId);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '删除失败',
          type: ToastType.error,
        );
      }
    }
  }

  /// 处理撤销消息
  Future<void> _handleRevokeMessage(String msgId) async {
    try {
      if (widget.onMessageRevoked != null) {
        widget.onMessageRevoked!(msgId);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '撤销失败',
          type: ToastType.error,
        );
      }
    }
  }

  /// 处理复制消息
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
      if (mounted) {
        CustomToast.show(
          context,
          message: '复制失败',
          type: ToastType.error,
        );
      }
    }
  }

  /// 处理获取 HTML 模板请求
  Future<void> _handleGetTemplate(int templateId) async {
    try {
      // 从缓存获取模板
      final htmlTemplate = await _htmlTemplateCacheService.getTemplate(templateId);
      
      if (htmlTemplate != null) {
        // 返回模板给 WebView
        final response = jsonEncode({
          'templateId': templateId,
          'htmlTemplate': htmlTemplate,
        });
        
        final jsCode = 'window.receiveTemplate($response);';
        _controller?.runJavaScript(jsCode);
      } else {
        // 通知 WebView 获取失败
        final response = jsonEncode({
          'templateId': templateId,
          'error': '模板不存在',
        });
        
        final jsCode = 'window.receiveTemplate($response);';
        _controller?.runJavaScript(jsCode);
      }
    } catch (e) {
      // 通知 WebView 获取失败
      final response = jsonEncode({
        'templateId': templateId,
        'error': e.toString(),
      });
      
      final jsCode = 'window.receiveTemplate($response);';
      _controller?.runJavaScript(jsCode);
    }
  }

  void _updateMessages({bool shouldScrollToBottom = false}) {
    if (!_isWebViewReady || _controller == null) {
      return;
    }

    final messagesData = widget.messages.map((message) {
      final msgId = message['msgId'];
      final isUser = message['isUser'] ?? false;
      final content = message['content'] ?? '';
      final customRole = message['customRole'];
      final avatarUri = message['avatarUri'];

      return {
        'content': _sanitizeString(content),
        'isUser': isUser,
        'isLoading': message['isLoading'] ?? false,
        'msgId': msgId,
        'customRole': customRole,
        'avatarUri': avatarUri,
        'fontSize': widget.fontSize,
        'bubbleColor': _colorToHex(widget.bubbleColor),
        'bubbleOpacity': widget.bubbleOpacity,
        'textColor': _colorToHex(widget.textColor),
        'userBubbleColor': _colorToHex(widget.userBubbleColor),
        'userBubbleOpacity': widget.userBubbleOpacity,
        'userTextColor': _colorToHex(widget.userTextColor),
      };
    }).toList();

    final jsCode = 'updateMessages(${jsonEncode(messagesData)}, $shouldScrollToBottom);';
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
  void didUpdateWidget(GroupChatWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMessages();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const SizedBox.shrink(); // 使用空容器，不显示加载指示器
    }
    return WebViewWidget(controller: _controller!);
  }
}

