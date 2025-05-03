import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/file_service.dart';
import '../../../theme/app_theme.dart';
import '../../../dao/chat_settings_dao.dart';
import 'dart:typed_data';
import '../services/character_chat_stream_service.dart';
import '../services/character_service.dart';
import '../models/sse_response.dart';
import '../widgets/chat_bubble.dart';
import 'character_panel_page.dart';
import 'chat_settings_page.dart';
import '../../../widgets/custom_toast.dart';

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
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // 聊天设置
  double _backgroundOpacity = 0.5;
  bool _enableMarkdown = true;
  Color _bubbleColor = Colors.white;
  double _bubbleOpacity = 0.8;
  Color _textColor = Colors.black;
  Color _userBubbleColor = AppTheme.primaryColor;
  double _userBubbleOpacity = 0.8;
  Color _userTextColor = Colors.white;

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
  static const int _pageSize = 20;

  // 当前正在接收的消息
  String _currentMessage = '';

  // 添加token计数
  int _totalTokens = 0;

  // 添加一个变量用于控制流的终止
  bool _shouldStopStream = false;

  // 添加刷新按钮动画控制器
  late AnimationController _refreshAnimationController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBackgroundImage();
    _loadMessageHistory();

    // 初始化菜单动画控制器
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _menuHeightAnimation = Tween<double>(
      begin: 0,
      end: 100,
    ).animate(CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeInOut,
    ));

    _menuAnimationController.addListener(() => setState(() {}));
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
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsDao.getAllSettings();
    setState(() {
      _backgroundOpacity = settings['backgroundOpacity'];
      _enableMarkdown = settings['markdownEnabled'];
      _bubbleColor = _hexToColor(settings['bubbleColor']);
      _bubbleOpacity = settings['bubbleOpacity'];
      _textColor = _hexToColor(settings['textColor']);
      _userBubbleColor = _hexToColor(settings['userBubbleColor']);
      _userBubbleOpacity = settings['userBubbleOpacity'];
      _userTextColor = _hexToColor(settings['userTextColor']);
    });
  }

  Color _hexToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
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

      if (isLoadMore && messageList.isNotEmpty) {
        // 记录当前滚动位置
        final double currentScrollPosition = _scrollController.position.pixels;
        final double maxScrollExtent =
            _scrollController.position.maxScrollExtent;

        // 将新消息一个个添加到列表顶部
        for (var i = messageList.length - 1; i >= 0; i--) {
          if (!mounted) break;

          final msg = messageList[i];
          setState(() {
            _messages.insert(0, {
              'content': msg['content'] ?? '',
              'isUser': msg['role'] == 'user',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'tokenCount': msg['tokenCount'] ?? 0,
              'opacity': 1.0,
              'messageId': msg['id'],
            });
          });
        }

        // 保持滚动位置
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final double newMaxScrollExtent =
              _scrollController.position.maxScrollExtent;
          final double newPosition =
              newMaxScrollExtent - (maxScrollExtent - currentScrollPosition);
          _scrollController.jumpTo(newPosition);
        });
      } else if (!isLoadMore) {
        // 首次加载时，先将所有消息添加但设置透明度为0
        final newMessages = messageList.reversed
            .map((msg) => {
                  'content': msg['content'] ?? '',
                  'isUser': msg['role'] == 'user',
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                  'tokenCount': msg['tokenCount'] ?? 0,
                  'opacity': 0.0, // 初始设置为透明
                  'messageId': msg['id'],
                })
            .toList();

        setState(() {
          _messages.clear();
          _messages.addAll(newMessages);
        });

        // 等待一帧以确保消息列表已经渲染
        await Future.delayed(const Duration(milliseconds: 50));

        // 将所有消息的透明度逐渐设置为1，创造落下的效果
        if (mounted) {
          setState(() {
            for (var msg in _messages) {
              msg['opacity'] = 1.0;
            }
          });
        }

        // 滚动到底部
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }

      setState(() {
        _totalPages = pagination['total_pages'] ?? 1;
        _totalTokens = messageList.fold<int>(
            0, (sum, msg) => sum + ((msg['tokenCount'] ?? 0) as int));
      });
    } catch (e) {
      debugPrint('加载消息历史失败: $e');
    } finally {
      setState(() => _isLoadingHistory = false);
    }
  }

  void _onScroll() {
    // 当滚动到顶部附近时，加载更多历史消息
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent + 50 &&
        _currentPage < _totalPages &&
        !_isLoadingHistory) {
      _currentPage++;
      _loadMessageHistory(isLoadMore: true);
    }
  }

  Future<void> _loadBackgroundImage() async {
    if (widget.sessionData['backgroundUri'] == null ||
        _isLoadingBackground ||
        _backgroundImage != null) {
      return;
    }

    _isLoadingBackground = true;
    try {
      final result =
          await _fileService.getFile(widget.sessionData['backgroundUri']);
      if (mounted) {
        setState(() {
          _backgroundImage = result.data;
          _isLoadingBackground = false;
        });
      }
    } catch (e) {
      debugPrint('背景图加载失败: $e');
      if (mounted) {
        setState(() => _isLoadingBackground = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _handleSendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    // 添加用户消息
    setState(() {
      _messages.add({
        'content': message,
        'isUser': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'messageId': null,
      });
      _isSending = true;
      _currentMessage = '';
      _shouldStopStream = false;
    });

    // 清空输入框并收起键盘
    _messageController.clear();
    FocusScope.of(context).unfocus();
    _scrollToBottom();

    try {
      // 添加一个AI消息占位
      setState(() {
        _messages.add({
          'content': '',
          'isUser': false,
          'isLoading': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'messageId': null,
        });
      });
      _scrollToBottom();

      // 订阅消息流
      await for (final SseResponse response in _chatService.sendMessage(
        widget.sessionData['id'],
        message,
      )) {
        if (!mounted || _shouldStopStream) break;

        setState(() {
          if (response.isMessage) {
            _currentMessage += response.content ?? '';
            _messages.last['content'] = _currentMessage;
            _messages.last['isLoading'] = false;
            _messages.last['status'] = response.status;
            if (response.messageId != null) {
              _messages.last['messageId'] = response.messageId;
            }
          } else if (response.isTokens) {
            _totalTokens += response.tokens ?? 0;
            debugPrint('当前总Token数: $_totalTokens');
          } else if (response.isDone) {
            _messages.last['status'] = 'done';
            _messages.last['isLoading'] = false;
          } else if (response.isError) {
            // 删除最后两条消息（用户消息和AI回复）
            _messages.removeLast();
            final userMessage = _messages.removeLast();
            // 将用户消息放回输入框
            _messageController.text = userMessage['content'];
            // 将光标移到文本末尾
            _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: _messageController.text.length),
            );
            // 显示提示
            CustomToast.show(
              context,
              message: '模型正忙，请稍后再试',
              type: ToastType.warning,
            );
          }
        });
        _scrollToBottom();
      }

      if (_shouldStopStream) {
        setState(() {
          _messages.last['content'] += '\n[已终止生成]';
          _messages.last['status'] = 'done';
          _messages.last['isLoading'] = false;
        });
      }
    } catch (e) {
      debugPrint('发送消息错误: $e');
      if (mounted) {
        setState(() {
          _messages.last['content'] = e.toString();
          _messages.last['isLoading'] = false;
          _messages.last['isError'] = true;
          _messages.last['status'] = 'error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _shouldStopStream = false;
        });
        _scrollToBottom();
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
              child: Text(
                '确定',
                style: TextStyle(color: Colors.red),
              ),
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
          _totalTokens = 0;
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

          final newMessages = messageList.reversed
              .map((msg) => {
                    'content': msg['content'] ?? '',
                    'isUser': msg['role'] == 'user',
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                    'tokenCount': msg['tokenCount'] ?? 0,
                    'opacity': 1.0,
                    'messageId': msg['id'],
                  })
              .toList();

          setState(() {
            _messages.clear();
            _messages.addAll(newMessages);
            _totalPages = pagination['total_pages'] ?? 1;
            _totalTokens = messageList.fold<int>(
                0, (sum, msg) => sum + ((msg['tokenCount'] ?? 0) as int));
          });

          // 显示成功提示
          CustomToast.show(
            context,
            message: '对话已重置',
            type: ToastType.success,
          );
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
        CustomToast.show(
          context,
          message: '重置失败: $e',
          type: ToastType.error,
        );
      }
    }
  }

  // 添加撤回最后一条消息的方法
  Future<void> _handleUndoLastMessage() async {
    if (_messages.isEmpty) return;

    try {
      // 调用撤回接口
      await _characterService.revokeLastMessage(widget.sessionData['id']);

      // 如果最后一条是AI的回复，需要同时删除用户的提问
      if (!_messages.last['isUser']) {
        setState(() {
          _messages.removeLast(); // 删除AI回复
          if (_messages.isNotEmpty && _messages.last['isUser']) {
            _messages.removeLast(); // 删除用户提问
          }
        });
      } else {
        setState(() {
          _messages.removeLast(); // 只删除用户消息
        });
      }
    } catch (e) {
      debugPrint('撤回消息失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('撤回失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 添加消息编辑处理方法
  Future<void> _handleMessageEdit(int messageId, String newContent) async {
    try {
      await _characterService.updateMessage(
        widget.sessionData['id'],
        messageId,
        newContent,
      );

      // 更新本地消息
      setState(() {
        final index =
            _messages.indexWhere((msg) => msg['messageId'] == messageId);
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
          final pagination = result['pagination'] ?? {};

          final newMessages = messageList.reversed
              .map((msg) => {
                    'content': msg['content'] ?? '',
                    'isUser': msg['role'] == 'user',
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                    'tokenCount': msg['tokenCount'] ?? 0,
                    'opacity': 1.0,
                    'messageId': msg['id'],
                  })
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
              _messages.addAll(
                newMessages.sublist(_messages.length),
              );
            });
          }

          // 更新总页数和token计数
          setState(() {
            _totalPages = pagination['total_pages'] ?? 1;
            _totalTokens = messageList.fold<int>(
                0, (sum, msg) => sum + ((msg['tokenCount'] ?? 0) as int));
          });

          // 如果有新消息，滚动到底部
          if (hasNewMessages) {
            _scrollToBottom();
          }
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
            Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: 24.sp,
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    final status = message['status'] as String?;
    final isError = message['isError'] == true;
    final opacity = message['opacity'] ?? 1.0;
    final isUser = message['isUser'] as bool;
    final messageId = message['messageId'] as int?;

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 200),
      child: ChatBubble(
        message: message['content'],
        isUser: isUser,
        isLoading: message['isLoading'] ?? false,
        isError: isError,
        status: status,
        bubbleColor: isUser ? _userBubbleColor : _bubbleColor,
        bubbleOpacity: isUser ? _userBubbleOpacity : _bubbleOpacity,
        textColor: isUser ? _userTextColor : _textColor,
        enableMarkdown: _enableMarkdown,
        messageId: messageId,
        onEdit: !isUser && messageId != null ? _handleMessageEdit : null,
      ),
    );
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
          if (_backgroundImage != null)
            Image.memory(
              _backgroundImage!,
              fit: BoxFit.cover,
            ),
          Container(
            color: Colors.black.withOpacity(_backgroundOpacity),
          ),
          Column(
            children: [
              SizedBox(height: padding.top),
              // 自定义顶部栏
              Container(
                height: 56.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    // 返回按钮
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(18.r),
                        child: Container(
                          width: 36.w,
                          height: 36.w,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20.sp,
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
                    // 右侧按钮（可选）
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

                                  // 直接用服务器返回的数据替换当前消息列表
                                  final newMessages = messageList.reversed
                                      .map((msg) => {
                                            'content': msg['content'] ?? '',
                                            'isUser': msg['role'] == 'user',
                                            'timestamp': DateTime.now()
                                                .millisecondsSinceEpoch,
                                            'tokenCount':
                                                msg['tokenCount'] ?? 0,
                                            'opacity': 1.0,
                                            'messageId': msg['id'],
                                          })
                                      .toList();

                                  setState(() {
                                    _messages.clear();
                                    _messages.addAll(newMessages);
                                    _totalPages =
                                        pagination['total_pages'] ?? 1;
                                    _totalTokens = messageList.fold<int>(
                                        0,
                                        (sum, msg) =>
                                            sum +
                                            ((msg['tokenCount'] ?? 0) as int));
                                    _currentPage = 1;
                                  });

                                  // 滚动到底部
                                  _scrollToBottom();
                                } catch (e) {
                                  debugPrint('刷新消息失败: $e');
                                  if (mounted) {
                                    CustomToast.show(
                                      context,
                                      message: '刷新失败，请重试',
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
                                            Colors.white),
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
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    top: 16.h,
                    bottom: 16.h +
                        (viewInsets.bottom > 0 ? viewInsets.bottom : 0) +
                        80.h,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageItem(message);
                  },
                ),
              ),
            ],
          ),
          // 将底部输入框改为Positioned定位
          Positioned(
            left: 0,
            right: 0,
            bottom: viewInsets.bottom,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0),
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.3),
                  ],
                  stops: const [0, 0.1, 1],
                ),
              ),
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
                        crossAxisCount: 3,
                        padding: EdgeInsets.only(
                          top: 8.h,
                          bottom: viewInsets.bottom > 0 ? 8.h : padding.bottom,
                        ),
                        mainAxisSpacing: 4.h,
                        crossAxisSpacing: 8.w,
                        childAspectRatio: 1.5,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildExpandedFunctionButton(
                            icon: Icons.person_outline,
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
                            icon: Icons.settings_outlined,
                            label: '设置',
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
                            icon: Icons.delete_outline,
                            label: '清空对话',
                            onTap: _handleResetSession,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
