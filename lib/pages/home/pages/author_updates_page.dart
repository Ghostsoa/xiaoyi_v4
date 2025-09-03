import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import '../services/home_service.dart';
import 'item_detail_page.dart';
import 'author_items_page.dart';
import 'dart:typed_data';
import '../../../services/file_service.dart';

class AuthorUpdatesPage extends StatefulWidget {
  const AuthorUpdatesPage({super.key});

  @override
  State<AuthorUpdatesPage> createState() => _AuthorUpdatesPageState();
}

class _AuthorUpdatesPageState extends State<AuthorUpdatesPage> {
  // 当前选中的标签（0=作品推送，1=关注列表）
  int _currentTab = 0;

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
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _buildCustomTabs(),
      ),
      body: _currentTab == 0
          ? const _AuthorUpdatesTab()
          : const _FollowingAuthorsTab(),
    );
  }

  // 自定义标签按钮
  Widget _buildCustomTabs() {
    return Container(
      height: 38.h,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          // 更新通知按钮
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentTab = 0;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: _currentTab == 0
                      ? LinearGradient(
                          colors: AppTheme.primaryGradient,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: _currentTab == 0 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  '作品推送',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight:
                        _currentTab == 0 ? FontWeight.bold : FontWeight.normal,
                    color: _currentTab == 0
                        ? Colors.white
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          // 已关注按钮
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentTab = 1;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: _currentTab == 1
                      ? LinearGradient(
                          colors: AppTheme.primaryGradient,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: _currentTab == 1 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  '关注列表',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight:
                        _currentTab == 1 ? FontWeight.bold : FontWeight.normal,
                    color: _currentTab == 1
                        ? Colors.white
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 作者更新通知页面
class _AuthorUpdatesTab extends StatefulWidget {
  const _AuthorUpdatesTab();

  @override
  _AuthorUpdatesTabState createState() => _AuthorUpdatesTabState();
}

class _AuthorUpdatesTabState extends State<_AuthorUpdatesTab> {
  final HomeService _homeService = HomeService();
  final FileService _fileService = FileService();
  final RefreshController _refreshController = RefreshController();

  // 添加标签切换
  int _currentSubTab = 0; // 0 = 未读通知, 1 = 全部通知

  bool _isLoading = true;
  List<dynamic> _updates = []; // 未读通知
  List<dynamic> _allUpdates = []; // 全部通知
  int _page = 1;
  int _allPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _hasMoreAll = true;

  // 图片缓存
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, bool> _loadingImages = {};

  // 作品详情缓存
  final Map<String, Map<String, dynamic>> _itemDetailsCache = {};
  final Map<String, bool> _loadingItemDetails = {};

  // 记录不存在的作品ID，避免重复请求
  final Set<String> _nonExistentItems = <String>{};

  // 展开状态管理
  final Set<String> _expandedDescriptions = {};
  final Set<String> _expandedItems = {};

  // 最大显示行数
  final int _maxDescLines = 2;

  // 新增：格式化时间显示
  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '未知时间';

    try {
      final DateTime createdAt = DateTime.parse(dateTimeStr);
      final Duration difference = DateTime.now().difference(createdAt);

      if (difference.inDays > 0) {
        return '${difference.inDays}天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return '未知时间';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  // 加载初始数据并决定显示哪个标签
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // 先获取未读通知
      final result = await _homeService.getUnreadAuthorUpdates(
        page: 1,
        pageSize: _pageSize,
      );

      if (mounted) {
        final List<dynamic> unreadUpdates = result['data']['updates'] ?? [];
        final int total = result['data']['total'] ?? 0;

        setState(() {
          _updates = unreadUpdates;
          _hasMore = _updates.length < total;
        });

        // 判断是否有未读通知，如果没有则默认显示全部通知
        if (unreadUpdates.isEmpty) {
          setState(() {
            _currentSubTab = 1; // 切换到全部通知标签
          });
          await _loadAllUpdates(refresh: true);
        }

        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomToast.show(
          context,
          message: '加载失败，请稍后重试',
        );
      }
    }
  }

  // 加载作品详情
  Future<void> _loadItemDetail(String itemId) async {
    // 如果已经在加载或已加载或已知不存在，则跳过
    if (_loadingItemDetails[itemId] == true ||
        _itemDetailsCache.containsKey(itemId) ||
        _nonExistentItems.contains(itemId)) {
      return;
    }

    _loadingItemDetails[itemId] = true;

    try {
      final details = await _homeService.getItemDetail(itemId);

      if (mounted) {
        setState(() {
          _itemDetailsCache[itemId] = details;
          _loadingItemDetails[itemId] = false;
        });

        // 如果有封面图，预加载
        if (details['cover_uri'] != null) {
          _loadItemImage(details['cover_uri']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingItemDetails[itemId] = false;
          // 记录不存在的作品，防止重复请求
          if (e.toString().contains('record not found')) {
            _nonExistentItems.add(itemId);
          }
        });
        debugPrint('加载作品详情失败: $e');
      }
    }
  }

  // 加载图片
  Future<void> _loadItemImage(String? imageUri) async {
    if (imageUri == null ||
        _loadingImages[imageUri] == true ||
        _imageCache.containsKey(imageUri)) {
      return;
    }

    _loadingImages[imageUri] = true;
    try {
      final result = await _fileService.getFile(imageUri);
      if (mounted) {
        setState(() {
          _imageCache[imageUri] = result.data;
          _loadingImages[imageUri] = false;
        });
      }
    } catch (e) {
      _loadingImages[imageUri] = false;
    }
  }

  Future<void> _loadUpdates({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _hasMore = true;
        _isLoading = true;
      });
    }

    try {
      final result = await _homeService.getUnreadAuthorUpdates(
        page: _page,
        pageSize: _pageSize,
      );

      if (mounted) {
        final List<dynamic> newUpdates = result['data']['updates'] ?? [];
        final int total = result['data']['total'] ?? 0;

        setState(() {
          if (_page == 1) {
            _updates = newUpdates;
          } else {
            _updates.addAll(newUpdates);
          }
          _hasMore = _updates.length < total;
          _isLoading = false;
        });

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

  // 加载全部通知
  Future<void> _loadAllUpdates({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _allPage = 1;
        _hasMoreAll = true;
        if (_currentSubTab == 1) _isLoading = true;
      });
    }

    try {
      final result = await _homeService.getAuthorUpdates(
        page: _allPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        final List<dynamic> newUpdates = result['data']['updates'] ?? [];
        final int total = result['data']['total'] ?? 0;

        setState(() {
          if (_allPage == 1) {
            _allUpdates = newUpdates;
          } else {
            _allUpdates.addAll(newUpdates);
          }
          _hasMoreAll = _allUpdates.length < total;
          if (_currentSubTab == 1) _isLoading = false;
        });

        if (refresh) {
          _refreshController.refreshCompleted();
        } else if (!_hasMoreAll) {
          _refreshController.loadNoData();
        } else {
          _refreshController.loadComplete();
        }
      }
    } catch (e) {
      if (mounted) {
        if (_currentSubTab == 1) setState(() => _isLoading = false);
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

  Future<void> _onRefresh() async {
    if (_currentSubTab == 0) {
      await _loadUpdates(refresh: true);
    } else {
      await _loadAllUpdates(refresh: true);
    }
  }

  Future<void> _onLoading() async {
    if (_currentSubTab == 0) {
      if (!_hasMore) {
        _refreshController.loadNoData();
        return;
      }
      _page++;
      await _loadUpdates();
    } else {
      if (!_hasMoreAll) {
        _refreshController.loadNoData();
        return;
      }
      _allPage++;
      await _loadAllUpdates();
    }
  }

  // 切换描述的展开状态
  void _toggleDescriptionExpanded(String updateId) {
    setState(() {
      if (_expandedDescriptions.contains(updateId)) {
        _expandedDescriptions.remove(updateId);
      } else {
        _expandedDescriptions.add(updateId);
      }
    });
  }

  // 切换作品详情的展开状态
  void _toggleItemExpanded(String updateId) {
    setState(() {
      if (_expandedItems.contains(updateId)) {
        _expandedItems.remove(updateId);
      } else {
        _expandedItems.add(updateId);

        // 当展开时，加载作品详情
        // 从更新列表中找到对应的item_id
        List<dynamic> activeUpdates =
            _currentSubTab == 0 ? _updates : _allUpdates;
        for (var update in activeUpdates) {
          if (update['id']?.toString() == updateId &&
              update['item_id'] != null) {
            String itemId = update['item_id'].toString();
            // 如果作品详情未加载且不是已知不存在的，则加载
            if (!_itemDetailsCache.containsKey(itemId) &&
                !_nonExistentItems.contains(itemId) &&
                _loadingItemDetails[itemId] != true) {
              _loadItemDetail(itemId);
            }

            // 移除自动标记已读逻辑
            // if (_currentSubTab == 0) {
            //   _markAsRead(update['author_id']?.toString() ?? '');
            // }

            break;
          }
        }
      }
    });
  }

  // 添加一键已读方法
  Future<void> _markAllAsRead() async {
    // 检查是否有未读通知
    if (_updates.isEmpty) {
      CustomToast.show(
        context,
        message: '暂无未读消息',
      );
      return;
    }

    try {
      // 获取第一条通知的作者ID
      final String authorId = _updates.first['author_id']?.toString() ?? '';
      if (authorId.isEmpty) {
        CustomToast.show(
          context,
          message: '标记已读失败，作者ID无效',
          type: ToastType.error,
        );
        return;
      }

      // 调用标记已读API
      final success = await _homeService.markAuthorUpdatesAsRead(authorId);

      if (success && mounted) {
        // 成功标记已读后，清空未读列表
        setState(() {
          _updates = [];
        });

        CustomToast.show(
          context,
          message: '已全部标记为已读',
          type: ToastType.success,
        );
      } else {
        CustomToast.show(
          context,
          message: '标记已读失败，请稍后重试',
          type: ToastType.error,
        );
      }
    } catch (e) {
      CustomToast.show(
        context,
        message: '标记已读失败: ${e.toString()}',
        type: ToastType.error,
      );
    }
  }

  Widget _buildUpdateItem(Map<String, dynamic> update) {
    final String updateId = update['id'].toString();
    final bool isDescExpanded = _expandedDescriptions.contains(updateId);
    final bool isItemExpanded = _expandedItems.contains(updateId);
    final String updateType = update['update_type'] ?? '';
    final bool isSystemPush = update['is_system_push'] == true;
    final String? authorName = update['author_name'];
    final String? itemId = update['item_id']?.toString();
    final bool isItemNonExistent =
        itemId != null && _nonExistentItems.contains(itemId);
    final String? description = update['description'];

    // 图标和颜色处理
    IconData typeIcon;
    Color typeColor;

    // 根据更新类型设置图标和颜色
    switch (updateType) {
      case 'new':
        typeIcon = Icons.fiber_new_rounded;
        typeColor = Colors.green;
        break;
      case 'update':
        typeIcon = Icons.update_rounded;
        typeColor = Colors.blue;
        break;
      default:
        typeIcon = Icons.notifications_rounded;
        typeColor = Colors.purple;
    }

    // 获取作品详情
    final Map<String, dynamic>? itemDetails =
        itemId != null ? _itemDetailsCache[itemId] : null;
    final bool isLoadingDetails =
        itemId != null && _loadingItemDetails[itemId] == true;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      elevation: 0,
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 通知头部和内容
          InkWell(
            onTap: () {
              // 点击整个通知卡片时切换作品详情展开状态
              _toggleItemExpanded(updateId);
            },
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 通知头部：类型图标、标题和作者信息
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 更新类型图标
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          typeIcon,
                          color: typeColor,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),

                      // 标题和作者信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 通知标题
                            Text(
                              update['title'] ?? '',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            SizedBox(height: 4.h),

                            // 时间和系统推送标记/作者名
                            Row(
                              children: [
                                // 显示时间
                                Text(
                                  _formatTime(update['created_at']),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                SizedBox(width: 8.w),

                                // 系统推送标记或作者名
                                if (isSystemPush)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6.w, vertical: 1.h),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      '系统',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                else if (authorName != null &&
                                    authorName.isNotEmpty)
                                  Text(
                                    '@$authorName',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 通知描述内容
                  if (description != null) ...[
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: () => _toggleDescriptionExpanded(updateId),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: isDescExpanded ? null : _maxDescLines,
                              overflow:
                                  isDescExpanded ? null : TextOverflow.ellipsis,
                            ),
                            if (description.length > 50) ...[
                              SizedBox(height: 4.h),
                              Text(
                                isDescExpanded ? '收起' : '展开',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  // 提示用户点击查看作品详情
                  if (itemId != null && !isItemExpanded) ...[
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: () => _toggleItemExpanded(updateId),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            vertical: 6.h, horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app_rounded,
                              size: 14.sp,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '点击查看相关作品详情',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 作品详情预览（可折叠）
          if (itemId != null)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild:
                  _buildItemPreview(itemId, itemDetails, isLoadingDetails),
              crossFadeState: isItemExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
        ],
      ),
    );
  }

  // 构建作品预览
  Widget _buildItemPreview(
      String itemId, Map<String, dynamic>? itemDetails, bool isLoading) {
    // 检查作品是否已被标记为不存在
    if (_nonExistentItems.contains(itemId)) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withOpacity(0.5),
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1.h,
            ),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.orange,
                size: 24.sp,
              ),
              SizedBox(height: 8.h),
              Text(
                '作品可能已被删除',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withOpacity(0.5),
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1.h,
            ),
          ),
        ),
        child: Center(
          child: Shimmer.fromColors(
            baseColor: AppTheme.textSecondary.withOpacity(0.3),
            highlightColor: AppTheme.textSecondary.withOpacity(0.6),
            child: Text(
              '正在加载相关作品...',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    if (itemDetails == null) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withOpacity(0.5),
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1.h,
            ),
          ),
        ),
        child: Center(
          child: Text(
            '作品详情不可用',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }

    final String? coverUri = itemDetails['cover_uri'];
    final String itemTitle = itemDetails['title'] ?? '未命名';
    final String itemType = _getItemTypeText(itemDetails['item_type'] ?? '');
    final String? itemDescription = itemDetails['description'];
    final List<dynamic> tags = itemDetails['tags'] ?? [];

    return InkWell(
      onTap: () {
        // 点击跳转到作品详情页
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailPage(item: itemDetails),
          ),
        );
        // 移除自动标记已读逻辑
        // .then((_) {
        //   // 返回后，如果是未读通知，标记为已读
        //   if (_currentSubTab == 0) {
        //     final String authorId = itemDetails['author_id']?.toString() ?? '';
        //     if (authorId.isNotEmpty) {
        //       _markAsRead(authorId);
        //     }
        //   }
        // });
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withOpacity(0.5),
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1.h,
            ),
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 封面图片
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: coverUri != null
                      ? _buildCoverImage(coverUri)
                      : Container(
                          width: 80.w,
                          height: 80.w,
                          color: Colors.grey.withOpacity(0.2),
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: Colors.grey,
                            size: 24.sp,
                          ),
                        ),
                ),
                SizedBox(width: 12.w),

                // 作品信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      Text(
                        itemTitle,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),

                      // 作者和类型标签放在同一行
                      Row(
                        children: [
                          // 作者名
                          Text(
                            '@${itemDetails['author_name'] ?? '未知作者'}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(width: 8.w),

                          // 类型标签
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: _getItemTypeColor(
                                  itemDetails['item_type'] ?? ''),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              itemType,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),

                      // 数据指标
                      Row(
                        children: [
                          _buildStat(Icons.favorite_rounded,
                              itemDetails['like_count'] ?? 0),
                          SizedBox(width: 12.w),
                          _buildStat(Icons.chat_rounded,
                              itemDetails['dialog_count'] ?? 0),
                          SizedBox(width: 12.w),
                          _buildStat(Icons.local_fire_department_rounded,
                              itemDetails['hot_score'] ?? 0,
                              isHot: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 描述（如果有）
            if (itemDescription != null) ...[
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  itemDescription,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // 标签（如果有）
            if (tags.isNotEmpty) ...[
              SizedBox(height: 8.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tags
                      .map(
                        (tag) => Padding(
                          padding: EdgeInsets.only(right: 6.w),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],

            // 底部提示
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 14.sp,
                  color: AppTheme.textSecondary.withOpacity(0.6),
                ),
                SizedBox(width: 4.w),
                Text(
                  '点击查看完整作品详情',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建作品类型文本
  String _getItemTypeText(String type) {
    switch (type) {
      case 'character_card':
        return '角色卡';
      case 'novel_card':
        return '小说卡';
      case 'group_chat_card':
        return '群聊卡';
      default:
        return '未知类型';
    }
  }

  // 获取作品类型颜色
  Color _getItemTypeColor(String type) {
    switch (type) {
      case 'character_card':
        return const Color(0xFF1E88E5); // 更深的蓝色
      case 'novel_card':
        return const Color(0xFFFF9800); // 更暖的橙色
      case 'group_chat_card':
        return const Color(0xFF4CAF50); // 更鲜艳的绿色
      default:
        return Colors.grey;
    }
  }

  // 构建统计数据
  Widget _buildStat(IconData icon, num value, {bool isHot = false}) {
    final String displayValue =
        value is int ? value.toString() : value.toStringAsFixed(1);

    return Row(
      children: [
        Icon(
          icon,
          size: 12.sp,
          color: isHot ? Colors.redAccent : Colors.grey,
        ),
        SizedBox(width: 2.w),
        Text(
          displayValue,
          style: TextStyle(
            fontSize: 12.sp,
            color: isHot ? Colors.redAccent : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // 构建封面图片
  Widget _buildCoverImage(String coverUri) {
    if (_imageCache.containsKey(coverUri)) {
      return Image.memory(
        _imageCache[coverUri]!,
        width: 80.w,
        height: 80.w,
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
        width: 80.w,
        height: 80.w,
        color: Colors.grey.withOpacity(0.2),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_paused_rounded,
            size: 60.sp,
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            _currentSubTab == 0 ? '暂无未读消息' : '暂无历史记录',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '关注您喜欢的作者，获取最新作品推送',
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
          Shimmer.fromColors(
            baseColor: AppTheme.primaryColor.withOpacity(0.4),
            highlightColor: AppTheme.primaryColor,
            child: Text(
              '正在加载数据...',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Shimmer.fromColors(
            baseColor: AppTheme.textSecondary.withOpacity(0.2),
            highlightColor: AppTheme.textSecondary.withOpacity(0.6),
            child: Text(
              '请稍候',
              style: TextStyle(
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建子标签切换按钮
  Widget _buildSubTabs() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h), // 减少底部边距
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          // 未读通知按钮
          GestureDetector(
            onTap: () {
              if (_currentSubTab != 0) {
                setState(() {
                  _currentSubTab = 0;
                });
              }
            },
            child: Text(
              '未读消息',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight:
                    _currentSubTab == 0 ? FontWeight.bold : FontWeight.normal,
                color: _currentSubTab == 0
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
            ),
          ),

          // 分隔符
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              '|',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
            ),
          ),

          // 全部通知按钮
          GestureDetector(
            onTap: () {
              if (_currentSubTab != 1) {
                setState(() {
                  _currentSubTab = 1;
                });
                // 如果还没加载过全部通知，则加载
                if (_allUpdates.isEmpty) {
                  _loadAllUpdates(refresh: true);
                }
              }
            },
            child: Text(
              '历史记录',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight:
                    _currentSubTab == 1 ? FontWeight.bold : FontWeight.normal,
                color: _currentSubTab == 1
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> activeUpdates =
        _currentSubTab == 0 ? _updates : _allUpdates;
    final bool hasMore = _currentSubTab == 0 ? _hasMore : _hasMoreAll;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 左侧放置子标签切换按钮
            _buildSubTabs(),

            // 右侧放置一键已读按钮
            if (_currentSubTab == 0 && _updates.isNotEmpty)
              Container(
                height: 32.h,
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.8),
                      AppTheme.primaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _markAllAsRead,
                    borderRadius: BorderRadius.circular(16.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.done_all,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '全部已读',
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
                ),
              ),
          ],
        ),
        // 减少标题栏底部边距
        toolbarHeight: 48.h,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : activeUpdates.isEmpty
              ? _buildEmptyState()
              : SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  onLoading: _onLoading,
                  enablePullUp: hasMore,
                  // 自定义纯文本下拉刷新头部
                  header: CustomHeader(
                    builder: (context, mode) {
                      String statusText = '';
                      if (mode == RefreshStatus.idle) {
                        statusText = '下拉刷新';
                      } else if (mode == RefreshStatus.refreshing) {
                        statusText = '正在刷新...';
                      } else if (mode == RefreshStatus.canRefresh) {
                        statusText = '松开刷新';
                      } else if (mode == RefreshStatus.completed) {
                        statusText = '刷新完成';
                      } else if (mode == RefreshStatus.failed) {
                        statusText = '刷新失败';
                      }

                      return SizedBox(
                        height: 55.h,
                        child: Center(
                          child: mode == RefreshStatus.refreshing
                              ? Shimmer.fromColors(
                                  baseColor:
                                      AppTheme.primaryColor.withOpacity(0.4),
                                  highlightColor: AppTheme.primaryColor,
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              : Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  // 自定义纯文本上拉加载尾部
                  footer: CustomFooter(
                    builder: (context, mode) {
                      String statusText = '';
                      Widget statusWidget;

                      if (mode == LoadStatus.idle) {
                        statusText = '上拉加载更多';
                        statusWidget = Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.textSecondary,
                          ),
                        );
                      } else if (mode == LoadStatus.loading) {
                        statusText = '正在加载...';
                        statusWidget = Shimmer.fromColors(
                          baseColor: AppTheme.primaryColor.withOpacity(0.4),
                          highlightColor: AppTheme.primaryColor,
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      } else if (mode == LoadStatus.failed) {
                        statusText = '加载失败，点击重试';
                        statusWidget = Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.red,
                          ),
                        );
                      } else if (mode == LoadStatus.canLoading) {
                        statusText = '松开加载更多';
                        statusWidget = Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.textSecondary,
                          ),
                        );
                      } else {
                        statusText = '没有更多数据了';
                        statusWidget = Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.textSecondary,
                          ),
                        );
                      }

                      return SizedBox(
                        height: 55.h,
                        child: Center(
                          child: statusWidget,
                        ),
                      );
                    },
                  ),
                  child: ListView.builder(
                    // 减少顶部内边距
                    padding: EdgeInsets.only(top: 0, bottom: 8.h),
                    itemCount: activeUpdates.length,
                    itemBuilder: (context, index) {
                      final update = activeUpdates[index];
                      return _buildUpdateItem(update);
                    },
                  ),
                ),
    );
  }
}

// 已关注作者页面
class _FollowingAuthorsTab extends StatefulWidget {
  const _FollowingAuthorsTab();

  @override
  _FollowingAuthorsTabState createState() => _FollowingAuthorsTabState();
}

class _FollowingAuthorsTabState extends State<_FollowingAuthorsTab> {
  final HomeService _homeService = HomeService();
  final FileService _fileService = FileService();
  final RefreshController _refreshController = RefreshController();

  bool _isLoading = true;
  List<dynamic> _authors = [];
  final Map<String, dynamic> _authorsInfo = {}; // 存储作者详细信息，key为authorId
  int _page = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  // 图片缓存
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, bool> _loadingImages = {};

  @override
  void initState() {
    super.initState();
    _loadAuthors();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  // 加载用户头像
  Future<void> _loadAuthorAvatar(String? avatarUri) async {
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

  Future<void> _loadAuthors({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _hasMore = true;
        _isLoading = true;
      });
    }

    try {
      final result = await _homeService.getFollowingAuthors(
        page: _page,
        pageSize: _pageSize,
      );

      if (mounted) {
        final List<dynamic> authorIds = result['data']['authors'] ?? [];
        final int total = result['data']['total'] ?? 0;

        setState(() {
          if (_page == 1) {
            _authors = authorIds;
          } else {
            _authors.addAll(authorIds);
          }
          _hasMore = _authors.length < total;
          _isLoading = false;
        });

        // 请求作者详细信息
        _loadAuthorsInfo(authorIds);

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

  // 实际加载作者详情
  Future<void> _loadAuthorsInfo(List<dynamic> authorIds) async {
    if (authorIds.isEmpty) return;

    try {
      // 将authorIds转换为整数列表
      final List<int> userIds =
          authorIds.map<int>((id) => int.parse(id.toString())).toList();

      // 批量获取用户信息
      final List<dynamic> usersInfo = await _homeService.getUsersBatch(userIds);

      // 更新作者信息缓存
      if (usersInfo.isNotEmpty) {
        for (var user in usersInfo) {
          final String userId = user['id'].toString();
          _authorsInfo[userId] = {
            'id': user['id'],
            'name': user['username'] ?? '未知用户',
            'avatar': user['avatar'],
            'description': user['bio'] ?? '', // 假设API返回的是bio字段
          };

          // 预加载头像
          if (user['avatar'] != null) {
            _loadAuthorAvatar(user['avatar']);
          }
        }

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('加载作者信息失败: $e');
    }
  }

  Future<void> _onRefresh() async {
    await _loadAuthors(refresh: true);
  }

  Future<void> _onLoading() async {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return;
    }

    _page++;
    await _loadAuthors();
  }

  // 取消关注作者
  Future<void> _toggleFollowAuthor(String authorId, bool isFollowing) async {
    try {
      bool success;

      // 立即更新UI状态，提供即时反馈
      if (isFollowing) {
        setState(() {
          _authors.remove(int.parse(authorId));
        });

        // API调用
        success = await _homeService.unfollowAuthor(authorId);

        // 如果失败，恢复状态
        if (!success && mounted) {
          setState(() {
            _authors.add(int.parse(authorId));
          });
          CustomToast.show(
            context,
            message: '取消关注失败',
            type: ToastType.error,
          );
        }
      } else {
        // 关注作者 (对于搜索结果)
        setState(() {
          // 如果是来自搜索结果，添加到已关注列表
          _authors.add(int.parse(authorId));
        });

        // API调用
        success = await _homeService.followAuthor(authorId);

        // 如果失败，恢复状态
        if (!success && mounted) {
          setState(() {
            _authors.remove(int.parse(authorId));
          });
          CustomToast.show(
            context,
            message: '关注失败',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      CustomToast.show(
        context,
        message: '操作失败，请稍后重试',
        type: ToastType.error,
      );
    }
  }

  // 检查作者是否已关注
  bool _isAuthorFollowed(String authorId) {
    return _authors.contains(int.parse(authorId));
  }

  Widget _buildAuthorCard(dynamic authorId) {
    // 获取作者信息，如果不存在则使用默认值
    final authorInfo = _authorsInfo[authorId.toString()] ??
        {
          'id': authorId,
          'name': '未知作者',
          'avatar': null,
          'description': '',
        };

    final bool isFollowed = _isAuthorFollowed(authorId.toString());
    final String? avatarUri = authorInfo['avatar'];
    final String id = authorId.toString();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      elevation: 2,
      color: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          // 点击作者卡片，跳转到作者作品页面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuthorItemsPage(
                authorId: authorId.toString(),
                authorName: authorInfo['name'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          child: Row(
            children: [
              // 作者头像
              _buildAuthorAvatar(avatarUri, authorInfo['name']),
              SizedBox(width: 16.w),
              // 作者信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorInfo['name'],
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
                    if (authorInfo['description'] != null &&
                        authorInfo['description'].isNotEmpty)
                      Text(
                        authorInfo['description'],
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
              // 关注/取消关注按钮
              GestureDetector(
                onTap: () {
                  if (isFollowed) {
                    // 已关注，确认取消关注
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppTheme.cardBackground,
                        title: Text(
                          '取消关注',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          '确定要取消关注该作者吗？',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              '取消',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _toggleFollowAuthor(authorId.toString(), true);
                            },
                            child: Text(
                              '确认',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // 未关注，直接关注
                    _toggleFollowAuthor(authorId.toString(), false);
                  }
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    gradient: isFollowed
                        ? null
                        : LinearGradient(
                            colors: AppTheme.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isFollowed ? Colors.grey.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(16.r),
                    border: isFollowed
                        ? Border.all(color: Colors.grey.withOpacity(0.3))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFollowed ? Icons.check : Icons.add,
                        size: 16.sp,
                        color: isFollowed ? Colors.grey : Colors.white,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        isFollowed ? '已关注' : '关注',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: isFollowed ? Colors.grey : Colors.white,
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

  // 构建作者头像
  Widget _buildAuthorAvatar(String? avatarUri, String name) {
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
        _loadAuthorAvatar(avatarUri);
      }

      // 显示shimmer加载效果替代转圈
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
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
            Icons.person_search_rounded,
            size: 60.sp,
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            '暂无关注的作者',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '关注您喜欢的作者，获取最新内容更新',
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
          Shimmer.fromColors(
            baseColor: AppTheme.primaryColor.withOpacity(0.4),
            highlightColor: AppTheme.primaryColor,
            child: Text(
              '正在加载数据...',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Shimmer.fromColors(
            baseColor: AppTheme.textSecondary.withOpacity(0.2),
            highlightColor: AppTheme.textSecondary.withOpacity(0.6),
            child: Text(
              '请稍候',
              style: TextStyle(
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 格式化时间显示
  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '未知时间';

    final DateTime createdAt = DateTime.parse(dateTimeStr);
    final Duration difference = DateTime.now().difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? _buildLoadingState()
        : _authors.isEmpty
            ? _buildEmptyState()
            : SmartRefresher(
                controller: _refreshController,
                onRefresh: _onRefresh,
                onLoading: _onLoading,
                enablePullUp: _hasMore,
                // 自定义纯文本下拉刷新头部
                header: CustomHeader(
                  builder: (context, mode) {
                    String statusText = '';
                    if (mode == RefreshStatus.idle) {
                      statusText = '下拉刷新';
                    } else if (mode == RefreshStatus.refreshing) {
                      statusText = '正在刷新...';
                    } else if (mode == RefreshStatus.canRefresh) {
                      statusText = '松开刷新';
                    } else if (mode == RefreshStatus.completed) {
                      statusText = '刷新完成';
                    } else if (mode == RefreshStatus.failed) {
                      statusText = '刷新失败';
                    }

                    return SizedBox(
                      height: 55.h,
                      child: Center(
                        child: mode == RefreshStatus.refreshing
                            ? Shimmer.fromColors(
                                baseColor:
                                    AppTheme.primaryColor.withOpacity(0.4),
                                highlightColor: AppTheme.primaryColor,
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                // 自定义纯文本上拉加载尾部
                footer: CustomFooter(
                  builder: (context, mode) {
                    String statusText = '';
                    Widget statusWidget;

                    if (mode == LoadStatus.idle) {
                      statusText = '上拉加载更多';
                      statusWidget = Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondary,
                        ),
                      );
                    } else if (mode == LoadStatus.loading) {
                      statusText = '正在加载...';
                      statusWidget = Shimmer.fromColors(
                        baseColor: AppTheme.primaryColor.withOpacity(0.4),
                        highlightColor: AppTheme.primaryColor,
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    } else if (mode == LoadStatus.failed) {
                      statusText = '加载失败，点击重试';
                      statusWidget = Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.red,
                        ),
                      );
                    } else if (mode == LoadStatus.canLoading) {
                      statusText = '松开加载更多';
                      statusWidget = Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondary,
                        ),
                      );
                    } else {
                      statusText = '没有更多数据了';
                      statusWidget = Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondary,
                        ),
                      );
                    }

                    return SizedBox(
                      height: 55.h,
                      child: Center(
                        child: statusWidget,
                      ),
                    );
                  },
                ),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  itemCount: _authors.length,
                  itemBuilder: (context, index) {
                    final authorId = _authors[index];
                    return _buildAuthorCard(authorId);
                  },
                ),
              );
  }
}
