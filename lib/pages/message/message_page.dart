import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_toast.dart';
import '../character_chat/pages/character_chat_page.dart';
import '../novel/pages/novel_reading_page.dart';
import 'notifications_page.dart';
import 'message_service.dart';
import '../../services/file_service.dart';
import 'dart:typed_data';

class MessagePage extends StatefulWidget {
  final int unreadCount;

  const MessagePage({
    super.key,
    this.unreadCount = 0,
  });

  @override
  State<MessagePage> createState() => MessagePageState();
}

class MessagePageState extends State<MessagePage> with WidgetsBindingObserver {
  final MessageService _messageService = MessageService();
  final FileService _fileService = FileService();
  final RefreshController _refreshController = RefreshController();

  late int _unreadCount;
  bool _isLoading = false;
  List<Map<String, dynamic>> _sessions = [];
  int _currentPage = 1;
  bool _hasMore = true;
  final Map<String, Uint8List> _avatarCache = {};
  bool _isLoadingMore = false;
  bool _isCharacterMode = true;
  bool _isMultiSelectMode = false;
  final Set<int> _selectedIds = <int>{};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _unreadCount = widget.unreadCount;
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _loadSessions();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreSessions();
    }
  }

  Future<void> _loadSessions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _sessions = [];
      _currentPage = 1;
    });

    try {
      final result = _isCharacterMode
          ? await _messageService.getCharacterSessions(
              page: _currentPage,
              pageSize: 10,
            )
          : await _messageService.getNovelSessions(
              page: _currentPage,
              pageSize: 10,
            );

      if (mounted) {
        setState(() {
          if (_isCharacterMode) {
            if (result['list'] is List) {
              _sessions = List<Map<String, dynamic>>.from(result['list']);
            } else {
              _sessions = [];
              debugPrint('获取会话列表返回数据格式错误: $result');
            }
          } else {
            // 处理小说会话列表
            if (result['sessions'] is List) {
              _sessions = List<Map<String, dynamic>>.from(result['sessions']);
            } else {
              _sessions = [];
              debugPrint('获取小说会话列表返回数据格式错误: $result');
            }
          }

          final int total = _isCharacterMode
              ? (result['total'] is int ? result['total'] : 0)
              : (result['total'] is int ? result['total'] : 0);
          _hasMore = _sessions.length < total;
          _isLoading = false;
        });

        // 预加载头像
        for (var session in _sessions) {
          _loadAvatar(session['cover_uri']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _sessions = []; // 确保在错误情况下清空会话列表
        });
        debugPrint('加载会话列表失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载会话列表失败: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadMoreSessions() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = _isCharacterMode
          ? await _messageService.getCharacterSessions(
              page: _currentPage + 1,
              pageSize: 10,
            )
          : await _messageService.getNovelSessions(
              page: _currentPage + 1,
              pageSize: 10,
            );

      if (mounted) {
        List<Map<String, dynamic>> newSessions = [];
        if (_isCharacterMode) {
          if (result['list'] is List) {
            newSessions = List<Map<String, dynamic>>.from(result['list']);
          } else {
            debugPrint('加载更多会话返回数据格式错误: $result');
          }
        } else {
          if (result['sessions'] is List) {
            newSessions = List<Map<String, dynamic>>.from(result['sessions']);
          } else {
            debugPrint('加载更多小说会话返回数据格式错误: $result');
          }
        }

        setState(() {
          _sessions.addAll(newSessions);
          _currentPage++;

          final int total = _isCharacterMode
              ? (result['total'] is int ? result['total'] : 0)
              : (result['total'] is int ? result['total'] : 0);
          _hasMore = _sessions.length < total;
          _isLoadingMore = false;
        });

        // 预加载新加载的会话的头像
        for (var session in newSessions) {
          _loadAvatar(session['cover_uri']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        debugPrint('加载更多会话失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载更多会话失败: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadAvatar(String? coverUri) async {
    if (coverUri == null ||
        coverUri.isEmpty ||
        _avatarCache.containsKey(coverUri)) {
      return;
    }

    try {
      final result = await _fileService.getFile(coverUri);
      if (mounted && result.data != null) {
        final data = result.data;
        if (data is Uint8List) {
          setState(() => _avatarCache[coverUri] = data);
        } else {
          debugPrint('预加载头像数据类型错误: ${data.runtimeType}');
        }
      }
    } catch (e) {
      debugPrint('加载头像失败: $e');
      // 不要在UI上显示这个错误，只是记录日志
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final dateTime = DateTime.parse(timeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return '刚刚';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}分钟前';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}小时前';
      } else if (difference.inDays < 30) {
        return '${difference.inDays}天前';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months个月前';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years年前';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏带有按钮
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 6.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '消息',
                    style: AppTheme.headingStyle,
                  ),
                  Row(
                    children: [
                      if (!_isMultiSelectMode) ...[
                        _buildIconButton(
                          icon: Icons.notifications_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsPage(),
                              ),
                            );
                          },
                          showBadge: _unreadCount > 0,
                          badgeCount: _unreadCount,
                        ),
                        SizedBox(width: 8.w),
                        _buildIconButton(
                          icon: Icons.delete_outline,
                          onTap: () {
                            setState(() {
                              _isMultiSelectMode = true;
                              _selectedIds.clear();
                            });
                          },
                        ),
                      ] else ...[
                        TextButton(
                          onPressed: _deleteSelectedSessions,
                          child: Text(
                            '删除',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isMultiSelectMode = false;
                              _selectedIds.clear();
                            });
                          },
                          child: Text(
                            '取消',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 添加分类切换按钮
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 8.h),
              child: Row(
                children: [
                  _buildCategoryButton(
                    title: '角色',
                    isSelected: _isCharacterMode,
                    onTap: () {
                      if (!_isCharacterMode) {
                        setState(() {
                          _isCharacterMode = true;
                          _loadSessions();
                        });
                      }
                    },
                  ),
                  SizedBox(width: 8.w),
                  _buildCategoryButton(
                    title: '小说',
                    isSelected: !_isCharacterMode,
                    onTap: () {
                      if (_isCharacterMode) {
                        setState(() {
                          _isCharacterMode = false;
                          _loadSessions(); // 切换时加载小说会话列表
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 16.h),
              child: Text(
                '最近的对话',
                style: AppTheme.secondaryStyle,
              ),
            ),

            if (_isLoading && _sessions.isEmpty)
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: 10, // 显示10个骨架项
                  itemBuilder: (context, index) => _isCharacterMode
                      ? _buildSkeletonItem()
                      : _buildNovelSkeletonItem(),
                ),
              )
            else if (!_isCharacterMode)
              Expanded(
                child: _sessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 48.sp,
                              color: AppTheme.textSecondary.withOpacity(0.3),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              '暂无小说',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppTheme.textSecondary.withOpacity(0.5),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '开始创作您的第一本小说吧',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.textSecondary.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SmartRefresher(
                        controller: _refreshController,
                        enablePullDown: true,
                        enablePullUp: true,
                        header: const ClassicHeader(
                          idleText: '下拉刷新',
                          refreshingText: '正在刷新',
                          completeText: '刷新完成',
                          failedText: '刷新失败',
                          releaseText: '释放刷新',
                        ),
                        footer: const ClassicFooter(
                          idleText: '上拉加载更多',
                          loadingText: '正在加载',
                          noDataText: '没有更多数据',
                          failedText: '加载失败',
                          canLoadingText: '释放加载更多',
                        ),
                        onRefresh: _onRefresh,
                        onLoading: _onLoading,
                        child: ListView.builder(
                          controller: _scrollController,
                          key: const PageStorageKey('novel_list'),
                          itemCount: _sessions.length,
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          itemBuilder: (context, index) {
                            try {
                              final session = _sessions[index];
                              return _buildNovelSessionItem(
                                context,
                                session,
                              );
                            } catch (e) {
                              debugPrint('构建小说项失败 index=$index: $e');
                              return SizedBox(
                                height: 60.h,
                                child: Center(
                                  child: Text(
                                    '加载失败',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
              )
            else
              Expanded(
                child: SmartRefresher(
                  controller: _refreshController,
                  enablePullDown: true,
                  enablePullUp: true,
                  header: const ClassicHeader(
                    idleText: '下拉刷新',
                    refreshingText: '正在刷新',
                    completeText: '刷新完成',
                    failedText: '刷新失败',
                    releaseText: '释放刷新',
                  ),
                  footer: const ClassicFooter(
                    idleText: '上拉加载更多',
                    loadingText: '正在加载',
                    noDataText: '没有更多数据',
                    failedText: '加载失败',
                    canLoadingText: '释放加载更多',
                  ),
                  onRefresh: _onRefresh,
                  onLoading: _onLoading,
                  child: _sessions.isEmpty
                      ? _buildEmptyView()
                      : ListView.builder(
                          key: const PageStorageKey('message_list'),
                          itemCount: _sessions.length,
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          itemBuilder: (context, index) {
                            try {
                              final session = _sessions[index];
                              return _buildSessionItem(
                                context,
                                session,
                              );
                            } catch (e) {
                              debugPrint('构建消息项失败 index=$index: $e');
                              // 返回空白占位元素，避免整个列表崩溃
                              return SizedBox(
                                height: 60.h,
                                child: Center(
                                  child: Text(
                                    '加载失败',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Shimmer.fromColors(
        baseColor: AppTheme.cardBackground,
        highlightColor: AppTheme.cardBackground.withOpacity(0.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 头像骨架
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cardBackground,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 名字骨架
                  Container(
                    width: 100.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      color: AppTheme.cardBackground,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // 消息骨架
                  Container(
                    width: 200.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      color: AppTheme.cardBackground,
                    ),
                  ),
                ],
              ),
            ),
            // 时间骨架
            Container(
              width: 40.w,
              height: 12.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.r),
                color: AppTheme.cardBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(
    BuildContext context,
    Map<String, dynamic> session,
  ) {
    // 添加防御性编程，确保 session 有效
    if (session.isEmpty) {
      return SizedBox.shrink();
    }

    // 安全获取 sessionId，防止类型转换错误
    final int sessionId;
    try {
      sessionId = session['id'] as int;
    } catch (e) {
      debugPrint('获取会话 ID 失败: $e');
      return SizedBox.shrink(); // 如果无法获取ID，不显示此项
    }

    final String? coverUri = session['cover_uri'];
    final bool hasAvatar = coverUri != null &&
        coverUri.isNotEmpty &&
        _avatarCache.containsKey(coverUri);
    final bool isSelected = _selectedIds.contains(sessionId);

    // 防止可能导致渲染错误的情况
    String sessionName = '';
    try {
      sessionName = session['name'] ?? '未命名会话';
    } catch (e) {
      sessionName = '未命名会话';
    }

    String lastMessage = '';
    try {
      lastMessage = session['last_message'] ?? '开始对话';
    } catch (e) {
      lastMessage = '开始对话';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: InkWell(
        onTap: () {
          if (_isMultiSelectMode) {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(sessionId);
              } else {
                _selectedIds.add(sessionId);
              }
            });
          } else {
            // 跳转到聊天页面
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CharacterChatPage(
                  sessionData: session,
                  characterData: session,  // 直接使用session数据而不是创建新对象
                ),
              ),
            );
          }
        },
        onLongPress: _isMultiSelectMode
            ? null
            : () {
                // 修复类型转换错误，使用全局位置显示菜单
                _showSessionMenu(context, session);
              },
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        splashColor: Colors.transparent,
        highlightColor: Colors.white.withOpacity(0.05),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isMultiSelectMode) ...[
                Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected ? AppTheme.primaryColor : Colors.white38,
                        width: 2,
                      ),
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 16.sp,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ],
              // 头像
              if (coverUri != null && coverUri.isNotEmpty)
                hasAvatar
                    ? Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.memory(
                            _avatarCache[coverUri]!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // 图片加载错误时显示占位符
                              return _buildAvatarPlaceholder(sessionName);
                            },
                          ),
                        ),
                      )
                    : FutureBuilder(
                        future: _fileService.getFile(coverUri),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            // 在获取数据后立即更新缓存
                            if (!_avatarCache.containsKey(coverUri)) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  try {
                                    final data = snapshot.data!.data;
                                    if (data is Uint8List) {
                                      setState(() {
                                        _avatarCache[coverUri] = data;
                                      });
                                    } else {
                                      debugPrint(
                                          '头像数据不是Uint8List类型: ${data.runtimeType}');
                                    }
                                  } catch (e) {
                                    debugPrint('缓存头像失败: $e');
                                  }
                                }
                              });
                            }

                            try {
                              final data = snapshot.data!.data;
                              if (data is Uint8List) {
                                return Container(
                                  width: 40.w,
                                  height: 40.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: Image.memory(
                                      data,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        // 图片加载错误时显示占位符
                                        return _buildAvatarPlaceholder(
                                            sessionName);
                                      },
                                    ),
                                  ),
                                );
                              } else {
                                debugPrint('头像数据类型错误: ${data.runtimeType}');
                                return _buildAvatarPlaceholder(sessionName);
                              }
                            } catch (e) {
                              debugPrint('渲染头像失败: $e');
                              return _buildAvatarPlaceholder(sessionName);
                            }
                          }
                          return _buildAvatarSkeleton(sessionName);
                        },
                      )
              else
                _buildAvatarSkeleton(sessionName),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            sessionName,
                            style: AppTheme.titleStyle.copyWith(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Text(
                          _formatTime(_safeGet(session, 'updated_at', '')),
                          style: AppTheme.hintStyle.copyWith(fontSize: 13.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      lastMessage,
                      style: AppTheme.secondaryStyle.copyWith(fontSize: 14.sp),
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
    );
  }

  // 添加安全获取Map值的辅助方法
  T _safeGet<T>(Map<String, dynamic>? map, String key, T defaultValue) {
    if (map == null) return defaultValue;
    try {
      final value = map[key];
      if (value == null) return defaultValue;
      if (value is T) return value;
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  // 添加头像占位符方法
  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.cardBackground,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1) : '?',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSkeleton(String? name) {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardBackground,
      highlightColor: AppTheme.cardBackground.withOpacity(0.5),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.cardBackground,
        ),
        child: name != null
            ? Center(
                child: Text(
                  name.substring(0, 1),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppTheme.cardBackground.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Icon(
                icon,
                color: AppTheme.textPrimary,
                size: 20.sp,
              ),
            ),
          ),
          if (showBadge)
            Positioned(
              right: -4.w,
              top: -4.h,
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                ),
                constraints: BoxConstraints(
                  minWidth: 16.w,
                  minHeight: 16.w,
                ),
                child: Center(
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: AppTheme.buttonGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: const GradientRotation(0.4),
                )
              : null,
          color: isSelected ? null : AppTheme.cardBackground.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.buttonGradient.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.border.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    _currentPage = 1;
    try {
      final result = _isCharacterMode
          ? await _messageService.getCharacterSessions(
              page: _currentPage,
              pageSize: 10,
            )
          : await _messageService.getNovelSessions(
              page: _currentPage,
              pageSize: 10,
            );

      if (mounted) {
        setState(() {
          if (_isCharacterMode) {
            if (result['list'] is List) {
              _sessions = List<Map<String, dynamic>>.from(result['list']);
            } else {
              _sessions = [];
              debugPrint('刷新会话列表返回数据格式错误: $result');
            }
          } else {
            if (result['sessions'] is List) {
              _sessions = List<Map<String, dynamic>>.from(result['sessions']);
            } else {
              _sessions = [];
              debugPrint('刷新小说会话列表返回数据格式错误: $result');
            }
          }

          final int total = _isCharacterMode
              ? (result['total'] is int ? result['total'] : 0)
              : (result['total'] is int ? result['total'] : 0);
          _hasMore = _sessions.length < total;
        });

        // 预加载头像
        for (var session in _sessions) {
          _loadAvatar(session['cover_uri']);
        }
      }
      _refreshController.refreshCompleted();

      // 重置RefreshController的加载状态，确保可以继续上拉加载
      if (_hasMore) {
        _refreshController.loadComplete();
      }
    } catch (e) {
      _refreshController.refreshFailed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _onLoading() async {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return;
    }

    try {
      final result = _isCharacterMode
          ? await _messageService.getCharacterSessions(
              page: _currentPage + 1,
              pageSize: 10,
            )
          : await _messageService.getNovelSessions(
              page: _currentPage + 1,
              pageSize: 10,
            );

      if (mounted) {
        List<Map<String, dynamic>> newSessions = [];

        if (_isCharacterMode) {
          if (result['list'] is List) {
            newSessions = List<Map<String, dynamic>>.from(result['list']);
          } else {
            debugPrint('加载更多会话返回数据格式错误: $result');
          }
        } else {
          if (result['sessions'] is List) {
            newSessions = List<Map<String, dynamic>>.from(result['sessions']);
          } else {
            debugPrint('加载更多小说会话返回数据格式错误: $result');
          }
        }

        if (newSessions.isNotEmpty) {
          setState(() {
            _sessions.addAll(newSessions);
            _currentPage++;

            final int total = _isCharacterMode
                ? (result['total'] is int ? result['total'] : 0)
                : (result['total'] is int ? result['total'] : 0);
            _hasMore = _sessions.length < total;
          });

          // 预加载新加载的会话的头像
          for (var session in newSessions) {
            _loadAvatar(session['cover_uri']);
          }
        }

        if (_hasMore) {
          _refreshController.loadComplete();
        } else {
          _refreshController.loadNoData();
        }
      }
    } catch (e) {
      _refreshController.loadFailed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _deleteSelectedSessions() async {
    if (_selectedIds.isEmpty) return;

    // 显示删除中的提示
    CustomToast.show(
      context,
      message: '正在删除...',
      type: ToastType.info,
      duration: const Duration(seconds: 10), // 设置较长时间，后面会手动关闭
    );

    try {
      setState(() => _isLoading = true);

      // 一一删除选中的会话
      for (final id in _selectedIds) {
        try {
          if (_isCharacterMode) {
            await _messageService.deleteSession(id);
          } else {
            await _messageService.deleteNovelSession(id);
          }
        } catch (e) {
          debugPrint('删除会话失败: $e');
        }
      }

      // 重新加载列表
      await _onRefresh();

      // 退出多选模式
      setState(() {
        _isMultiSelectMode = false;
        _selectedIds.clear();
      });

      // 关闭删除中提示
      CustomToast.dismiss();

      if (mounted) {
        CustomToast.show(
          context,
          message: '删除成功',
          type: ToastType.success,
        );
      }
    } catch (e) {
      // 关闭删除中提示
      CustomToast.dismiss();

      if (mounted) {
        CustomToast.show(
          context,
          message: '删除失败: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 添加refresh方法供外部调用
  void refresh() {
    if (mounted) {
      _onRefresh();
    }
  }

  // 添加空列表视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48.sp,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            '暂无对话',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '快去探索角色，开始有趣的对话吧',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondary.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNovelSessionItem(
    BuildContext context,
    Map<String, dynamic> session,
  ) {
    // 添加防御性编程，确保 session 有效
    if (session.isEmpty) {
      return SizedBox.shrink();
    }

    // 安全获取 sessionId，防止类型转换错误
    final int sessionId;
    try {
      sessionId = session['id'] as int;
    } catch (e) {
      debugPrint('获取小说会话 ID 失败: $e');
      return SizedBox.shrink(); // 如果无法获取ID，不显示此项
    }

    final String? coverUri = session['cover_uri'];
    final bool hasAvatar = coverUri != null &&
        coverUri.isNotEmpty &&
        _avatarCache.containsKey(coverUri);
    final bool isSelected = _selectedIds.contains(sessionId);

    // 防止可能导致渲染错误的情况
    String title = '';
    try {
      title = session['title'] ?? '未命名小说';
    } catch (e) {
      title = '未命名小说';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: InkWell(
        onTap: () {
          if (_isMultiSelectMode) {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(sessionId);
              } else {
                _selectedIds.add(sessionId);
              }
            });
          } else {
            // 创建安全的小说数据
            final Map<String, dynamic> safeNovelData = {
              'title': title,
              'id': sessionId,
              'cover_uri': coverUri,
            };

            // 跳转到小说阅读页面
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NovelReadingPage(
                  sessionData: session,
                  novelData: safeNovelData,
                ),
              ),
            );
          }
        },
        onLongPress: _isMultiSelectMode
            ? null
            : () {
                // 修复类型转换错误，使用全局位置显示菜单
                _showSessionMenu(context, session);
              },
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        splashColor: Colors.transparent,
        highlightColor: Colors.white.withOpacity(0.05),
        child: Container(
          height: 60.h, // 保持与角色会话项相同的高度
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            color: AppTheme.cardBackground.withOpacity(0.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // 背景图
              Positioned.fill(
                child: coverUri != null && coverUri.isNotEmpty
                    ? hasAvatar
                        ? Image.memory(
                            _avatarCache[coverUri]!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppTheme.cardBackground,
                              );
                            },
                          )
                        : FutureBuilder(
                            future: _fileService.getFile(coverUri),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                // 在获取数据后立即更新缓存
                                if (!_avatarCache.containsKey(coverUri)) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted) {
                                      try {
                                        final data = snapshot.data!.data;
                                        if (data is Uint8List) {
                                          setState(() {
                                            _avatarCache[coverUri] = data;
                                          });
                                        }
                                      } catch (e) {
                                        debugPrint('缓存封面失败: $e');
                                      }
                                    }
                                  });
                                }

                                try {
                                  final data = snapshot.data!.data;
                                  if (data is Uint8List) {
                                    return Image.memory(
                                      data,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: AppTheme.cardBackground,
                                        );
                                      },
                                    );
                                  } else {
                                    return Container(
                                      color: AppTheme.cardBackground,
                                    );
                                  }
                                } catch (e) {
                                  return Container(
                                    color: AppTheme.cardBackground,
                                  );
                                }
                              }
                              return Shimmer.fromColors(
                                baseColor: AppTheme.cardBackground,
                                highlightColor:
                                    AppTheme.cardBackground.withOpacity(0.5),
                                child: Container(
                                  color: AppTheme.cardBackground,
                                ),
                              );
                            },
                          )
                    : Container(
                        color: AppTheme.cardBackground,
                      ),
              ),
              // 黑色渐变蒙层，确保文字可见
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),
              // 多选模式下的选择圆圈
              if (_isMultiSelectMode)
                Positioned(
                  left: 12.w,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected ? AppTheme.primaryColor : Colors.white,
                          width: 2,
                        ),
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 16.sp,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              // 内容区域
              Positioned(
                left: _isMultiSelectMode ? 48.w : 16.w,
                right: 16.w,
                bottom: 8.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题和时间
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 3.0,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Text(
                          _formatTime(_safeGet(session, 'updated_at', '')),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white.withOpacity(0.8),
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2.0,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // 标签
                    if (session['tags'] is List &&
                        (session['tags'] as List).isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: Wrap(
                          spacing: 6.w,
                          runSpacing: 4.h,
                          children: (session['tags'] as List)
                              .take(2) // 最多显示2个标签
                              .map((tag) => Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      tag.toString(),
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNovelSkeletonItem() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Shimmer.fromColors(
        baseColor: AppTheme.cardBackground,
        highlightColor: AppTheme.cardBackground.withOpacity(0.5),
        child: Container(
          height: 60.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            color: AppTheme.cardBackground,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 标题骨架
                    Container(
                      width: 120.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    // 时间骨架
                    Container(
                      width: 40.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                // 标签骨架
                Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      width: 40.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 显示会话长按菜单
  void _showSessionMenu(BuildContext context, Map<String, dynamic> session,
      [Offset? position]) {
    final int sessionId = session['id'] as int;
    final String sessionName = _isCharacterMode
        ? (session['name'] ?? '未命名会话')
        : (session['title'] ?? '未命名小说');

    // 如果没有提供位置，则在屏幕中心显示
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect positionRect = position != null
        ? RelativeRect.fromRect(
            Rect.fromPoints(position, position),
            Offset.zero & overlay.size,
          )
        : RelativeRect.fromLTRB(overlay.size.width / 3, overlay.size.height / 3,
            overlay.size.width / 3, overlay.size.height / 3);

    showMenu(
      context: context,
      position: positionRect,
      // 设置更紧凑的内边距
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      constraints: BoxConstraints(
        minWidth: 120.w,
        maxWidth: 180.w,
      ),
      items: [
        PopupMenuItem(
          value: 'rename',
          // 减小内边距
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          height: 40.h,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_outlined,
                size: 16.sp,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 8.w),
              Text(
                '重命名',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          height: 40.h,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline,
                size: 16.sp,
                color: Colors.red,
              ),
              SizedBox(width: 8.w),
              Text(
                '删除',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'rename') {
        _showRenameDialog(sessionId, sessionName);
      } else if (value == 'delete') {
        _showDeleteConfirmDialog(sessionId);
      }
    });
  }

  // 显示重命名对话框
  void _showRenameDialog(int sessionId, String currentName) {
    final TextEditingController controller =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Text(
            '重命名',
            style: AppTheme.titleStyle,
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: '请输入新名称',
              hintStyle:
                  TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '取消',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  _renameSession(sessionId, newName);
                }
                Navigator.of(context).pop();
              },
              child: Text(
                '确定',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  // 重命名会话
  Future<void> _renameSession(int sessionId, String newName) async {
    try {
      setState(() => _isLoading = true);

      final result = _isCharacterMode
          ? await _messageService.renameSession(sessionId, newName)
          : await _messageService.renameNovelSession(sessionId, newName);

      if (result['success'] == true) {
        CustomToast.show(context, message: '重命名成功', type: ToastType.success);
        _onRefresh(); // 刷新列表
      } else {
        CustomToast.show(context,
            message: result['msg'] ?? '重命名失败', type: ToastType.error);
      }
    } catch (e) {
      CustomToast.show(context, message: '重命名失败: $e', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 显示删除确认对话框
  void _showDeleteConfirmDialog(int sessionId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Text(
            '确认删除',
            style: AppTheme.titleStyle,
          ),
          content: Text(
            '确定要删除这个会话吗？此操作不可恢复。',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '取消',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSingleSession(sessionId);
              },
              child: Text(
                '删除',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // 删除单个会话
  Future<void> _deleteSingleSession(int sessionId) async {
    try {
      // 显示删除中的提示
      CustomToast.show(
        context,
        message: '正在删除...',
        type: ToastType.info,
        duration: const Duration(seconds: 3),
      );

      setState(() => _isLoading = true);

      if (_isCharacterMode) {
        await _messageService.deleteSession(sessionId);
      } else {
        await _messageService.deleteNovelSession(sessionId);
      }

      // 重新加载列表
      await _onRefresh();

      if (mounted) {
        CustomToast.show(
          context,
          message: '删除成功',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '删除失败: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
