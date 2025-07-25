import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:typed_data';
import '../../../services/file_service.dart';
import '../services/home_service.dart';
import '../../../widgets/custom_toast.dart';
import '../pages/item_detail_page.dart';
import '../../../theme/app_theme.dart';

class RecommendItemsPage extends StatefulWidget {
  const RecommendItemsPage({super.key});

  @override
  State<RecommendItemsPage> createState() => _RecommendItemsPageState();
}

class _RecommendItemsPageState extends State<RecommendItemsPage> {
  final HomeService _homeService = HomeService();
  final FileService _fileService = FileService();
  final RefreshController _refreshController = RefreshController();

  bool _isLoading = true;
  List<dynamic> _items = [];
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
    // 清空图片缓存
    setState(() {
      _imageCache.clear();
    });
    await _loadData();
    _refreshController.refreshCompleted();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final result = await _homeService.getRecommendItems(
        page: 1,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          _items = result['data']['items'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomToast.show(
          context,
          message: '加载失败，请重试',
          type: ToastType.error,
        );
        _refreshController.refreshFailed();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text('每日推荐', style: AppTheme.titleStyle),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        enablePullUp: false,
        header: ClassicHeader(
          idleText: "下拉刷新",
          releaseText: "松开刷新",
          refreshingText: "正在刷新...",
          completeText: "刷新完成",
          failedText: "刷新失败",
        ),
        onRefresh: _onRefresh,
        child: _buildListView(),
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
      itemCount: _isLoading ? 5 : _items.length,
      itemBuilder: (context, index) {
        if (_isLoading) {
          return _buildShimmerItem();
        }
        return _buildListItem(_items[index]);
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

  Widget _buildListItem(Map<String, dynamic> item) {
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
                              '${item['hot_score'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.redAccent,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.favorite_rounded,
                              size: 16.sp,
                              color: AppTheme.textSecondary,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${item['like_count'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.chat_rounded,
                              size: 16.sp,
                              color: AppTheme.textSecondary,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${item['dialog_count'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.textSecondary,
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
                    Text(
                      '@${item['author_name'] ?? '未知'} · $timeAgo',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}
