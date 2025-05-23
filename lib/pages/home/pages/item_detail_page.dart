import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';
import '../../../services/file_service.dart';
import '../services/home_service.dart';
import '../../../pages/character_chat/pages/character_init_page.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';

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

  // 缓存图片数据
  Uint8List? _cachedCoverImage;
  bool _isLoadingCover = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.item['is_liked'] ?? false;
    _likeCount = widget.item['like_count'] ?? 0;
    _loadCoverImage();
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // 顶部图片和返回按钮
          SliverAppBar(
            backgroundColor: AppTheme.background,
            expandedHeight: 250.h,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.item['cover_uri'] != null
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
          ),

          // 内容区域
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和作者信息
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item['title'] ?? '',
                              style: AppTheme.headingStyle,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '@${widget.item["author_name"]}',
                              style: AppTheme.secondaryStyle,
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
                          color: _getItemTypeColor(widget.item["item_type"]),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getItemTypeIcon(widget.item["item_type"]),
                              size: 16.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              _getItemTypeText(widget.item["item_type"]),
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
                  SizedBox(height: 16.h),

                  // 描述
                  if (widget.item['description'] != null) ...[
                    Text(
                      '简介',
                      style: AppTheme.titleStyle,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      widget.item['description'],
                      style: AppTheme.bodyStyle.copyWith(height: 1.5),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // 标签
                  if ((widget.item['tags'] as List?)?.isNotEmpty ?? false) ...[
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
                                  borderRadius: BorderRadius.circular(
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
                                        fontSize: AppTheme.smallSize,
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
                  _buildInfoItem('创建时间',
                      _formatDateTime(createdAt.add(const Duration(hours: 8)))),
                  _buildInfoItem('更新时间',
                      _formatDateTime(updatedAt.add(const Duration(hours: 8)))),
                ],
              ),
            ),
          ),
        ],
      ),
      // 底部操作栏
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: OutlinedButton.icon(
                  onPressed: _isLiking ? null : _toggleLike,
                  icon: Icon(
                    _isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20.sp,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isLiked ? '已点赞 $_likeCount' : '点赞 $_likeCount',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.amber[700],
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: OutlinedButton.icon(
                  onPressed: _isRewarding ? null : _showRewardDialog,
                  icon: Icon(
                    Icons.workspace_premium_rounded,
                    size: 20.sp,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isRewarding ? '激励中...' : '激励',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Container(
                decoration: AppTheme.buttonDecoration,
                child: FilledButton.icon(
                  onPressed: () {
                    if (widget.item["item_type"] == "character_card") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CharacterInitPage(
                            characterData: widget.item,
                          ),
                        ),
                      );
                    }
                    // TODO: 其他类型的跳转逻辑
                  },
                  icon: Icon(
                    Icons.chat_rounded,
                    size: 20.sp,
                  ),
                  label: const Text('开始对话'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          ],
        ),
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
        Image.memory(
          _cachedCoverImage!,
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.background.withOpacity(0.8),
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
            '选择激励金额',
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
