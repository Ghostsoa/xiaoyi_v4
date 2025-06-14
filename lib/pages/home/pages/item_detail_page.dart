import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';
import '../../../services/file_service.dart';
import '../services/home_service.dart';
import '../../../pages/character_chat/pages/character_init_page.dart';
import '../../../pages/novel/pages/novel_init_page.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import 'author_items_page.dart';

class ItemDetailPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailPage({super.key, required this.item});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  final FileService _fileService = FileService();
  final HomeService _homeService = HomeService();

  late bool _isLiked;
  late int _likeCount;
  bool _isLiking = false;
  bool _isRewarding = false;

  // 收藏状态
  late bool _isFavorite;
  bool _isFavoriting = false;

  // 缓存图片数据
  Uint8List? _cachedCoverImage;
  bool _isLoadingCover = false;

  // 滚动控制
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  // 用于DraggableScrollableSheet的控制器
  late ScrollController _sheetScrollController;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.item['is_liked'] ?? false;
    _likeCount = widget.item['like_count'] ?? 0;
    _isFavorite = widget.item['is_favorited'] ?? false;
    _loadCoverImage();

    // 监听滚动事件
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCoverImage({bool forceReload = false}) async {
    if (widget.item['cover_uri'] == null ||
        _isLoadingCover ||
        (!forceReload && _cachedCoverImage != null)) {
      return;
    }

    _isLoadingCover = true;
    try {
      final result = await _fileService.getFile(widget.item['cover_uri']);
      if (mounted) {
        setState(() {
          _cachedCoverImage = result.data;
          _isLoadingCover = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCover = false);
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_isLiking) return;

    final String? itemId = widget.item['id']?.toString();
    if (itemId == null) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '操作失败：无效的内容ID',
          type: ToastType.error,
        );
      }
      return;
    }

    setState(() => _isLiking = true);
    try {
      if (_isLiked) {
        await _homeService.unlikeItem(itemId);
        if (mounted) {
          setState(() {
            _isLiked = false;
            _likeCount--;
          });
        }
      } else {
        await _homeService.likeItem(itemId);
        if (mounted) {
          setState(() {
            _isLiked = true;
            _likeCount++;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '${_isLiked ? '取消点赞' : '点赞'}失败: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLiking = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavoriting) return;

    final String? itemId = widget.item['id']?.toString();
    if (itemId == null) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '操作失败：无效的内容ID',
          type: ToastType.error,
        );
      }
      return;
    }

    setState(() => _isFavoriting = true);
    try {
      if (_isFavorite) {
        await _homeService.unfavoriteItem(itemId);
        if (mounted) {
          setState(() {
            _isFavorite = false;
          });
          CustomToast.show(
            context,
            message: '已取消收藏',
            type: ToastType.success,
          );
        }
      } else {
        await _homeService.favoriteItem(itemId);
        if (mounted) {
          setState(() {
            _isFavorite = true;
          });
          CustomToast.show(
            context,
            message: '收藏成功',
            type: ToastType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '${_isFavorite ? '取消收藏' : '收藏'}失败: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFavoriting = false);
      }
    }
  }

  Future<void> _rewardItem(double amount) async {
    if (_isRewarding) return;

    final String? itemId = widget.item['id']?.toString();
    if (itemId == null) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '操作失败：无效的内容ID',
          type: ToastType.error,
        );
      }
      return;
    }

    setState(() => _isRewarding = true);
    try {
      final response = await _homeService.rewardItem(itemId, amount);
      if (response['code'] == 0) {
        if (mounted) {
          CustomToast.show(
            context,
            message: '激励成功，感谢您的支持！',
            type: ToastType.success,
          );
        }
      } else {
        if (mounted) {
          CustomToast.show(
            context,
            message: '激励失败: ${response['message']}',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '激励失败: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRewarding = false);
      }
    }
  }

  void _showRewardDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _RewardBottomSheet(
        onReward: (amount) {
          Navigator.pop(context);
          _rewardItem(amount);
        },
      ),
    );
  }

  void _navigateToContent() {
    if (widget.item["item_type"] == "character_card") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CharacterInitPage(
            characterData: widget.item,
          ),
        ),
      );
    } else if (widget.item["item_type"] == "novel_card") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NovelInitPage(
            novelData: widget.item,
          ),
        ),
      );
    }
    // TODO: 其他类型的跳转逻辑
  }

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

  IconData _getItemTypeIcon(String type) {
    switch (type) {
      case 'character_card':
        return Icons.person_rounded;
      case 'novel_card':
        return Icons.book_rounded;
      case 'chat_card':
        return Icons.groups_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getItemTypeColor(String type) {
    switch (type) {
      case 'character_card':
        return const Color(0xFF1E88E5); // 更深的蓝色
      case 'novel_card':
        return const Color(0xFFFF9800); // 更暖的橙色
      case 'chat_card':
        return const Color(0xFF4CAF50); // 更鲜艳的绿色
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime createdAt = DateTime.parse(widget.item['created_at']);
    final DateTime updatedAt = DateTime.parse(widget.item['updated_at']);

    // 获取屏幕高度
    final double screenHeight = MediaQuery.of(context).size.height;
    // 封面占满屏幕
    final double coverHeight = screenHeight;
    // 内容区域初始位置（从屏幕的60%处开始）
    final double initialContentOffset = screenHeight * 0.6;
    // 内容区域可以拉到的最小位置（顶部保留空间）
    final double minContentOffset = screenHeight * 0.15;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 背景色
          Container(color: AppTheme.background),

          // 封面图片 - 占满全屏
          Positioned.fill(
            child: widget.item['cover_uri'] != null
                ? _buildCoverImage()
                : Container(
                    color: AppTheme.cardBackground,
                    child: Icon(
                      Icons.image_rounded,
                      size: 48.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
          ),

          // 返回按钮 - 放在左上角
          Positioned(
            top: MediaQuery.of(context).padding.top + 10.h,
            left: 16.w,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ),

          // 内容区域 - 可拖动
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // 当内容向上滚动超过封面时，改变AppBar颜色
              if (notification is ScrollUpdateNotification) {
                setState(() {
                  _scrollOffset = notification.metrics.pixels;
                });
              }
              return false;
            },
            child: DraggableScrollableSheet(
              initialChildSize: initialContentOffset / screenHeight,
              minChildSize: minContentOffset / screenHeight,
              maxChildSize: 0.9, // 最大可以占屏幕的90%
              builder: (context, scrollController) {
                _sheetScrollController = scrollController;
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      // 顶部拖动指示器
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SizedBox(height: 12.h),
                            Center(
                              child: Container(
                                width: 40.w,
                                height: 5.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2.5.r),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                          ],
                        ),
                      ),

                      // 内容主体
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 标题和作者信息
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.item['title'] ?? '',
                                          style: AppTheme.headingStyle,
                                        ),
                                        SizedBox(height: 4.h),
                                        Row(
                                          children: [
                                            Text(
                                              '@${widget.item["author_name"]}',
                                              style: AppTheme.secondaryStyle,
                                            ),
                                            SizedBox(width: 6.w),
                                            GestureDetector(
                                              onTap: () {
                                                final String authorId = widget
                                                        .item['author_id']
                                                        ?.toString() ??
                                                    '';
                                                final String authorName = widget
                                                        .item['author_name'] ??
                                                    '未知作者';

                                                if (authorId.isNotEmpty) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          AuthorItemsPage(
                                                        authorId: authorId,
                                                        authorName: authorName,
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  CustomToast.show(
                                                    context,
                                                    message: '获取作者信息失败',
                                                    type: ToastType.error,
                                                  );
                                                }
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8.w,
                                                  vertical: 2.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.r),
                                                  border: Border.all(
                                                    color: AppTheme.primaryColor
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .collections_bookmark_outlined,
                                                      size: 14.sp,
                                                      color:
                                                          AppTheme.primaryColor,
                                                    ),
                                                    SizedBox(width: 4.w),
                                                    Text(
                                                      '作者作品',
                                                      style: TextStyle(
                                                        fontSize: 12.sp,
                                                        color: AppTheme
                                                            .primaryColor,
                                                      ),
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
                                  // 互动数据
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.local_fire_department_rounded,
                                            size: 16.sp,
                                            color: Colors.redAccent,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            '${widget.item["hot_score"]}',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.favorite_rounded,
                                            size: 16.sp,
                                            color: AppTheme.textSecondary,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            '${widget.item["like_count"]}',
                                            style: AppTheme.secondaryStyle,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.chat_rounded,
                                            size: 16.sp,
                                            color: AppTheme.textSecondary,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            '${widget.item["dialog_count"]}',
                                            style: AppTheme.secondaryStyle,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              SizedBox(height: 16.h),

                              // 类型和标签区域
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getItemTypeColor(
                                          widget.item["item_type"]),
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSmall),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getItemTypeIcon(
                                              widget.item["item_type"]),
                                          size: 16.sp,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          _getItemTypeText(
                                              widget.item["item_type"]),
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24.h),

                              // 操作按钮区域
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  // 点赞按钮
                                  _buildActionButton(
                                    icon: _isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    label: _isLiked ? '已点赞' : '点赞',
                                    color: Colors.pink,
                                    onPressed: _isLiking ? null : _toggleLike,
                                  ),

                                  // 收藏按钮
                                  _buildActionButton(
                                    icon: _isFavorite
                                        ? Icons.star
                                        : Icons.star_border,
                                    label: _isFavorite ? '已收藏' : '收藏',
                                    color: Colors.blue,
                                    onPressed:
                                        _isFavoriting ? null : _toggleFavorite,
                                  ),

                                  // 激励按钮
                                  _buildActionButton(
                                    icon: Icons.workspace_premium,
                                    label: _isRewarding ? '激励中' : '激励',
                                    color: Colors.amber[700] ?? Colors.amber,
                                    onPressed:
                                        _isRewarding ? null : _showRewardDialog,
                                  ),

                                  // 开始阅读/对话按钮
                                  _buildActionButton(
                                    icon: Icons.chat,
                                    label:
                                        widget.item["item_type"] == "novel_card"
                                            ? '阅读'
                                            : '对话',
                                    color: AppTheme.primaryColor,
                                    onPressed: _navigateToContent,
                                  ),
                                ],
                              ),

                              Divider(
                                  height: 40.h,
                                  thickness: 1,
                                  color: Colors.grey.withOpacity(0.2)),

                              // 描述
                              if (widget.item['description'] != null) ...[
                                Text(
                                  '简介',
                                  style: AppTheme.titleStyle,
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  widget.item['description'],
                                  style:
                                      AppTheme.bodyStyle.copyWith(height: 1.5),
                                ),
                                SizedBox(height: 16.h),
                              ],

                              // 标签
                              if ((widget.item['tags'] as List?)?.isNotEmpty ??
                                  false) ...[
                                Text(
                                  '标签',
                                  style: AppTheme.titleStyle,
                                ),
                                SizedBox(height: 8.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: (widget.item['tags'] as List)
                                      .map((tag) => Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12.w,
                                              vertical: 6.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppTheme.radiusSmall),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.tag_rounded,
                                                  size: 14.sp,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 4.w),
                                                Text(
                                                  tag,
                                                  style: TextStyle(
                                                    fontSize:
                                                        AppTheme.smallSize,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ),
                                SizedBox(height: 16.h),
                              ],

                              // 时间信息
                              Text(
                                '其他信息',
                                style: AppTheme.titleStyle,
                              ),
                              SizedBox(height: 8.h),
                              _buildInfoItem(
                                  '创建时间',
                                  _formatDateTime(
                                      createdAt.add(const Duration(hours: 8)))),
                              _buildInfoItem(
                                  '更新时间',
                                  _formatDateTime(
                                      updatedAt.add(const Duration(hours: 8)))),

                              // 底部空白
                              SizedBox(height: 24.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    if (_isLoadingCover && _cachedCoverImage == null) {
      return Shimmer.fromColors(
        baseColor: AppTheme.cardBackground,
        highlightColor: AppTheme.cardBackground.withOpacity(0.5),
        child: Container(color: AppTheme.cardBackground),
      );
    }

    if (_cachedCoverImage == null) {
      return Container(
        color: AppTheme.cardBackground,
        child: Icon(
          Icons.image_rounded,
          size: 48.sp,
          color: AppTheme.textSecondary,
        ),
      );
    }

    return Stack(
      children: [
        // 实际图像
        Image.memory(
          _cachedCoverImage!,
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
        ),
        // 顶部渐变 (当滚动时显示)
        if (_scrollOffset > 50)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(min(0.5, _scrollOffset / 200)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: AppTheme.secondaryStyle,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyStyle,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  double min(double a, double b) => a < b ? a : b;

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required void Function()? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24.sp,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RewardBottomSheet extends StatefulWidget {
  final Function(double) onReward;

  const _RewardBottomSheet({required this.onReward});

  @override
  State<_RewardBottomSheet> createState() => _RewardBottomSheetState();
}

class _RewardBottomSheetState extends State<_RewardBottomSheet> {
  double _selectedAmount = 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '激励创作者',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: AppTheme.textSecondary),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            '选择激励',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRewardOption(context, 10),
              _buildRewardOption(context, 50),
              _buildRewardOption(context, 100),
            ],
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onReward(_selectedAmount);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: Text(
                '确认激励 $_selectedAmount 小懿币',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildRewardOption(BuildContext context, double amount) {
    final bool isSelected = _selectedAmount == amount;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAmount = amount;
        });
      },
      child: Container(
        width: 80.w,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withOpacity(0.3)
              : Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.amber.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 24.sp,
              color: isSelected ? Colors.amber[700] : Colors.amber[300],
            ),
            SizedBox(height: 8.h),
            Text(
              '${amount.toInt()}',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.amber[700] : Colors.amber[300],
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '小懿币',
              style: TextStyle(
                fontSize: 12.sp,
                color:
                    isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
