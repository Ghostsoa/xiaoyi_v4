import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/file_service.dart';
import '../../../theme/app_theme.dart';
import '../../../dao/chat_settings_dao.dart';
import '../../../dao/user_dao.dart';
import 'dart:typed_data';
import '../services/character_chat_stream_service.dart';
import '../services/character_service.dart';
import '../models/sse_response.dart';
import '../widgets/chat_bubble.dart';
import 'character_panel_page.dart';
import 'chat_settings_page.dart';
import '../../../widgets/custom_toast.dart';
import 'ui_settings_page.dart';
import '../../../pages/login/login_page.dart';

class CharacterChatPage extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final Map<String, dynamic> characterData;

  const CharacterChatPage({
    super.key,
    required this.sessionData,
    required this.characterData,
  });

  @override
  State<CharacterChatPage> createState() => _CharacterChatPageState();
}

class _CharacterChatPageState extends State<CharacterChatPage>
    with TickerProviderStateMixin {
  final FileService _fileService = FileService();
  final CharacterChatStreamService _chatService = CharacterChatStreamService();
  final CharacterService _characterService = CharacterService();
  final ChatSettingsDao _settingsDao = ChatSettingsDao();
  final UserDao _userDao = UserDao();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // 版本检查相关
  bool _hasNewVersion = false;
  bool _isUpdatingVersion = false;

  // 聊天设置
  double _backgroundOpacity = 0.5;
  Color _bubbleColor = Colors.white;
  double _bubbleOpacity = 0.8;
  Color _textColor = Colors.black;
  Color _userBubbleColor = AppTheme.primaryColor;
  double _userBubbleOpacity = 0.8;
  Color _userTextColor = Colors.white;
  double _fontSize = 14.0; // 添加字体大小设置

  Uint8List? _backgroundImage;
  bool _isLoadingBackground = false;
  bool _isMenuExpanded = false;
  bool _isSending = false;
  bool _isLoadingHistory = false;
  bool _isRefreshing = false;
  String _currentInputText = ''; // 添加输入文本跟踪
  late AnimationController _menuAnimationController;
  late Animation<double> _menuHeightAnimation;

  // 消息列表
  final List<Map<String, dynamic>> _messages = [];

  // 分页信息
  int _currentPage = 1;
  int _totalPages = 1;
  static const int _pageSize = 10;

  // 当前正在接收的消息
  String _currentMessage = '';

  // 添加一个变量用于控制流的终止
  bool _shouldStopStream = false;

  // 添加刷新按钮动画控制器
  late AnimationController _refreshAnimationController;

  // 添加格式化模式
  String _formatMode = 'none';

  // 添加抽屉控制变量
  double _drawerOffset = 0.0;
  bool _isDragging = false;
  final double _maxDrawerOffset = 500.0;
  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerAnimation;

  @override
  void initState() {
    super.initState();
    // 先加载设置，再加载其他内容
    _loadSettings().then((_) {
      _loadBackgroundImage();
      _loadMessageHistory();
      _loadFormatMode();
    });

    // 静默检查版本
    _checkSessionVersion();

    // 初始化抽屉动画控制器
    _drawerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _drawerAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _drawerAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _drawerAnimationController.addListener(() {
      setState(() {
        _drawerOffset = _drawerAnimation.value;
      });
    });

    // 初始化菜单动画控制器
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _menuHeightAnimation = Tween<double>(begin: 0, end: 100).animate(
      CurvedAnimation(
        parent: _menuAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _menuAnimationController.addListener(() => setState(() {}));

    // 改进滚动监听
    _scrollController.addListener(_onScroll);

    // 初始化刷新动画控制器
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // 添加输入监听
    _messageController.addListener(() {
      setState(() {
        _currentInputText = _messageController.text;
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _menuAnimationController.dispose();
    _scrollController.dispose();
    _refreshAnimationController.dispose();
    _drawerAnimationController.dispose();
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
        _fontSize = settings['fontSize'] ?? 14.0; // 加载字体大小设置
      });
    } catch (e) {
      debugPrint('加载设置失败: $e');
      // 使用默认值
      if (mounted) {
        setState(() {
          _backgroundOpacity = 0.5;
          _bubbleColor = Colors.white;
          _bubbleOpacity = 0.8;
          _textColor = Colors.black;
          _userBubbleColor = AppTheme.primaryColor;
          _userBubbleOpacity = 0.8;
          _userTextColor = Colors.white;
          _fontSize = 14.0; // 默认字体大小
        });
      }
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
      return Colors.white; // 返回默认颜色
    }
  }

  Future<void> _loadMessageHistory({bool isLoadMore = false}) async {
    if (_isLoadingHistory) return;

    setState(() => _isLoadingHistory = true);

    try {
      final result = await _characterService.getSessionMessages(
        widget.sessionData['id'],
        page: _currentPage,
        pageSize: _pageSize,
      );

      final List<dynamic> messageList = result['list'] ?? [];
      final pagination = result['pagination'] ?? {};

      if (mounted) {
        setState(() {
          if (!isLoadMore) {
            _messages.clear();
          }

          // 直接使用服务器返回的顺序
          _messages.addAll(messageList.map((msg) => {
                'content': msg['content'] ?? '',
                'isUser': msg['role'] == 'user',
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'tokenCount': msg['tokenCount'] ?? 0,
                'msgId': msg['msgId'],
                'status': 'done',
                'statusBar': msg['statusBar'], // 添加状态栏数据
                'enhanced': msg['enhanced'], // 添加增强状态数据
              }));

          _totalPages = pagination['total_pages'] ?? 1;
        });
      }
    } catch (e) {
      debugPrint('加载消息历史失败: $e');
      if (mounted) {
        CustomToast.show(context, message: e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  // 修改滚动监听方法
  void _onScroll() {
    // 当滚动到底部时加载更多历史消息
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        _currentPage < _totalPages &&
        !_isLoadingHistory) {
      _currentPage++;
      _loadMoreMessages();
    }
  }

  // 添加加载更多消息的方法
  Future<void> _loadMoreMessages() async {
    if (_isLoadingHistory) return;
    setState(() => _isLoadingHistory = true);

    try {
      final result = await _characterService.getSessionMessages(
        widget.sessionData['id'],
        page: _currentPage,
        pageSize: _pageSize,
      );

      final List<dynamic> messageList = result['list'] ?? [];
      final pagination = result['pagination'] ?? {};

      if (mounted) {
        setState(() {
          // 直接添加到列表末尾,保持服务器返回的顺序
          _messages.addAll(messageList.map((msg) => {
                'content': msg['content'] ?? '',
                'isUser': msg['role'] == 'user',
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'tokenCount': msg['tokenCount'] ?? 0,
                'msgId': msg['msgId'],
                'status': 'done',
                'statusBar': msg['statusBar'], // 添加状态栏数据
                'enhanced': msg['enhanced'], // 添加增强状态数据
              }));

          _totalPages = pagination['total_pages'] ?? 1;
        });
      }
    } catch (e) {
      debugPrint('加载更多消息失败: $e');
      if (mounted) {
        CustomToast.show(context, message: e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _loadBackgroundImage() async {
    if (widget.sessionData['background_uri'] == null ||
        _isLoadingBackground ||
        _backgroundImage != null) {
      return;
    }

    _isLoadingBackground = true;
    try {
      final result = await _fileService.getFile(
        widget.sessionData['background_uri'],
      );
      if (mounted) {
        setState(() {
          _backgroundImage = result.data;
          _isLoadingBackground = false;
        });
      }
    } catch (e) {
      debugPrint('背景图加载失败: $e');
      if (mounted) {
        CustomToast.show(context, message: e.toString(), type: ToastType.error);
        setState(() => _isLoadingBackground = false);
      }
    }
  }

  Future<void> _handleSendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    // 添加用户消息到列表开头
    setState(() {
      _messages.insert(0, {
        'content': message,
        'isUser': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'msgId': null,
      });
      _isSending = true;
      _currentMessage = '';
      _shouldStopStream = false;
    });

    // 清空输入框并收起键盘
    _messageController.clear();
    FocusScope.of(context).unfocus();

    try {
      // 添加AI消息占位
      setState(() {
        _messages.insert(0, {
          'content': '',
          'isUser': false,
          'isLoading': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'msgId': null,
        });
      });

      // 订阅消息流
      await for (final SseResponse response in _chatService.sendMessage(
        widget.sessionData['id'],
        message,
      )) {
        if (!mounted || _shouldStopStream) break;

        setState(() {
          if (response.isMessage) {
            final newContent = response.content ?? '';
            _currentMessage += newContent;
            _messages[0]['content'] = _currentMessage;
            _messages[0]['isLoading'] = false;
            _messages[0]['status'] = response.status;

            // 保存消息ID
            if (response.messageId != null) {
              _messages[0]['msgId'] = response.messageId;
            }

            // 保存状态栏数据
            if (response.statusBar != null) {
              _messages[0]['statusBar'] = response.statusBar;
            }

            // 保存增强状态
            if (response.enhanced != null) {
              _messages[0]['enhanced'] = response.enhanced;
            }
          } else if (response.isDone) {
            _messages[0]['status'] = 'done';
            _messages[0]['isLoading'] = false;

            // 保存状态栏数据
            if (response.statusBar != null) {
              _messages[0]['statusBar'] = response.statusBar;
            }

            // 保存增强状态
            if (response.enhanced != null) {
              _messages[0]['enhanced'] = response.enhanced;
            }
          } else if (response.isError) {
            // 处理错误消息
            final errorContent =
                response.content ?? response.errorMsg ?? '未知错误';

            setState(() {
              // 错误消息不应显示为气泡，直接移除AI消息占位
              _messages.removeAt(0);

              // 同时将用户的消息也移除，并恢复到输入框中
              if (_messages.isNotEmpty && _messages[0]['isUser']) {
                final userMessage = _messages.removeAt(0);
                // 将用户消息放回输入框
                _messageController.text = userMessage['content'];
                _messageController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _messageController.text.length),
                );
              }
            });

            // 显示错误提示
            if (mounted) {
              CustomToast.show(context,
                  message: errorContent, type: ToastType.error);
            }

            // 检查是否是令牌失效
            if (errorContent.contains('令牌失效') || errorContent.contains('未登录')) {
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            }
          }
        });
      }

      if (_shouldStopStream) {
        setState(() {
          _messages[0]['content'] += '\n[已终止生成]';
          _messages[0]['status'] = 'done';
          _messages[0]['isLoading'] = false;
        });
      }
    } catch (e) {
      debugPrint('发送消息错误: $e');
      if (mounted) {
        setState(() {
          // 错误处理 - 移除AI回复和用户消息，把用户消息恢复到输入框
          if (_messages.isNotEmpty) {
            // 如果AI回复已经显示，先删除它
            if (!_messages[0]['isUser']) {
              _messages.removeAt(0);
            }

            // 然后找到并删除最近的用户消息，将其内容恢复到输入框
            int userMsgIndex =
                _messages.indexWhere((msg) => msg['isUser'] == true);
            if (userMsgIndex >= 0) {
              final userMessage = _messages.removeAt(userMsgIndex);
              // 将用户消息放回输入框
              _messageController.text = userMessage['content'];
              _messageController.selection = TextSelection.fromPosition(
                TextPosition(offset: _messageController.text.length),
              );
            }
          }
        });

        CustomToast.show(context, message: e.toString(), type: ToastType.error);

        if (e.toString().contains('令牌失效')) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
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

  void _handleStopGeneration() {
    setState(() => _shouldStopStream = true);
  }

  void _handleMenuToggle() {
    setState(() {
      _isMenuExpanded = !_isMenuExpanded;
      if (_isMenuExpanded) {
        _menuAnimationController.forward();
      } else {
        _menuAnimationController.reverse();
      }
    });
  }

  // 添加重置会话的方法
  Future<void> _handleResetSession() async {
    // 显示确认对话框
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认重置'),
          content: const Text('确定要清空所有对话记录吗？此操作不可恢复。'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('确定', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      // 调用重置会话接口
      await _characterService.resetSession(widget.sessionData['id']);

      if (mounted) {
        // 清空本地消息列表
        setState(() {
          _messages.clear();
          _currentPage = 1;
          _totalPages = 1;
        });

        // 刷新消息列表
        setState(() => _isRefreshing = true);
        try {
          final result = await _characterService.getSessionMessages(
            widget.sessionData['id'],
            page: 1,
            pageSize: _pageSize,
          );

          if (!mounted) return;

          final List<dynamic> messageList = result['list'] ?? [];
          final pagination = result['pagination'] ?? {};

          // 直接使用服务器返回的顺序，不需要反转
          final newMessages = messageList
              .map(
                (msg) => {
                  'content': msg['content'] ?? '',
                  'isUser': msg['role'] == 'user',
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                  'tokenCount': msg['tokenCount'] ?? 0,
                  'msgId': msg['msgId'],
                  'status': 'done',
                  'statusBar': msg['statusBar'], // 添加状态栏数据
                  'enhanced': msg['enhanced'], // 添加增强状态数据
                },
              )
              .toList();

          setState(() {
            _messages.clear();
            _messages.addAll(newMessages);
            _totalPages = pagination['total_pages'] ?? 1;
            _currentPage = 1;
          });

          // 滚动到底部
          _scrollToBottom();

          // 显示成功提示
          CustomToast.show(context, message: '对话已重置', type: ToastType.success);
        } catch (e) {
          debugPrint('刷新消息失败: $e');
        } finally {
          if (mounted) {
            setState(() => _isRefreshing = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '重置失败: $e', type: ToastType.error);
      }
    }
  }

  // 添加撤回最后一条消息的方法
  Future<void> _handleUndoLastMessage() async {
    if (_messages.isEmpty) return;

    try {
      // 调用撤回接口
      await _characterService.revokeLastMessage(widget.sessionData['id']);

      // 如果第一条是AI的回复，需要同时删除用户的提问
      if (!_messages[0]['isUser']) {
        setState(() {
          _messages.removeAt(0); // 删除AI回复
          if (_messages.isNotEmpty && _messages[0]['isUser']) {
            // 将用户消息内容放回输入框
            _messageController.text = _messages[0]['content'];
            // 将光标移到文本末尾
            _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: _messageController.text.length),
            );
            _messages.removeAt(0); // 删除用户提问
          }
        });
      } else {
        setState(() {
          // 将用户消息内容放回输入框
          _messageController.text = _messages[0]['content'];
          // 将光标移到文本末尾
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: _messageController.text.length),
          );
          _messages.removeAt(0); // 只删除用户消息
        });
      }
    } catch (e) {
      debugPrint('撤回消息失败: $e');
      if (mounted) {
        CustomToast.show(context, message: e.toString(), type: ToastType.error);
      }
    }
  }

  // 添加消息编辑处理方法
  Future<void> _handleMessageEdit(String msgId, String newContent) async {
    try {
      await _characterService.updateMessage(
        widget.sessionData['id'],
        msgId,
        newContent,
      );

      // 更新本地消息
      setState(() {
        final index = _messages.indexWhere(
          (msg) => msg['msgId'] == msgId,
        );
        if (index != -1) {
          _messages[index]['content'] = newContent;
        }
      });

      // 编辑完成后调用刷新方法
      if (mounted) {
        setState(() => _isRefreshing = true);
        try {
          final result = await _characterService.getSessionMessages(
            widget.sessionData['id'],
            page: 1,
            pageSize: _pageSize,
          );

          if (!mounted) return;

          final List<dynamic> messageList = result['list'] ?? [];

          final newMessages = messageList
              .map(
                (msg) => {
                  'content': msg['content'] ?? '',
                  'isUser': msg['role'] == 'user',
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                  'tokenCount': msg['tokenCount'] ?? 0,
                  'msgId': msg['msgId'],
                  'status': 'done',
                  'statusBar': msg['statusBar'], // 添加状态栏数据
                  'enhanced': msg['enhanced'], // 添加增强状态数据
                },
              )
              .toList();

          // 对比并更新消息
          bool hasNewMessages = false;

          // 检查现有消息的内容变化
          for (int i = 0; i < _messages.length; i++) {
            if (i < newMessages.length) {
              final oldMsg = _messages[i];
              final newMsg = newMessages[i];

              if (oldMsg['content'] != newMsg['content']) {
                setState(() {
                  oldMsg['content'] = newMsg['content'];
                });
              }
            }
          }

          // 检查是否有新消息
          if (newMessages.length > _messages.length) {
            hasNewMessages = true;
            setState(() {
              _messages.addAll(newMessages.sublist(_messages.length));
            });
          }

          // 如果有新消息，滚动到底部
          if (hasNewMessages) {}
        } catch (e) {
          debugPrint('刷新消息失败: $e');
        } finally {
          if (mounted) {
            setState(() => _isRefreshing = false);
          }
        }
      }
    } catch (e) {
      debugPrint('更新消息失败: $e');
      if (mounted) {
        CustomToast.show(context, message: e.toString(), type: ToastType.error);
      }
    }
  }

  // 添加加载格式化模式的方法
  Future<void> _loadFormatMode() async {
    // 首先检查角色数据中是否包含ui_settings
    if (widget.characterData.containsKey('ui_settings')) {
      final uiSettings = widget.characterData['ui_settings'];
      String mode = 'none';

      // 根据ui_settings字段设置相应的格式模式
      switch (uiSettings) {
        case 'markdown':
          mode = 'markdown';
          break;
        case 'disabled':
          mode = 'none';
          break;
        case 'legacy_bar':
          mode = 'old';
          break;
        default:
          // 如果ui_settings不是预期的值，从存储中加载
          mode = await _settingsDao.getUiMode();
      }

      if (mounted) {
        setState(() {
          _formatMode = mode;
        });
      }
    } else {
      // 如果没有ui_settings字段，从存储中加载默认设置
      final mode = await _settingsDao.getUiMode();
      if (mounted) {
        setState(() {
          _formatMode = mode;
        });
      }
    }
  }

  Widget _buildExpandedFunctionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 24.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 添加简单的滚动到底部方法
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0); // 因为列表是反向的,所以滚动到0就是底部
    }
  }

  // 添加检查版本的方法
  Future<void> _checkSessionVersion() async {
    // 静默异步检查，不影响UI
    try {
      final versionData = await _characterService.checkSessionVersion(
        widget.sessionData['id'],
      );

      if (mounted) {
        setState(() {
          _hasNewVersion = !(versionData['isLatest'] ?? true);
        });
      }
    } catch (e) {
      // 静默处理错误，仅打印日志
      debugPrint('检查版本失败：$e');
    }
  }

  // 添加更新版本的方法
  Future<void> _handleVersionUpdate() async {
    if (!_hasNewVersion || _isUpdatingVersion) return;

    setState(() {
      _isUpdatingVersion = true;
    });

    try {
      await _characterService.updateSessionVersion(
        widget.sessionData['id'],
      );

      if (mounted) {
        setState(() {
          _hasNewVersion = false;
          _isUpdatingVersion = false;
        });
        CustomToast.show(context,
            message: '会话已更新到最新版本', type: ToastType.success);
      }
    } catch (e) {
      debugPrint('更新版本失败：$e');
      if (mounted) {
        setState(() {
          _isUpdatingVersion = false;
        });
        CustomToast.show(context, message: '更新版本失败：$e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
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
                height: 44.h,
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
                    // 角色名称
                    Expanded(
                      child: Text(
                        widget.characterData['name'] ?? '对话',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 版本更新按钮（仅在有新版本时显示）
                    if (_hasNewVersion)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap:
                              _isUpdatingVersion ? null : _handleVersionUpdate,
                          borderRadius: BorderRadius.circular(18.r),
                          child: Container(
                            width: 36.w,
                            height: 36.w,
                            alignment: Alignment.center,
                            child: _isUpdatingVersion
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        Colors.amber,
                                      ),
                                    ),
                                  )
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.upgrade,
                                        color: Colors.amber,
                                        size: 22.sp,
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          width: 8.w,
                                          height: 8.w,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    // 刷新按钮
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isRefreshing
                            ? null
                            : () async {
                                setState(() => _isRefreshing = true);

                                try {
                                  final result = await _characterService
                                      .getSessionMessages(
                                    widget.sessionData['id'],
                                    page: 1,
                                    pageSize: _pageSize,
                                  );

                                  if (!mounted) return;

                                  final List<dynamic> messageList =
                                      result['list'] ?? [];
                                  final pagination = result['pagination'] ?? {};

                                  // 直接使用服务器返回的顺序，不需要反转
                                  final newMessages = messageList
                                      .map(
                                        (msg) => {
                                          'content': msg['content'] ?? '',
                                          'isUser': msg['role'] == 'user',
                                          'timestamp': DateTime.now()
                                              .millisecondsSinceEpoch,
                                          'tokenCount': msg['tokenCount'] ?? 0,
                                          'msgId': msg['msgId'],
                                          'status': 'done',
                                          'statusBar':
                                              msg['statusBar'], // 添加状态栏数据
                                          'enhanced':
                                              msg['enhanced'], // 添加增强状态数据
                                        },
                                      )
                                      .toList();

                                  setState(() {
                                    _messages.clear();
                                    _messages.addAll(newMessages);
                                    _totalPages =
                                        pagination['total_pages'] ?? 1;
                                    _currentPage = 1;
                                  });

                                  // 滚动到底部
                                  _scrollToBottom();
                                } catch (e) {
                                  debugPrint('刷新消息失败: $e');
                                  if (mounted) {
                                    CustomToast.show(
                                      context,
                                      message: e.toString(),
                                      type: ToastType.error,
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isRefreshing = false);
                                  }
                                }
                              },
                        borderRadius: BorderRadius.circular(18.r),
                        child: Container(
                          width: 36.w,
                          height: 36.w,
                          alignment: Alignment.center,
                          child: _isRefreshing
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.w,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 中间可拖拽的消息区域（占满剩余空间）
              Expanded(
                child: GestureDetector(
                  onVerticalDragStart: (details) {
                    setState(() {
                      _isDragging = true;
                    });
                  },
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _drawerOffset += details.delta.dy;
                      // 限制抽屉范围
                      if (_drawerOffset < 0) _drawerOffset = 0;
                      if (_drawerOffset > _maxDrawerOffset)
                        _drawerOffset = _maxDrawerOffset;
                    });
                  },
                  onVerticalDragEnd: (details) {
                    // 保持在当前位置，不自动收起或展开
                    setState(() {
                      _isDragging = false;

                      // 设置动画的起始值为当前位置
                      _drawerAnimation = Tween<double>(
                        begin: _drawerOffset,
                        end: _drawerOffset,
                      ).animate(
                        CurvedAnimation(
                          parent: _drawerAnimationController,
                          curve: Curves.easeOut,
                        ),
                      );

                      // 如果有较大的滑动速度，则根据速度方向决定展开或收起
                      if (details.velocity.pixelsPerSecond.dy.abs() > 500) {
                        if (details.velocity.pixelsPerSecond.dy > 0) {
                          // 向下滑动，展开到最大
                          _drawerAnimation = Tween<double>(
                            begin: _drawerOffset,
                            end: _maxDrawerOffset,
                          ).animate(
                            CurvedAnimation(
                              parent: _drawerAnimationController,
                              curve: Curves.easeOut,
                            ),
                          );
                        } else {
                          // 向上滑动，收起
                          _drawerAnimation = Tween<double>(
                            begin: _drawerOffset,
                            end: 0,
                          ).animate(
                            CurvedAnimation(
                              parent: _drawerAnimationController,
                              curve: Curves.easeOut,
                            ),
                          );
                        }
                        // 重置动画并开始
                        _drawerAnimationController.reset();
                        _drawerAnimationController.forward();
                      }
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(top: _drawerOffset),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                    ),
                    child: Column(
                      children: [
                        // 抽屉指示条
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8.h),
                          width: 60.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(2.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                        ),
                        // 消息列表 - 占用抽屉区域的大部分空间，但不是全部
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20.r)),
                            child: ListView.builder(
                              reverse: true, // 反转列表,新消息在底部
                              controller: _scrollController,
                              padding: EdgeInsets.only(
                                top: 16.h,
                                bottom: 16.h,
                              ),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                return ChatBubble(
                                  key: ValueKey(
                                      message['msgId'] ?? message['timestamp']),
                                  message: message['content'],
                                  isUser: message['isUser'],
                                  isLoading: message['isLoading'] ?? false,
                                  status: message['status'],
                                  bubbleColor: message['isUser']
                                      ? _userBubbleColor
                                      : _bubbleColor,
                                  bubbleOpacity: message['isUser']
                                      ? _userBubbleOpacity
                                      : _bubbleOpacity,
                                  textColor: message['isUser']
                                      ? _userTextColor
                                      : _textColor,
                                  msgId: message['msgId'],
                                  onEdit: !message['isUser'] &&
                                          message['msgId'] != null
                                      ? _handleMessageEdit
                                      : null,
                                  formatMode: _formatMode,
                                  statusBar: message['statusBar'],
                                  enhance: message['enhanced'],
                                  fontSize: _fontSize, // 传递字体大小设置
                                );
                              },
                              // 性能优化选项
                              addAutomaticKeepAlives: false,
                              addRepaintBoundaries: true,
                              clipBehavior: Clip.hardEdge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 底部输入框区域（固定部分）
              Container(
                padding: EdgeInsets.only(bottom: viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 输入框区域
                    Container(
                      padding: EdgeInsets.only(
                        left: 16.w,
                        right: 16.w,
                        top: 8.h,
                        bottom: padding.bottom + 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // 汉堡按钮
                          Container(
                            width: 36.w,
                            height: 36.w,
                            margin: EdgeInsets.only(right: 8.w),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _handleMenuToggle,
                                borderRadius: BorderRadius.circular(18.r),
                                child: Icon(
                                  _isMenuExpanded
                                      ? Icons.keyboard_arrow_down
                                      : Icons.keyboard_arrow_up,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                              ),
                            ),
                          ),
                          // 输入框
                          Expanded(
                            child: Container(
                              constraints: BoxConstraints(
                                minHeight: 36.h,
                                maxHeight: 120.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(18.r),
                              ),
                              child: TextField(
                                controller: _messageController,
                                focusNode: _focusNode,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                ),
                                maxLines: null,
                                decoration: InputDecoration(
                                  hintText: '发送消息...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14.sp,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 8.h,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                          // 发送/终止/撤回按钮
                          Container(
                            width: 36.w,
                            height: 36.w,
                            margin: EdgeInsets.only(left: 8.w),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isSending
                                    ? _handleStopGeneration
                                    : _currentInputText.trim().isNotEmpty
                                        ? _handleSendMessage
                                        : _handleUndoLastMessage,
                                borderRadius: BorderRadius.circular(18.r),
                                child: Icon(
                                  _isSending
                                      ? Icons.stop_rounded
                                      : _currentInputText.trim().isNotEmpty
                                          ? Icons.send
                                          : Icons.undo,
                                  color: _isSending
                                      ? Colors.red.withOpacity(0.8)
                                      : _currentInputText.trim().isNotEmpty
                                          ? AppTheme.primaryColor
                                          : Colors.white.withOpacity(0.8),
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 展开的功能区
                    if (_isMenuExpanded)
                      Container(
                        height: _menuHeightAnimation.value,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: GridView.count(
                          crossAxisCount: 4,
                          padding: EdgeInsets.only(
                            top: 8.h,
                            bottom:
                                viewInsets.bottom > 0 ? 8.h : padding.bottom,
                          ),
                          mainAxisSpacing: 4.h,
                          crossAxisSpacing: 4.w,
                          childAspectRatio: 1.2,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildExpandedFunctionButton(
                              icon: Icons.person,
                              label: '角色',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CharacterPanelPage(
                                      characterData: widget.sessionData,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildExpandedFunctionButton(
                              icon: Icons.palette,
                              label: '界面',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ChatSettingsPage(
                                      sessionData: widget.sessionData,
                                      onSettingsChanged: () {
                                        // 重新加载设置
                                        _loadSettings();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildExpandedFunctionButton(
                              icon: Icons.format_paint,
                              label: '消息渲染',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UiSettingsPage(
                                      onSettingsChanged: () {
                                        // 重新加载格式化模式
                                        _loadFormatMode();
                                        // 强制刷新所有消息
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildExpandedFunctionButton(
                              icon: Icons.delete,
                              label: '清空对话',
                              onTap: _handleResetSession,
                            ),
                          ],
                        ),
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
