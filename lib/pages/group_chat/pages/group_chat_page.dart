import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../../../theme/app_theme.dart';
import '../../../services/file_service.dart';
import '../../../services/html_template_cache_service.dart';
import '../widgets/group_chat_input_area.dart';
import '../widgets/group_chat_webview.dart';
import '../widgets/role_panel.dart';
import '../services/group_chat_stream_service.dart';
import '../services/group_chat_session_service.dart';
import 'group_chat_panel_page.dart';
import '../../home/pages/item_detail_page.dart';
import '../../../widgets/custom_toast.dart';
import '../../../widgets/confirmation_dialog.dart';
import '../../../dao/group_chat_settings_dao.dart';
import 'group_chat_settings_page.dart';

class GroupChatPage extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final Map<String, dynamic> groupChatData;

  const GroupChatPage({
    super.key,
    required this.sessionData,
    required this.groupChatData,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final FileService _fileService = FileService();
  final HtmlTemplateCacheService _htmlTemplateCacheService = HtmlTemplateCacheService();
  final GroupChatStreamService _chatService = GroupChatStreamService();
  final GroupChatSessionService _sessionService = GroupChatSessionService();
  final GroupChatSettingsDao _settingsDao = GroupChatSettingsDao();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, dynamic>> _messages = [];

  bool _isSending = false;
  bool _isLoadingHistory = false;
  bool _isRefreshing = false; // 刷新状态
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreMessages = true;
  
  // 背景设置
  Uint8List? _backgroundImage;
  bool _isLoadingBackground = false;
  double _backgroundOpacity = 0.5;

  // 聊天设置
  double _fontSize = 14.0;
  Color _bubbleColor = Colors.white;
  double _bubbleOpacity = 0.8;
  Color _textColor = Colors.black;
  Color _userBubbleColor = AppTheme.primaryColor;
  double _userBubbleOpacity = 0.8;
  Color _userTextColor = Colors.white;

  // 添加一个变量用于控制流的终止
  bool _shouldStopStream = false;

  // 角色头像缓存 - key: avatarUri, value: base64 data URL
  final Map<String, String> _avatarCache = {};

  /// 获取会话ID，处理类型转换
  int get _sessionId {
    final id = widget.sessionData['id'];
    if (id is int) {
      return id;
    } else if (id is String) {
      return int.parse(id);
    } else {
      throw Exception('Invalid session ID type: ${id.runtimeType}');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _preloadRoleAvatars();
    _loadBackgroundImage();
    _checkAndPrepareHtmlTemplates();
    // 不在这里加载历史消息，等 WebView 准备好后再加载
  }

  /// 检查并准备 HTML 模板
  Future<void> _checkAndPrepareHtmlTemplates() async {
    try {
      // 注意：字段名是 html_templates（下划线），不是 htmlTemplates（驼峰）
      final htmlTemplates = widget.groupChatData['html_templates']?.toString() ?? '';
      
      if (htmlTemplates.isEmpty) {
        return;
      }
      
      // 解析模板ID
      final ids = htmlTemplates.split(',')
          .map((e) => int.tryParse(e.trim()))
          .where((e) => e != null)
          .toList();
      
      if (ids.isEmpty) {
        return;
      }
      
      debugPrint('=====================================');
      debugPrint('【群聊HTML模板】开始检查模板缓存');
      debugPrint('模板ID列表: $htmlTemplates');
      debugPrint('模板数量: ${ids.length}');
      
      // 检查是否已经全部缓存
      final allCached = await _htmlTemplateCacheService.checkAllCached(htmlTemplates);
      
      if (allCached) {
        debugPrint('【群聊HTML模板】✅ 所有模板已缓存，无需准备');
        debugPrint('=====================================');
        return;
      }
      
      debugPrint('【群聊HTML模板】⚠️ 检测到未缓存模板，准备开始下载');
      debugPrint('=====================================');
      
      // 需要缓存，延迟到下一帧显示进度对话框
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showHtmlTemplateCachingDialog(htmlTemplates);
          }
        });
      }
    } catch (e) {
      debugPrint('【群聊HTML模板】❌ 检查失败: $e');
      debugPrint('=====================================');
    }
  }

  /// 显示 HTML 模板缓存进度对话框
  Future<void> _showHtmlTemplateCachingDialog(String htmlTemplates) async {
    if (!mounted) return;

    final ids = htmlTemplates.split(',')
        .map((e) => int.tryParse(e.trim()))
        .where((e) => e != null)
        .toList();
    
    final total = ids.length;

    // 使用 ValueNotifier 来更新进度
    final progressNotifier = ValueNotifier<int>(0);

    // 显示弹窗（不等待）
    showDialog(
      context: context,
      barrierDismissible: false, // 不可关闭
      builder: (BuildContext context) {
        return ValueListenableBuilder<int>(
          valueListenable: progressNotifier,
          builder: (context, current, child) {
            return WillPopScope(
              onWillPop: () async => false, // 禁止返回键关闭
              child: Dialog(
                backgroundColor: AppTheme.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.code,
                        size: 48.sp,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '准备HTML模板',
                        style: TextStyle(
                          fontSize: AppTheme.titleSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '正在缓存模板代码，请稍候...',
                        style: TextStyle(
                          fontSize: AppTheme.bodySize,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      
                      // 进度条
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        child: LinearProgressIndicator(
                          value: total > 0 ? current / total : 0,
                          backgroundColor: AppTheme.border.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          minHeight: 8.h,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      
                      // 进度文本
                      Text(
                        '$current / $total',
                        style: TextStyle(
                          fontSize: AppTheme.bodySize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // 在后台执行缓存准备
    try {
      await _htmlTemplateCacheService.prepareTemplatesWithProgress(
        htmlTemplates,
        onProgress: (current, total) {
          progressNotifier.value = current;
        },
      );

      debugPrint('=====================================');
      debugPrint('【群聊HTML模板】✅ 模板缓存完成');
      debugPrint('=====================================');
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('=====================================');
      debugPrint('【群聊HTML模板】❌ 模板缓存失败: $e');
      debugPrint('=====================================');
      
      if (mounted) {
        Navigator.of(context).pop();
        CustomToast.show(
          context,
          message: 'HTML 模板准备失败',
          type: ToastType.error,
        );
      }
    }
  }

  /// WebView 准备就绪的回调
  void _onWebViewReady() {
    _loadMessageHistory();
  }

  /// 预加载所有角色的头像
  Future<void> _preloadRoleAvatars() async {
    try {
      final roles = widget.groupChatData['roles'] as List?;
      if (roles == null || roles.isEmpty) return;

      for (final role in roles) {
        final avatarUri = role['avatarUri'] as String?;
        if (avatarUri == null || avatarUri.isEmpty || _avatarCache.containsKey(avatarUri)) {
          continue;
        }

        try {
          final result = await _fileService.getFile(avatarUri);
          if (result.data is Uint8List) {
            final base64String = base64Encode(result.data);
            final dataUrl = 'data:image/jpeg;base64,$base64String';
            _avatarCache[avatarUri] = dataUrl;
          }
        } catch (e) {
          // 静默失败
        }
      }
    } catch (e) {
      // 静默失败
    }
  }

  /// 获取头像的 base64 data URL
  String? _getAvatarDataUrl(String? avatarUri) {
    if (avatarUri == null || avatarUri.isEmpty) {
      return null;
    }
    return _avatarCache[avatarUri];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsDao.getAllSettings();
      if (!mounted) return;

      setState(() {
        _backgroundOpacity = settings['backgroundOpacity'] ?? 0.5;
        _bubbleColor = _hexToColor(settings['bubbleColor'] ?? '#FFFFFF');
        _bubbleOpacity = settings['bubbleOpacity'] ?? 0.8;
        _textColor = _hexToColor(settings['textColor'] ?? '#000000');
        _userBubbleColor = _hexToColor(settings['userBubbleColor'] ??
            AppTheme.primaryColor.value.toRadixString(16));
        _userBubbleOpacity = settings['userBubbleOpacity'] ?? 0.8;
        _userTextColor = _hexToColor(settings['userTextColor'] ?? '#FFFFFF');
        _fontSize = settings['fontSize'] ?? 14.0;
      });
    } catch (e) {
      debugPrint('加载设置失败: $e');
    }
  }

  Color _hexToColor(String hexColor) {
    try {
      hexColor = hexColor.toUpperCase().replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      debugPrint('颜色转换失败: $e');
      return Colors.white;
    }
  }

  /// 加载历史消息
  Future<void> _loadMessageHistory() async {
    if (_isLoadingHistory) return;

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final result = await _sessionService.getMessages(_sessionId, page: 1, pageSize: 50);
      
      final messageList = result['list'] as List?;
      if (messageList == null || messageList.isEmpty) {
        debugPrint('[群聊页面] 没有历史消息');
        // 如果没有历史消息，显示问候语
        if (mounted) {
          setState(() {
            _isLoadingHistory = false;
          });
          _initializeGreeting();
        }
        return;
      }

      debugPrint('[群聊页面] 加载了 ${messageList.length} 条历史消息');

      // 转换消息格式
      final formattedMessages = <Map<String, dynamic>>[];
      for (final msg in messageList) {
        final role = msg['role'] as String?;
        final isUser = role == 'user';
        
        final formattedMsg = {
          'msgId': msg['msgId'],
          'content': msg['content'] ?? '',
          'isUser': isUser,
          'isLoading': false,
          'createdAt': msg['createdAt'],
        };

        // 如果是 assistant 消息，添加 customRole 和头像
        if (!isUser && msg['customRole'] != null) {
          formattedMsg['customRole'] = msg['customRole'];
          
          // 根据 customRole 查找对应角色的头像
          final avatarUri = _findRoleAvatar(msg['customRole'] as String);
          if (avatarUri != null) {
            formattedMsg['avatarUri'] = _getAvatarDataUrl(avatarUri);
          }
        }

        formattedMessages.add(formattedMsg);
      }

      if (!mounted) return;

      // 更新分页信息
      final pagination = result['pagination'] as Map<String, dynamic>?;
      if (pagination != null) {
        _currentPage = pagination['page'] ?? 1;
        _totalPages = pagination['total_pages'] ?? 1;
        _hasMoreMessages = _currentPage < _totalPages;
        debugPrint('[群聊页面] 分页信息: $_currentPage/$_totalPages, 还有更多: $_hasMoreMessages');
      }

      setState(() {
        // 直接添加消息，不反转（API返回的是按时间倒序，最新的在前）
        // 配合 column-reverse，最新消息会显示在底部
        _messages.addAll(formattedMessages);
        _isLoadingHistory = false;
      });
    } catch (e) {
      debugPrint('[群聊页面] 加载历史消息失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
        // 加载失败时显示问候语
        _initializeGreeting();
      }
    }
  }

  /// 加载更多历史消息（分页）
  Future<void> _loadMoreMessages() async {
    if (_isLoadingHistory || !_hasMoreMessages) {
      debugPrint('[群聊页面] 跳过加载: isLoading=$_isLoadingHistory, hasMore=$_hasMoreMessages');
      return;
    }

    debugPrint('[群聊页面] 开始加载第 ${_currentPage + 1} 页消息');

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final result = await _sessionService.getMessages(
        _sessionId,
        page: _currentPage + 1,
        pageSize: 20,
      );

      final messageList = result['list'] as List?;
      if (messageList == null || messageList.isEmpty) {
        debugPrint('[群聊页面] 没有更多消息了');
        setState(() {
          _hasMoreMessages = false;
          _isLoadingHistory = false;
        });
        return;
      }

      debugPrint('[群聊页面] 加载了 ${messageList.length} 条更多消息');

      // 转换消息格式
      final formattedMessages = <Map<String, dynamic>>[];
      for (final msg in messageList) {
        final role = msg['role'] as String?;
        final isUser = role == 'user';

        final formattedMsg = {
          'msgId': msg['msgId'],
          'content': msg['content'] ?? '',
          'isUser': isUser,
          'isLoading': false,
          'createdAt': msg['createdAt'],
        };

        // 如果是 assistant 消息，添加 customRole 和头像
        if (!isUser && msg['customRole'] != null) {
          formattedMsg['customRole'] = msg['customRole'];

          // 根据 customRole 查找对应角色的头像
          final avatarUri = _findRoleAvatar(msg['customRole'] as String);
          if (avatarUri != null) {
            formattedMsg['avatarUri'] = _getAvatarDataUrl(avatarUri);
          }
        }

        formattedMessages.add(formattedMsg);
      }

      if (!mounted) return;

      // 更新分页信息
      final pagination = result['pagination'] as Map<String, dynamic>?;
      if (pagination != null) {
        _currentPage = pagination['page'] ?? _currentPage + 1;
        _totalPages = pagination['total_pages'] ?? _totalPages;
        _hasMoreMessages = _currentPage < _totalPages;
        debugPrint('[群聊页面] 更新分页信息: $_currentPage/$_totalPages, 还有更多: $_hasMoreMessages');
      }

      setState(() {
        // 将新加载的历史消息添加到列表末尾（视觉上在顶部）
        _messages.addAll(formattedMessages);
        _isLoadingHistory = false;
      });
    } catch (e) {
      debugPrint('[群聊页面] 加载更多消息失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  /// 初始化问候语（仅在没有历史消息时显示）
  void _initializeGreeting() {
    final greeting = widget.sessionData['greeting'];
    if (greeting != null && greeting.toString().isNotEmpty) {
      setState(() {
        _messages.add({
          'msgId': 'greeting',
          'content': greeting,
          'isUser': false,
          'isLoading': false,
          'createdAt': DateTime.now().toIso8601String(),
        });
      });
    }
  }

  /// 根据角色名称查找头像 URI
  String? _findRoleAvatar(String roleName) {
    try {
      final roles = widget.groupChatData['roles'] as List?;
      if (roles == null || roles.isEmpty) {
        return null;
      }

      for (final role in roles) {
        if (role['name'] == roleName) {
          return role['avatarUri'] as String?;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[群聊页面] 查找角色头像失败: $e');
      return null;
    }
  }

  Future<void> _loadBackgroundImage() async {
    if (widget.groupChatData['background_uri'] == null ||
        _isLoadingBackground ||
        _backgroundImage != null) {
      return;
    }

    setState(() {
      _isLoadingBackground = true;
    });

    try {
      final result = await _fileService.getFile(widget.groupChatData['background_uri']);
      if (mounted) {
        setState(() {
          _backgroundImage = result.data;
          _isLoadingBackground = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBackground = false;
        });
      }
      debugPrint('背景图片加载失败: $e');
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    // 重置流终止标志
    _shouldStopStream = false;

    // 添加用户消息到列表
    setState(() {
      _messages.insert(0, {
        'msgId': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'content': message,
        'isUser': true,
        'isLoading': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 添加AI回复占位
      _messages.insert(0, {
        'msgId': 'temp_ai_${DateTime.now().millisecondsSinceEpoch}',
        'content': '',
        'isUser': false,
        'isLoading': true,
        'createdAt': DateTime.now().toIso8601String(),
      });

      _isSending = true;
    });

    _messageController.clear();

    try {
      // 使用流式服务发送消息
      await for (final response in _chatService.sendMessage(_sessionId, message)) {
        if (_shouldStopStream) break;

        if (!mounted) break;

        setState(() {
          if (response.isMessage) {
            // 检查是否是新消息（根据msgId）
            final existingIndex = _messages.indexWhere(
              (msg) => msg['msgId'] == response.messageId && msg['msgId'] != null,
            );

            if (existingIndex >= 0) {
              // 更新已存在的消息
              _messages[existingIndex]['content'] = response.content ?? '';
              _messages[existingIndex]['isLoading'] = false;
              _messages[existingIndex]['status'] = 'done';
              if (response.data['customRole'] != null) {
                _messages[existingIndex]['customRole'] = response.data['customRole'];
              }
              if (response.data['avatarUri'] != null) {
                final avatarUri = response.data['avatarUri'] as String?;
                _messages[existingIndex]['avatarUri'] = _getAvatarDataUrl(avatarUri);
              }
            } else {
              // 新的assistant消息（多个角色可能会有多条）
              // 先检查是否有loading占位符需要更新
              final loadingIndex = _messages.indexWhere(
                (msg) => msg['isLoading'] == true && msg['isUser'] == false,
              );

              if (loadingIndex >= 0) {
                // 更新第一个loading占位符
                final avatarUri = response.data['avatarUri'] as String?;
                _messages[loadingIndex] = {
                  'msgId': response.messageId,
                  'content': response.content ?? '',
                  'isUser': false,
                  'isLoading': false,
                  'status': 'done',
                  'customRole': response.data['customRole'],
                  'avatarUri': _getAvatarDataUrl(avatarUri),
                  'createdAt': DateTime.now().toIso8601String(),
                };
              } else {
                // 添加新消息
                final avatarUri = response.data['avatarUri'] as String?;
                _messages.insert(0, {
                  'msgId': response.messageId,
                  'content': response.content ?? '',
                  'isUser': false,
                  'isLoading': false,
                  'status': 'done',
                  'customRole': response.data['customRole'],
                  'avatarUri': _getAvatarDataUrl(avatarUri),
                  'createdAt': DateTime.now().toIso8601String(),
                });
              }
            }
          } else if (response.isDone) {
            // 流结束，确保所有loading状态都关闭
            for (var msg in _messages) {
              if (msg['isLoading'] == true) {
                msg['isLoading'] = false;
              }
            }
          } else if (response.isError) {
            // 处理错误消息
            final errorContent = response.content ?? response.errorMsg ?? '未知错误';

            // 错误消息不应显示为气泡，直接移除AI消息占位
            _messages.removeWhere((msg) => msg['isLoading'] == true && msg['isUser'] == false);

            // 同时将用户的消息也移除，并恢复到输入框中
            final userMsgIndex = _messages.indexWhere((msg) => msg['isUser'] == true);
            if (userMsgIndex >= 0) {
              final userMessage = _messages.removeAt(userMsgIndex);
              _messageController.text = userMessage['content'];
              _messageController.selection = TextSelection.fromPosition(
                TextPosition(offset: _messageController.text.length),
              );
            }

            // 显示错误提示
            if (mounted) {
              CustomToast.show(context, message: errorContent, type: ToastType.error);
            }
          }
        });
      }

      if (_shouldStopStream) {
        setState(() {
          // 找到loading的消息并标记为已终止
          for (var msg in _messages) {
            if (msg['isLoading'] == true) {
              msg['content'] = (msg['content'] ?? '') + '\n[已终止生成]';
              msg['isLoading'] = false;
              msg['status'] = 'done';
            }
          }
        });
      }
    } catch (e) {
      debugPrint('发送消息错误: $e');
      if (mounted) {
        setState(() {
          // 错误处理 - 移除AI回复和用户消息，把用户消息恢复到输入框
          _messages.removeWhere((msg) => msg['isLoading'] == true && msg['isUser'] == false);

          final userMsgIndex = _messages.indexWhere((msg) => msg['isUser'] == true);
          if (userMsgIndex >= 0) {
            final userMessage = _messages.removeAt(userMsgIndex);
            _messageController.text = userMessage['content'];
            _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: _messageController.text.length),
            );
          }
        });

        CustomToast.show(context, message: e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _shouldStopStream = false;
        });
      }
    }
  }
  
  void _stopGeneration() {
    setState(() => _shouldStopStream = true);
  }
  
  Future<void> _resetSession() async {
    // 显示确认对话框
    final bool? confirmed = await ConfirmationDialog.show(
      context: context,
      title: '确认重置',
      content: '确定要清空群聊所有对话记录吗？此操作不可恢复。',
      confirmText: '确定',
      cancelText: '取消',
      isDangerous: true,
    );

    if (confirmed != true) return;

    try {
      // 调用重置 API
      await _sessionService.resetSession(_sessionId);

      if (mounted) {
        // 重置会话的逻辑
        setState(() {
          _messages.clear();
          _currentPage = 1;
          _totalPages = 1;
          _hasMoreMessages = true;
        });
        
        // 重新加载历史消息
        await _loadMessageHistory();

        CustomToast.show(context, message: '对话已重置', type: ToastType.success);
      }
    } catch (e) {
      debugPrint('[群聊页面] 重置会话失败: $e');
      if (mounted) {
        CustomToast.show(context, message: '重置失败: $e', type: ToastType.error);
      }
    }
  }

  /// 刷新消息列表（静默刷新，不清空列表）
  Future<void> _refreshMessages() async {
    if (_isRefreshing) return; // 防止重复刷新
    
    debugPrint('[群聊页面] 静默刷新消息列表');
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final result = await _sessionService.getMessages(_sessionId, page: 1, pageSize: 50);
      
      final messageList = result['list'] as List?;
      if (messageList == null || messageList.isEmpty) {
        debugPrint('[群聊页面] 刷新后没有消息');
        if (mounted) {
          setState(() {
            _messages.clear();
            _currentPage = 1;
            _totalPages = 1;
            _hasMoreMessages = false;
          });
        }
        return;
      }

      debugPrint('[群聊页面] 刷新获取了 ${messageList.length} 条消息');

      // 转换消息格式
      final formattedMessages = <Map<String, dynamic>>[];
      for (final msg in messageList) {
        final role = msg['role'] as String?;
        final isUser = role == 'user';
        
        final formattedMsg = {
          'msgId': msg['msgId'],
          'content': msg['content'] ?? '',
          'isUser': isUser,
          'isLoading': false,
          'createdAt': msg['createdAt'],
        };

        // 如果是 assistant 消息，添加 customRole 和头像
        if (!isUser && msg['customRole'] != null) {
          formattedMsg['customRole'] = msg['customRole'];
          
          // 根据 customRole 查找对应角色的头像
          final avatarUri = _findRoleAvatar(msg['customRole'] as String);
          if (avatarUri != null) {
            formattedMsg['avatarUri'] = _getAvatarDataUrl(avatarUri);
          }
        }

        formattedMessages.add(formattedMsg);
      }

      // 更新分页信息
      final pagination = result['pagination'] as Map<String, dynamic>?;
      if (pagination != null) {
        _currentPage = pagination['page'] ?? 1;
        _totalPages = pagination['total_pages'] ?? 1;
        _hasMoreMessages = _currentPage < _totalPages;
        debugPrint('[群聊页面] 刷新后分页信息: $_currentPage/$_totalPages, 还有更多: $_hasMoreMessages');
      }

      if (mounted) {
        setState(() {
          // 静默替换消息列表
          _messages.clear();
          _messages.addAll(formattedMessages);
        });
      }
    } catch (e) {
      debugPrint('[群聊页面] 刷新消息失败: $e');
      // 刷新失败不提示，保持现有列表
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// 处理消息编辑
  Future<void> _handleMessageEdit(String msgId, String newContent) async {
    try {
      await _sessionService.updateMessage(_sessionId, msgId, newContent);

      // 更新本地消息
      setState(() {
        final index = _messages.indexWhere((msg) => msg['msgId'] == msgId);
        if (index != -1) {
          _messages[index]['content'] = newContent;
        }
      });

      if (mounted) {
        CustomToast.show(context, message: '消息已更新', type: ToastType.success);
      }
    } catch (e) {
      debugPrint('[群聊页面] 更新消息失败: $e');
      if (mounted) {
        CustomToast.show(context, message: '更新失败: $e', type: ToastType.error);
      }
    }
  }

  /// 处理消息删除
  Future<void> _handleMessageDeleted(String msgId) async {
    try {
      debugPrint('[群聊页面] 处理消息删除，msgId: $msgId');
      
      await _sessionService.deleteMessage(_sessionId, msgId);
      
      // 静默删除：直接从本地列表移除
      if (mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg['msgId'] == msgId);
        });
        CustomToast.show(context, message: '消息已删除', type: ToastType.success);
      }
    } catch (e) {
      debugPrint('[群聊页面] 删除消息失败: $e');
      if (mounted) {
        CustomToast.show(context, message: '删除失败: $e', type: ToastType.error);
      }
    }
  }

  /// 处理消息撤销
  Future<void> _handleMessageRevoked(String msgId) async {
    try {
      debugPrint('[群聊页面] 处理消息撤销，msgId: $msgId, msgId类型: ${msgId.runtimeType}');
      debugPrint('[群聊页面] sessionId: $_sessionId, sessionId类型: ${_sessionId.runtimeType}');
      
      // 先找到要撤销的消息的索引
      int targetIndex = -1;
      String? userMessageContent;
      
      for (int i = 0; i < _messages.length; i++) {
        if (_messages[i]['msgId'] == msgId) {
          targetIndex = i;
          // 如果是用户消息，保存内容用于恢复到输入框
          if (_messages[i]['isUser'] == true) {
            userMessageContent = _messages[i]['content'] as String?;
          }
          break;
        }
      }

      if (targetIndex == -1) {
        throw Exception('未找到要撤销的消息');
      }

      debugPrint('[群聊页面] 找到要撤销的消息，索引: $targetIndex');

      // 调用撤销 API
      debugPrint('[群聊页面] 准备调用 revokeMessageAndAfter API');
      await _sessionService.revokeMessageAndAfter(_sessionId, msgId);
      debugPrint('[群聊页面] API 调用成功');
      
      // 静默撤销：删除该消息及之前的所有消息（因为列表是倒序的，index 0 是最新）
      if (mounted) {
        setState(() {
          // 删除从 0 到 targetIndex 的所有消息
          _messages.removeRange(0, targetIndex + 1);
        });

        // 如果是用户消息，恢复内容到输入框
        if (userMessageContent != null && userMessageContent.isNotEmpty) {
          _messageController.text = userMessageContent;
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: _messageController.text.length),
          );
        }

        CustomToast.show(context, message: '消息已撤销', type: ToastType.success);
      }
    } catch (e, stackTrace) {
      debugPrint('[群聊页面] 撤销消息失败: $e');
      debugPrint('[群聊页面] 堆栈信息: $stackTrace');
      if (mounted) {
        CustomToast.show(context, message: '撤销失败: $e', type: ToastType.error);
      }
    }
  }
  
  void _navigateToGroupChatDetail() async {
    // 获取群聊卡ID
    final groupChatId = widget.groupChatData['item_id'] ?? widget.groupChatData['id'];
    if (groupChatId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法获取群聊卡信息')),
        );
      }
      return;
    }

    try {
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 获取群聊卡详情数据
      // TODO: 这里需要调用相应的服务来获取群聊卡详情
      // 暂时使用现有数据
      final groupChatDetail = widget.groupChatData;

      // 关闭加载指示器
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 跳转到群聊卡大厅详情页面
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailPage(
              item: groupChatDetail,
            ),
          ),
        );
      }
    } catch (e) {
      // 关闭加载指示器
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取群聊卡详情失败: $e')),
        );
      }
    }
  }

  void _openGroupPanel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupChatPanelPage(
          groupChatData: widget.groupChatData,
        ),
      ),
    );
  }

  void _showRolePanel() {
    final roles = widget.groupChatData['roles'] as List?;
    if (roles == null || roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('暂无角色信息')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RolePanel(roles: roles),
    );
  }

  /// 跳转到群聊设置页面
  void _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatSettingsPage(
          sessionData: widget.sessionData,
          backgroundImage: _backgroundImage,
          backgroundOpacity: _backgroundOpacity,
          onSettingsChanged: () {
            // 设置改变后，重新加载设置并刷新界面
            _loadSettings();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false, // 关键：不让Flutter自动调整布局以避免键盘
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景层
          if (_backgroundImage != null)
            Image.memory(
              _backgroundImage!,
              fit: BoxFit.cover,
            ),
          Container(color: Colors.black.withOpacity(_backgroundOpacity)),

          // 主内容层
          Column(
            children: [
              // 顶部区域
              SizedBox(height: padding.top - 8.h),
              // 自定义顶部栏
              Container(
                height: 56.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                child: Row(
                  children: [
                    // 返回按钮
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(18.r),
                        child: Container(
                          width: 32.w,
                          height: 32.w,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // 群聊信息区域 - 整体可点击跳转到大厅
                    Expanded(
                      child: GestureDetector(
                        onTap: _navigateToGroupChatDetail,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.groupChatData['name'] ?? '群聊',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                if (widget.groupChatData['author_name'] != null) ...[
                                  Text(
                                    '@${widget.groupChatData['author_name']}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                ],
                                if (widget.groupChatData['roles'] != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      '${(widget.groupChatData['roles'] as List).length} 个角色',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 群聊角色按钮
                    GestureDetector(
                      onTap: () {
                        _showRolePanel();
                      },
                      child: Container(
                        width: 44.w,
                        height: 44.w,
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      ),
                    ),
                    // 刷新按钮
                    GestureDetector(
                      onTap: _isRefreshing ? null : _refreshMessages,
                      child: Container(
                        width: 44.w,
                        height: 44.w,
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: _isRefreshing
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.w,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // 聊天消息列表区域 - 使用WebView
              Expanded(
                child: GroupChatWebView(
                  messages: _messages,
                  fontSize: _fontSize,
                  bubbleColor: _bubbleColor,
                  bubbleOpacity: _bubbleOpacity,
                  textColor: _textColor,
                  userBubbleColor: _userBubbleColor,
                  userBubbleOpacity: _userBubbleOpacity,
                  userTextColor: _userTextColor,
                  onLoadMore: _loadMoreMessages,
                  onWebViewReady: _onWebViewReady,
                  onMessageEdit: _handleMessageEdit,
                  onMessageDeleted: _handleMessageDeleted,
                  onMessageRevoked: _handleMessageRevoked,
                ),
              ),

              // 底部交互区域（整体）- 包含输入框和功能区
              Container(
                padding: EdgeInsets.only(
                    bottom: viewInsets.bottom > 0 
                        ? viewInsets.bottom // 键盘弹出时，为键盘预留空间
                        : padding.bottom), // 键盘收起时，为底部安全区域预留空间
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 新的输入区域组件
                    GroupChatInputArea(
                      messageController: _messageController,
                      focusNode: _focusNode,
                      isSending: _isSending,
                      onSendTap: _sendMessage,
                      onStopGenerationTap: _stopGeneration,
                      onOpenGroupPanel: _openGroupPanel,
                      onOpenSettings: _navigateToSettings,
                      onResetSession: _resetSession,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
