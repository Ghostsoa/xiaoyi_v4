import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../services/file_service.dart';
import '../../../services/message_cache_service.dart';
import '../../../services/session_data_service.dart';
import '../../../theme/app_theme.dart';
import '../../../dao/chat_settings_dao.dart';
import '../../../dao/user_dao.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async'; // 添加Timer导入
import 'dart:math' as math; // 添加math导入
import '../services/character_chat_stream_service.dart';
import '../services/character_service.dart';
import '../models/sse_response.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_area.dart';
import 'character_panel_page.dart';
import 'chat_settings_page.dart';
import '../../../widgets/custom_toast.dart';
import '../../../widgets/confirmation_dialog.dart';
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
  final MessageCacheService _messageCacheService = MessageCacheService();
  final SessionDataService _sessionDataService = SessionDataService();
  final ChatSettingsDao _settingsDao = ChatSettingsDao();
  final UserDao _userDao = UserDao();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  // 添加行为日志上报定时器
  Timer? _durationReportTimer;

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

  // 选项预制内容管理
  final Map<String, Map<String, dynamic>> _optionsPresetContent = {}; // 存储选项组的预制内容

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
  bool _isResetting = false; // 添加重置状态
  String _currentInputText = ''; // 添加输入文本跟踪
  late AnimationController _menuAnimationController;
  late Animation<double> _menuHeightAnimation;

  // 消息列表
  final List<Map<String, dynamic>> _messages = [];

  // 分页信息
  int _currentPage = 1;
  int _totalPages = 1;
  int get _pageSize => _isLocalMode ? 100 : 20; // 本地模式使用更大的页面大小

  // 双模式相关
  bool _isLocalMode = false; // 是否为本地模式
  String? _activeArchiveId; // 当前激活的存档ID

  // 后台预加载相关
  final List<Map<String, dynamic>> _allLoadedMessages = []; // 所有已加载的消息
  bool _isBackgroundLoading = false; // 是否正在后台加载
  int _backgroundLoadedPages = 0; // 已后台加载的页数
  static const int _backgroundPageSize = 200; // 后台加载的页面大小（本地模式可以更大）

  // 搜索相关
  bool _isSearchMode = false; // 是否处于搜索模式
  String _searchKeyword = ''; // 当前搜索关键词
  List<Map<String, dynamic>> _searchResults = []; // 搜索结果
  final TextEditingController _searchController = TextEditingController();

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

  // 添加灵感相关变量
  final bool _isLoadingInspiration = false;
  final List<Map<String, dynamic>> _inspirationSuggestions = [];
  final bool _isShowingInspiration = false;
  late AnimationController _inspirationAnimationController;
  late Animation<double> _inspirationOpacityAnimation;

  // 🔥 添加"回到底部"按钮相关变量
  bool _showBackToBottomButton = false;
  late AnimationController _backToBottomAnimationController;
  late Animation<double> _backToBottomAnimation;

  // 初始化行为日志上报定时器
  void _startDurationReporting() {
    // 每10秒上报一次行为日志
    _durationReportTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _reportDialogDuration();
    });
  }

  // 上报对话持续时间
  void _reportDialogDuration() {
    try {
      // 获取角色ID和作者ID
      final int characterId =
          widget.characterData['character_id'] ?? widget.characterData['id'];
      final int authorId = widget.characterData['author_id'] ?? 0;

      // 调用服务上报
      _characterService.reportDialogDuration(characterId, authorId);
    } catch (e) {
      // 静默处理错误，不影响用户体验
      debugPrint('上报对话持续时间出错: $e');
    }
  }

  /// 检查并初始化模式（本地/在线）
  Future<void> _checkAndInitializeMode() async {
    try {
      await _sessionDataService.initDatabase();
      await _messageCacheService.initDatabase();

      debugPrint('[CharacterChatPage] 会话数据: ${widget.sessionData}');

      // 先从传入的会话数据检查
      _activeArchiveId = widget.sessionData['active_archive_id'] as String?;

      // 如果传入数据没有，从数据库获取最新的会话信息
      if (_activeArchiveId == null) {
        try {
          final sessionResponse = await _sessionDataService.getLocalCharacterSessions(
            page: 1,
            pageSize: 1000
          );

          final session = sessionResponse.sessions.firstWhere(
            (s) => s.id == widget.sessionData['id'],
            orElse: () => throw '会话不存在',
          );

          _activeArchiveId = session.activeArchiveId;
          debugPrint('[CharacterChatPage] 从数据库获取激活存档ID: $_activeArchiveId');
        } catch (e) {
          debugPrint('[CharacterChatPage] 从数据库获取会话信息失败: $e');
        }
      }

      debugPrint('[CharacterChatPage] 最终激活存档ID: $_activeArchiveId');

      if (_activeArchiveId != null && _activeArchiveId!.isNotEmpty) {
        // 检查是否有对应的缓存数据
        final hasCache = await _messageCacheService.hasArchiveCache(
          sessionId: widget.sessionData['id'],
          archiveId: _activeArchiveId!,
        );

        debugPrint('[CharacterChatPage] 存档 $_activeArchiveId 是否有缓存: $hasCache');

        if (hasCache) {
          _isLocalMode = true;
          debugPrint('[CharacterChatPage] ✅ 进入本地模式，存档ID: $_activeArchiveId');
          // 启动后台预加载
          _startBackgroundLoading();
        } else {
          _isLocalMode = false;
          debugPrint('[CharacterChatPage] ❌ 存档 $_activeArchiveId 无缓存，使用在线模式');
        }
      } else {
        _isLocalMode = false;
        debugPrint('[CharacterChatPage] ❌ 无激活存档，使用在线模式');
      }

      debugPrint('[CharacterChatPage] 最终模式: ${_isLocalMode ? "本地模式" : "在线模式"}');
    } catch (e) {
      debugPrint('[CharacterChatPage] 模式检查失败，默认使用在线模式: $e');
      _isLocalMode = false;
    }
  }

  @override
  void initState() {
    super.initState();
    // 先检查模式，再加载设置和其他内容
    _checkAndInitializeMode().then((_) {
      _loadSettings().then((_) {
        _loadBackgroundImage();
        _loadAvatarImage(); // 添加加载头像
        _loadMessageHistory();
        _loadFormatMode();
        _loadCommonPhrases(); // 加载常用记录
      });
    });

    // 静默检查版本
    _checkSessionVersion();

    // 初始化行为日志上报定时器
    _startDurationReporting();

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

    _menuHeightAnimation = Tween<double>(begin: 0, end: 80).animate(
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

    // 初始化灵感动画控制器
    _inspirationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _inspirationOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _inspirationAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // 🔥 初始化"回到底部"按钮动画控制器
    _backToBottomAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _backToBottomAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _backToBottomAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _inspirationAnimationController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // 统一滚动监听 - 合并分页加载和回到底部按钮逻辑
    _itemPositionsListener.itemPositions.addListener(_onScrollUnified);

    // 初始化刷新动画控制器
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // 添加输入监听
    _messageController.addListener(() {
      setState(() {
        _updateCurrentInputText();
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
    _searchController.dispose();
    _focusNode.dispose();
    _menuAnimationController.dispose();
    // ItemScrollController 不需要手动dispose
    _refreshAnimationController.dispose();
    _drawerAnimationController.dispose();
    _bubbleAnimationController.dispose();
    _inspirationAnimationController.dispose();
    _backToBottomAnimationController.dispose(); // 🔥 释放"回到底部"按钮动画控制器
    _phraseNameController.dispose();
    _phraseContentController.dispose();

    // 销毁行为日志上报定时器
    _durationReportTimer?.cancel();

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
      Map<String, dynamic> result;

      debugPrint('[CharacterChatPage] _loadMessageHistory - 当前模式: ${_isLocalMode ? "本地模式" : "在线模式"}');
      debugPrint('[CharacterChatPage] _loadMessageHistory - 激活存档ID: $_activeArchiveId');

      if (_isLocalMode && _activeArchiveId != null) {
        // 本地模式：直接从缓存加载，不请求API
        debugPrint('[CharacterChatPage] 🔄 从本地缓存加载消息 (page: $_currentPage)');
        result = await _messageCacheService.getArchiveMessages(
          sessionId: widget.sessionData['id'],
          archiveId: _activeArchiveId!,
          page: _currentPage,
          pageSize: _pageSize,
        );
      } else {
        // 在线模式：直接从API加载
        debugPrint('[CharacterChatPage] 🌐 从API加载消息 (page: $_currentPage)');
        result = await _characterService.getSessionMessages(
          widget.sessionData['id'],
          page: _currentPage,
          pageSize: _pageSize,
        );
      }

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



  // 统一滚动监听方法 - 处理分页加载和回到底部按钮
  void _onScrollUnified() {
    if (!mounted) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || _messages.isEmpty) return;

    try {
      // 获取所有可见位置的索引
      final visibleIndices = positions.map((pos) => pos.index).toList();

      // 验证索引范围
      final validIndices = visibleIndices.where((index) =>
        index >= 0 && index < _messages.length).toList();

      if (validIndices.isEmpty) return;

      // 1. 处理分页加载逻辑
      final maxIndex = validIndices.reduce((a, b) => a > b ? a : b);
      if (maxIndex >= _messages.length - 3 && // 提前3个item开始加载
          _currentPage < _totalPages &&
          !_isLoadingHistory) {
        _currentPage++;
        _loadMoreMessages();
      }

      // 2. 处理"回到底部"按钮显示逻辑
      // 检查是否在底部（索引0是最新消息，因为列表是反转的）
      final isAtBottom = validIndices.contains(0);

      // 如果不在底部且有足够的消息，显示"回到底部"按钮
      final shouldShow = !isAtBottom && _messages.length > 5;

      if (shouldShow != _showBackToBottomButton) {
        setState(() {
          _showBackToBottomButton = shouldShow;
        });

        if (shouldShow) {
          _backToBottomAnimationController.forward();
        } else {
          _backToBottomAnimationController.reverse();
        }
      }
    } catch (e) {
      debugPrint('滚动监听处理错误: $e');
      // 发生错误时重置按钮状态
      if (_showBackToBottomButton) {
        setState(() {
          _showBackToBottomButton = false;
        });
        _backToBottomAnimationController.reverse();
      }
    }
  }

  // 添加加载更多消息的方法
  Future<void> _loadMoreMessages() async {
    if (_isLoadingHistory) return;
    setState(() => _isLoadingHistory = true);

    try {
      Map<String, dynamic> result;

      if (_isLocalMode && _activeArchiveId != null) {
        // 本地模式：从缓存分页加载
        result = await _messageCacheService.getArchiveMessages(
          sessionId: widget.sessionData['id'],
          archiveId: _activeArchiveId!,
          page: _currentPage,
          pageSize: _pageSize,
        );
      } else {
        // 在线模式：从API分页加载
        result = await _characterService.getSessionMessages(
          widget.sessionData['id'],
          page: _currentPage,
          pageSize: _pageSize,
        );
      }

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
    // 使用 _currentInputText，它已经包含了合并的内容
    final message = _currentInputText.trim();
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

        // 清空所有预制内容，避免跨消息污染
        _optionsPresetContent.clear();
        _updateCurrentInputText();
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

      // 消息发送完成后，刷新消息列表以获取服务器分配的正确消息ID
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
          // 清空预制内容
          _optionsPresetContent.clear();
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

    debugPrint('开始执行刷新消息操作');
    setState(() => _isRefreshing = true);

    try {
      debugPrint(
          '调用API获取消息列表: sessionId=${widget.sessionData['id']}, page=1, pageSize=$_pageSize');
      final result = await _characterService.getSessionMessages(
        widget.sessionData['id'],
        page: 1,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      debugPrint('API返回消息列表成功');

      final List<dynamic> messageList = result['list'] ?? [];
      final pagination = result['pagination'] ?? {};

      debugPrint(
          '获取到消息数量: ${messageList.length}, 总页数: ${pagination['total_pages'] ?? 1}');

      // 如果是本地模式，同步更新缓存
      if (_isLocalMode && _activeArchiveId != null) {
        await _syncRefreshToCache(messageList);
      }

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
        debugPrint('更新UI: 清空旧消息列表，添加${newMessages.length}条新消息');
        _messages.clear();
        _messages.addAll(newMessages);
        _totalPages = pagination['total_pages'] ?? 1;
        _currentPage = 1;
      });

      // 滚动到底部
      _scrollToBottom();
      debugPrint('刷新消息完成');
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
        setState(() {
          _isRefreshing = false;
          debugPrint('重置刷新状态');
        });
      }
    }
  }

  // 添加重置会话的方法
  Future<void> _handleResetSession() async {
    // 显示确认对话框
    final bool? confirmed = await ConfirmationDialog.show(
      context: context,
      title: '确认重置',
      content: '确定要清空存档所有对话记录吗？此操作不可恢复。',
      confirmText: '确定',
      cancelText: '取消',
      isDangerous: true,
    );

    if (confirmed != true) return;

    try {
      // 设置重置状态，显示加载指示器
      setState(() => _isResetting = true);

      // 调用重置会话接口
      await _characterService.resetSession(widget.sessionData['id']);

      // 重置成功后，清理当前存档的本地缓存数据
      await _clearCurrentArchiveCacheAfterReset();

      if (mounted) {
        // 🔥 关键改进：先获取新数据，再一次性更新UI，避免闪烁
        Map<String, dynamic>? newData;
        try {
          debugPrint('[CharacterChatPage] 重置后立即获取新数据');
          newData = await _characterService.getSessionMessages(
            widget.sessionData['id'],
            page: 1,
            pageSize: _pageSize,
          );
          debugPrint('[CharacterChatPage] 重置后获取到 ${(newData['list'] as List?)?.length ?? 0} 条消息');
        } catch (e) {
          debugPrint('[CharacterChatPage] 获取重置后数据失败: $e');
        }

        // 重新检查模式状态
        await _checkAndInitializeMode();

        // 如果是本地模式且获取到新数据，同步写入缓存
        if (_isLocalMode && _activeArchiveId != null && newData != null) {
          try {
            await _syncRefreshToCache(newData['list'] ?? []);
            debugPrint('[CharacterChatPage] 重置后数据已同步到本地缓存');
          } catch (e) {
            debugPrint('[CharacterChatPage] 同步重置后数据到缓存失败: $e');
          }
        }

        // 原子性更新所有状态，避免中间空白期
        setState(() {
          _messages.clear();
          _currentPage = 1;
          _totalPages = 1;
          // 清理搜索相关状态
          _isSearchMode = false;
          _searchKeyword = '';
          _searchResults.clear();
          _allLoadedMessages.clear();
          _isBackgroundLoading = false;
          _backgroundLoadedPages = 0;

          // 如果成功获取到新数据，立即填充，避免空白状态
          if (newData != null) {
            final List<dynamic> messageList = newData['list'] ?? [];
            final pagination = newData['pagination'] ?? {};

            _messages.addAll(messageList.map((msg) => {
              'content': msg['content'] ?? '',
              'isUser': msg['role'] == 'user',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'tokenCount': msg['tokenCount'] ?? 0,
              'msgId': msg['msgId'],
              'status': 'done',
              'statusBar': msg['statusBar'],
              'enhanced': msg['enhanced'],
              'createdAt': msg['createdAt'],
              'keywords': msg['keywords'],
            }));

            _totalPages = pagination['total_pages'] ?? 1;
            debugPrint('[CharacterChatPage] UI已原子性更新，消息数量: ${_messages.length}');
          }
        });

        // 清空输入框
        _messageController.clear();

        // 🔥 无需延迟，立即滚动到底部，避免动画延迟
        _scrollToBottom(immediate: true);

        // 启动后台预加载（如果是本地模式）
        if (_isLocalMode && _activeArchiveId != null) {
          _startBackgroundLoading();
        }

        // 显示成功提示
        CustomToast.show(context, message: '对话已重置', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '重置失败: $e', type: ToastType.error);
      }
    } finally {
      // 重置完成，恢复按钮状态
      if (mounted) {
        setState(() => _isResetting = false);
      }
    }
  }

  /// 显示搜索对话框
  /// 切换搜索模式
  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (_isSearchMode) {
        // 进入搜索模式，清空输入框
        _messageController.clear();
        _searchKeyword = '';
        _searchResults.clear();
      } else {
        // 退出搜索模式，清空搜索结果
        _messageController.clear();
        _searchKeyword = '';
        _searchResults.clear();
      }
    });
  }

  /// 执行内联搜索
  void _performInlineSearch(String keyword) {
    if (!_isLocalMode || keyword.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _searchKeyword = keyword.trim();

      // 在内存中搜索已加载的消息
      _searchResults = _allLoadedMessages.where((message) {
        final content = message['content'] as String? ?? '';
        return content.toLowerCase().contains(_searchKeyword.toLowerCase());
      }).toList();
    });
  }

  /// 跳转到搜索结果消息
  void _jumpToSearchResult(String msgId) {
    // 退出搜索模式并清空输入框
    setState(() {
      _isSearchMode = false;
      _messageController.clear(); // 清空主输入框
      _searchKeyword = '';
      _searchResults.clear();
    });

    // 跳转到目标消息
    _jumpToMessage(msgId);

    // 🔥 搜索跳转后显示"回到底部"按钮（延迟一下确保跳转完成）
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showBackToBottomButton = true;
        });
        _backToBottomAnimationController.forward();
      }
    });
  }

  /// 🔥 格式化搜索结果的时间戳（+8小时时差）
  String _formatSearchResultTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) {
      return '';
    }

    try {
      // 解析服务器时间（UTC）
      DateTime serverTime = DateTime.parse(createdAt);
      // 添加8小时时差
      DateTime localTime = serverTime.add(Duration(hours: 8));

      // 格式化为 MM-dd HH:mm
      String month = localTime.month.toString().padLeft(2, '0');
      String day = localTime.day.toString().padLeft(2, '0');
      String hour = localTime.hour.toString().padLeft(2, '0');
      String minute = localTime.minute.toString().padLeft(2, '0');

      return '$month-$day $hour:$minute';
    } catch (e) {
      debugPrint('时间格式化失败: $e');
      return '';
    }
  }

  /// 解析角色名称，分离调试版前缀
  Map<String, String> _parseCharacterName(String characterName) {
    if (characterName.startsWith('(调试版)')) {
      return {
        'prefix': '(调试版)',
        'name': characterName.substring(5).trim(),
      };
    }
    return {
      'prefix': '',
      'name': characterName,
    };
  }

  /// 构建调试版标签
  Widget _buildDebugTag() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppTheme.buttonGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: const GradientRotation(0.4),
        ),
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.buttonGradient.first.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '调试版',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }



  /// 构建搜索结果界面（模仿灵感功能样式）
  Widget _buildSearchInterface() {
    if (_searchResults.isEmpty && _searchKeyword.isEmpty) {
      return SizedBox.shrink();
    }

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
              Icon(
                Icons.search,
                color: AppTheme.primaryColor,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                '搜索结果 (${_searchResults.length})',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              // 关闭按钮
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleSearchMode,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // 搜索结果列表
          if (_searchResults.isNotEmpty)
            _buildSearchResults()
          else if (_searchKeyword.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Center(
                child: Text(
                  '未找到相关消息',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建搜索结果列表（模仿灵感列表样式）
  Widget _buildSearchResults() {
    return Container(
      constraints: BoxConstraints(maxHeight: 200.h),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          final content = result['content'] as String? ?? '';
          final isUser = result['isUser'] as bool? ?? false;
          final msgId = result['msgId'] as String? ?? '';
          final createdAt = result['createdAt'] as String? ?? ''; // 🔥 获取创建时间

          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isUser
                    ? AppTheme.primaryColor.withOpacity(0.6) // 用户消息用主题色边框
                    : Colors.grey.withOpacity(0.6), // AI消息用灰色边框
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () => _jumpToSearchResult(msgId),
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部信息行：消息类型标签 + 时间戳
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 消息类型标签
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppTheme.primaryColor.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            isUser ? '用户' : '模型',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // 🔥 时间戳显示
                        if (createdAt.isNotEmpty)
                          Text(
                            _formatSearchResultTime(createdAt),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    // 消息内容
                    Text(
                      content,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        height: 1.4,
                        fontWeight: FontWeight.normal,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  



  /// 跳转到指定消息（优先使用后台预加载数据）
  Future<void> _jumpToMessage(String msgId) async {
    try {
      // 先在当前显示的消息列表中查找
      final currentIndex = _messages.indexWhere((msg) => msg['msgId'] == msgId);

      if (currentIndex != -1) {
        // 消息在当前页面，瞬间跳转到位置
        _itemScrollController.jumpTo(index: currentIndex);
        CustomToast.show(context, message: '已定位到消息', type: ToastType.success);
        return;
      }

      // 如果有后台预加载的数据，优先使用快速定位
      if (_allLoadedMessages.isNotEmpty) {
        await _fastJumpUsingPreloadedData(msgId);
      } else {
        // 没有预加载数据，使用传统的逐页加载方式
        await _loadUntilMessageFound(msgId);
      }

    } catch (e) {
      debugPrint('[CharacterChatPage] 跳转到消息失败: $e');
      CustomToast.show(context, message: '定位消息失败', type: ToastType.error);
    }
  }

  /// 使用预加载数据快速跳转
  Future<void> _fastJumpUsingPreloadedData(String msgId) async {
    try {
      // 在预加载的数据中查找目标消息
      final targetIndex = _allLoadedMessages.indexWhere((msg) => msg['msgId'] == msgId);

      if (targetIndex == -1) {
        // 预加载数据中没有找到，可能还没加载到，使用传统方式
        await _loadUntilMessageFound(msgId);
        return;
      }

      // 找到目标消息，计算需要加载到第几页
      final targetPage = (targetIndex ~/ _pageSize) + 1;

      debugPrint('[CharacterChatPage] 🚀 快速定位：目标消息在第 $targetPage 页，索引 $targetIndex');

      // 直接加载到目标页面
      _currentPage = targetPage;
      await _loadMessageHistory();

      // 等待UI更新
      await Future.delayed(Duration(milliseconds: 100));

      // 在新加载的页面中找到目标消息并瞬间跳转
      final newIndex = _messages.indexWhere((msg) => msg['msgId'] == msgId);
      if (newIndex != -1) {
        _itemScrollController.jumpTo(index: newIndex);
        CustomToast.show(context, message: '已定位到消息', type: ToastType.success);
      } else {
        CustomToast.show(context, message: '定位失败，请重试', type: ToastType.warning);
      }
    } catch (e) {
      debugPrint('[CharacterChatPage] 快速定位失败: $e');
      // 快速定位失败，回退到传统方式
      await _loadUntilMessageFound(msgId);
    }
  }

  /// 加载页面直到找到目标消息
  Future<void> _loadUntilMessageFound(String msgId) async {
    if (!_isLocalMode || _activeArchiveId == null) {
      CustomToast.show(context, message: '只有本地模式才能跨页定位', type: ToastType.warning);
      return;
    }

    try {
      // 显示加载提示
      bool isLoading = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16.h),
              Text('正在查找消息...'),
            ],
          ),
        ),
      );

      // 重置到第一页并开始加载
      _currentPage = 1;
      await _loadMessageHistory();

      // 检查消息是否在当前页
      int targetIndex = _messages.indexWhere((msg) => msg['msgId'] == msgId);

      // 如果不在当前页，继续加载更多页面
      while (targetIndex == -1 && _currentPage < _totalPages) {
        _currentPage++;
        await _loadMoreMessages();
        targetIndex = _messages.indexWhere((msg) => msg['msgId'] == msgId);
      }

      // 关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (targetIndex != -1) {
        // 找到消息，瞬间跳转到位置
        await Future.delayed(Duration(milliseconds: 100));
        _itemScrollController.jumpTo(index: targetIndex);
        CustomToast.show(context, message: '已定位到消息', type: ToastType.success);
      } else {
        CustomToast.show(context, message: '未找到该消息', type: ToastType.warning);
      }
    } catch (e) {
      // 确保关闭加载对话框
      if (mounted) {
        Navigator.of(context).pop();
      }
      debugPrint('[CharacterChatPage] 跨页定位失败: $e');
      CustomToast.show(context, message: '定位失败: $e', type: ToastType.error);
    }
  }



  /// 启动后台预加载
  Future<void> _startBackgroundLoading() async {
    if (!_isLocalMode || _activeArchiveId == null || _isBackgroundLoading) return;

    debugPrint('[CharacterChatPage] 🚀 启动后台预加载');
    _isBackgroundLoading = true;
    _backgroundLoadedPages = 0;
    _allLoadedMessages.clear();

    // 延迟500ms后开始，本地模式可以更快
    Future.delayed(Duration(milliseconds: 500), () {
      _backgroundLoadMessages();
    });
  }

  /// 后台加载消息
  Future<void> _backgroundLoadMessages() async {
    try {
      int currentPage = 1;
      bool hasMorePages = true;

      while (hasMorePages && _isLocalMode && _activeArchiveId != null) {
        debugPrint('[CharacterChatPage] 📥 后台加载第 $currentPage 页');

        final result = await _messageCacheService.getArchiveMessages(
          sessionId: widget.sessionData['id'],
          archiveId: _activeArchiveId!,
          page: currentPage,
          pageSize: _backgroundPageSize,
        );

        final List<dynamic> messageList = result['list'] ?? [];
        final pagination = result['pagination'] ?? {};

        if (messageList.isEmpty) {
          hasMorePages = false;
          break;
        }

        // 转换消息格式并添加到全量列表
        final convertedMessages = messageList.map((msg) => {
          'content': msg['content'] ?? '',
          'isUser': msg['role'] == 'user',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'tokenCount': msg['tokenCount'] ?? 0,
          'msgId': msg['msgId'] ?? msg['msg_id'] ?? '',
          'status': 'done',
          'statusBar': msg['statusBar'],
          'enhanced': msg['enhanced'] is int ? (msg['enhanced'] == 1) : msg['enhanced'],
          'createdAt': msg['createdAt'] ?? msg['created_at'] ?? '',
          'keywords': msg['keywords'],
        }).toList();

        _allLoadedMessages.addAll(convertedMessages);
        _backgroundLoadedPages = currentPage;

        debugPrint('[CharacterChatPage] 📥 已加载 ${_allLoadedMessages.length} 条消息');

        // 检查是否还有更多页面
        final totalPages = pagination['total_pages'] ?? 1;
        hasMorePages = currentPage < totalPages;
        currentPage++;

        // 添加小延迟，本地模式可以更快
        await Future.delayed(Duration(milliseconds: 50));
      }

      debugPrint('[CharacterChatPage] ✅ 后台预加载完成，共加载 ${_allLoadedMessages.length} 条消息');
    } catch (e) {
      debugPrint('[CharacterChatPage] ❌ 后台预加载失败: $e');
    } finally {
      _isBackgroundLoading = false;
    }
  }

  /// 重置后清理当前存档的本地缓存
  Future<void> _clearCurrentArchiveCacheAfterReset() async {
    // 只有在本地模式且有激活存档时才清理缓存
    if (_isLocalMode && _activeArchiveId != null && _activeArchiveId!.isNotEmpty) {
      try {
        await _messageCacheService.initDatabase();

        // 清理当前激活存档的缓存数据
        await _messageCacheService.clearArchiveCache(
          sessionId: widget.sessionData['id'],
          archiveId: _activeArchiveId!,
        );

        debugPrint('[CharacterChatPage] ✅ 重置后已清理当前存档的本地缓存: $_activeArchiveId');
      } catch (e) {
        debugPrint('[CharacterChatPage] ❌ 重置后清理本地缓存失败: $e');
      }
    } else {
      debugPrint('[CharacterChatPage] 非本地模式或无激活存档，跳过缓存清理');
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

      // 如果是本地模式，同步更新缓存
      if (_isLocalMode && _activeArchiveId != null) {
        await _syncMessageUpdateToCache(msgId, newContent);
      }
    } catch (e) {
      debugPrint('更新消息失败: $e');
      if (mounted) {
        CustomToast.show(context, message: e.toString(), type: ToastType.error);
      }
    }
  }

  /// 同步消息更新到缓存
  Future<void> _syncMessageUpdateToCache(String msgId, String newContent) async {
    try {
      // 找到对应的消息数据
      final messageIndex = _messages.indexWhere((msg) => msg['msgId'] == msgId);
      if (messageIndex == -1) return;

      final message = _messages[messageIndex];

      // 更新缓存
      await _messageCacheService.updateMessage(
        sessionId: widget.sessionData['id'],
        archiveId: _activeArchiveId!,
        msgId: msgId,
        messageData: {
          'content': newContent,
          'tokenCount': message['tokenCount'] ?? 0,
          'statusBar': message['statusBar'],
          'enhanced': message['enhanced'],
          'keywords': message['keywords'],
        },
      );

      debugPrint('[CharacterChatPage] 已同步消息更新到缓存: $msgId');
    } catch (e) {
      debugPrint('[CharacterChatPage] 同步消息更新到缓存失败: $e');
    }
  }

  /// 同步刷新操作到缓存（处理删除/撤销等操作）
  Future<void> _syncRefreshToCache(List<dynamic> messageList) async {
    try {
      // 转换消息格式
      final messages = messageList.map((msg) => {
        'msgId': msg['msgId'],
        'content': msg['content'] ?? '',
        'role': msg['role'],
        'createdAt': msg['createdAt'],
        'tokenCount': msg['tokenCount'] ?? 0,
        'statusBar': msg['statusBar'],
        'enhanced': msg['enhanced'],
        'keywords': msg['keywords'],
      }).toList();

      // 更新缓存（这会覆盖现有数据，实现删除/撤销的同步）
      await _messageCacheService.insertOrUpdateMessages(
        sessionId: widget.sessionData['id'],
        archiveId: _activeArchiveId!,
        messages: messages,
      );

      debugPrint('[CharacterChatPage] 已同步刷新操作到缓存: ${messages.length} 条消息');
    } catch (e) {
      debugPrint('[CharacterChatPage] 同步刷新操作到缓存失败: $e');
    }
  }

  /// 处理消息删除（包含幽灵消息处理和正常删除后的UI刷新）
  Future<void> _handleMessageDeleted(String? msgId) async {
    debugPrint('[CharacterChatPage] 处理消息删除，msgId: $msgId, 模式: ${_isLocalMode ? "本地" : "在线"}');

    if (_isLocalMode && _activeArchiveId != null && msgId != null) {
      // 本地模式：处理幽灵消息，删除本地缓存并重新加载
      await _handleGhostMessage(msgId, '删除');
    } else {
      // 在线模式：删除成功后刷新消息列表以更新UI缓存
      debugPrint('[CharacterChatPage] 在线模式删除成功，刷新消息列表');
      await _refreshMessages();
    }
  }

  /// 处理消息撤销（包含幽灵消息处理和正常撤销后的UI刷新）
  Future<void> _handleMessageRevoked(String? msgId) async {
    debugPrint('[CharacterChatPage] 处理消息撤销，msgId: $msgId, 模式: ${_isLocalMode ? "本地" : "在线"}');

    // 先找到要撤销的消息，如果是用户消息则将内容放回输入框
    await _restoreRevokedMessageToInput(msgId);

    if (_isLocalMode && _activeArchiveId != null && msgId != null) {
      // 本地模式：处理幽灵消息，删除本地缓存并重新加载
      await _handleGhostMessageRevoke(msgId);
    } else {
      // 在线模式：撤销成功后刷新消息列表以更新UI缓存
      debugPrint('[CharacterChatPage] 在线模式撤销成功，刷新消息列表');
      await _refreshMessages();
    }
  }

  /// 将撤销的用户消息内容恢复到输入框
  Future<void> _restoreRevokedMessageToInput(String? msgId) async {
    if (msgId == null) return;

    try {
      // 在当前消息列表中查找要撤销的消息
      final messageIndex = _messages.indexWhere((msg) => msg['msgId'] == msgId);
      if (messageIndex == -1) {
        debugPrint('[CharacterChatPage] 未找到要撤销的消息: $msgId');
        return;
      }

      final targetMessage = _messages[messageIndex];

      // 撤销操作会删除该消息及之后的所有消息
      // 我们需要找到被撤销的消息中最后一条用户消息
      String? lastUserMessageContent;

      // 从目标消息开始，向前查找（因为列表是倒序的，索引小的是更新的消息）
      for (int i = messageIndex; i >= 0; i--) {
        final message = _messages[i];
        if (message['isUser'] == true) {
          lastUserMessageContent = message['content'] as String?;
          break; // 找到最后一条用户消息就停止
        }
      }

      // 如果找到了用户消息，将其内容放回输入框
      if (lastUserMessageContent != null && lastUserMessageContent.isNotEmpty) {
        setState(() {
          _messageController.text = lastUserMessageContent!;
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: _messageController.text.length),
          );
        });
        debugPrint('[CharacterChatPage] 已将撤销的用户消息恢复到输入框: ${lastUserMessageContent.substring(0, math.min(50, lastUserMessageContent.length))}...');
      }
    } catch (e) {
      debugPrint('[CharacterChatPage] 恢复撤销消息到输入框失败: $e');
    }
  }

  /// 处理幽灵消息（删除失败但本地有缓存）
  Future<void> _handleGhostMessage(String msgId, String operation) async {
    try {
      debugPrint('[CharacterChatPage] 开始处理幽灵消息：sessionId=${widget.sessionData['id']}, archiveId=$_activeArchiveId, msgId=$msgId');

      await _messageCacheService.deleteMessage(
        sessionId: widget.sessionData['id'],
        archiveId: _activeArchiveId!,
        msgId: msgId,
      );

      debugPrint('[CharacterChatPage] ✅ 幽灵消息处理：已从本地缓存$operation消息 $msgId');

      // 重新加载本地缓存数据
      debugPrint('[CharacterChatPage] 重新加载本地缓存数据...');
      await _loadMessageHistory();
      debugPrint('[CharacterChatPage] 本地缓存数据重新加载完成');
    } catch (e) {
      debugPrint('[CharacterChatPage] ❌ 处理幽灵消息失败: $e');
    }
  }

  /// 处理幽灵消息撤销（删除该消息及之后的所有消息）
  Future<void> _handleGhostMessageRevoke(String msgId) async {
    try {
      debugPrint('[CharacterChatPage] 开始处理幽灵消息撤销：sessionId=${widget.sessionData['id']}, archiveId=$_activeArchiveId, msgId=$msgId');

      // 找到要撤销的消息在列表中的位置
      final messageIndex = _messages.indexWhere((msg) => msg['msgId'] == msgId);
      if (messageIndex == -1) {
        debugPrint('[CharacterChatPage] 未找到要撤销的消息: $msgId');
        return;
      }

      // 获取该消息的创建时间
      final targetMessage = _messages[messageIndex];
      final targetCreatedAt = targetMessage['createdAt'];

      if (targetCreatedAt == null) {
        debugPrint('[CharacterChatPage] 消息缺少创建时间，无法确定撤销范围');
        return;
      }

      debugPrint('[CharacterChatPage] 找到目标消息，创建时间: $targetCreatedAt');

      // 删除该消息及之后的所有消息（包括该消息本身）
      await _messageCacheService.deleteMessagesFromTime(
        sessionId: widget.sessionData['id'],
        archiveId: _activeArchiveId!,
        fromTime: targetCreatedAt,
      );

      debugPrint('[CharacterChatPage] ✅ 幽灵消息撤销：已从本地缓存删除消息 $msgId 及之后的所有消息');

      // 重新加载本地缓存数据
      debugPrint('[CharacterChatPage] 重新加载本地缓存数据...');
      await _loadMessageHistory();
      debugPrint('[CharacterChatPage] 本地缓存数据重新加载完成');
    } catch (e) {
      debugPrint('[CharacterChatPage] ❌ 处理幽灵消息撤销失败: $e');
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

    // 显示确认对话框，带有"今后不再提醒"选项
    final bool? confirmed = await ConfirmationDialog.show(
      context: context,
      title: '重新生成',
      content: '确定要重新生成这条消息吗？当前内容将被覆盖，此操作不可恢复。',
      confirmText: '重新生成',
      cancelText: '取消',
      isDangerous: true,
      showRememberOption: true,
      rememberKey: 'regenerate_message',
    );

    if (confirmed != true) return; // 用户取消了操作

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


  // 改进的滚动到底部方法，添加边界检查和错误处理
  void _scrollToBottom({bool immediate = false}) {
    if (!mounted || _messages.isEmpty) return;

    try {
      // 确保索引在有效范围内
      if (_messages.isNotEmpty) {
        if (immediate) {
          // 立即跳转，无动画，用于重置等需要快速响应的场景
          _itemScrollController.jumpTo(index: 0);
        } else {
          // 使用更快的动画，提供更流畅的体验
          _itemScrollController.scrollTo(
            index: 0,
            duration: Duration(milliseconds: 150), // 从300ms减少到150ms
            curve: Curves.easeOutCubic, // 更自然的缓动曲线
          );
        }

        // 滚动后隐藏"回到底部"按钮
        if (_showBackToBottomButton) {
          setState(() {
            _showBackToBottomButton = false;
          });
          _backToBottomAnimationController.reverse();
        }
      }
    } catch (e) {
      debugPrint('滚动到底部失败: $e');
      // 发生错误时也要隐藏按钮
      if (_showBackToBottomButton) {
        setState(() {
          _showBackToBottomButton = false;
        });
        _backToBottomAnimationController.reverse();
      }
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
    debugPrint(
        '版本更新按钮点击: hasNewVersion=$_hasNewVersion, isUpdating=$_isUpdatingVersion');

    if (_isUpdatingVersion) return; // 只检查正在更新状态

    // 显示确认对话框
    final bool? confirmed = await ConfirmationDialog.show(
      context: context,
      title: '同步最新版本',
      content: '确定要同步到最新版本吗？同步后可能会影响当前的对话状态。',
      confirmText: '同步',
      cancelText: '取消',
      isDangerous: false,
    );

    if (confirmed != true) return; // 用户取消了操作

    setState(() {
      _isUpdatingVersion = true;
    });

    try {
      debugPrint('开始调用更新版本API');
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

  

  // 更新当前输入文本（合并用户输入和预制内容）
  void _updateCurrentInputText() {
    String userInput = _messageController.text;
    String presetContent = _getFormattedPresetContent();

    if (presetContent.isNotEmpty) {
      _currentInputText = userInput.isNotEmpty
          ? '$userInput $presetContent'
          : presetContent;
    } else {
      _currentInputText = userInput;
    }
  }

  // 处理选项变化的回调
  void _onOptionsChanged(String groupId, String title, List<String> selectedOptions) {
    setState(() {
      if (selectedOptions.isEmpty) {
        // 如果没有选中的选项，移除这个组的预制内容
        _optionsPresetContent.remove(groupId);
        debugPrint('移除空选项组: $groupId');
      } else {
        // 更新这个组的预制内容
        _optionsPresetContent[groupId] = {
          'title': title,
          'selectedOptions': selectedOptions,
        };
        debugPrint('更新选项组: $groupId -> $title: ${selectedOptions.join(", ")}');
      }

      // 智能更新当前输入文本
      _updateCurrentInputText();
    });

    // 调试输出
    debugPrint('=== 选项变化调试 ===');
    debugPrint('组ID: $groupId');
    debugPrint('标题: $title');
    debugPrint('选中选项: ${selectedOptions.join(", ")}');
    debugPrint('当前预制内容组数量: ${_optionsPresetContent.length}');
    debugPrint('预制内容组详情: $_optionsPresetContent');
    debugPrint('格式化预制内容: "${_getFormattedPresetContent()}"');
    debugPrint('最终输入文本: "$_currentInputText"');
    debugPrint('==================');
  }

  // 获取格式化的预制内容
  String _getFormattedPresetContent() {
    if (_optionsPresetContent.isEmpty) return '';

    List<String> formattedParts = [];

    // 创建一个临时的清理后的Map，移除空选项组
    Map<String, Map<String, dynamic>> cleanedContent = {};

    _optionsPresetContent.forEach((groupId, data) {
      String title = data['title'];
      List<String> options = List<String>.from(data['selectedOptions'] ?? []);

      // 只保留有选项的组
      if (options.isNotEmpty) {
        cleanedContent[groupId] = data;
        formattedParts.add('$title：${options.join("、")}');
      }
    });

    // 如果发现有空组，清理掉它们
    if (cleanedContent.length != _optionsPresetContent.length) {
      debugPrint('发现并清理空选项组，原有${_optionsPresetContent.length}个，清理后${cleanedContent.length}个');
      _optionsPresetContent.clear();
      _optionsPresetContent.addAll(cleanedContent);
    }

    return formattedParts.join(' ');
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


  // 添加跳转到存档页面的方法
  void _navigateToChatArchive() async {
    final bool? needRefresh = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatArchivePage(
          sessionId: widget.sessionData['id'].toString(),
          backgroundOpacity: _backgroundOpacity,
        ),
      ),
    );

    // 如果返回值为true，表示激活存档发生变化，需要重新检查模式并刷新消息
    if (needRefresh == true && mounted) {
      debugPrint('[CharacterChatPage] 存档页面返回，激活存档发生变化，重新加载');
      await _recheckModeAfterArchiveChange();
      _refreshMessages();
    }
  }

  /// 存档切换后重新检查模式
  Future<void> _recheckModeAfterArchiveChange() async {
    try {
      // 重新获取会话数据，检查最新的激活存档ID
      final sessionResponse = await _sessionDataService.getLocalCharacterSessions(
        page: 1,
        pageSize: 1000
      );

      final session = sessionResponse.sessions.firstWhere(
        (s) => s.id == widget.sessionData['id'],
        orElse: () => throw '会话不存在',
      );

      // 更新本地的激活存档ID
      _activeArchiveId = session.activeArchiveId;

      if (_activeArchiveId != null && _activeArchiveId!.isNotEmpty) {
        // 检查是否有对应的缓存数据
        final hasCache = await _messageCacheService.hasArchiveCache(
          sessionId: widget.sessionData['id'],
          archiveId: _activeArchiveId!,
        );

        if (hasCache) {
          _isLocalMode = true;
          debugPrint('[CharacterChatPage] 切换到本地模式，存档ID: $_activeArchiveId');
          // 🔥 关键修复：启动后台预加载，确保搜索功能可用
          _startBackgroundLoading();
        } else {
          _isLocalMode = false;
          debugPrint('[CharacterChatPage] 存档 $_activeArchiveId 无缓存，使用在线模式');
        }
      } else {
        _isLocalMode = false;
        _activeArchiveId = null;
        debugPrint('[CharacterChatPage] 无激活存档，切换到在线模式');
      }
    } catch (e) {
      debugPrint('[CharacterChatPage] 重新检查模式失败: $e');
      _isLocalMode = false;
      _activeArchiveId = null;
    }
  }

  /// 清理JSON字符串，去除可能的markdown包裹
  String _cleanJsonString(String jsonString) {
    // 去除前后空白
    String cleaned = jsonString.trim();

    // 去除markdown代码块包裹
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7); // 去除 ```json
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3); // 去除 ```
    }

    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3); // 去除结尾的 ```
    }

    // 再次去除前后空白
    return cleaned.trim();
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
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Builder(
                                          builder: (context) {
                                            final characterName = widget.characterData['name'] ?? '对话';
                                            final parsedName = _parseCharacterName(characterName);
                                            final bool isDebugVersion = parsedName['prefix']!.isNotEmpty;
                                            final String displayName = parsedName['name']!;

                                            return Text(
                                              displayName,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                      ),
                                      // 🔥 调试版标签
                                      Builder(
                                        builder: (context) {
                                          final characterName = widget.characterData['name'] ?? '对话';
                                          final parsedName = _parseCharacterName(characterName);
                                          final bool isDebugVersion = parsedName['prefix']!.isNotEmpty;

                                          if (isDebugVersion) {
                                            return Row(
                                              children: [
                                                SizedBox(width: 6.w),
                                                _buildDebugTag(),
                                              ],
                                            );
                                          }
                                          return SizedBox.shrink();
                                        },
                                      ),
                                    ],
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
                      GestureDetector(
                        onTap: () {
                          debugPrint('版本更新按钮被点击');
                          if (!_isUpdatingVersion) {
                            _handleVersionUpdate();
                          }
                        },
                        child: Container(
                          width: 44.w,
                          height: 44.w,
                          color: Colors.transparent,
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

                    // 刷新按钮
                    GestureDetector(
                      onTap: () async {
                        debugPrint('刷新按钮被点击');
                        if (_isRefreshing) {
                          debugPrint('已经在刷新中，忽略点击');
                          return;
                        }

                        try {
                          setState(() => _isRefreshing = true);
                          debugPrint('设置刷新状态为true');

                          // 直接调用API，而不是通过_refreshMessages方法
                          debugPrint('直接调用API获取消息列表');
                          final result =
                              await _characterService.getSessionMessages(
                            widget.sessionData['id'],
                            page: 1,
                            pageSize: _pageSize,
                          );

                          debugPrint('API返回结果成功');
                          if (!mounted) return;

                          final List<dynamic> messageList =
                              result['list'] ?? [];
                          final pagination = result['pagination'] ?? {};

                          debugPrint('获取到消息数量: ${messageList.length}');

                          final newMessages = messageList
                              .map(
                                (msg) => {
                                  'content': msg['content'] ?? '',
                                  'isUser': msg['role'] == 'user',
                                  'timestamp':
                                      DateTime.now().millisecondsSinceEpoch,
                                  'tokenCount': msg['tokenCount'] ?? 0,
                                  'msgId': msg['msgId'],
                                  'status': 'done',
                                  'statusBar': msg['statusBar'],
                                  'enhanced': msg['enhanced'],
                                  'createdAt': msg['createdAt'],
                                  'keywords': msg['keywords'],
                                },
                              )
                              .toList();

                          if (mounted) {
                            setState(() {
                              debugPrint(
                                  '更新UI: 清空旧消息，添加${newMessages.length}条新消息');
                              _messages.clear();
                              _messages.addAll(newMessages);
                              _totalPages = pagination['total_pages'] ?? 1;
                              _currentPage = 1;
                            });

                            // 滚动到底部
                            _scrollToBottom();
                            CustomToast.show(context,
                                message: '刷新成功', type: ToastType.success);
                          }
                        } catch (e) {
                          debugPrint('刷新消息失败: $e');
                          if (mounted) {
                            CustomToast.show(context,
                                message: '刷新失败: $e', type: ToastType.error);
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isRefreshing = false;
                              debugPrint('重置刷新状态为false');
                            });
                          }
                        }
                      },
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
                                      Colors.white),
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
                            child: ScrollablePositionedList.builder(
                              reverse: true, // 反转列表,新消息在底部
                              itemScrollController: _itemScrollController,
                              itemPositionsListener: _itemPositionsListener,
                              padding: EdgeInsets.only(
                                top: 16.h,
                                bottom: 16.h,
                              ),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                // 添加边界检查，防止重置时的索引错误
                                if (index < 0 || index >= _messages.length) {
                                  return SizedBox.shrink();
                                }
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
                                  onEdit: _handleMessageEdit,
                                  formatMode: _formatMode,
                                  statusBar: message['statusBar'],
                                  enhance: message['enhanced'],
                                  fontSize: _fontSize, // 传递字体大小设置
                                  sessionId: widget.sessionData['id'], // 添加会话ID
                                  onMessageDeleted: () {
                                    // 消息删除成功后刷新消息列表
                                    _handleMessageDeleted(message['msgId']);
                                  },
                                  onMessageRevoked: () {
                                    // 消息撤销成功后刷新消息列表
                                    _handleMessageRevoked(message['msgId']);
                                  },
                                  onMessageRegenerate: !message['isUser']
                                      ? _handleRegenerateMessage
                                      : null, // 只对AI消息添加重新生成功能
                                  onOptionsChanged: _onOptionsChanged, // 传递选项变化回调
                                  createdAt: message['createdAt'], // 添加创建时间
                                  keywords: message['keywords'], // 传递关键词数组
                                  resourceMapping: widget.sessionData['resourceMapping'] ?? widget.sessionData['resource_mapping'],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 底部交互区域（整体）- 包含输入框和功能区
              Container(
                padding: EdgeInsets.only(
                    bottom: viewInsets.bottom > 0
                        ? viewInsets.bottom
                        : padding.bottom),
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
                    // 新的输入区域组件（包含功能气泡、输入框、展开功能区，并统一“快捷语/灵感/搜索”展示面板）
                    ChatInputArea(
                      messageController: _messageController,
                      focusNode: _focusNode,
                      isLocalMode: _isLocalMode,
                      isSending: _isSending,
                      isResetting: _isResetting,
                      isSearchMode: _isSearchMode,
                      currentInputText: _currentInputText,
                      searchResults: _searchResults,
                      onTapSearchResult: _jumpToSearchResult,
                      onMenuToggle: _handleMenuToggle,
                      onSendTap: _handleSendMessage,
                      onStopGenerationTap: _handleStopGeneration,
                      onToggleSearchMode: _toggleSearchMode,
                      onInlineSearch: _performInlineSearch,
                      onOpenCharacterPanel: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CharacterPanelPage(
                              characterData: widget.sessionData,
                            ),
                          ),
                        );
                      },
                      onOpenChatSettings: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatSettingsPage(
                              sessionData: widget.sessionData,
                              backgroundOpacity: _backgroundOpacity,
                              onSettingsChanged: () {
                                _loadSettings();
                              },
                            ),
                          ),
                        );
                      },
                      onOpenUiSettings: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UiSettingsPage(
                              backgroundOpacity: _backgroundOpacity,
                              onSettingsChanged: () {
                                _loadFormatMode();
                                setState(() {});
                              },
                            ),
                          ),
                        );
                      },
                      onResetSession: _handleResetSession,
                      onOpenArchive: _navigateToChatArchive,
                      fetchInspirationSuggestions: () async {
                        final result = await _characterService.getInspirationSuggestions(
                          widget.sessionData['id'],
                        );
                        final inspirationJson = result['inspiration'];
                        if (inspirationJson is String) {
                          try {
                            final cleaned = _cleanJsonString(inspirationJson);
                            final data = jsonDecode(cleaned);
                            final suggestions = (data['suggestions'] as List<dynamic>?)
                                    ?.map((e) => (e['content'] ?? '').toString().trim())
                                    .where((s) => s.isNotEmpty)
                                    .toList() ??
                                <String>[];
                            return suggestions;
                          } catch (_) {
                            return <String>[];
                          }
                        }
                        return <String>[];
                      },
                      fetchMemories: ({String? cursor, int limit = 20}) async {
                        final data = await _characterService.getMemories(
                          widget.sessionData['id'],
                          cursor: cursor,
                          limit: limit,
                        );
                        return data;
                      },
                      createMemory: ({required String saveSlotId, required String title, required String content}) async {
                        await _characterService.createMemory(
                          widget.sessionData['id'],
                          saveSlotId: saveSlotId,
                          title: title,
                          content: content,
                        );
                      },
                      updateMemory: ({required String saveSlotId, required String memoryId, String? title, String? content}) async {
                        await _characterService.updateMemory(
                          widget.sessionData['id'],
                          saveSlotId: saveSlotId,
                          memoryId: memoryId,
                          title: title,
                          content: content,
                        );
                      },
                      deleteMemory: ({required String saveSlotId, required String memoryId}) async {
                        await _characterService.deleteMemory(
                          widget.sessionData['id'],
                          saveSlotId: saveSlotId,
                          memoryId: memoryId,
                        );
                      },
                      insertMemoryRelative: ({required String anchorMemoryId, required String position, required String title, required String content}) async {
                        await _characterService.insertMemoryRelative(
                          widget.sessionData['id'],
                          anchorMemoryId: anchorMemoryId,
                          position: position,
                          title: title,
                          content: content,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 🔥 "回到底部"悬浮按钮 - 右下角长条形毛玻璃设计
          if (_showBackToBottomButton)
            Positioned(
              right: 16.w,
              bottom: 80.h, // 降低位置，更接近输入框
              child: FadeTransition(
                opacity: _backToBottomAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _scrollToBottom();
                      // _scrollToBottom() 方法内部已经处理了按钮隐藏逻辑
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3), // 毛玻璃效果
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 14.sp,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            '回到底部',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
