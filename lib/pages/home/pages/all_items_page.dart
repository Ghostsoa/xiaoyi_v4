import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:typed_data';
import '../../../services/file_service.dart';
import '../services/home_service.dart';
import 'item_detail_page.dart';
import '../../../widgets/custom_toast.dart';
import '../../../theme/app_theme.dart';

class AllItemsPage extends StatefulWidget {
  const AllItemsPage({super.key});

  @override
  State<AllItemsPage> createState() => _AllItemsPageState();
}

class _AllItemsPageState extends State<AllItemsPage> {
  final HomeService _homeService = HomeService();
  final FileService _fileService = FileService();
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _items = [];
  List<String> _hotTags = [];
  final List<String> _selectedTags = [];
  int _page = 1;
  final int _pageSize = 20;

  // 图片缓存
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, bool> _loadingImages = {};

  // 筛选条件
  String _selectedType = 'all';
  String _sortBy = 'new';
  String? _keyword;

  final List<Map<String, String>> _typeOptions = [
    {'value': 'all', 'label': '全部'},
    {'value': 'character_card', 'label': '角色'},
    {'value': 'novel_card', 'label': '小说'},
  ];

  final List<Map<String, String>> _sortOptions = [
    {'value': 'new', 'label': '最新'},
    {'value': 'hot', 'label': '最热'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadHotTags();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHotTags() async {
    try {
      final result = await _homeService.getHotTags();
      if (mounted) {
        setState(() {
          _hotTags = List<String>.from(result['data'] ?? []);
        });
      }
    } catch (e) {
      // 标签加载失败不影响主要功能
      debugPrint('加载标签失败: $e');
    }
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
        keyword: _keyword,
        sortBy: _sortBy,
        types: _selectedType == 'all' ? null : [_selectedType],
        tags: _selectedTags.isEmpty ? null : _selectedTags,
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

  void _onSearch(String value) {
    _keyword = value.trim().isEmpty ? null : value.trim();
    _page = 1;
    _refreshController.resetNoData();
    _loadData();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
    _page = 1;
    _refreshController.resetNoData();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text('全部角色', style: AppTheme.titleStyle),
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
          noDataText: "没有更多数据",
          failedText: "加载失败，请重试",
          canLoadingText: "松开加载更多",
        ),
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: CustomScrollView(
          slivers: [
            // 搜索栏
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 8.h),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.cardBackground.withOpacity(0.3),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                  ),
                  onSubmitted: _onSearch,
                  textInputAction: TextInputAction.search,
                ),
              ),
            ),

            // 标签列表
            if (_hotTags.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        '热门标签',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    SizedBox(
                      height: 24.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: _hotTags.length,
                        itemBuilder: (context, index) {
                          final tag = _hotTags[index];
                          final isSelected = _selectedTags.contains(tag);
                          return Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: GestureDetector(
                              onTap: () => _toggleTag(tag),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : AppTheme.border.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: isSelected
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // 筛选栏
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: _typeOptions.map((type) {
                          final isSelected = _selectedType == type['value'];
                          return Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: GestureDetector(
                              onTap: () {
                                if (_selectedType != type['value']) {
                                  setState(() {
                                    _selectedType = type['value']!;
                                  });
                                  _page = 1;
                                  _refreshController.resetNoData();
                                  _loadData();
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : AppTheme.border.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  type['label']!,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: isSelected
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Row(
                      children: _sortOptions.map((sort) {
                        final isSelected = _sortBy == sort['value'];
                        return Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: GestureDetector(
                            onTap: () {
                              if (_sortBy != sort['value']) {
                                setState(() {
                                  _sortBy = sort['value']!;
                                });
                                _page = 1;
                                _refreshController.resetNoData();
                                _loadData();
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.border.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                sort['label']!,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: isSelected
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // 列表内容
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              sliver: _buildListContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent() {
    if (_isLoading && _items.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildShimmerItem(),
          childCount: 5,
        ),
      );
    }

    if (_items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 48.sp,
                color: AppTheme.textSecondary.withOpacity(0.5),
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
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == _items.length) {
            return _buildShimmerItem();
          }
          return _buildListItem(_items[index]);
        },
        childCount: _items.length + (_isLoading ? 1 : 0),
      ),
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
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusXSmall),
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
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusXSmall),
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
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusXSmall),
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
                      color: AppTheme.cardBackground.withOpacity(0.3),
                      child: Icon(
                        Icons.image_rounded,
                        color: AppTheme.textSecondary.withOpacity(0.5),
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
