import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:typed_data';
import '../../theme/app_theme.dart';
import '../../services/file_service.dart';
import 'services/home_service.dart';
import 'package:shimmer/shimmer.dart';
import 'pages/hot_items_page.dart';
import 'pages/item_detail_page.dart';
import 'pages/recommend_items_page.dart';
import 'pages/all_items_page.dart';
import 'pages/search_result_page.dart';
import 'pages/tag_items_page.dart';
import 'pages/favorites_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final HomeService _homeService = HomeService();
  final FileService _fileService = FileService();
  final RefreshController _refreshController = RefreshController();

  bool _isLoading = true;
  bool _showAllTags = false;

  List<dynamic> _hotItems = [];
  List<dynamic> _recommendItems = [];
  List<String> _hotTags = [];

  // 图片缓存Map
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, bool> _loadingImages = {};
  bool _forceReload = false; // 是否强制重新加载图片

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

  Future<void> _loadData() async {
    if (!mounted) return;

    if (!_isLoading) {
      setState(() => _isLoading = true);
    }

    try {
      // 并行加载数据
      final results = await Future.wait([
        _homeService.getHotItems(),
        _homeService.getRecommendItems(),
        _homeService.getHotTags(),
      ]);

      if (mounted) {
        setState(() {
          _hotItems = results[0]['data']['items'] ?? [];
          _recommendItems = results[1]['data']['items'] ?? [];
          _hotTags = List<String>.from(results[2]['data'] ?? []);
          _isLoading = false;
        });

        // 预加载所有图片
        for (final item in [..._hotItems, ..._recommendItems]) {
          if (item['cover_uri'] != null) {
            _loadItemImage(item['cover_uri'], forceReload: _forceReload);
          }
        }
        // 重置强制重新加载标志
        _forceReload = false;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // 不显示任何错误提示，用户可以下拉刷新重试
      }
    }
  }

  void _onRefresh() async {
    setState(() {
      _forceReload = true; // 下拉刷新时强制重新加载图片
    });
    try {
      await _loadData();
      if (mounted) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      if (mounted) {
        _refreshController.refreshFailed();
        // 错误通过刷新控制器的状态显示，不额外显示toast
      }
    }
  }

  // 添加refresh方法供外部调用，实现静默刷新
  void refresh() {
    if (mounted) {
      // 静默加载数据，不更新加载状态
      bool originalLoadingState = _isLoading;
      _loadSilently();
    }
  }

  // 静默加载数据，不显示加载状态
  Future<void> _loadSilently() async {
    if (!mounted) return;

    try {
      // 并行加载数据
      final results = await Future.wait([
        _homeService.getHotItems(),
        _homeService.getRecommendItems(),
        _homeService.getHotTags(),
      ]);

      if (mounted) {
        final newHotItems = results[0]['data']['items'] ?? [];
        final newRecommendItems = results[1]['data']['items'] ?? [];
        final newHotTags = List<String>.from(results[2]['data'] ?? []);

        // 检查数据是否发生变化
        bool dataChanged = false;

        if (_hotItems.length != newHotItems.length ||
            _recommendItems.length != newRecommendItems.length ||
            _hotTags.length != newHotTags.length) {
          dataChanged = true;
        }

        // 如果数据发生变化，更新UI
        if (dataChanged) {
          setState(() {
            _hotItems = newHotItems;
            _recommendItems = newRecommendItems;
            _hotTags = newHotTags;
          });

          // 预加载新图片
          for (final item in [...newHotItems, ...newRecommendItems]) {
            if (item['cover_uri'] != null) {
              _loadItemImage(item['cover_uri'], forceReload: false);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('静默刷新数据失败: $e');
      // 静默刷新出错时不显示错误提示
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 固定在顶部的搜索栏
            Container(
              padding: EdgeInsets.all(16.w),
              color: AppTheme.background,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14.sp,
                      ),
                      decoration: InputDecoration(
                        hintText: '搜索',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.textSecondary,
                          size: 20.sp,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onTap: () {
                        FocusScope.of(context).requestFocus();
                      },
                      onTapOutside: (event) {
                        FocusScope.of(context).unfocus();
                      },
                      onFieldSubmitted: (value) {
                        FocusScope.of(context).unfocus();
                        if (value.trim().isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchResultPage(
                                keyword: value.trim(),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 可滚动内容区域
            Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _onRefresh,
                enablePullDown: true,
                header: CustomHeader(
                  builder: (BuildContext context, RefreshStatus? mode) {
                    Widget body;
                    if (mode == RefreshStatus.idle) {
                      body = Text('下拉刷新',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14.sp));
                    } else if (mode == RefreshStatus.refreshing) {
                      body = Shimmer.fromColors(
                        baseColor: Colors.white70,
                        highlightColor: Colors.white,
                        child: Text(
                          '正在刷新...',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      );
                    } else if (mode == RefreshStatus.failed) {
                      body = Text('刷新失败',
                          style:
                              TextStyle(color: Colors.amber, fontSize: 14.sp));
                    } else if (mode == RefreshStatus.canRefresh) {
                      body = Text('松开刷新',
                          style:
                              TextStyle(color: Colors.white, fontSize: 14.sp));
                    } else {
                      body = Text('刷新完成',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14.sp));
                    }
                    return Container(
                      height: 55.0,
                      child: Center(child: body),
                    );
                  },
                ),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 欢迎标语和收藏按钮（同一行）
                    SliverToBoxAdapter(
                      child: Row(
                        children: [
                          // 发现更多AI角色
                          Expanded(
                            flex: 3, // 占据四分之三的空间
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AllItemsPage(),
                                  ),
                                );
                              },
                              child: Container(
                                margin:
                                    EdgeInsets.fromLTRB(16.w, 4.h, 8.w, 16.h),
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: AppTheme.primaryGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    transform: GradientRotation(0.4),
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryGradient.first
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.auto_awesome,
                                              color: AppTheme.primaryColor,
                                              size: 24.sp,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              '发现更多',
                                              style: AppTheme
                                                  .gradientMediumHeadingStyle,
                                            ),
                                          ],
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.white,
                                          size: 24.sp,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      '点击查看全部角色',
                                      style: AppTheme.gradientSubtitleStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // 我的收藏按钮
                          Expanded(
                            flex: 1, // 占据四分之一的空间
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const FavoritesPage(),
                                  ),
                                );
                              },
                              child: Container(
                                margin:
                                    EdgeInsets.fromLTRB(8.w, 4.h, 16.w, 16.h),
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber.shade700,
                                      Colors.amber.shade500
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: Colors.white,
                                      size: 24.sp,
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      '收藏',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 今日热门
                    _buildItemSection(
                      '今日热门',
                      '今日最受欢迎的AI角色',
                      _hotItems,
                      AppTheme.textPrimary,
                      AppTheme.textSecondary,
                      AppTheme.primaryColor,
                    ),

                    // 每日推荐
                    _buildItemSection(
                      '每日推荐',
                      '根据您的兴趣智能推荐的角色',
                      _recommendItems,
                      AppTheme.textPrimary,
                      AppTheme.textSecondary,
                      AppTheme.primaryColor,
                    ),

                    // 热门标签
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tag_rounded,
                                  color: Colors.blueAccent,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '热门标签',
                                  style: AppTheme.gradientTitleStyle,
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '点击标签探索更多相关角色',
                              style: AppTheme.gradientLabelStyle,
                            ),
                            SizedBox(height: 12.h),
                            _isLoading
                                ? _buildTagsSkeleton()
                                : Wrap(
                                    spacing: 8.w,
                                    runSpacing: 8.h,
                                    children: [
                                      ..._hotTags
                                          .take(_showAllTags
                                              ? _hotTags.length
                                              : 8)
                                          .map((tag) => GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          TagItemsPage(
                                                        tag: tag,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12.w,
                                                    vertical: 6.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppTheme.primaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6.r),
                                                  ),
                                                  child: Text(
                                                    '#$tag',
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              )),
                                      if (_hotTags.length > 8)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _showAllTags = !_showAllTags;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12.w,
                                              vertical: 6.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _showAllTags ? '收起' : '更多标签',
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                SizedBox(width: 2.w),
                                                Icon(
                                                  _showAllTags
                                                      ? Icons.keyboard_arrow_up
                                                      : Icons
                                                          .keyboard_arrow_down,
                                                  size: 12.sp,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemSection(
    String title,
    String subtitle,
    List<dynamic> items,
    Color textPrimary,
    Color textSecondary,
    Color primaryColor,
  ) {
    final bool isHotSection = title == '今日热门';
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isHotSection
                              ? Icons.local_fire_department_rounded
                              : Icons.recommend_rounded,
                          color: isHotSection
                              ? Colors.redAccent
                              : Colors.orangeAccent,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          title,
                          style: AppTheme.gradientTextStyle(
                            colors: AppTheme.primaryGradient,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        if (isHotSection) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HotItemsPage(),
                            ),
                          );
                        } else if (title == '每日推荐') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RecommendItemsPage(),
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            '查看全部',
                            style: AppTheme.gradientActionStyle,
                          ),
                          ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                colors: AppTheme.primaryGradient,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds);
                            },
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: AppTheme.gradientTextStyle(
                    colors: [Colors.white60, Colors.white38],
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          _isLoading
              ? _buildItemsSkeleton(isHotSection)
              : items.isEmpty
                  ? _buildEmptyState(title, AppTheme.textSecondary)
                  : SizedBox(
                      height: 180.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.only(left: 12.w),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildItemCard(
                            item,
                            AppTheme.textPrimary,
                            isHotItem: isHotSection,
                            index: index,
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildItemsSkeleton(bool isHotSection) {
    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: 12.w),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            width: 120.w,
            margin: EdgeInsets.only(right: 12.w),
            child: Stack(
              children: [
                // 主卡片
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Shimmer.fromColors(
                    baseColor: AppTheme.cardBackground,
                    highlightColor: AppTheme.cardBackground.withOpacity(0.5),
                    child: Container(
                      width: 120.w,
                      height: 150.w,
                      color: AppTheme.cardBackground,
                    ),
                  ),
                ),
                // 标题渐变遮罩层
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(12.w, 32.h, 12.w, 12.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Shimmer.fromColors(
                      baseColor: AppTheme.cardBackground,
                      highlightColor: AppTheme.cardBackground.withOpacity(0.5),
                      child: Container(
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                  ),
                ),
                // 热门标签
                if (isHotSection && index < 3)
                  Positioned(
                    left: 8.w,
                    top: 8.h,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: [
                          const Color(0xFFFF6B6B),
                          const Color(0xFFFFAB4C),
                          const Color(0xFFFFD93D),
                        ][index]
                            .withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Shimmer.fromColors(
                        baseColor: AppTheme.cardBackground,
                        highlightColor:
                            AppTheme.cardBackground.withOpacity(0.5),
                        child: Container(
                          width: 32.w,
                          height: 12.h,
                          color: AppTheme.cardBackground,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, Color textSecondary) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(vertical: 24.h),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              title == '今日热门'
                  ? Icons.local_fire_department_outlined
                  : Icons.recommend_outlined,
              size: 32.sp,
              color: title == '今日热门'
                  ? Colors.redAccent.withOpacity(0.5)
                  : Colors.orangeAccent.withOpacity(0.5),
            ),
            SizedBox(height: 8.h),
            Text(
              '暂无${title.replaceAll('今日', '').replaceAll('每日', '')}内容',
              style: AppTheme.gradientTextStyle(
                colors: [Colors.white60, Colors.white38],
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, Color textPrimary,
      {bool isHotItem = false, int? index}) {
    final String? coverUri = item['cover_uri'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailPage(item: item),
          ),
        );
      },
      child: Container(
        width: 120.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: coverUri != null
                  ? _buildCoverImage(coverUri, item['title'])
                  : _buildEmptyCover(item['title']),
            ),
            if (isHotItem && index != null && index < 3)
              Positioned(
                left: 8.w,
                top: 8.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: [
                      const Color(0xFFFF6B6B),
                      const Color(0xFFFFAB4C),
                      const Color(0xFFFFD93D),
                    ][index]
                        .withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'TOP ${index + 1}',
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
      ),
    );
  }

  Widget _buildCoverImage(String coverUri, String? title) {
    if (_imageCache.containsKey(coverUri)) {
      return Stack(
        children: [
          Image.memory(
            _imageCache[coverUri]!,
            width: 120.w,
            height: 150.w,
            fit: BoxFit.cover,
          ),
          _buildTitleOverlay(title),
        ],
      );
    }

    if (!_loadingImages[coverUri]!) {
      _loadItemImage(coverUri);
    }

    return Shimmer.fromColors(
      baseColor: AppTheme.cardBackground,
      highlightColor: AppTheme.cardBackground.withOpacity(0.5),
      child: Container(
        width: 120.w,
        height: 150.w,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  Widget _buildEmptyCover(String? title) {
    return Container(
      width: 120.w,
      height: 150.w,
      color: AppTheme.cardBackground,
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.image_outlined,
              color: AppTheme.textSecondary,
            ),
          ),
          _buildTitleOverlay(title, isDark: false),
        ],
      ),
    );
  }

  Widget _buildTitleOverlay(String? title, {bool isDark = true}) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 32.h, 12.w, 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Text(
          title ?? '',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildTagsSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardBackground,
      highlightColor: AppTheme.cardBackground.withOpacity(0.5),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: List.generate(
          8,
          (index) => Container(
            width: 60.w,
            height: 28.h,
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
      ),
    );
  }
}
