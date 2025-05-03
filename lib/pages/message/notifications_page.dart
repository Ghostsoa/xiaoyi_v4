import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_toast.dart';
import 'notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  late AnimationController _shimmerController;
  late TabController _tabController;

  List<dynamic> _notifications = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;

  // 筛选状态：null-全部, 0-未读, 1-已读
  int? _currentStatusFilter;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1500));
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadNotifications();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;

    setState(() {
      switch (_tabController.index) {
        case 0:
          _currentStatusFilter = null; // 全部
          break;
        case 1:
          _currentStatusFilter = 0; // 未读
          break;
        case 2:
          _currentStatusFilter = 1; // 已读
          break;
      }
    });

    _loadNotifications();
  }

  // 加载通知列表
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    try {
      final result = await _notificationService.getNotifications(
        status: _currentStatusFilter,
        page: _currentPage,
        pageSize: _pageSize,
      );

      // 处理notifications为null的情况
      final notifications = result['notifications'];
      final List<dynamic> notificationsList =
          notifications != null ? (notifications as List) : [];

      setState(() {
        _notifications = notificationsList;
        _hasMore = notificationsList.length >= _pageSize;
        _isLoading = false;
      });

      _refreshController.refreshCompleted();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _notifications = [];
      });

      _refreshController.refreshFailed();
      _showErrorToast('获取通知失败: $e');
    }
  }

  // 加载更多通知
  Future<void> _loadMoreNotifications() async {
    if (_isLoading || !_hasMore) {
      _refreshController.loadNoData();
      return;
    }

    try {
      final nextPage = _currentPage + 1;
      final result = await _notificationService.getNotifications(
        status: _currentStatusFilter,
        page: nextPage,
        pageSize: _pageSize,
      );

      // 处理notifications为null的情况
      final notifications = result['notifications'];
      final List<dynamic> newNotifications =
          notifications != null ? (notifications as List) : [];

      if (newNotifications.isNotEmpty) {
        setState(() {
          _notifications.addAll(newNotifications);
          _currentPage = nextPage;
          _hasMore = newNotifications.length >= _pageSize;
        });
        _refreshController.loadComplete();
      } else {
        setState(() {
          _hasMore = false;
        });
        _refreshController.loadNoData();
      }
    } catch (e) {
      _refreshController.loadFailed();
      _showErrorToast('加载更多通知失败: $e');
    }
  }

  // 标记通知为已读
  Future<void> _markAsRead(int notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      // 更新本地列表状态
      setState(() {
        final index =
            _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['status'] = 1;
        }
      });
    } catch (e) {
      _showErrorToast('标记已读失败: $e');
    }
  }

  // 标记所有通知为已读
  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();

      // 更新所有未读通知为已读
      setState(() {
        for (int i = 0; i < _notifications.length; i++) {
          if (_notifications[i]['status'] == 0) {
            _notifications[i]['status'] = 1;
          }
        }
      });

      _showSuccessToast('已全部标为已读');
    } catch (e) {
      _showErrorToast('标记全部已读失败: $e');
    }
  }

  // 打开通知链接
  Future<void> _openNotificationLink(String? link) async {
    if (link == null || link.isEmpty) return;

    final Uri uri = Uri.parse(link);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorToast('无法打开链接');
    }
  }

  // 显示成功提示
  void _showSuccessToast(String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.success,
    );
  }

  // 显示错误提示
  void _showErrorToast(String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.error,
    );
  }

  // 构建骨架屏加载效果
  Widget _buildSkeletonLoading() {
    final baseColor = AppTheme.cardBackground;
    final highlightColor = AppTheme.cardBackground.withOpacity(0.5);

    return Container(
      color: AppTheme.background,
      child: ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: 6, // 显示6条骨架项目
        itemBuilder: (context, index) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            margin: EdgeInsets.only(bottom: 8.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.border.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [
                        baseColor,
                        highlightColor,
                        baseColor,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin:
                          Alignment(-1.0 + 2 * _shimmerController.value, 0.0),
                      end: Alignment(1.0 + 2 * _shimmerController.value, 0.0),
                      tileMode: TileMode.clamp,
                    ).createShader(bounds);
                  },
                  child: child!,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题骨架
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 160.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXSmall),
                        ),
                      ),
                      Container(
                        width: 40.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXSmall),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // 类型和时间骨架
                  Row(
                    children: [
                      Container(
                        width: 60.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXSmall),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Container(
                        width: 70.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXSmall),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // 内容骨架
                  Container(
                    width: double.infinity,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusXSmall),
                    ),
                  ),

                  SizedBox(height: 6.h),

                  Container(
                    width: 300.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusXSmall),
                    ),
                  ),

                  SizedBox(height: 6.h),

                  Container(
                    width: 250.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusXSmall),
                    ),
                  ),

                  // 操作按钮骨架（如果是偶数项显示）
                  if (index % 2 == 0) ...[
                    SizedBox(height: 12.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 70.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXSmall),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: false,
        title: Text(
          '我的通知',
          style: AppTheme.titleStyle,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppTheme.textPrimary, size: 20.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 全部已读按钮
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              '全部已读',
              style: AppTheme.linkStyle,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.border.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3.0,
              indicatorSize: TabBarIndicatorSize.label,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.resolveWith<Color>(
                  (states) => Colors.transparent),
              labelStyle: AppTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 15.sp,
              ),
              unselectedLabelStyle: AppTheme.bodyStyle.copyWith(
                fontSize: 14.sp,
              ),
              tabs: const [
                Tab(text: '全部'),
                Tab(text: '未读'),
                Tab(text: '已读'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildSkeletonLoading()
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_none_outlined,
                        size: 64.sp,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '暂无通知',
                        style: AppTheme.secondaryStyle.copyWith(
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                )
              : SmartRefresher(
                  enablePullDown: true,
                  enablePullUp: _hasMore,
                  header: ClassicHeader(
                    refreshStyle: RefreshStyle.Follow,
                    idleText: '下拉刷新',
                    releaseText: '松开刷新',
                    refreshingText: '正在刷新...',
                    completeText: '刷新成功',
                    failedText: '刷新失败',
                    textStyle: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14.sp,
                    ),
                  ),
                  footer: CustomFooter(
                    builder: (context, mode) {
                      Widget body;
                      if (mode == LoadStatus.idle) {
                        body = Text("上拉加载更多",
                            style: TextStyle(color: AppTheme.textSecondary));
                      } else if (mode == LoadStatus.loading) {
                        body = const CircularProgressIndicator.adaptive(
                            strokeWidth: 2);
                      } else if (mode == LoadStatus.failed) {
                        body = Text("加载失败，点击重试",
                            style: TextStyle(color: Colors.red));
                      } else if (mode == LoadStatus.canLoading) {
                        body = Text("松开加载更多",
                            style: TextStyle(color: AppTheme.textSecondary));
                      } else {
                        body = Text("没有更多数据了",
                            style: TextStyle(color: AppTheme.textSecondary));
                      }
                      return SizedBox(
                        height: 55.0,
                        child: Center(child: body),
                      );
                    },
                  ),
                  controller: _refreshController,
                  onRefresh: _loadNotifications,
                  onLoading: _loadMoreNotifications,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.r),
                    itemCount: _notifications.length,
                    cacheExtent: 1000, // 增加缓存范围
                    addAutomaticKeepAlives: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final bool isUnread = notification['status'] == 0;

                      return _buildNotificationItem(
                        notification,
                        isUnread,
                      );
                    },
                  ),
                ),
    );
  }

  // 构建通知项
  Widget _buildNotificationItem(
    Map<String, dynamic> notification,
    bool isUnread,
  ) {
    // 解析通知类型
    String typeLabel = '系统通知';
    Color typeColor = AppTheme.primaryColor;

    switch (notification['type']) {
      case 'system':
        typeLabel = '系统通知';
        typeColor = AppTheme.primaryColor;
        break;
      case 'activity':
        typeLabel = '活动通知';
        typeColor = AppTheme.accentOrange;
        break;
      case 'update':
        typeLabel = '更新通知';
        typeColor = AppTheme.success;
        break;
      case 'reminder':
        typeLabel = '提醒通知';
        typeColor = AppTheme.accentPink;
        break;
      case 'promotion':
        typeLabel = '促销通知';
        typeColor = AppTheme.warning;
        break;
      case 'warning':
        typeLabel = '警告通知';
        typeColor = AppTheme.error;
        break;
    }

    // 解析通知优先级
    int notificationLevel = notification['level'] ?? 0;
    String levelLabel = '';
    Color levelColor = AppTheme.textSecondary;

    switch (notificationLevel) {
      case 1:
        levelLabel = '重要';
        levelColor = AppTheme.warning;
        break;
      case 2:
        levelLabel = '紧急';
        levelColor = AppTheme.error;
        break;
      case 0:
      default:
        levelLabel = '';
        levelColor = AppTheme.textSecondary;
        break;
    }

    // 通知时间格式化
    final DateTime createdAt = DateTime.parse(notification['created_at']);
    final String formattedTime = _formatDateTime(createdAt);

    // 提取链接信息
    final String? link = notification['link'];
    final bool hasLink = link != null && link.isNotEmpty;
    String displayLink = '';

    if (hasLink) {
      try {
        final Uri uri = Uri.parse(link);
        displayLink = uri.host;
      } catch (e) {
        displayLink = link;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.border.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和标签行
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 通知标题
              Expanded(
                child: Text(
                  notification['title'] ?? '通知',
                  style: AppTheme.titleStyle.copyWith(
                    fontSize: 16.sp,
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 优先级标签
              if (levelLabel.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(left: 8.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXSmall),
                  ),
                  child: Text(
                    levelLabel,
                    style: TextStyle(
                      color: levelColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 4.h),

          // 类型和时间
          Row(
            children: [
              Text(
                typeLabel,
                style: TextStyle(
                  color: typeColor,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                formattedTime,
                style: AppTheme.hintStyle,
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // 通知内容
          Text(
            notification['content'] ?? '',
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.textPrimary.withOpacity(0.8),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          // 链接区域
          if (hasLink) ...[
            SizedBox(height: 12.h),
            InkWell(
              onTap: () => _openNotificationLink(link),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link,
                      size: 16.sp,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        '相关链接: $displayLink',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 13.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 已读按钮（只对未读消息显示）
          if (isUnread) ...[
            SizedBox(height: 12.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _markAsRead(notification['id']),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: AppTheme.cardBackground.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXSmall),
                  ),
                ),
                child: Text(
                  '标为已读',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 格式化时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        }
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (dateTime.year == now.year) {
      return '${dateTime.month}月${dateTime.day}日';
    } else {
      return '${dateTime.year}年${dateTime.month}月${dateTime.day}日';
    }
  }
}
