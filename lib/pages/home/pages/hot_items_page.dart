import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:typed_data';
import '../../../services/file_service.dart';
import '../services/home_service.dart';
import '../pages/item_detail_page.dart';
import '../../../widgets/custom_toast.dart';
import '../../../theme/app_theme.dart';

class HotItemsPage extends StatefulWidget {
  const HotItemsPage({super.key});

  @override
  State<HotItemsPage> createState() => _HotItemsPageState();
}

class _HotItemsPageState extends State<HotItemsPage> {
  final HomeService _homeService = HomeService();
  final FileService _fileService = FileService();
  final RefreshController _refreshController = RefreshController();

  String _currentPeriod = 'daily';
  bool _isLoading = true;
  List<dynamic> _items = [];
  int _page = 1;
  final int _pageSize = 10;

  // 图片缓存
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, bool> _loadingImages = {};

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadItemImage(String? coverUri,
      {bool forceReload = false}) async {
    if (coverUri == null ||
        _loadingImages[coverUri] == true ||
        (!forceReload && _imageCache.containsKey(coverUri))) {
      return;
    }

    _loadingImages[coverUri] = true;
    try {
      final result = await _fileService.getFile(coverUri);
      if (mounted) {
        setState(() {
          _imageCache[coverUri] = result.data;
          _loadingImages[coverUri] = false;
        });
      }
    } catch (e) {
      _loadingImages[coverUri] = false;
    }
  }

  Future<void> _onRefresh() async {
    _page = 1;
    // 清空图片缓存
    setState(() {
      _imageCache.clear();
    });
    await _loadData();
    _refreshController.refreshCompleted();
  }

