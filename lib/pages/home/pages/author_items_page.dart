import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:typed_data';
import 'dart:math' as math;
import '../../../services/file_service.dart';
import '../services/home_service.dart';
import 'item_detail_page.dart';
import '../../../widgets/custom_toast.dart';
import '../../../theme/app_theme.dart';
import 'author_followers_page.dart';

class AuthorItemsPage extends StatefulWidget {
  final String authorId;
  final String authorName;

  const AuthorItemsPage({
    super.key,
    required this.authorId,
    required this.authorName,
  });

  @override
  State<AuthorItemsPage> createState() => _AuthorItemsPageState();
}

class _AuthorItemsPageState extends State<AuthorItemsPage> {
  final HomeService _homeService = HomeService();
  final FileService _fileService = FileService();
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isLoadingAuthorInfo = true;
  List<dynamic> _items = [];
  int _page = 1;
  final int _pageSize = 10;

  // 存储作者详细信息
  Map<String, dynamic>? _authorStats;
  Uint8List? _authorAvatar;
  bool _isLoadingAvatar = false;

  // 关注状态 - 默认为未关注，静默更新
  bool _isFollowing = false;
  final bool _isCheckingFollowStatus = false;
  bool _isUpdatingFollowStatus = false;

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
    {'value': 'group_chat_card', 'label': '群聊'},
  ];

  final List<Map<String, String>> _sortOptions = [
    {'value': 'new', 'label': '最新'},
    {'value': 'hot', 'label': '最热'},
    {'value': 'like', 'label': '最多点赞'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAuthorStats(); // 先加载作者信息
    _loadData();
    _checkFollowingStatus(); // 检查关注状态
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 加载作者的详细统计信息
  Future<void> _loadAuthorStats() async {
    setState(() => _isLoadingAuthorInfo = true);

    try {
      final result = await _homeService.getAuthorPublicStats(widget.authorId);

      if (mounted) {
        setState(() {
          _authorStats = result['data'];
          _isLoadingAuthorInfo = false;
        });

        // 加载作者头像
        if (_authorStats != null && _authorStats!['avatar'] != null) {
          _loadAuthorAvatar(_authorStats!['avatar']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAuthorInfo = false);
        CustomToast.show(
          context,
          message: '获取作者信息失败',
          type: ToastType.error,
        );
      }
    }
  }

  // 加载作者头像
  Future<void> _loadAuthorAvatar(String? avatarUri) async {
    if (avatarUri == null || _isLoadingAvatar) {
      return;
    }

    _isLoadingAvatar = true;
    try {
      final result = await _fileService.getFile(avatarUri);
      if (mounted) {
        setState(() {
          _authorAvatar = result.data;
          _isLoadingAvatar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAvatar = false);
      }
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
    await Future.wait([
      _loadAuthorStats(),
      _loadData(),
      _checkFollowingStatus(),
    ]);
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
      final result = await _homeService.getAuthorItems(
        widget.authorId,
        page: _page,
        pageSize: _pageSize,
        keyword: _keyword,
        sortBy: _sortBy,
        types: _selectedType == 'all' ? null : [_selectedType],
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

  // 检查是否已关注该作者
  Future<void> _checkFollowingStatus() async {
    // 不需要设置加载状态，静默检查
    try {
      final bool isFollowing =
          await _homeService.checkAuthorFollowing(widget.authorId);

      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      // 静默处理错误，默认保持未关注状态
    }
  }

  // 切换关注/取消关注
  Future<void> _toggleFollowAuthor() async {
    if (_isUpdatingFollowStatus) return;

    setState(() => _isUpdatingFollowStatus = true);

    try {
      bool success;

      // 切换关注状态
      if (_isFollowing) {
        // 取消关注
        success = await _homeService.unfollowAuthor(widget.authorId);
      } else {
        // 关注
        success = await _homeService.followAuthor(widget.authorId);
      }

      // 如果操作成功，更新状态
      if (success && mounted) {
        setState(() {
          _isFollowing = !_isFollowing;

          // 更新作者统计信息中的粉丝数量
          if (_authorStats != null) {
            int followerCount = _authorStats!['follower_count'] ?? 0;
            _authorStats!['follower_count'] = _isFollowing
                ? followerCount + 1
                : math.max(0, followerCount - 1);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: _isFollowing ? '取消关注失败' : '关注失败',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingFollowStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text('关于 ${widget.authorName}', style: AppTheme.titleStyle),
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
            // 作者信息卡片
            SliverToBoxAdapter(
              child: _buildAuthorInfoCard(),
            ),

            // 搜索栏
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 8.h),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索作品',
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

            // 列表内容标题
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                child: Row(
                  children: [
                    Container(
                      width: 4.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppTheme.primaryGradient,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '作品列表',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 简洁筛选栏
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                child: Row(
                  children: [
                    // 类型筛选
                    Row(
                      children: _typeOptions.map((type) {
                        final isSelected = _selectedType == type['value'];
                        return Padding(
                          padding: EdgeInsets.only(right: 12.w),
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
                            child: Text(
                              type['label']!,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const Spacer(),

                    // 排序方式
                    Row(
                      children: _sortOptions.map((sort) {
                        final isSelected = _sortBy == sort['value'];
                        return Padding(
                          padding: EdgeInsets.only(left: 12.w),
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
                            child: Text(
                              sort['label']!,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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

  // 构建作者信息卡片
  Widget _buildAuthorInfoCard() {
    // 无论是否在加载中，都显示作者基本信息卡片
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.7),
            AppTheme.primaryColor.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 作者基本信息
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // 头像
                _buildAuthorAvatar(),

                SizedBox(width: 16.w),

                // 名称和ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.authorName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'ID: ${widget.authorId}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // 关注按钮
                GestureDetector(
                  onTap: _isUpdatingFollowStatus ? null : _toggleFollowAuthor,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: _isFollowing ? Colors.transparent : Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border:
                          _isFollowing ? Border.all(color: Colors.white) : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isFollowing ? Icons.check : Icons.add,
                          size: 14.sp,
                          color: _isFollowing
                              ? Colors.white
                              : AppTheme.primaryColor,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          _isFollowing ? '已关注' : '关注',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: _isFollowing
                                ? Colors.white
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 作者数据统计 - 完全静默加载，不显示加载指示器
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16.r),
                bottomRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('粉丝', _authorStats?['follower_count'] ?? 0),
                Container(
                  height: 24.h,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem('获赞', _authorStats?['like_count'] ?? 0),
                Container(
                  height: 24.h,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem(
                    '作品',
                    (_authorStats?['character_count'] ?? 0) +
                        (_authorStats?['novel_count'] ?? 0)),
                Container(
                  height: 24.h,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem(
                    '素材',
                    (_authorStats?['world_count'] ?? 0) +
                        (_authorStats?['template_count'] ?? 0) +
                        (_authorStats?['entry_count'] ?? 0)),
              ],
            ),
          ),

          // 移除原有的详细创作数据展示部分
        ],
      ),
    );
  }

  // 构建作者信息骨架屏
  Widget _buildAuthorInfoSkeleton() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Shimmer.fromColors(
        baseColor: AppTheme.cardBackground,
        highlightColor: AppTheme.cardBackground.withOpacity(0.5),
        child: Column(
          children: [
            Row(
              children: [
                // 头像骨架
                Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 用户名骨架
                      Container(
                        height: 20.h,
                        width: 100.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // ID骨架
                      Container(
                        height: 14.h,
                        width: 60.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
                // 关注按钮骨架
                Container(
                  width: 70.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            // 统计数据骨架
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                4,
                (index) => Column(
                  children: [
                    Container(
                      width: 30.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      width: 40.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),
            // 创作数据骨架
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                4,
                (index) => Column(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 50.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
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

  // 构建作者头像
  Widget _buildAuthorAvatar() {
    // 如果有头像数据，尝试显示，但添加错误处理
    if (_authorAvatar != null) {
      return ClipOval(
        child: Image.memory(
          _authorAvatar!,
          width: 60.w,
          height: 60.w,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // 出错时显示默认图标
            return Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white24,
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 34.sp,
                ),
              ),
            );
          },
        ),
      );
    }

    // 默认显示头像图标
    return Container(
      width: 60.w,
      height: 60.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white24,
      ),
      child: Center(
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: 34.sp,
        ),
      ),
    );
  }

  // 构建统计项
  Widget _buildStatItem(String label, int count) {
    String displayCount = count.toString();
    if (count > 999) {
      displayCount = '${(count / 1000).toStringAsFixed(1)}k';
    }

    return GestureDetector(
      onTap: () {
        // 当用户点击粉丝数量时，导航到关注者列表页面
        if (label == '粉丝') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuthorFollowersPage(
                authorId: widget.authorId,
                authorName: widget.authorName,
              ),
            ),
          );
        }
      },
      child: Column(
        children: [
          Text(
            displayCount,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // 构建创作项
  Widget _buildCreationItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '$label $count',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
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
                '暂无作品',
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
