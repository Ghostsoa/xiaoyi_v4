import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_toast.dart';
import '../character_chat/pages/character_chat_page.dart';
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
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> with WidgetsBindingObserver {
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
      final result = await _messageService.getCharacterSessions(
        page: _currentPage,
        pageSize: 10,
      );

      if (mounted) {
        setState(() {
          _sessions = List<Map<String, dynamic>>.from(result['list']);
          _hasMore = _sessions.length < result['total'];
          _isLoading = false;
        });

        // 预加载头像
        for (var session in _sessions) {
          _loadAvatar(session['coverUri']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _loadMoreSessions() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await _messageService.getCharacterSessions(
        page: _currentPage + 1,
        pageSize: 10,
      );

      if (mounted) {
        final newSessions = List<Map<String, dynamic>>.from(result['list']);
        setState(() {
          _sessions.addAll(newSessions);
          _currentPage++;
          _hasMore = _sessions.length < result['total'];
          _isLoadingMore = false;
        });

        // 预加载新加载的会话的头像
        for (var session in newSessions) {
          _loadAvatar(session['coverUri']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
      if (mounted) {
        setState(() => _avatarCache[coverUri] = result.data);
      }
    } catch (e) {
      debugPrint('加载头像失败: $e');
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
                          _sessions = []; // 清空小说列表
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
                  itemBuilder: (context, index) => _buildSkeletonItem(),
                ),
              )
            else if (!_isCharacterMode)
              Expanded(
                child: Center(
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
                        '小说功能开发中...',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                      ),
                    ],
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
                  child: ListView.builder(
                    itemCount: _sessions.length,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return _buildSessionItem(
                        context,
                        session,
                      );
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
    final String? coverUri = session['coverUri'];
    final bool hasAvatar = coverUri != null &&
        coverUri.isNotEmpty &&
        _avatarCache.containsKey(coverUri);
    final int sessionId = session['id'] as int;
    final bool isSelected = _selectedIds.contains(sessionId);

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
                  characterData: {
                    'name': session['name'],
                    // 其他角色相关数据...
                  },
                ),
              ),
            );
          }
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
                        ),
                      ),
                    )
                  : _buildAvatarSkeleton(session['name']),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          session['name'] ?? '',
                          style: AppTheme.titleStyle.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatTime(session['updatedAt']),
                          style: AppTheme.hintStyle.copyWith(fontSize: 13.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      session['lastMessage'] ?? '开始对话',
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
      final result = await _messageService.getCharacterSessions(
        page: _currentPage,
        pageSize: 10,
      );

      if (mounted) {
        setState(() {
          _sessions = List<Map<String, dynamic>>.from(result['list']);
          _hasMore = _sessions.length < result['total'];
        });

        // 预加载头像
        for (var session in _sessions) {
          _loadAvatar(session['coverUri']);
        }
      }
      _refreshController.refreshCompleted();
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
      final result = await _messageService.getCharacterSessions(
        page: _currentPage + 1,
        pageSize: 10,
      );

      if (mounted) {
        final newSessions = List<Map<String, dynamic>>.from(result['list']);
        setState(() {
          _sessions.addAll(newSessions);
          _currentPage++;
          _hasMore = _sessions.length < result['total'];
        });

        // 预加载新加载的会话的头像
        for (var session in newSessions) {
          _loadAvatar(session['coverUri']);
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
          await _messageService.deleteSession(id);
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
}
