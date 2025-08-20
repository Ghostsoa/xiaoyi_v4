import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:typed_data';
import '../../../services/file_service.dart';
import '../../home/services/home_service.dart';
import '../../../widgets/custom_toast.dart';
import '../../../theme/app_theme.dart';
import '../../home/pages/author_items_page.dart';

class MyFollowersPage extends StatefulWidget {
  const MyFollowersPage({super.key});

  @override
  State<MyFollowersPage> createState() => _MyFollowersPageState();
}

class _MyFollowersPageState extends State<MyFollowersPage> {
  final HomeService _homeService = HomeService();
  final FileService _fileService = FileService();
  final RefreshController _refreshController = RefreshController();

  bool _isLoading = true;
  List<dynamic> _followers = [];
  final Map<String, dynamic> _followersInfo = {}; // 存储关注者详细信息，key为userId
  int _page = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  // 图片缓存
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, bool> _loadingImages = {};

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  // 加载用户头像
  Future<void> _loadUserAvatar(String? avatarUri) async {
    if (avatarUri == null ||
        avatarUri.isEmpty ||
        _loadingImages[avatarUri] == true ||
        _imageCache.containsKey(avatarUri)) {
      return;
    }

    _loadingImages[avatarUri] = true;
    try {
      final result = await _fileService.getFile(avatarUri);
      if (mounted) {
        setState(() {
          _imageCache[avatarUri] = result.data;
          _loadingImages[avatarUri] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingImages[avatarUri] = false;
        });
      }
    }
  }

  Future<void> _loadFollowers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _hasMore = true;
        _isLoading = true;
      });
    }

    try {
      final result = await _homeService.getMyFollowers(
        page: _page,
        pageSize: _pageSize,
      );

      if (mounted) {
        final List<dynamic> followerIds = result['data']['followers'] ?? [];
        final int total = result['data']['total'] ?? 0;

        setState(() {
          if (_page == 1) {
            _followers = followerIds;
          } else {
            _followers.addAll(followerIds);
          }
          _hasMore = _followers.length < total;
          _isLoading = false;
        });

        // 请求关注者详细信息
        _loadFollowersInfo(followerIds);

        if (refresh) {
          _refreshController.refreshCompleted();
        } else if (!_hasMore) {
          _refreshController.loadNoData();
        } else {
          _refreshController.loadComplete();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (refresh) {
          _refreshController.refreshFailed();
        } else {
          _refreshController.loadFailed();
        }
        CustomToast.show(
          context,
          message: '加载失败，请稍后重试',
        );
      }
    }
  }

  // 实际加载关注者详情
  Future<void> _loadFollowersInfo(List<dynamic> followerIds) async {
    if (followerIds.isEmpty) return;

    try {
      // 将followerIds转换为整数列表
      final List<int> userIds =
          followerIds.map<int>((id) => int.parse(id.toString())).toList();

      // 批量获取用户信息
      final List<dynamic> usersInfo = await _homeService.getUsersBatch(userIds);

      // 更新关注者信息缓存
      if (usersInfo.isNotEmpty) {
        for (var user in usersInfo) {
          final String userId = user['id'].toString();
          _followersInfo[userId] = {
            'id': user['id'],
            'name': user['username'] ?? '未知用户',
            'avatar': user['avatar'],
            'description': user['bio'] ?? '', // 假设API返回的是bio字段
          };

          // 预加载头像
          if (user['avatar'] != null) {
            _loadUserAvatar(user['avatar']);
          }
        }

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('加载关注者信息失败: $e');
    }
  }

  Future<void> _onRefresh() async {
    await _loadFollowers(refresh: true);
  }

  Future<void> _onLoading() async {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return;
    }

    _page++;
    await _loadFollowers();
  }

  Widget _buildUserCard(dynamic userId) {
    // 获取用户信息，如果不存在则使用默认值
    final userInfo = _followersInfo[userId.toString()] ??
        {
          'id': userId,
          'name': '未知用户',
          'avatar': null,
          'description': '',
        };

    final String? avatarUri = userInfo['avatar'];
    final String id = userId.toString();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      elevation: 2,
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          // 点击用户卡片，跳转到用户作品页面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuthorItemsPage(
                authorId: userId.toString(),
                authorName: userInfo['name'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          child: Row(
            children: [
              // 用户头像
              _buildUserAvatar(avatarUri, userInfo['name']),
              SizedBox(width: 16.w),
              // 用户信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userInfo['name'],
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'ID: $id',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    if (userInfo['description'] != null &&
                        userInfo['description'].isNotEmpty)
                      Text(
                        userInfo['description'],
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // 访问按钮
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AuthorItemsPage(
                        authorId: userId.toString(),
                        authorName: userInfo['name'],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppTheme.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 16.sp,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '访问',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建用户头像
  Widget _buildUserAvatar(String? avatarUri, String name) {
    // 如果有缓存的头像图片
    if (avatarUri != null && _imageCache.containsKey(avatarUri)) {
      return ClipOval(
        child: Image.memory(
          _imageCache[avatarUri]!,
          width: 50.w,
          height: 50.w,
          fit: BoxFit.cover,
        ),
      );
    }

    // 如果头像URI存在但还未加载，尝试加载
    if (avatarUri != null && avatarUri.isNotEmpty) {
      // 避免重复加载
      if (_loadingImages[avatarUri] != true) {
        _loadUserAvatar(avatarUri);
      }

      // 显示加载中占位
      return Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ),
      );
    }

    // 无头像时显示首字母
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.7),
            AppTheme.primaryColor.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 60.sp,
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            '暂无粉丝',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '创建并分享优质作品，就会有更多用户关注你',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 16.h),
          Text(
            '加载中...',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text('我的粉丝', style: AppTheme.titleStyle),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _followers.isEmpty
              ? _buildEmptyState()
              : SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  onLoading: _onLoading,
                  enablePullUp: _hasMore,
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
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: _followers.length,
                    itemBuilder: (context, index) {
                      final userId = _followers[index];
                      return _buildUserCard(userId);
                    },
                  ),
                ),
    );
  }
}
