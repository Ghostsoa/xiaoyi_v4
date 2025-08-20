import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'dart:developer' as developer;
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_theme.dart';
import '../../../services/file_service.dart';
import '../../../services/message_cache_service.dart';
import '../../../dao/novel_settings_dao.dart';
import '../../../widgets/custom_toast.dart';
import '../../../widgets/novel_cache_pull_dialog.dart';
import '../services/novel_service.dart';
import '../widgets/novel_content_bubble.dart';
import '../widgets/novel_top_bar.dart';
import '../widgets/novel_ai_interaction_area.dart';
import '../utils/novel_content_parser.dart';
import '../widgets/novel_settings_sheet.dart';

class NovelReadingPage extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final Map<String, dynamic> novelData;

  const NovelReadingPage({
    super.key,
    required this.sessionData,
    required this.novelData,
  });

  @override
  State<NovelReadingPage> createState() => _NovelReadingPageState();
}

class _NovelReadingPageState extends State<NovelReadingPage>
    with SingleTickerProviderStateMixin {
  final FileService _fileService = FileService();
  final NovelService _novelService = NovelService();
  final MessageCacheService _messageCacheService = MessageCacheService();
  final NovelSettingsDao _settingsDao = NovelSettingsDao();
  final ScrollController _scrollController = ScrollController();
  late ListObserverController _observerController;
  final GlobalKey _listViewKey = GlobalKey();

  // 界面设置
  bool _showControls = true;
  bool _showAiInteraction = true;
  final bool _isLoading = false;
  bool _isGenerating = false;
  bool _isLoadingHistory = false;
  int _currentHistoryPage = 1;
  bool _hasMoreHistory = true;

  // 阅读设置
  double _contentFontSize = 16.0;
  double _titleFontSize = 18.0;
  Color _backgroundColor = const Color(0xFF121212);
  Color _textColor = Colors.white;

  // 刷新按钮状态
  bool _isRefreshing = false;
  bool _showRefreshSuccess = false;

  // 刷新按钮旋转动画控制器
  late AnimationController _refreshRotationController;
  late Animation<double> _refreshRotationAnimation;

  // 内容气泡列表
  final List<Map<String, dynamic>> _novelBubbles = [];

  // 章节信息
  int _totalChapters = 0;
  final ValueNotifier<String> _currentChapterTitleNotifier = ValueNotifier<String>("加载中...");

  // 缓存背景图片
  Uint8List? _cachedBackgroundImage;
  bool _isLoadingBackground = false;

  // 提示输入相关
  final TextEditingController _promptController = TextEditingController();
  bool _showPromptInput = false;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  // AI交互区高度
  final double _aiInteractionHeight = 160.0;
  // 添加键盘高度跟踪变量
  double _keyboardHeight = 0.0;
  // 添加键盘可见状态
  bool _isKeyboardVisible = false;

  // 会话ID
  String get _sessionId => (widget.sessionData['id'] ?? '').toString();
  int get _sessionIdInt => int.tryParse(_sessionId) ?? 0;

  // 章节数据
  List<Map<String, dynamic>> get _chapters =>
      (widget.novelData['chapters'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();

  // 缓存相关状态
  bool _isLocalMode = false; // 是否使用本地缓存模式
  bool _isBackgroundLoading = false; // 是否正在后台加载
  List<Map<String, dynamic>> _allLoadedChapters = []; // 所有已加载的章节（用于搜索）

  // 搜索相关状态
  bool _isSearchMode = false; // 是否处于搜索模式
  String _searchKeyword = ''; // 当前搜索关键词
  List<Map<String, dynamic>> _searchResults = []; // 搜索结果
  final TextEditingController _searchController = TextEditingController();

  // 编辑相关状态
  bool _isEditingContent = false; // 是否正在编辑内容

  // 滚动监听控制
  bool _isInteractionPanelAnimating = false; // 交互面板是否正在动画中

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
    _loadUserSettings();

    // 初始化章节数据
    _totalChapters = _chapters.length;

    // 初始化 observer controller
    _observerController = ListObserverController(controller: _scrollController);

    // 初始化刷新旋转动画控制器
    _refreshRotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _refreshRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_refreshRotationController);

    // 设置滚动监听
    _scrollController.addListener(_handleScroll);

    // 设置系统UI样式
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // 检查缓存并初始化模式
    _checkAndInitializeMode().then((_) {
      if (mounted) {
        setState(() {
          if (_novelBubbles.isNotEmpty) {
            _currentChapterTitleNotifier.value =
                _novelBubbles[0]['title'] ?? '章节加载完毕';
          } else {
            _currentChapterTitleNotifier.value = '开始创作吧';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // ItemScrollController 不需要手动dispose
    _refreshRotationController.dispose();
    _promptController.dispose();
    _refreshController.dispose();
    // 恢复系统UI样式
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    super.dispose();
  }

  // 监听滚动事件
  void _handleScroll() {
    // 如果交互面板正在动画中，跳过处理
    if (_isInteractionPanelAnimating) {
      return;
    }

    if (!mounted || _novelBubbles.isEmpty) return;

    // 只隐藏顶部控件，不隐藏交互面板
    _hideControls();

    // 简化处理，基于滚动位置检查是否需要加载更多
    if (_scrollController.hasClients) {
      final scrollOffset = _scrollController.offset;
      final maxScrollExtent = _scrollController.position.maxScrollExtent;

      // 如果滚动到接近底部（在反转列表中是顶部），加载更多历史
      if (maxScrollExtent > 0 && scrollOffset > maxScrollExtent * 0.8 && !_isLoadingHistory && _hasMoreHistory) {
        _loadHistoryMessages();
      }
    }

    // 章节标题由 scrollview_observer 自动处理
  }


  void _hideControls() {
    if (_showControls) {
      setState(() {
        _showControls = false;
      });
    }
  }


  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _toggleAiInteraction() {
    // 设置动画标志，禁用滚动监听
    _isInteractionPanelAnimating = true;

    setState(() {
      _showAiInteraction = !_showAiInteraction;
    });

    // 动画完成后恢复滚动监听
    Future.delayed(Duration(milliseconds: 250), () {
      _isInteractionPanelAnimating = false;
    });
  }

  // 滚动到指定索引的方法
  void _scrollToIndex(int index, {bool animate = true}) {
    if (_novelBubbles.isEmpty) return;

    // 使用 scrollview_observer 的 animateTo 方法
    if (animate) {
      _observerController.animateTo(
        index: index,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _observerController.jumpTo(index: index);
    }
  }

  Future<void> _loadBackgroundImage() async {
    if (widget.sessionData['background_uri'] == null ||
        _isLoadingBackground ||
        _cachedBackgroundImage != null) {
      return;
    }

    _isLoadingBackground = true;
    try {
      final result =
          await _fileService.getFile(widget.sessionData['background_uri']);
      if (mounted) {
        setState(() {
          _cachedBackgroundImage = result.data;
          _isLoadingBackground = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBackground = false);
      }
    }
  }

  // 加载用户设置
  Future<void> _loadUserSettings() async {
    try {
      final settings = await _settingsDao.loadAllSettings();
      if (mounted) {
        setState(() {
          _contentFontSize = settings['contentFontSize'];
          _titleFontSize = settings['titleFontSize'];
          _backgroundColor = settings['backgroundColor'];
          _textColor = settings['textColor'];
        });
      }
    } catch (e) {
      developer.log('加载用户设置失败: $e');
      // 使用默认设置
    }
  }

  // 保存用户设置
  Future<void> _saveUserSettings() async {
    try {
      await _settingsDao.saveAllSettings(
        contentFontSize: _contentFontSize,
        titleFontSize: _titleFontSize,
        backgroundColor: _backgroundColor,
        textColor: _textColor,
      );
      _showSuccessMessage('设置已保存');
    } catch (e) {
      developer.log('保存用户设置失败: $e');
      _showErrorMessage('保存设置失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isInitialMode = _totalChapters == 0;
    String novelTitle = widget.novelData['title'] ?? '未命名小说';
    final viewInsets = MediaQuery.of(context).viewInsets;
    final padding = MediaQuery.of(context).padding;
    final bottomContentPadding = padding.bottom - 2.h;

    // 监听键盘状态变化
    final currentKeyboardHeight = viewInsets.bottom;
    if (_keyboardHeight != currentKeyboardHeight) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _keyboardHeight = currentKeyboardHeight;
            _isKeyboardVisible = _keyboardHeight > 0;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      extendBody: true,
      resizeToAvoidBottomInset: false, // 保持为false，我们自己处理键盘显示逻辑
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图片或颜色
          Positioned.fill(
            child: _cachedBackgroundImage != null
                ? Image.memory(
                    _cachedBackgroundImage!,
                    fit: BoxFit.cover,
                  )
                : Container(color: _backgroundColor),
          ),

          // 顶部安全区域+导航栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              minimum: EdgeInsets.zero,
              child: NovelTopBar(
                novelTitle: novelTitle,
                onExit: () => Navigator.of(context).pop(),
                onPullCache: _showPullCacheDialog,
                onOverrideCache: _showOverrideCacheDialog,
                isLocalMode: _isLocalMode,
                showPullCache: !_isLocalMode, // 只在在线模式下显示拉取缓存按钮
                showOverrideCache: _isLocalMode, // 只在本地模式下显示覆盖缓存按钮
              ),
            ),
          ),

          // 内容区域
          Positioned(
            top: MediaQuery.of(context).padding.top + 30.h,
            left: 0,
            right: 0,
            bottom: bottomContentPadding,
            child: GestureDetector(
              onTap: () {
                _toggleControls();
                _toggleAiInteraction();
              },
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SmartRefresher(
                      enablePullDown: false,
                      enablePullUp: true,
                      controller: _refreshController,
                      footer: CustomFooter(
                        builder: (context, mode) {
                          Widget body;
                          if (mode == LoadStatus.idle) {
                            body = const Text("上拉加载更多历史章节");
                          } else if (mode == LoadStatus.loading) {
                            body = Shimmer.fromColors(
                              baseColor: AppTheme.primaryColor.withValues(alpha: 0.6),
                              highlightColor: Colors.white,
                              period: const Duration(milliseconds: 1800),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 16.sp,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '正在加载历史章节',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.white70,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '...',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (mode == LoadStatus.failed) {
                            body = const Text("加载失败，请重试");
                          } else if (mode == LoadStatus.canLoading) {
                            body = const Text("释放立即加载");
                          } else {
                            body = const Text("没有更多历史章节了");
                          }
                          return Container(
                            height: 55.0,
                            color: Colors.transparent,
                            child: Center(child: body),
                          );
                        },
                      ),
                      onLoading: () {
                        developer.log('强制触发加载更多回调');
                        _loadHistoryMessages();
                      },
                      child: ListViewObserver(
                        controller: _observerController,
                        onObserve: (resultModel) {
                          // 监听当前第一个正在显示的子部件
                          if (resultModel.firstChild != null) {
                            final firstIndex = resultModel.firstChild!.index;
                            final clampedIndex = firstIndex.clamp(0, _novelBubbles.length - 1);

                            String newTitle = _novelBubbles[clampedIndex]['title'] ?? '';

                            if (newTitle.isNotEmpty &&
                                _currentChapterTitleNotifier.value != newTitle) {
                              _currentChapterTitleNotifier.value = newTitle;
                            }
                          }
                        },
                        child: ListView.builder(
                          key: _listViewKey,
                          controller: _scrollController,
                          reverse: true,
                          padding: EdgeInsets.only(
                            left: 16.w,
                            right: 16.w,
                            top: 16.h,
                            bottom: _calculateContentBottomPadding(),
                          ),
                          itemCount: _novelBubbles.length,
                          itemBuilder: (context, index) {
                            final bubble = _novelBubbles[index];
                            return NovelContentBubble(
                              title: bubble['title'],
                              paragraphs: List<Map<String, dynamic>>.from(
                                  bubble['paragraphs']),
                              createdAt: bubble['createdAt'] ?? '',
                              msgId: bubble['msgId'] ?? '',
                              isGenerating: bubble['isGenerating'] ?? false,
                              contentFontSize: _contentFontSize,
                              titleFontSize: _titleFontSize,
                              backgroundColor: _backgroundColor,
                              textColor: _textColor,
                              onEdit: _handleEditContent,
                              onEditingStateChanged: (isEditing) {
                                setState(() {
                                  _isEditingContent = isEditing;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ),

          // 底部AI交互区域
          if (_showAiInteraction)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              left: 16.w,
              right: 16.w,
              bottom: _calculateInteractionAreaBottom(padding),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _textColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ValueListenableBuilder<String>(
                  valueListenable: _currentChapterTitleNotifier,
                  builder: (context, currentTitle, child) {
                    return NovelAiInteractionArea(
                      currentChapterTitle: currentTitle,
                  isInitialMode: isInitialMode,
                  isGenerating: _isGenerating,
                  isRefreshing: _isRefreshing,
                  showRefreshSuccess: _showRefreshSuccess,
                  refreshRotationAnimation: _refreshRotationAnimation,
                  novelBubbles: _novelBubbles,
                  backgroundColor: _backgroundColor,
                  textColor: _textColor,
                  isLocalMode: _isLocalMode,
                  isSearchMode: _isSearchMode,
                  onSettings: _handleSettings,
                  onRegenerate: _handleRegenerate,
                  onRefreshPage: _handleRefreshPage,
                  onResetConversation: _handleResetConversation,
                  onScrollToBottom: _scrollToBottom,
                  onAutoContinue: _handleAutoContinue,
                  onTogglePromptInput: _togglePromptInput,
                  onCancelPrompt: _togglePromptInput,
                  onSubmitPrompt: (prompt) {
                    if (prompt.isNotEmpty) {
                      _handleContinueWithPrompt(prompt);
                      _promptController.clear();
                      setState(() {
                        _showPromptInput = false;
                      });
                    }
                  },
                  onToggleSearch: _toggleSearchMode,
                  onSearch: _performSearch,
                  searchController: _searchController,
                  onPreviousChapter: _goToNextChapter,
                  onNextChapter: _goToPreviousChapter,
                  onShowChapterList: _showChapterList,
                      showPromptInput: _showPromptInput,
                      promptController: _promptController,
                    );
                  },
                ),
              ),
            ),

        ],
      ),
    );
  }

  // 处理AI自动生成内容
  Future<void> _handleAutoContinue() async {
    try {
      // 创建占位气泡
      final String bubbleId = DateTime.now().millisecondsSinceEpoch.toString();
      final placeholderBubble = {
        'id': bubbleId,
        'title': '正在创作中...',
        'paragraphs': <Map<String, dynamic>>[
          {
            'content': '灵感正在涌现...',
            'type': 'narrator',
          }
        ],
        'createdAt': DateTime.now().toIso8601String(),
        'isGenerating': true,
        'msgId': '', // 初始为空，稍后会更新
      };

      setState(() {
        _novelBubbles.insert(0, placeholderBubble);
        _isGenerating = true;
        _currentChapterTitleNotifier.value = placeholderBubble['title']! as String;
      });

      // 调用AI对话接口
      final response = await _novelService.sendNovelChat(_sessionId);

      if (response['code'] != 0) {
        throw response['msg'] ?? '请求失败';
      }

      final data = response['data'] as Map<String, dynamic>;
      final content = data['content'] as String;

      // 优先使用API返回的chapterTitle字段，如果没有则使用默认标题
      String chapterTitle = data['chapterTitle'] as String? ??
          NovelContentParser.getDefaultChapterTitle(_totalChapters + 1);

      // 解析内容为段落列表
      final paragraphs = NovelContentParser.parseContent(content);

      // 更新气泡内容
      if (mounted) {
        setState(() {
          if (_novelBubbles.isNotEmpty) {
            _novelBubbles[0]['title'] = chapterTitle;
            _novelBubbles[0]['paragraphs'] = paragraphs;
            _novelBubbles[0]['createdAt'] =
                data['created_at'] ?? DateTime.now().toIso8601String();
            _novelBubbles[0]['isGenerating'] = false;
            _novelBubbles[0]['msgId'] = data['msgId'] ?? ''; // 使用API返回的msgId
            _currentChapterTitleNotifier.value = _novelBubbles[0]['title']!;
          }
          _totalChapters++;
          _isGenerating = false;
        });
        _showSuccessMessage('新章节创作完成');
      }

      // 更新章节数据结构
      if (widget.novelData['chapters'] == null) {
        widget.novelData['chapters'] = [];
      }

      final newChapter = {
        'title': chapterTitle,
        'content': paragraphs,
        'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
        'msgId': data['msgId'] ?? '', // 使用API返回的msgId
      };

      (widget.novelData['chapters'] as List).add(newChapter);

      // 只在本地模式下同步新章节到缓存
      if (_isLocalMode) {
        await _syncChaptersToCache([newChapter]);
        // 重新加载所有章节数据
        await _reloadAllChapters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_novelBubbles.isNotEmpty &&
              _novelBubbles[0]['isGenerating'] == true) {
            _novelBubbles.removeAt(0);
          }
          _isGenerating = false;
          if (mounted && _novelBubbles.isNotEmpty) {
            _currentChapterTitleNotifier.value = _novelBubbles[0]['title'] ?? "出错了";
          } else if (mounted) {
            _currentChapterTitleNotifier.value = "自动生成章节失败";
          }
        });
      }
      _showErrorMessage('自动生成章节失败: $e');
    }
  }

  // 处理用户提供的引导生成内容
  Future<void> _handleContinueWithPrompt(String prompt) async {
    try {
      // 创建占位气泡
      final String bubbleId = DateTime.now().millisecondsSinceEpoch.toString();
      final placeholderBubble = {
        'id': bubbleId,
        'title': '根据您的引导创作中...',
        'paragraphs': <Map<String, dynamic>>[
          {
            'content': '正在根据您的想法进行创作...',
            'type': 'narrator',
          }
        ],
        'createdAt': DateTime.now().toIso8601String(),
        'isGenerating': true,
        'msgId': '', // 初始为空，稍后会更新
      };

      setState(() {
        _novelBubbles.insert(0, placeholderBubble);
        _isGenerating = true;
        _currentChapterTitleNotifier.value = placeholderBubble['title']! as String;
      });

      // 调用AI对话接口
      final response =
          await _novelService.sendNovelChat(_sessionId, input: prompt);

      if (response['code'] != 0) {
        throw response['msg'] ?? '请求失败';
      }

      final data = response['data'] as Map<String, dynamic>;
      final content = data['content'] as String;

      // 优先使用API返回的chapterTitle字段，如果没有则使用默认标题
      String chapterTitle = data['chapterTitle'] as String? ??
          NovelContentParser.getDefaultChapterTitle(_totalChapters + 1);

      // 解析内容为段落列表
      final paragraphs = NovelContentParser.parseContent(content);

      // 更新气泡内容
      if (mounted) {
        setState(() {
          if (_novelBubbles.isNotEmpty) {
            _novelBubbles[0]['title'] = chapterTitle;
            _novelBubbles[0]['paragraphs'] = paragraphs;
            _novelBubbles[0]['createdAt'] =
                data['created_at'] ?? DateTime.now().toIso8601String();
            _novelBubbles[0]['isGenerating'] = false;
            _novelBubbles[0]['msgId'] = data['msgId'] ?? ''; // 使用API返回的msgId
            _currentChapterTitleNotifier.value = _novelBubbles[0]['title']!;
          }
          _totalChapters++;
          _isGenerating = false;
        });
        _showSuccessMessage('引导创作完成');
      }

      // 更新章节数据结构
      if (widget.novelData['chapters'] == null) {
        widget.novelData['chapters'] = [];
      }

      final newChapter = {
        'title': chapterTitle,
        'content': paragraphs,
        'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
        'msgId': data['msgId'] ?? '', // 使用API返回的msgId
      };

      (widget.novelData['chapters'] as List).add(newChapter);

      // 只在本地模式下同步新章节到缓存
      if (_isLocalMode) {
        await _syncChaptersToCache([newChapter]);
        // 重新加载所有章节数据
        await _reloadAllChapters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_novelBubbles.isNotEmpty &&
              _novelBubbles[0]['isGenerating'] == true) {
            _novelBubbles.removeAt(0);
          }
          _isGenerating = false;
          if (mounted && _novelBubbles.isNotEmpty) {
            _currentChapterTitleNotifier.value = _novelBubbles[0]['title'] ?? "出错了";
          } else if (mounted) {
            _currentChapterTitleNotifier.value = "引导生成章节失败";
          }
        });
      }
      _showErrorMessage('引导生成章节失败: $e');
    }
  }

  // 显示错误信息
  void _showErrorMessage(String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.error,
    );
  }

  // 显示成功信息
  void _showSuccessMessage(String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.success,
    );
  }

  // 显示信息提示
  void _showInfoMessage(String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.info,
    );
  }

  // ==================== 缓存相关方法 ====================

  /// 检查缓存并初始化模式
  Future<void> _checkAndInitializeMode() async {
    try {
      debugPrint('[NovelReadingPage] 检查缓存状态，会话ID: $_sessionIdInt');

      // 检查是否有缓存数据
      final hasCache = await _messageCacheService.hasNovelCache(
        sessionId: _sessionIdInt,
      );

      debugPrint('[NovelReadingPage] 是否有缓存: $hasCache');

      if (hasCache) {
        _isLocalMode = true;
        debugPrint('[NovelReadingPage] ✅ 进入本地模式');
        // 启动后台预加载
        _startBackgroundLoading();
      } else {
        _isLocalMode = false;
        debugPrint('[NovelReadingPage] ❌ 无缓存，使用在线模式');
      }

      // 加载历史消息
      await _loadHistoryMessages();
    } catch (e) {
      debugPrint('[NovelReadingPage] 检查缓存失败: $e');
      _isLocalMode = false;
      // 出错时仍然尝试加载历史消息
      await _loadHistoryMessages();
    }
  }

  /// 切换到本地模式但不重新加载数据
  Future<void> _switchToLocalModeWithoutReload() async {
    try {
      debugPrint('[NovelReadingPage] 切换到本地模式（不重新加载数据）');

      setState(() {
        _isLocalMode = true;
      });

      // 启动后台预加载
      _startBackgroundLoading();
    } catch (e) {
      debugPrint('[NovelReadingPage] 切换到本地模式失败: $e');
    }
  }

  /// 启动后台预加载
  Future<void> _startBackgroundLoading() async {
    if (_isBackgroundLoading || !_isLocalMode) return;

    _isBackgroundLoading = true;
    debugPrint('[NovelReadingPage] 🚀 启动后台预加载');

    try {
      // 获取所有缓存的章节用于搜索
      final result = await _messageCacheService.getNovelChapters(
        sessionId: _sessionIdInt,
        page: 1,
        pageSize: 1000, // 获取大量数据用于搜索
      );

      _allLoadedChapters = List<Map<String, dynamic>>.from(result['list'] ?? []);
      debugPrint('[NovelReadingPage] 📥 后台预加载完成，章节数: ${_allLoadedChapters.length}');
    } catch (e) {
      debugPrint('[NovelReadingPage] 后台预加载失败: $e');
    } finally {
      _isBackgroundLoading = false;
    }
  }

  /// 同步章节到缓存
  Future<void> _syncChaptersToCache(List<Map<String, dynamic>> chapters) async {
    if (!mounted || chapters.isEmpty) return;

    try {
      // 转换章节格式以适配缓存
      final cacheChapters = chapters.map((chapter) => {
        'msgId': chapter['msgId'] ?? '',
        'title': chapter['title'] ?? '',
        'content': chapter['content'] ?? chapter['paragraphs'] ?? [],
        'createdAt': chapter['createdAt'] ?? chapter['created_at'] ?? DateTime.now().toIso8601String(),
      }).toList();

      await _messageCacheService.insertOrUpdateNovelChapters(
        sessionId: _sessionIdInt,
        chapters: cacheChapters,
      );

      debugPrint('[NovelReadingPage] 已同步 ${chapters.length} 个章节到缓存');
    } catch (e) {
      debugPrint('[NovelReadingPage] 同步章节到缓存失败: $e');
    }
  }

  /// 重新加载所有章节数据
  Future<void> _reloadAllChapters() async {
    try {
      final result = await _messageCacheService.getNovelChapters(
        sessionId: _sessionIdInt,
        page: 1,
        pageSize: 1000,
      );

      _allLoadedChapters = List<Map<String, dynamic>>.from(result['list'] ?? []);
      debugPrint('[NovelReadingPage] 重新加载章节数据完成，章节数: ${_allLoadedChapters.length}');
    } catch (e) {
      debugPrint('[NovelReadingPage] 重新加载章节数据失败: $e');
    }
  }



  /// 显示拉取缓存对话框
  Future<void> _showPullCacheDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NovelCachePullDialog(
        sessionId: _sessionIdInt,
        onCompleted: () {
          // 拉取完成后只切换模式，不重新加载数据
          _switchToLocalModeWithoutReload();
          _showSuccessMessage('缓存拉取完成，现在可以使用搜索功能');
        },
      ),
    );
  }

  /// 显示覆盖缓存确认对话框
  Future<void> _showOverrideCacheDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Text(
          '覆盖缓存',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '这将清空现有缓存并重新拉取所有章节数据。\n\n确定要继续吗？',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performOverrideCache();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              '确定',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 执行覆盖缓存
  Future<void> _performOverrideCache() async {
    // 显示拉取缓存对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NovelCachePullDialog(
        sessionId: _sessionIdInt,
        onCompleted: () {
          // 覆盖完成后只切换模式，不重新加载数据
          _switchToLocalModeWithoutReload();
          _showSuccessMessage('缓存已覆盖更新');
        },
      ),
    );
  }

  // ==================== 搜索相关方法 ====================

  /// 切换搜索模式
  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (_isSearchMode) {
        // 进入搜索模式，清空搜索结果
        _searchKeyword = '';
        _searchResults.clear();
        _searchController.clear();
      } else {
        // 退出搜索模式，清空搜索结果
        _searchKeyword = '';
        _searchResults.clear();
        _searchController.clear();
      }
    });
  }

  /// 执行搜索
  Future<void> _performSearch(String keyword) async {
    if (!_isLocalMode || keyword.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _searchKeyword = keyword.trim();
    });

    try {
      // 从缓存中搜索章节
      final results = await _messageCacheService.searchNovelChapters(
        sessionId: _sessionIdInt,
        keyword: _searchKeyword,
      );

      setState(() {
        _searchResults = results;
      });

      debugPrint('[NovelReadingPage] 搜索关键词 "$_searchKeyword" 找到 ${results.length} 个结果');

      // 如果有搜索结果，显示在底部弹窗中
      if (results.isNotEmpty) {
        _showSearchResults(results);
      } else {
        _showInfoMessage('未找到相关章节');
      }
    } catch (e) {
      debugPrint('[NovelReadingPage] 搜索失败: $e');
      setState(() {
        _searchResults.clear();
      });
      _showErrorMessage('搜索失败: $e');
    }
  }

  /// 显示搜索结果
  void _showSearchResults(List<Map<String, dynamic>> results) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppTheme.primaryColor,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  '搜索结果 (${results.length})',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // 搜索结果列表
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _jumpToSearchResult(result['msgId'] as String? ?? '');
                    },
                    child: _buildSearchResultItem(result),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 跳转到搜索结果章节
  void _jumpToSearchResult(String msgId) {
    // 退出搜索模式
    setState(() {
      _isSearchMode = false;
      _searchKeyword = '';
      _searchResults.clear();
    });

    // 跳转到目标章节
    _jumpToChapter(msgId);
  }

  /// 跳转到指定章节
  Future<void> _jumpToChapter(String msgId) async {
    try {
      // 在当前显示的章节列表中查找
      final currentIndex = _novelBubbles.indexWhere((bubble) => bubble['msgId'] == msgId);

      if (currentIndex != -1) {
        // 章节在当前页面，使用平滑滚动到位置
        _scrollToIndex(currentIndex, animate: true);
        _showSuccessMessage('已定位到章节');
        return;
      }

      // 如果有预加载的数据，使用快速定位
      if (_allLoadedChapters.isNotEmpty) {
        await _fastJumpUsingPreloadedData(msgId);
      } else {
        // 没有预加载数据，显示提示
        _showInfoMessage('请先拉取缓存以支持快速定位');
      }
    } catch (e) {
      debugPrint('[NovelReadingPage] 跳转到章节失败: $e');
      _showErrorMessage('定位章节失败');
    }
  }

  /// 使用预加载数据快速跳转
  Future<void> _fastJumpUsingPreloadedData(String msgId) async {
    try {
      // 在预加载数据中找到目标章节
      final targetIndex = _allLoadedChapters.indexWhere((chapter) => chapter['msgId'] == msgId);

      if (targetIndex == -1) {
        _showErrorMessage('未找到目标章节');
        return;
      }

      // 计算需要加载到第几页
      final targetPage = (targetIndex ~/ 2) + 1; // 假设每页2个章节

      debugPrint('[NovelReadingPage] 🚀 快速定位：目标章节在第 $targetPage 页，索引 $targetIndex');

      // 直接加载到目标页面
      _currentHistoryPage = targetPage;
      await _loadHistoryMessages();

      // 等待UI更新，增加等待时间确保列表完全渲染
      await Future.delayed(Duration(milliseconds: 300));

      // 在新加载的页面中找到目标章节并精确跳转
      final newIndex = _novelBubbles.indexWhere((bubble) => bubble['msgId'] == msgId);
      if (newIndex != -1) {
        // 使用 scrollTo 而不是 jumpTo，提供平滑的动画效果
        _scrollToIndex(newIndex, animate: true);
        _showSuccessMessage('已定位到章节');
      } else {
        _showErrorMessage('定位失败，请重试');
      }
    } catch (e) {
      debugPrint('[NovelReadingPage] 快速定位失败: $e');
      _showErrorMessage('定位失败');
    }
  }





  /// 构建搜索结果项
  Widget _buildSearchResultItem(Map<String, dynamic> result) {
    final title = result['title'] as String? ?? '未知章节';
    final createdAt = result['createdAt'] as String? ?? '';

    // 获取章节内容的前几段作为预览
    String contentPreview = '';
    if (result['content'] is List) {
      final paragraphs = result['content'] as List;
      if (paragraphs.isNotEmpty) {
        final firstParagraph = paragraphs.first;
        if (firstParagraph is Map && firstParagraph['content'] is String) {
          contentPreview = firstParagraph['content'] as String;
          if (contentPreview.length > 100) {
            contentPreview = '${contentPreview.substring(0, 100)}...';
          }
        }
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 章节标题
            Text(
              title,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (contentPreview.isNotEmpty) ...[
              SizedBox(height: 8.h),
              // 内容预览（高亮搜索关键词）
              _buildHighlightedText(
                contentPreview,
                _searchKeyword,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  height: 1.4,
                ),
                maxLines: 2,
              ),
            ],
            if (createdAt.isNotEmpty) ...[
              SizedBox(height: 8.h),
              // 创建时间
              Text(
                _formatSearchResultTime(createdAt),
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 格式化搜索结果时间
  String _formatSearchResultTime(String timeStr) {
    try {
      final dateTime = DateTime.parse(timeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return timeStr;
    }
  }

  /// 构建高亮文本
  Widget _buildHighlightedText(
    String text,
    String keyword, {
    TextStyle? style,
    int? maxLines,
  }) {
    if (keyword.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerKeyword = keyword.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerKeyword);

    while (index != -1) {
      // 添加关键词前的文本
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: style,
        ));
      }

      // 添加高亮的关键词
      spans.add(TextSpan(
        text: text.substring(index, index + keyword.length),
        style: style?.copyWith(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.3),
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + keyword.length;
      index = lowerText.indexOf(lowerKeyword, start);
    }

    // 添加剩余的文本
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ==================== 键盘和UI联动相关方法 ====================

  /// 计算内容区域的底部 padding
  double _calculateContentBottomPadding() {
    // 基础底部 padding
    double basePadding = 16.h;

    // 如果正在编辑内容且键盘可见，需要额外的 padding 来避让键盘
    if (_isEditingContent && _isKeyboardVisible) {
      return basePadding + _keyboardHeight;
    }

    // 其他情况只需要基础 padding，交互面板是独立的
    return basePadding;
  }

  /// 计算交互区域的底部位置
  double _calculateInteractionAreaBottom(EdgeInsets padding) {
    // 基础底部距离
    double baseBottom = padding.bottom + 12.h;

    // 如果正在编辑内容，隐藏交互面板
    if (_isEditingContent) {
      return -200.h; // 移到屏幕外隐藏
    }

    // 如果键盘可见（搜索或"我有一个想法"），交互区域被键盘顶上去
    if (_isKeyboardVisible) {
      return baseBottom + _keyboardHeight;
    }

    return baseBottom;
  }



  // ==================== 章节导航相关方法 ====================

  /// 跳转到上一章
  void _goToPreviousChapter() {
    if (!_isLocalMode || _allLoadedChapters.isEmpty) return;

    // 找到当前用户看到的章节
    final currentVisibleChapterTitle = _currentChapterTitleNotifier.value;
    if (currentVisibleChapterTitle.isEmpty) return;

    // 在全部章节中找到当前章节的位置
    final currentIndex = _allLoadedChapters.indexWhere(
      (chapter) => chapter['title'] == currentVisibleChapterTitle
    );

    if (currentIndex > 0) {
      // 跳转到上一章
      final previousChapter = _allLoadedChapters[currentIndex - 1];
      _jumpToChapter(previousChapter['msgId'] as String);
    } else {
      _showInfoMessage('已经是最新章节了');
    }
  }

  /// 跳转到下一章
  void _goToNextChapter() {
    if (!_isLocalMode || _allLoadedChapters.isEmpty) return;

    // 找到当前用户看到的章节
    final currentVisibleChapterTitle = _currentChapterTitleNotifier.value;
    if (currentVisibleChapterTitle.isEmpty) return;

    // 在全部章节中找到当前章节的位置
    final currentIndex = _allLoadedChapters.indexWhere(
      (chapter) => chapter['title'] == currentVisibleChapterTitle
    );

    if (currentIndex >= 0 && currentIndex < _allLoadedChapters.length - 1) {
      // 跳转到下一章
      final nextChapter = _allLoadedChapters[currentIndex + 1];
      _jumpToChapter(nextChapter['msgId'] as String);
    } else {
      _showInfoMessage('已经是第一章了');
    }
  }

  /// 显示章节目录
  void _showChapterList() {
    if (!_isLocalMode || _allLoadedChapters.isEmpty) {
      _showInfoMessage('请先拉取缓存以查看章节目录');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.list,
                  color: AppTheme.primaryColor,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  '章节目录',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // 章节列表（反转顺序，最新章节在上）
            Expanded(
              child: ListView.builder(
                itemCount: _allLoadedChapters.length,
                itemBuilder: (context, index) {
                  // 反转索引，最新章节在上
                  final reversedIndex = _allLoadedChapters.length - 1 - index;
                  final chapter = _allLoadedChapters[reversedIndex];
                  final title = chapter['title'] as String? ?? '未知章节';
                  final msgId = chapter['msgId'] as String? ?? '';

                  // 检查是否是当前章节
                  final isCurrentChapter = title == _currentChapterTitleNotifier.value;

                  return Container(
                    decoration: isCurrentChapter ? BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8.r),
                    ) : null,
                    margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    child: ListTile(
                      title: Row(
                        children: [
                          if (isCurrentChapter) ...[
                            Icon(
                              Icons.play_arrow,
                              color: AppTheme.primaryColor,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                          ],
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: isCurrentChapter ? AppTheme.primaryColor : Colors.white,
                                fontSize: 16.sp,
                                fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _jumpToChapter(msgId);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 加载历史消息
  Future<void> _loadHistoryMessages() async {
    // 避免重复请求
    if (_isLoadingHistory || !_hasMoreHistory) {
      debugPrint("跳过加载 - 已经在加载: $_isLoadingHistory 或没有更多历史: $_hasMoreHistory");
      return;
    }

    debugPrint("开始加载历史消息，页码: $_currentHistoryPage，模式: ${_isLocalMode ? '本地' : '在线'}");
    setState(() => _isLoadingHistory = true);
    List<Map<String, dynamic>> messages = [];

    try {
      Map<String, dynamic> result;

      if (_isLocalMode) {
        // 本地模式：从缓存加载
        debugPrint('[NovelReadingPage] 🔄 从本地缓存加载章节 (page: $_currentHistoryPage)');
        result = await _messageCacheService.getNovelChapters(
          sessionId: _sessionIdInt,
          page: _currentHistoryPage,
          pageSize: 2,
        );
      } else {
        // 在线模式：从API加载
        debugPrint('[NovelReadingPage] 🌐 从API加载章节 (page: $_currentHistoryPage)');
        final response = await _novelService.getNovelMessages(
          _sessionId,
          page: _currentHistoryPage,
          pageSize: 2,
        );

        // 记录日志
        final Map<String, dynamic> responseForLog = Map.from(response);
        if (responseForLog['data'] is Map) {
          final dataMap = Map<String, dynamic>.from(responseForLog['data']);
          if (dataMap['list'] is List) {
            final List<dynamic> messagesList = List.from(dataMap['list']);
            final List<dynamic> simplifiedMessages = messagesList.map((msg) {
              if (msg is Map) {
                final Map<String, dynamic> newMsg = Map.from(msg);
                newMsg.remove('content');
                return newMsg;
              }
              return msg;
            }).toList();
            dataMap['list'] = simplifiedMessages;
          }
          responseForLog['data'] = dataMap;
        }
        debugPrint("原始响应(不含content): $responseForLog");

        if (response['code'] != 0) {
          throw response['msg'] ?? '请求失败';
        }

        final data = response['data'] as Map<String, dynamic>;
        messages = (data['list'] as List? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();

        // 更新分页信息
        final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
        final total = pagination['total'] as int? ?? 0;
        final pageSize = pagination['page_size'] as int? ?? 2;
        final currentPage = pagination['page'] as int? ?? _currentHistoryPage;
        final totalPages = pagination['total_pages'] as int? ?? 1;

        _hasMoreHistory = messages.isNotEmpty && currentPage < totalPages;

        debugPrint(
            "加载成功 - 当前页: $currentPage/$totalPages, 消息数量: ${messages.length}, 总记录数: $total, 每页大小: $pageSize, 是否有更多: $_hasMoreHistory");

        // 转换API响应为统一格式
        result = {
          'list': messages,
          'pagination': {
            'total_pages': totalPages,
            'current_page': currentPage,
            'total_count': total,
            'page_size': pageSize,
          }
        };

        // 在线模式下不自动写入缓存，让用户主动选择拉取缓存
      }

      // 统一处理结果
      messages = List<Map<String, dynamic>>.from(result['list'] ?? []);
      final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
      final currentPage = pagination['current_page'] as int? ?? _currentHistoryPage;
      final totalPages = pagination['total_pages'] as int? ?? 1;

      _hasMoreHistory = messages.isNotEmpty && currentPage < totalPages;

      debugPrint(
          "加载成功 - 当前页: $currentPage/$totalPages, 消息数量: ${messages.length}, 是否有更多: $_hasMoreHistory");

      // 处理消息数据
      await _processHistoryMessages(messages);

      // 更新页码
      _currentHistoryPage = currentPage + 1;
    } catch (e) {
      debugPrint("加载失败: $e");
      _showErrorMessage('加载更多章节失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
        if (!_hasMoreHistory || messages.isEmpty) {
          _refreshController.loadNoData();
        } else {
          _refreshController.loadComplete();
        }
      }
    }
  }

  // 处理历史消息
  Future<void> _processHistoryMessages(
      List<Map<String, dynamic>> messages) async {
    if (messages.isEmpty) {
      return;
    }

    debugPrint("处理历史消息，条数: ${messages.length}");

    List<Map<String, dynamic>> tempChapters = [];
    List<Map<String, dynamic>> tempBubbles = [];

    // API返回的是最新的在前，反转使其变为时间升序
    final orderedMessages = messages.reversed.toList();

    for (final message in orderedMessages) {
      // 只处理AI发送的消息
      if (message['role'] == 'assistant') {
        // 处理内容：可能是字符串（API数据）或段落列表（缓存数据）
        List<Map<String, dynamic>> paragraphs;
        if (message['content'] is String) {
          // API数据：需要解析字符串内容
          final content = message['content'] as String;
          paragraphs = NovelContentParser.parseContent(content);
        } else if (message['content'] is List) {
          // 缓存数据：已经是解析过的段落列表
          paragraphs = List<Map<String, dynamic>>.from(message['content']);
        } else {
          // 异常情况：创建空段落列表
          paragraphs = [];
          debugPrint('[NovelReadingPage] 警告：未知的内容格式: ${message['content'].runtimeType}');
        }

        // 尝试获取章节标题
        String chapterTitle = message['chapterTitle'] as String? ??
                             message['title'] as String? ?? ''; // 缓存数据中标题字段是 'title'

        // 如果没有章节标题，使用默认章节编号
        if (chapterTitle.isEmpty) {
          chapterTitle = NovelContentParser.getDefaultChapterTitle(
              tempChapters.length + 1);
        }

        // 创建气泡对象
        final bubble = {
          'title': chapterTitle,
          'paragraphs': paragraphs,
          'createdAt': message['createdAt'] ??
              message['created_at'] ??
              message['time'] ??
              DateTime.now().toIso8601String(),
          'isGenerating': false,
          'msgId': message['msgId'] ?? '',
        };

        tempBubbles.add(bubble);

        // 创建章节对象
        final chapter = {
          'title': chapterTitle,
          'content': paragraphs,
          'created_at': message['createdAt'] ??
              message['created_at'] ??
              message['time'] ??
              DateTime.now().toIso8601String(),
          'msgId': message['msgId'] ?? '',
        };

        tempChapters.add(chapter);
        debugPrint("添加章节: ${chapter['title']}");
      }
    }

    // 更新小说数据
    if (tempBubbles.isNotEmpty) {
      setState(() {
        // 判断是首次加载还是分页加载
        if (_currentHistoryPage == 1) {
          // 首次加载，直接使用新气泡替换
          _novelBubbles.clear();
          // 因为ListView是反向显示，所以需要反转列表顺序
          _novelBubbles.addAll(tempBubbles.reversed);
          debugPrint("首次加载，替换所有气泡，数量: ${tempBubbles.length}");

          // 同时更新原有的章节数据
          if (widget.novelData['chapters'] == null) {
            widget.novelData['chapters'] = [];
          }
          widget.novelData['chapters'] = List.from(tempChapters);
        } else {
          // 分页加载时保持当前位置（ListView 会自动处理）

          // 将历史章节添加到列表末尾
          _novelBubbles.addAll(tempBubbles.reversed);
          debugPrint(
              "分页加载，添加${tempBubbles.length}个气泡，总数: ${_novelBubbles.length}");

          // 同时更新原有的章节数据
          final currentChapters =
              List.from(widget.novelData['chapters'] as List);
          widget.novelData['chapters'] = [
            ...tempChapters.reversed,
            ...currentChapters
          ];

          
        }

        // 更新章节计数
        _totalChapters = _chapters.length;

        // 更新当前显示的章节标题
        if (_novelBubbles.isNotEmpty) {
          _currentChapterTitleNotifier.value =
              _novelBubbles[0]['title'] ?? '章节加载完毕';
        } else {
          if (_currentHistoryPage == 1 && messages.isEmpty) {
            _currentChapterTitleNotifier.value = '开始创作吧';
          } else {
            _currentChapterTitleNotifier.value = '没有更多内容了';
          }
        }
      });
    } else if (_currentHistoryPage == 1 && messages.isEmpty) {
      // 首次加载且没有消息
      setState(() {
        _currentChapterTitleNotifier.value = '开始创作吧';
        _totalChapters = 0;
      });
    }
  }

  // 切换提示输入显示状态
  void _togglePromptInput() {
    setState(() {
      _showPromptInput = !_showPromptInput;
      // 如果关闭输入框，收起键盘
      if (!_showPromptInput && _isKeyboardVisible) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  // 设置按钮处理逻辑
  void _handleSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: NovelSettingsSheet(
          sessionId: _sessionId,
          contentFontSize: _contentFontSize,
          titleFontSize: _titleFontSize,
          backgroundColor: _backgroundColor,
          textColor: _textColor,
          onContentFontSizeChanged: (value) {
            setState(() {
              _contentFontSize = value;
            });
            _saveUserSettings();
          },
          onTitleFontSizeChanged: (value) {
            setState(() {
              _titleFontSize = value;
            });
            _saveUserSettings();
          },
          onBackgroundColorChanged: (color) {
            setState(() {
              _backgroundColor = color;
            });
            _saveUserSettings();
          },
          onTextColorChanged: (color) {
            setState(() {
              _textColor = color;
            });
            _saveUserSettings();
          },
        ),
      ),
    );
  }

  // 撤回最新章节处理逻辑
  Future<void> _handleRegenerate() async {
    if (_isGenerating || _novelBubbles.isEmpty) return;

    final String chapterToRegenerate = _novelBubbles[0]['title'] ?? "未知章节";
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground.withValues(alpha: 0.9),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          title: Text('确认撤回',
              style: TextStyle(color: Colors.white, fontSize: 16.sp)),
          content: Text('您确定要撤回最新章节 "$chapterToRegenerate" 吗？',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
          actions: <Widget>[
            TextButton(
              child: Text('取消', style: TextStyle(color: Colors.grey[400])),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('确认撤回', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isGenerating = true;
        });

        // 调用撤销章节API
        final response = await _novelService.undoNovelChapter(
            _sessionId, chapterToRegenerate);

        if (response['code'] != 0) {
          throw response['message'] ?? '请求失败';
        }

        // API调用成功后，更新UI和缓存
        final String removedChapterMsgId = _novelBubbles.isNotEmpty ?
            (_novelBubbles[0]['msgId'] as String? ?? '') : '';

        setState(() {
          _novelBubbles.removeAt(0);

          if (widget.novelData.containsKey('chapters') &&
              widget.novelData['chapters'] is List &&
              (widget.novelData['chapters'] as List).isNotEmpty) {
            (widget.novelData['chapters'] as List).removeLast();
          }

          _totalChapters = _chapters.length;

          if (_novelBubbles.isNotEmpty) {
            _currentChapterTitleNotifier.value = _novelBubbles[0]['title'] ?? '上一章';
          } else {
            _currentChapterTitleNotifier.value = '开始创作吧';
          }
          _isGenerating = false;
        });

        // 只在本地模式下删除缓存中的章节
        if (_isLocalMode && removedChapterMsgId.isNotEmpty) {
          try {
            await _messageCacheService.deleteNovelChapter(
              sessionId: _sessionIdInt,
              msgId: removedChapterMsgId,
            );
            debugPrint('[NovelReadingPage] 已从缓存中删除章节: $removedChapterMsgId');
          } catch (e) {
            debugPrint('[NovelReadingPage] 删除缓存章节失败: $e');
          }
        }

        _showSuccessMessage('章节已撤回');
      } catch (e) {
        if (mounted) {
          setState(() {
            _isGenerating = false;
          });
          _showErrorMessage('撤回章节失败: $e');
        }
      }
    }
  }

  // 刷新页面处理逻辑
  Future<void> _handleRefreshPage() async {
    if (_isLoadingHistory || _isGenerating || _isRefreshing) return;

    _refreshRotationController.reset();
    _refreshRotationController.repeat();

    setState(() {
      _isRefreshing = true;
      _showRefreshSuccess = false;
      _currentChapterTitleNotifier.value = "正在刷新...";
    });

    _refreshController.resetNoData();

    _novelBubbles.clear();
    _currentHistoryPage = 1;
    _hasMoreHistory = true;

    try {
      await _loadHistoryMessages();

      if (mounted) {
        _refreshRotationController.stop();

        setState(() {
          _isRefreshing = false;
          _showRefreshSuccess = true;
        });

        _showSuccessMessage('内容已刷新');

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showRefreshSuccess = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _refreshRotationController.stop();

        setState(() {
          _isRefreshing = false;
          _showRefreshSuccess = false;
        });
        _showErrorMessage('刷新失败: $e');
      }
    }
  }

  // 重置对话处理逻辑
  Future<void> _handleResetConversation() async {
    if (_isGenerating) return;

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground.withValues(alpha: 0.9),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          title: Text('确认重置',
              style: TextStyle(color: Colors.white, fontSize: 16.sp)),
          content: Text('您确定要重置所有小说内容吗？此操作将清空本地和已生成的章节，不可撤销。',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
          actions: <Widget>[
            TextButton(
              child: Text('取消', style: TextStyle(color: Colors.grey[400])),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('确认重置', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isGenerating = true;
        });

        // 调用重置会话API
        final response = await _novelService.resetNovelSession(_sessionId);

        if (response['code'] != 0) {
          throw response['message'] ?? '请求失败';
        }

        // API调用成功后，更新UI和缓存
        setState(() {
          _novelBubbles.clear();

          if (widget.novelData.containsKey('chapters') &&
              widget.novelData['chapters'] is List) {
            (widget.novelData['chapters'] as List).clear();
          }
          _totalChapters = 0;
          _currentHistoryPage = 1;
          _hasMoreHistory = true;
          _currentChapterTitleNotifier.value = "开始创作吧";
          _promptController.clear();
          _showPromptInput = false;
          _isGenerating = false;
        });

        // 只在本地模式下清空缓存
        if (_isLocalMode) {
          try {
            await _messageCacheService.clearNovelCache(_sessionIdInt);
            debugPrint('[NovelReadingPage] 已清空小说缓存');
          } catch (e) {
            debugPrint('[NovelReadingPage] 清空缓存失败: $e');
          }
        }

        _refreshController.resetNoData();
        _showSuccessMessage('小说内容已重置');
      } catch (e) {
        if (mounted) {
          setState(() {
            _isGenerating = false;
          });
          _showErrorMessage('重置会话失败: $e');
        }
      }
    }
  }

  // 回到底部处理逻辑
  void _scrollToBottom() {
    if (_novelBubbles.isNotEmpty) {
      _scrollToIndex(0, animate: true); // 在反转列表中，索引0是最新的内容（底部）
    }
  }

  // 添加编辑章节内容的处理方法
  Future<void> _handleEditContent(String msgId, String newContent) async {
    try {
      // 调用API更新内容
      final response = await _novelService.updateMessageContent(
        _sessionId,
        msgId,
        newContent,
      );

      if (response['code'] != 0) {
        throw response['message'] ?? '请求失败';
      }

      // 解析编辑后的内容
      final paragraphs = NovelContentParser.parseContent(newContent);

      // 更新本地数据
      String chapterTitle = '';
      setState(() {
        // 找到对应的气泡并更新
        for (var i = 0; i < _novelBubbles.length; i++) {
          if (_novelBubbles[i]['msgId'] == msgId) {
            _novelBubbles[i]['paragraphs'] = paragraphs;
            chapterTitle = _novelBubbles[i]['title'] ?? '';
            break;
          }
        }

        // 更新章节数据
        for (var i = 0; i < _chapters.length; i++) {
          if (_chapters[i]['msgId'] == msgId) {
            _chapters[i]['content'] = paragraphs;
            break;
          }
        }
      });

      // 只在本地模式下同步编辑后的内容到缓存
      if (_isLocalMode) {
        try {
          final updatedChapter = {
            'msgId': msgId,
            'title': chapterTitle,
            'content': paragraphs,
            'createdAt': DateTime.now().toIso8601String(),
          };

          await _messageCacheService.insertOrUpdateNovelChapters(
            sessionId: _sessionIdInt,
            chapters: [updatedChapter],
          );

          debugPrint('[NovelReadingPage] 已同步编辑后的章节到缓存: $msgId');
        } catch (e) {
          debugPrint('[NovelReadingPage] 同步编辑后章节到缓存失败: $e');
        }
      }

      // 显示成功消息
      _showSuccessMessage('内容已更新');
    } catch (e) {
      _showErrorMessage('更新内容失败: $e');
    }
  }
}
