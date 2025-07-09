import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:developer' as developer;
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_theme.dart';
import '../../../services/file_service.dart';
import '../../../dao/novel_settings_dao.dart';
import '../../../widgets/custom_toast.dart';
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
  final NovelSettingsDao _settingsDao = NovelSettingsDao();
  final ScrollController _scrollController = ScrollController();

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
  String _currentChapterTitleForDisplay = "加载中...";

  // 缓存背景图片
  Uint8List? _cachedBackgroundImage;
  bool _isLoadingBackground = false;

  // 提示输入相关
  final TextEditingController _promptController = TextEditingController();
  bool _showPromptInput = false;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  // AI交互区高度
  double _aiInteractionHeight = 160.0;
  // 添加键盘高度跟踪变量
  double _keyboardHeight = 0.0;
  // 添加键盘可见状态
  bool _isKeyboardVisible = false;

  // 会话ID
  String get _sessionId => (widget.sessionData['id'] ?? '').toString();

  // 章节数据
  List<Map<String, dynamic>> get _chapters =>
      (widget.novelData['chapters'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
    _loadUserSettings();

    // 初始化章节数据
    _totalChapters = _chapters.length;

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

    // 加载历史消息
    _loadHistoryMessages().then((_) {
      if (mounted) {
        setState(() {
          if (_novelBubbles.isNotEmpty) {
            _currentChapterTitleForDisplay =
                _novelBubbles[0]['title'] ?? '章节加载完毕';
          } else {
            _currentChapterTitleForDisplay = '开始创作吧';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
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
    if (_scrollController.position.isScrollingNotifier.value) {
      _hideControls();
      _hideAiInteraction();
    }

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingHistory &&
        _hasMoreHistory) {
      _loadHistoryMessages();
    }

    _updateVisibleChapterTitle();
  }

  // 更新当前可见章节的标题
  void _updateVisibleChapterTitle() {
    if (_novelBubbles.isEmpty || _scrollController.positions.isEmpty) return;

    double scrollOffset = _scrollController.offset;
    double viewportHeight = _scrollController.position.viewportDimension;
    double viewportTop = scrollOffset;
    double viewportBottom = scrollOffset + viewportHeight;

    int centerItemIndex = (_novelBubbles.length *
            scrollOffset /
            _scrollController.position.maxScrollExtent)
        .floor();

    centerItemIndex = centerItemIndex.clamp(0, _novelBubbles.length - 1);

    String newTitle = _novelBubbles[centerItemIndex]['title'] ?? '';
    if (newTitle.isNotEmpty &&
        _currentChapterTitleForDisplay != newTitle &&
        mounted) {
      setState(() {
        _currentChapterTitleForDisplay = newTitle;
      });
    }
  }

  void _hideControls() {
    if (_showControls) {
      setState(() {
        _showControls = false;
      });
    }
  }

  void _hideAiInteraction() {
    if (_showAiInteraction) {
      setState(() {
        _showAiInteraction = false;
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _toggleAiInteraction() {
    setState(() {
      _showAiInteraction = !_showAiInteraction;
    });
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
                              baseColor: AppTheme.primaryColor.withOpacity(0.6),
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
                      child: ListView.builder(
                        reverse: true,
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
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
                          );
                        },
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
              bottom: padding.bottom +
                  12.h +
                  (_showPromptInput && _isKeyboardVisible
                      ? _keyboardHeight
                      : 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return NotificationListener<SizeChangedLayoutNotification>(
                    onNotification: (notification) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final renderBox =
                            context.findRenderObject() as RenderBox?;
                        if (renderBox != null && mounted) {
                          setState(() {
                            _aiInteractionHeight = renderBox.size.height;
                          });
                        }
                      });
                      return true;
                    },
                    child: SizeChangedLayoutNotifier(
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: _backgroundColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: _textColor.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: NovelAiInteractionArea(
                          currentChapterTitle: _currentChapterTitleForDisplay,
                          isInitialMode: isInitialMode,
                          isGenerating: _isGenerating,
                          isRefreshing: _isRefreshing,
                          showRefreshSuccess: _showRefreshSuccess,
                          refreshRotationAnimation: _refreshRotationAnimation,
                          novelBubbles: _novelBubbles,
                          backgroundColor: _backgroundColor,
                          textColor: _textColor,
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
                          showPromptInput: _showPromptInput,
                          promptController: _promptController,
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
        _currentChapterTitleForDisplay = placeholderBubble['title']! as String;
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
            _currentChapterTitleForDisplay = _novelBubbles[0]['title']!;
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
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_novelBubbles.isNotEmpty &&
              _novelBubbles[0]['isGenerating'] == true) {
            _novelBubbles.removeAt(0);
          }
          _isGenerating = false;
          if (mounted && _novelBubbles.isNotEmpty) {
            _currentChapterTitleForDisplay = _novelBubbles[0]['title'] ?? "出错了";
          } else if (mounted) {
            _currentChapterTitleForDisplay = "自动生成章节失败";
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
        _currentChapterTitleForDisplay = placeholderBubble['title']! as String;
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
            _currentChapterTitleForDisplay = _novelBubbles[0]['title']!;
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
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_novelBubbles.isNotEmpty &&
              _novelBubbles[0]['isGenerating'] == true) {
            _novelBubbles.removeAt(0);
          }
          _isGenerating = false;
          if (mounted && _novelBubbles.isNotEmpty) {
            _currentChapterTitleForDisplay = _novelBubbles[0]['title'] ?? "出错了";
          } else if (mounted) {
            _currentChapterTitleForDisplay = "引导生成章节失败";
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

  // 加载历史消息
  Future<void> _loadHistoryMessages() async {
    // 避免重复请求
    if (_isLoadingHistory || !_hasMoreHistory) {
      debugPrint("跳过加载 - 已经在加载: $_isLoadingHistory 或没有更多历史: $_hasMoreHistory");
      return;
    }

    debugPrint("开始加载历史消息，页码: $_currentHistoryPage");
    setState(() => _isLoadingHistory = true);
    List<Map<String, dynamic>> messages = [];

    try {
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
        final content = message['content'] as String;

        // 尝试获取章节标题
        String chapterTitle = message['chapterTitle'] as String? ?? '';

        // 如果没有章节标题，使用默认章节编号
        if (chapterTitle.isEmpty) {
          chapterTitle = NovelContentParser.getDefaultChapterTitle(
              tempChapters.length + 1);
        }

        // 解析内容为段落列表
        final paragraphs = NovelContentParser.parseContent(content);

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
          // 分页加载，将历史章节添加到列表末尾
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
          _currentChapterTitleForDisplay =
              _novelBubbles[0]['title'] ?? '章节加载完毕';
        } else {
          if (_currentHistoryPage == 1 && messages.isEmpty) {
            _currentChapterTitleForDisplay = '开始创作吧';
          } else {
            _currentChapterTitleForDisplay = '没有更多内容了';
          }
        }
      });
    } else if (_currentHistoryPage == 1 && messages.isEmpty) {
      // 首次加载且没有消息
      setState(() {
        _currentChapterTitleForDisplay = '开始创作吧';
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
          backgroundColor: AppTheme.cardBackground.withOpacity(0.9),
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

        setState(() {
          _novelBubbles.removeAt(0);

          if (widget.novelData.containsKey('chapters') &&
              widget.novelData['chapters'] is List &&
              (widget.novelData['chapters'] as List).isNotEmpty) {
            (widget.novelData['chapters'] as List).removeLast();
          }

          _totalChapters = _chapters.length;

          if (_novelBubbles.isNotEmpty) {
            _currentChapterTitleForDisplay = _novelBubbles[0]['title'] ?? '上一章';
          } else {
            _currentChapterTitleForDisplay = '开始创作吧';
          }
          _isGenerating = false;
        });
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
      _currentChapterTitleForDisplay = "正在刷新...";
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
          backgroundColor: AppTheme.cardBackground.withOpacity(0.9),
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

        setState(() {
          _novelBubbles.clear();

          if (widget.novelData.containsKey('chapters') &&
              widget.novelData['chapters'] is List) {
            (widget.novelData['chapters'] as List).clear();
          }
          _totalChapters = 0;
          _currentHistoryPage = 1;
          _hasMoreHistory = true;
          _currentChapterTitleForDisplay = "开始创作吧";
          _promptController.clear();
          _showPromptInput = false;
          _isGenerating = false;
        });
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
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuint,
      );
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
      setState(() {
        // 找到对应的气泡并更新
        for (var i = 0; i < _novelBubbles.length; i++) {
          if (_novelBubbles[i]['msgId'] == msgId) {
            _novelBubbles[i]['paragraphs'] = paragraphs;
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

      // 显示成功消息
      _showSuccessMessage('内容已更新');
    } catch (e) {
      _showErrorMessage('更新内容失败: $e');
    }
  }
}
