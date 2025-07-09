import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/file_service.dart';
import '../../../theme/app_theme.dart';
import '../../../dao/chat_settings_dao.dart';
import '../../../dao/user_dao.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../services/character_chat_stream_service.dart';
import '../services/character_service.dart';
import '../models/sse_response.dart';
import '../widgets/chat_bubble.dart';
import 'character_panel_page.dart';
import 'chat_settings_page.dart';
import '../../../widgets/custom_toast.dart';
import 'ui_settings_page.dart';
import '../../../pages/login/login_page.dart';
import '../../../pages/home/pages/item_detail_page.dart';
import 'chat_archive_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 常用记录数据模型
class CommonPhrase {
  final String id;
  final String name;
  final String content;

  CommonPhrase({required this.id, required this.name, required this.content});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
    };
  }

  factory CommonPhrase.fromJson(Map<String, dynamic> json) {
    return CommonPhrase(
      id: json['id'],
      name: json['name'],
      content: json['content'],
    );
  }
}

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

  // 添加常用记录相关变量
  List<CommonPhrase> _commonPhrases = [];
  bool _isShowingPhrases = false;
  OverlayEntry? _phrasesOverlay;
  final GlobalKey _commonPhrasesKey = GlobalKey();
  final TextEditingController _phraseNameController = TextEditingController();
  final TextEditingController _phraseContentController =
      TextEditingController();

  // 添加输入框是否聚焦的状态
  bool _isInputFocused = false;

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
  Uint8List? _avatarImage; // 添加头像图片缓存
  bool _isLoadingBackground = false;
  bool _isLoadingAvatar = false; // 添加头像加载状态
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

  // 添加功能气泡动画控制器
  late AnimationController _bubbleAnimationController;
  late Animation<double> _bubbleOpacityAnimation;

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
      _loadAvatarImage(); // 添加加载头像
      _loadMessageHistory();
      _loadFormatMode();
      _loadCommonPhrases(); // 加载常用记录
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

    // 初始化功能气泡动画控制器
    _bubbleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bubbleOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _bubbleAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _bubbleAnimationController.addListener(() => setState(() {}));

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

    // 添加焦点监听
    _focusNode.addListener(_onFocusChange);
  }

  // 焦点变化监听方法
  void _onFocusChange() {
    setState(() {
      _isInputFocused = _focusNode.hasFocus;
      if (_isInputFocused) {
        _bubbleAnimationController.forward();
      } else {
        _bubbleAnimationController.reverse();
        // 当失去焦点时，隐藏常用记录列表
        _hidePhrasesList();
      }
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
    _bubbleAnimationController.dispose();
    _phraseNameController.dispose();
    _phraseContentController.dispose();

    // 直接移除overlay，而不是调用_hidePhrasesList
    if (_phrasesOverlay != null) {
      _phrasesOverlay?.remove();
      _phrasesOverlay = null;
    }
    _isShowingPhrases = false;

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
                'createdAt': msg['createdAt'], // 添加创建时间
                'keywords': msg['keywords'], // 添加关键词数组
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
                'createdAt': msg['createdAt'], // 添加创建时间
                'keywords': msg['keywords'], // 添加关键词数组
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

  Future<void> _loadAvatarImage() async {
    if (widget.characterData['cover_uri'] == null ||
        _isLoadingAvatar ||
        _avatarImage != null) {
      return;
    }

    _isLoadingAvatar = true;
    try {
      final result = await _fileService.getFile(
        widget.characterData['cover_uri'],
      );
      if (mounted) {
        setState(() {
          _avatarImage = result.data;
          _isLoadingAvatar = false;
        });
      }
    } catch (e) {
      debugPrint('头像图片加载失败: $e');
      if (mounted) {
        setState(() => _isLoadingAvatar = false);
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
        'msgId': null, // 暂时为null，发送完成后会刷新获取真实msgId
        'createdAt': DateTime.now().toIso8601String(), // 添加当前时间作为创建时间
        'keywords': null, // 用户消息没有关键词
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
          'createdAt': DateTime.now().toIso8601String(), // 添加当前时间作为创建时间
          'keywords': null, // AI消息还未生成，暂无关键词
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

            // 保存关键词数据
            if (response.keywords != null) {
              _messages[0]['keywords'] = response.keywords;
            }

            // 如果没有createdAt字段，添加当前时间
            if (_messages[0]['createdAt'] == null) {
              _messages[0]['createdAt'] = DateTime.now().toIso8601String();
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

      // 消息发送完成后，刷新消息列表以获取完整的ID信息
      await _refreshMessages();

      // 添加调试信息，检查每条消息是否有msgId
      debugPrint('---- 消息列表信息 ----');
      for (int i = 0; i < _messages.length; i++) {
        final msg = _messages[i];
        debugPrint(
            '消息${i + 1}: isUser=${msg['isUser']}, msgId=${msg['msgId']}');
      }
      debugPrint('-------------------');
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

  // 添加消息刷新方法
  Future<void> _refreshMessages() async {
    if (_isRefreshing) return;

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

      final newMessages = messageList
          .map(
            (msg) => {
              'content': msg['content'] ?? '',
              'isUser': msg['role'] == 'user',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'tokenCount': msg['tokenCount'] ?? 0,
              'msgId': msg['msgId'],
              'status': 'done',
              'statusBar': msg['statusBar'],
              'enhanced': msg['enhanced'],
              'createdAt': msg['createdAt'], // 添加创建时间
              'keywords': msg['keywords'], // 添加关键词数组
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
        await _refreshMessages();

        // 显示成功提示
        CustomToast.show(context, message: '对话已重置', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '重置失败: $e', type: ToastType.error);
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

  // 添加重新生成消息的方法
  Future<void> _handleRegenerateMessage(String msgId) async {
    if (_isSending) return;

    // 查找需要重新生成的消息
    final int messageIndex = _messages.indexWhere((m) => m['msgId'] == msgId);
    if (messageIndex == -1) {
      if (mounted) {
        CustomToast.show(context, message: '找不到指定的消息', type: ToastType.error);
      }
      return;
    }

    setState(() {
      // 标记消息为正在加载状态
      _messages[messageIndex]['isLoading'] = true;
      _messages[messageIndex]['status'] = 'streaming';
      _messages[messageIndex]['content'] = ''; // 清空内容，准备重新生成
      _isSending = true;
      _currentMessage = '';
      _shouldStopStream = false;
    });

    try {
      // 调用重新生成API
      await for (final SseResponse response in _chatService.regenerateMessage(
        widget.sessionData['id'],
        msgId,
      )) {
        if (!mounted || _shouldStopStream) break;

        setState(() {
          if (response.isMessage) {
            final newContent = response.content ?? '';
            _currentMessage += newContent;

            // 更新消息内容
            _messages[messageIndex]['content'] = _currentMessage;
            _messages[messageIndex]['isLoading'] = false;
            _messages[messageIndex]['status'] = response.status;

            // 更新消息ID（如果服务端返回了新ID）
            if (response.messageId != null) {
              _messages[messageIndex]['msgId'] = response.messageId;
            }

            // 更新状态栏数据
            if (response.statusBar != null) {
              _messages[messageIndex]['statusBar'] = response.statusBar;
            }

            // 更新增强状态
            if (response.enhanced != null) {
              _messages[messageIndex]['enhanced'] = response.enhanced;
            }
          } else if (response.isDone) {
            _messages[messageIndex]['status'] = 'done';
            _messages[messageIndex]['isLoading'] = false;

            // 更新状态栏数据
            if (response.statusBar != null) {
              _messages[messageIndex]['statusBar'] = response.statusBar;
            }

            // 更新增强状态
            if (response.enhanced != null) {
              _messages[messageIndex]['enhanced'] = response.enhanced;
            }
          } else if (response.isError) {
            // 处理错误消息
            final errorContent =
                response.content ?? response.errorMsg ?? '未知错误';

            // 重置消息状态
            _messages[messageIndex]['status'] = 'error';
            _messages[messageIndex]['isLoading'] = false;

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
          _messages[messageIndex]['content'] += '\n[已终止生成]';
          _messages[messageIndex]['status'] = 'done';
          _messages[messageIndex]['isLoading'] = false;
        });
      }
    } catch (e) {
      debugPrint('重新生成消息错误: $e');
      if (mounted) {
        setState(() {
          // 重置消息状态
          _messages[messageIndex]['status'] = 'error';
          _messages[messageIndex]['isLoading'] = false;
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

  void _navigateToCharacterDetail() async {
    // 获取角色卡ID
    final characterId = widget.characterData['character_id'];
    if (characterId == null) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '无法获取角色卡信息',
          type: ToastType.error,
        );
      }
      return;
    }

    try {
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 调用API获取角色卡详情
      final characterDetail =
          await _characterService.getCharacterDetail(characterId);

      // 关闭加载指示器
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 检查响应状态码
      if (characterDetail.containsKey('code') && characterDetail['code'] != 0) {
        if (mounted) {
          CustomToast.show(
            context,
            message: '无法在大厅找到对应卡',
            type: ToastType.error,
          );
        }
        return;
      }

      // 跳转到角色卡详情页面
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailPage(
              item: characterDetail,
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
        CustomToast.show(
          context,
          message: '无法在大厅找到对应卡',
          type: ToastType.error,
        );
      }
    }
  }

  // 添加括号功能方法
  void _insertBrackets() {
    final TextEditingController controller = _messageController;
    final TextSelection selection = controller.selection;
    final String currentText = controller.text;

    String newText;
    TextSelection newSelection;

    // 如果有选中文本，则在两侧添加括号
    if (selection.start != selection.end) {
      final String selectedText =
          currentText.substring(selection.start, selection.end);
      newText = currentText.replaceRange(
          selection.start, selection.end, '($selectedText)');
      newSelection = TextSelection.collapsed(offset: selection.end + 2);
    } else {
      // 如果没有选中文本，则插入空括号，并将光标放在括号中间
      newText = currentText.replaceRange(selection.start, selection.end, '()');
      newSelection = TextSelection.collapsed(offset: selection.start + 1);
    }

    controller.value = controller.value.copyWith(
      text: newText,
      selection: newSelection,
    );
  }

  // 添加清空输入框方法
  void _clearInput() {
    _messageController.clear();
  }

  // 添加功能气泡UI组件
  Widget _buildFunctionBubble({
    Widget? icon,
    required String label,
    required VoidCallback onTap,
    Key? key,
  }) {
    return Container(
      key: key,
      margin: EdgeInsets.only(right: 8.w),
      child: Material(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  icon,
                  SizedBox(width: 4.w),
                ],
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
        ),
      ),
    );
  }

  // 加载常用记录
  Future<void> _loadCommonPhrases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phrasesJson = prefs.getString('common_phrases') ?? '[]';
      final List<dynamic> phrasesList = jsonDecode(phrasesJson);

      setState(() {
        _commonPhrases =
            phrasesList.map((item) => CommonPhrase.fromJson(item)).toList();
      });
    } catch (e) {
      debugPrint('加载常用记录失败: $e');
      // 出错时使用空列表
      setState(() {
        _commonPhrases = [];
      });
    }
  }

  // 保存常用记录
  Future<void> _saveCommonPhrases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phrasesJson =
          jsonEncode(_commonPhrases.map((p) => p.toJson()).toList());
      await prefs.setString('common_phrases', phrasesJson);
    } catch (e) {
      debugPrint('保存常用记录失败: $e');
      if (mounted) {
        CustomToast.show(context, message: '保存失败: $e', type: ToastType.error);
      }
    }
  }

  // 添加常用记录
  Future<void> _addCommonPhrase(String name, String content) async {
    if (name.trim().isEmpty || content.trim().isEmpty) {
      if (mounted) {
        CustomToast.show(context, message: '名称和内容不能为空', type: ToastType.error);
      }
      return;
    }

    final newPhrase = CommonPhrase(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      content: content.trim(),
    );

    setState(() {
      _commonPhrases.add(newPhrase);
    });

    await _saveCommonPhrases();

    if (mounted) {
      CustomToast.show(context, message: '添加成功', type: ToastType.success);
    }
  }

  // 删除常用记录
  Future<void> _deleteCommonPhrase(String id) async {
    setState(() {
      _commonPhrases.removeWhere((phrase) => phrase.id == id);
    });

    await _saveCommonPhrases();
  }

  // 使用常用记录
  void _useCommonPhrase(String content) {
    final TextEditingController controller = _messageController;
    final TextSelection selection = controller.selection;
    final String currentText = controller.text;

    // 在光标位置插入内容
    final int start = selection.start;
    final int end = selection.end;

    if (start < 0 || end < 0) {
      // 如果没有有效的光标位置，则追加到末尾
      controller.text = currentText + content;
      controller.selection =
          TextSelection.collapsed(offset: controller.text.length);
    } else {
      // 在光标位置插入内容
      final newText = currentText.replaceRange(start, end, content);
      controller.text = newText;
      controller.selection =
          TextSelection.collapsed(offset: start + content.length);
    }

    _hidePhrasesList();
  }

  // 显示常用记录列表
  void _showPhrasesList() {
    setState(() {
      _isShowingPhrases = true;
    });
  }

  // 隐藏常用记录列表
  void _hidePhrasesList() {
    if (_phrasesOverlay != null) {
      _phrasesOverlay?.remove();
      _phrasesOverlay = null;
    }

    if (mounted) {
      setState(() {
        _isShowingPhrases = false;
      });
    } else {
      _isShowingPhrases = false;
    }
  }

  // 构建常用记录列表UI
  Widget _buildPhrasesList() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              Text(
                '快捷语',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              // 返回按钮
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _hidePhrasesList,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // 列表内容
          _commonPhrases.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Center(
                    child: Text(
                      '暂无快捷语',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12.sp),
                    ),
                  ),
                )
              : Container(
                  constraints: BoxConstraints(maxHeight: 150.h),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _commonPhrases.length > 10
                        ? 10
                        : _commonPhrases.length, // 最多显示10条
                    itemBuilder: (context, index) {
                      final phrase = _commonPhrases[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: InkWell(
                          onTap: () => _useCommonPhrase(phrase.content),
                          borderRadius: BorderRadius.circular(4.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 6.h),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    phrase.name,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12.sp),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                GestureDetector(
                                  onTap: () => _deleteCommonPhrase(phrase.id),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  // 显示添加常用记录对话框
  void _showAddPhraseDialog() {
    _phraseNameController.clear();
    _phraseContentController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加快捷语'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _phraseNameController,
              decoration: InputDecoration(
                labelText: '备注',
                hintText: '输入一个简短的备注',
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _phraseContentController,
              decoration: InputDecoration(
                labelText: '内容',
                hintText: '输入要保存的内容',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _addCommonPhrase(
                _phraseNameController.text,
                _phraseContentController.text,
              );
              Navigator.pop(context);
            },
            child: Text('保存'),
          ),
        ],
      ),
    );
  }

  // 添加跳转到存档页面的方法
  void _navigateToChatArchive() async {
    final bool? needRefresh = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatArchivePage(
          sessionId: widget.sessionData['id'].toString(),
        ),
      ),
    );

    // 如果返回值为true，表示有存档被激活，需要刷新消息
    if (needRefresh == true && mounted) {
      _refreshMessages();
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
                height: 56.h, // 增加高度以容纳两行文本
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
                    // 角色头像和信息区域 - 整体可点击
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigateToCharacterDetail(),
                        child: Row(
                          children: [
                            // 角色头像
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18.r),
                              child: _avatarImage != null
                                  ? Image.memory(
                                      _avatarImage!,
                                      width: 36.w,
                                      height: 36.w,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 36.w,
                                      height: 36.w,
                                      color: Colors.grey.withOpacity(0.3),
                                      child: Icon(Icons.person,
                                          color: Colors.white),
                                    ),
                            ),
                            SizedBox(width: 12.w),
                            // 角色名称和作者
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.characterData['name'] ?? '对话',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.characterData['author_name'] !=
                                      null)
                                    Text(
                                      '@${widget.characterData['author_name']}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12.sp,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                      if (_drawerOffset > _maxDrawerOffset) {
                        _drawerOffset = _maxDrawerOffset;
                      }
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
                            child: RefreshIndicator(
                              onRefresh: _refreshMessages,
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
                                    key: ValueKey(message['msgId'] ??
                                        message['timestamp']),
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
                                    onEdit: _handleMessageEdit,
                                    formatMode: _formatMode,
                                    statusBar: message['statusBar'],
                                    enhance: message['enhanced'],
                                    fontSize: _fontSize, // 传递字体大小设置
                                    sessionId:
                                        widget.sessionData['id'], // 添加会话ID
                                    onMessageDeleted: () {
                                      // 消息删除成功后刷新消息列表
                                      _refreshMessages();
                                    },
                                    onMessageRevoked: () {
                                      // 消息撤销成功后刷新消息列表
                                      _refreshMessages();
                                    },
                                    onMessageRegenerate: !message['isUser']
                                        ? _handleRegenerateMessage
                                        : null, // 只对AI消息添加重新生成功能
                                    createdAt: message['createdAt'], // 添加创建时间
                                    keywords: message['keywords'], // 传递关键词数组
                                  );
                                },
                                // 性能优化选项
                                addAutomaticKeepAlives: false,
                                addRepaintBoundaries: true,
                                clipBehavior: Clip.hardEdge,
                              ),
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
                    // 功能气泡区域 (仅在输入框聚焦时显示)
                    if (_isInputFocused)
                      FadeTransition(
                        opacity: _bubbleOpacityAnimation,
                        child: _isShowingPhrases
                            ? _buildPhrasesList() // 显示常用记录列表
                            : Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 8.h),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // 括号功能气泡
                                    _buildFunctionBubble(
                                      icon: null,
                                      label: '()',
                                      onTap: _insertBrackets,
                                    ),
                                    // 清空功能气泡
                                    _buildFunctionBubble(
                                      icon: Icon(Icons.backspace_outlined,
                                          color: Colors.white, size: 14.sp),
                                      label: '清空输入框',
                                      onTap: _clearInput,
                                    ),
                                    // 常用记录气泡
                                    _buildFunctionBubble(
                                      key: _commonPhrasesKey,
                                      icon: Icon(Icons.history,
                                          color: Colors.white, size: 14.sp),
                                      label: '快捷语',
                                      onTap: _showPhrasesList,
                                    ),
                                    // 添加常用记录气泡 - 只显示图标
                                    Container(
                                      margin: EdgeInsets.only(right: 8.w),
                                      child: Material(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: CircleBorder(),
                                        child: InkWell(
                                          onTap: _showAddPhraseDialog,
                                          customBorder: CircleBorder(),
                                          child: Padding(
                                            padding: EdgeInsets.all(8.w),
                                            child: Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 16.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                    // 输入框区域
                    Container(
                      padding: EdgeInsets.only(
                        left: 16.w,
                        right: 16.w,
                        top: 8.h,
                        bottom: padding.bottom + 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
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
                            alignment: Alignment.center,
                            child: GestureDetector(
                              onTap: _handleMenuToggle,
                              child: AnimatedIcon(
                                icon: AnimatedIcons.menu_close,
                                progress: _menuAnimationController,
                                color: Colors.white,
                                size: 24.sp,
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
                                color: Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(18.r),
                              ),
                              child: TextField(
                                controller: _messageController,
                                focusNode: _focusNode,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14.sp,
                                ),
                                maxLines: null,
                                decoration: InputDecoration(
                                  hintText: '发送消息...',
                                  hintStyle: TextStyle(
                                    color:
                                        AppTheme.textSecondary.withOpacity(0.6),
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
                          // 发送/终止按钮 (修改为灯泡图标)
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
                                        : null,
                                borderRadius: BorderRadius.circular(18.r),
                                child: Icon(
                                  _isSending
                                      ? Icons.stop_rounded
                                      : Icons.lightbulb,
                                  color: _isSending
                                      ? Colors.red.withOpacity(0.8)
                                      : _currentInputText.trim().isNotEmpty
                                          ? Colors.amber
                                          : Colors.white
                                              .withOpacity(0.4), // 输入为空时按钮变灰
                                  size: 24.sp,
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
                          color: Colors.black.withOpacity(0.05),
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
                              icon: Icons.archive,
                              label: '存档',
                              onTap: _navigateToChatArchive,
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
