import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import '../services/author_service.dart';
import '../../home/services/home_service.dart';
import '../../../services/file_service.dart';
import 'author_push_create_page.dart';

class AuthorPushListPage extends StatefulWidget {
  const AuthorPushListPage({super.key});

  @override
  State<AuthorPushListPage> createState() => _AuthorPushListPageState();
}

class _AuthorPushListPageState extends State<AuthorPushListPage> {
  final AuthorService _authorService = AuthorService();
  final HomeService _homeService = HomeService();
  final FileService _fileService = FileService();
  final RefreshController _refreshController = RefreshController();

  bool _isLoading = true;
  List<dynamic> _updates = [];
  int _page = 1;
  final int _pageSize = 10;
  bool _hasMore = true;

  // 展开状态管理
  final Set<String> _expandedDescriptions = {};
  final Set<String> _expandedItems = {};

  // 图片缓存
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, bool> _loadingImages = {};

  // 作品详情缓存
  final Map<String, Map<String, dynamic>> _itemDetailsCache = {};
  final Map<String, bool> _loadingItemDetails = {};

  // 记录不存在的作品ID，避免重复请求
  final Set<String> _nonExistentItems = {};

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
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

  Future<void> _loadUpdates({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _hasMore = true;
        _isLoading = true;
      });
    }

    try {
      final result = await _authorService.getMyUpdates(
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

        // 预加载每个更新对应的作品详情
        for (var update in newUpdates) {
          if (update['item_id'] != null) {
            _loadItemDetail(update['item_id'].toString());
          }
        }

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

  Future<void> _onRefresh() async {
    await _loadUpdates(refresh: true);
  }

  Future<void> _onLoading() async {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return;
    }
    _page++;
    await _loadUpdates();
  }

  // 删除更新记录
  Future<void> _deleteUpdate(int updateId) async {
    try {
      await _authorService.deleteUpdate(updateId);

      // 从列表中移除
      setState(() {
        _updates.removeWhere((update) => update['id'] == updateId);
      });

      CustomToast.show(
        context,
        message: '删除成功',
        type: ToastType.success,
      );
    } catch (e) {
      CustomToast.show(
        context,
        message: '删除失败: ${e.toString()}',
        type: ToastType.error,
      );
    }
  }

  // 编辑更新记录
  void _editUpdate(Map<String, dynamic> update) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuthorPushCreatePage(existingUpdate: update),
      ),
    ).then((_) => _onRefresh()); // 返回后刷新列表
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
  void _toggleItemExpanded(String updateId, String itemId) {
    setState(() {
      if (_expandedItems.contains(updateId)) {
        _expandedItems.remove(updateId);
      } else {
        _expandedItems.add(updateId);
        // 确保加载作品详情
        if (!_itemDetailsCache.containsKey(itemId) &&
            !_nonExistentItems.contains(itemId) &&
            _loadingItemDetails[itemId] != true) {
          _loadItemDetail(itemId);
        }
      }
    });
  }

  // 格式化时间显示
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

  Widget _buildUpdateItem(Map<String, dynamic> update) {
    final String updateId = update['id'].toString();
    final bool isDescExpanded = _expandedDescriptions.contains(updateId);
    final bool isItemExpanded = _expandedItems.contains(updateId);
    final String updateType = update['update_type'] ?? '';
    final bool isSystemPush = update['is_system_push'] == true;
    final String? description = update['description'];
    final String? itemId = update['item_id']?.toString();
    final bool isItemNonExistent =
        itemId != null && _nonExistentItems.contains(itemId);

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
              if (itemId != null) {
                _toggleItemExpanded(updateId, itemId);
              }
            },
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 通知头部：类型图标、标题、时间和操作按钮
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

                      // 标题和时间信息
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

                            // 时间和系统推送标记
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

                                // 系统推送标记
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
                                  ),

                                // 作品类型标签
                                if (update['item_type'] != null)
                                  Container(
                                    margin: EdgeInsets.only(left: 8.w),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6.w, vertical: 1.h),
                                    decoration: BoxDecoration(
                                      color: _getItemTypeColor(
                                          update['item_type']),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      _getItemTypeText(update['item_type']),
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 操作按钮
                      Row(
                        children: [
                          // 编辑按钮
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: AppTheme.primaryColor,
                              size: 20.sp,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () => _editUpdate(update),
                          ),
                          SizedBox(width: 8.w),
                          // 删除按钮
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red.withOpacity(0.7),
                              size: 20.sp,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () {
                              // 确认删除对话框
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('确认删除'),
                                  content: const Text('确定要删除这条更新记录吗？删除后将无法恢复。'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _deleteUpdate(update['id']);
                                      },
                                      child: Text(
                                        '删除',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 通知描述内容
                  if (description != null) ...[
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: () => _toggleDescriptionExpanded(updateId),
                      child: Container(
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
                              maxLines: isDescExpanded ? null : 2,
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
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 16.sp,
                            color: AppTheme.textSecondary.withOpacity(0.6),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '点击查看作品详情',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textSecondary.withOpacity(0.6),
                            ),
                          ),
                        ],
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
                        SizedBox(width: 8.w),

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
        ],
      ),
    );
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
        color: AppTheme.cardBackground,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 60.sp,
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            '暂无发布记录',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '发布更新让您的粉丝及时了解新动态',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text('我的更新推送', style: AppTheme.titleStyle),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AuthorPushCreatePage()),
          ).then((_) {
            // 返回时刷新列表
            _onRefresh();
          });
        },
        backgroundColor: AppTheme.primaryColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _updates.isEmpty
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

                      return Container(
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

                      return Container(
                        height: 55.h,
                        child: Center(
                          child: statusWidget,
                        ),
                      );
                    },
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _updates.length,
                    itemBuilder: (context, index) {
                      final update = _updates[index];
                      return _buildUpdateItem(update);
                    },
                  ),
                ),
    );
  }
}