  Future<void> _onLoading() async {
    _page++;
    await _loadData();
    _refreshController.loadComplete();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    if (_page == 1) {
      setState(() => _isLoading = true);
    }

    try {
      final result = await _homeService.getHotItems(
        period: _currentPeriod,
        page: _page,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (_page == 1) {
            _items = result['data']['items'] ?? [];
          } else {
            _items.addAll(result['data']['items'] ?? []);
          }
          _isLoading = false;
        });

        final items = result['data']['items'] ?? [];
        if (items.isEmpty) {
          _refreshController.loadNoData();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomToast.show(
          context,
          message: '加载失败，请重试',
          type: ToastType.error,
        );
        if (_page == 1) {
          _refreshController.refreshFailed();
        } else {
          _refreshController.loadFailed();
        }
      }
    }
  }

  void _changePeriod(String period) {
    if (_currentPeriod != period) {
      setState(() {
        _currentPeriod = period;
        _items = [];
        _page = 1;
      });
      _refreshController.resetNoData();
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text('排行榜', style: AppTheme.titleStyle),
        centerTitle: true,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, size: 20.sp),
            tooltip: '此处显示的是周期内热度，非总热度值',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.cardBackground,
                  title: Text('热度说明', style: AppTheme.titleStyle),
                  content: Text(
                    '此榜单显示的是在当前选择周期内（日榜/周榜/月榜）的热度值，而非内容的总热度。\n\n'
                    '热度根据内容在周期内的活跃度动态计算，反映了内容的实时流行程度。',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: Text('了解了',
                          style: TextStyle(color: AppTheme.primaryLight)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
            child: Row(
              children: [
                Expanded(
                  child: _buildPeriodButton('日榜', 'daily'),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildPeriodButton('周榜', 'weekly'),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildPeriodButton('月榜', 'monthly'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SmartRefresher(
              controller: _refreshController,
              enablePullDown: true,
              enablePullUp: true,
              header: ClassicHeader(
                idleText: "下拉刷新",
                releaseText: "松开刷新",
                refreshingText: "正在刷新...",
                completeText: "刷新完成",
                failedText: "刷新失败",
              ),
              footer: ClassicFooter(
                idleText: "上拉加载更多",
                loadingText: "正在加载...",
                noDataText: "没有更多数据",
                failedText: "加载失败，请重试",
                canLoadingText: "松开加载更多",
              ),
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              child: _buildListView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String title, String period) {
    final bool isSelected = _currentPeriod == period;
    final IconData icon = period == 'daily'
        ? Icons.calendar_today_rounded
        : period == 'weekly'
            ? Icons.date_range_rounded
            : Icons.calendar_month_rounded;

    return Container(
      decoration: isSelected ? AppTheme.buttonDecoration : null,
      child: ElevatedButton(
        onPressed: () => _changePeriod(period),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? Colors.transparent
              : AppTheme.cardBackground.withOpacity(0.3),
          foregroundColor: isSelected ? Colors.white : AppTheme.textSecondary,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : AppTheme.border.withOpacity(0.3),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.sp),
            SizedBox(width: 4.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (_items.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 48.sp,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              '暂无内容',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _isLoading && _page == 1
          ? 5 // 显示5个骨架项
          : _items.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoading && _page == 1) {
          return _buildShimmerItem();
        }
        if (index == _items.length) {
          return _buildShimmerItem();
        }
        return _buildListItem(_items[index], index);
      },
    );
  }

  Widget _buildShimmerItem() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: AppTheme.cardBackground,
            highlightColor: AppTheme.cardBackground.withOpacity(0.5),
            child: Container(
              height: 96.h,
              width: 96.h,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: AppTheme.cardBackground,
                  highlightColor: AppTheme.cardBackground.withOpacity(0.5),
                  child: Container(
                    height: 20.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Shimmer.fromColors(
                  baseColor: AppTheme.cardBackground,
                  highlightColor: AppTheme.cardBackground.withOpacity(0.5),
                  child: Container(
                    height: 32.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: List.generate(
                    3,
                    (index) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index < 2 ? 8.w : 0),
                        child: Shimmer.fromColors(
                          baseColor: AppTheme.cardBackground,
                          highlightColor:
                              AppTheme.cardBackground.withOpacity(0.5),
                          child: Container(
                            height: 16.h,
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item, int index) {
    final DateTime createdAt = DateTime.parse(item['created_at']);
    final Duration difference = DateTime.now().difference(createdAt);

    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes}分钟前';
    } else {
      timeAgo = '刚刚';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailPage(item: item),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: item['cover_uri'] != null
                      ? _buildCoverImage(item['cover_uri'])
                      : Container(
                          height: 96.h,
                          width: 96.h,
                          color: AppTheme.cardBackground,
                          child: Icon(
                            Icons.image_rounded,
                            color: AppTheme.textSecondary,
                            size: 32.sp,
                          ),
                        ),
                ),
                if (index < 3)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: index == 0
                              ? [Colors.red, Colors.redAccent]
                              : index == 1
                                  ? [Colors.orange, Colors.deepOrange]
                                  : [Colors.amber, Colors.orange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8.r),
                          bottomRight: Radius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: SizedBox(
                height: 96.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['title'] ?? '',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 16.sp,
                              color: Colors.redAccent,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${item['periodic_hot_score'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (item['description'] != null)
                      SizedBox(
                        height: 38.h,
                        child: Text(
                          item['description'],
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppTheme.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Text(
                      (item['tags'] as List?)
                              ?.map((tag) => '#$tag')
                              .join(' ') ??
                          '',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        // 类型标记
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(item['item_type']),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            _getTypeLabel(item),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // 作者+时间
                        Expanded(
                          child: Text(
                            '@${item['author_name'] ?? '未知'} · $timeAgo',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(String coverUri) {
    if (_imageCache.containsKey(coverUri)) {
      return Image.memory(
        _imageCache[coverUri]!,
        height: 96.h,
        width: 96.h,
        fit: BoxFit.cover,
      );
    }

    if (_loadingImages[coverUri] != true) {
      _loadItemImage(coverUri);
    }

    return Shimmer.fromColors(
      baseColor: AppTheme.cardBackground,
      highlightColor: AppTheme.cardBackground.withOpacity(0.5),
      child: Container(
        height: 96.h,
        width: 96.h,
        color: AppTheme.cardBackground,
      ),
    );
  }

  Color _getTypeColor(String? itemType) {
    switch (itemType) {
      case 'character_card':
        return const Color(0xFF1E88E5); // 更深的蓝色
      case 'novel_card':
        return const Color(0xFFFF9800); // 更暖的橙色
      case 'group_chat_card':
        return const Color(0xFF4CAF50); // 更鲜艳的绿色
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getTypeLabel(Map<String, dynamic> item) {
    switch (item['item_type']) {
      case 'character_card':
        return '角色卡';
      case 'novel_card':
        return '小说';
      case 'group_chat_card':
        // 获取群聊角色数量
        final roleGroup = item['role_group'];
        int roleCount = 0;
        
        if (roleGroup != null) {
          if (roleGroup is List) {
            roleCount = roleGroup.length;
          } else if (roleGroup is Map) {
            // 如果role_group是Map，尝试获取roles字段
            final roles = roleGroup['roles'] as List?;
            roleCount = roles?.length ?? 0;
          }
        }
        
        return '群聊·$roleCount';
      default:
        return '未知';
    }
  }
}
