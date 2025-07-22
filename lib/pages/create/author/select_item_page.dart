import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:typed_data';
import '../../../services/file_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import '../../home/services/home_service.dart';
import '../../../dao/user_dao.dart';

class SelectItemPage extends StatefulWidget {
  const SelectItemPage({super.key});

  @override
  State<SelectItemPage> createState() => _SelectItemPageState();
}

class _SelectItemPageState extends State<SelectItemPage> {
  final HomeService _homeService = HomeService();
  final FileService _fileService = FileService();
  final UserDao _userDao = UserDao();
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _items = [];
  int _page = 1;
  final int _pageSize = 10;
  String? _authorId;

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
    {'value': 'like', 'label': '最多点赞'},
    {'value': 'dialog', 'label': '最多对话'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userId = await _userDao.getUserId();
      if (userId != null && mounted) {
        setState(() {
          _authorId = userId.toString();
        });
        // 加载用户的作品列表
        _loadData();
      } else {
        CustomToast.show(
          context,
          message: '无法获取用户信息',
          type: ToastType.error,
        );
      }
    } catch (e) {
      CustomToast.show(
        context,
        message: '加载用户信息失败',
        type: ToastType.error,
      );
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
    await _loadData();
    _refreshController.refreshCompleted();
  }

  Future<void> _onLoading() async {
    _page++;
    await _loadData();
    _refreshController.loadComplete();
  }

  Future<void> _loadData() async {
    if (!mounted || _authorId == null) return;

    if (_page == 1) {
      setState(() => _isLoading = true);
    }

    try {
      final result = await _homeService.getAuthorItems(
        _authorId!,
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

  // 选择作品并返回
  void _selectItem(Map<String, dynamic> item) {
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text('选择作品', style: AppTheme.titleStyle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 8.h),
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

          // 筛选栏
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
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

          // 列表内容
          Expanded(
            child: _buildListContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent() {
    if (_isLoading && _items.isEmpty) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemBuilder: (context, index) => _buildShimmerItem(),
        itemCount: 5,
      );
    }

    if (_items.isEmpty) {
      return Center(
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
            SizedBox(height: 8.h),
            Text(
              '请先创建一些作品',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: true,
      header: const ClassicHeader(
        idleText: "下拉刷新",
        releaseText: "松开刷新",
        refreshingText: "正在刷新...",
        completeText: "刷新完成",
        failedText: "刷新失败",
      ),
      footer: const ClassicFooter(
        idleText: "上拉加载更多",
        loadingText: "正在加载...",
        noDataText: "没有更多数据",
        failedText: "加载失败，请重试",
        canLoadingText: "松开加载更多",
      ),
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemBuilder: (context, index) {
          return _buildListItem(_items[index]);
        },
        itemCount: _items.length,
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

    final String itemType = item['item_type'] ?? '';
    final Color typeColor = _getItemTypeColor(itemType);

    return InkWell(
      onTap: () => _selectItem(item),
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
                        // 类型标签
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: typeColor,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            _getItemTypeText(itemType),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
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
                      ],
                    ),
                    if (item['description'] != null)
                      Expanded(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    // 统计信息
                    Row(
                      children: [
                        _buildStatItem(
                            Icons.favorite_rounded, item['like_count'] ?? 0),
                        SizedBox(width: 16.w),
                        _buildStatItem(
                            Icons.chat_rounded, item['dialog_count'] ?? 0),
                        SizedBox(width: 16.w),
                        _buildStatItem(Icons.local_fire_department_rounded,
                            item['hot_score'] ?? 0,
                            isHot: true),
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

  // 构建统计项
  Widget _buildStatItem(IconData icon, num value, {bool isHot = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14.sp,
          color: isHot ? Colors.redAccent : AppTheme.textSecondary,
        ),
        SizedBox(width: 4.w),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 12.sp,
            color: isHot ? Colors.redAccent : AppTheme.textSecondary,
          ),
        ),
      ],
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

  // 获取作品类型文本
  String _getItemTypeText(String type) {
    switch (type) {
      case 'character_card':
        return '角色卡';
      case 'novel_card':
        return '小说卡';
      case 'chat_card':
        return '群聊卡';
      default:
        return '未知类型';
    }
  }

  // 获取作品类型颜色
  Color _getItemTypeColor(String type) {
    switch (type) {
      case 'character_card':
        return const Color(0xFF1E88E5); // 蓝色
      case 'novel_card':
        return const Color(0xFFFF9800); // 橙色
      case 'chat_card':
        return const Color(0xFF4CAF50); // 绿色
      default:
        return Colors.grey;
    }
  }
}
