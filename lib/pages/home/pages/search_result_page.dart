import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:typed_data';
import '../../../theme/app_theme.dart';
import '../../../services/file_service.dart';
import '../services/home_service.dart';
import '../widgets/item_skeleton.dart';
import 'item_detail_page.dart';

class SearchResultPage extends StatefulWidget {
  final String keyword;

  const SearchResultPage({
    super.key,
    required this.keyword,
  });

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  final HomeService _homeService = HomeService();
  final FileService _fileService = FileService();
  final RefreshController _refreshController = RefreshController();

  bool _isLoading = true;
  List<dynamic> _searchResults = [];
  int _page = 1;
  final int _pageSize = 20;

  // 图片缓存
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, bool> _loadingImages = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
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
      final result = await _homeService.getAllItems(
        page: _page,
        pageSize: _pageSize,
        keyword: widget.keyword,
        sortBy: 'new',
      );

      if (mounted) {
        setState(() {
          if (_page == 1) {
            _searchResults = result['data']['items'] ?? [];
          } else {
            _searchResults.addAll(result['data']['items'] ?? []);
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
        if (_page == 1) {
          _refreshController.refreshFailed();
        } else {
          _refreshController.loadFailed();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppTheme.textPrimary,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '有关于"${widget.keyword}"',
          style: AppTheme.titleStyle,
        ),
        centerTitle: true,
      ),
      body: SmartRefresher(
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
          noDataText: "没有更多数据了",
          failedText: "加载失败，请重试",
        ),
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: _buildListContent(),
      ),
    );
  }

  Widget _buildListContent() {
    if (_isLoading && _searchResults.isEmpty) {
      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: 10,
        itemBuilder: (context, index) => const ItemSkeleton(),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48.sp,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              '未找到相关内容',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '换个关键词试试吧',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _searchResults.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _searchResults.length) {
          return const ItemSkeleton();
        }
        return _buildListItem(_searchResults[index]);
      },
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
