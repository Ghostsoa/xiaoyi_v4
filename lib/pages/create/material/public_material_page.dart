import 'package:flutter/material.dart';
import '../services/material_service.dart';
import '../../../services/file_service.dart';
import 'dart:async';
import '../../../widgets/custom_toast.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import 'dart:typed_data';

class PublicMaterialPage extends StatefulWidget {
  const PublicMaterialPage({super.key});

  @override
  State<PublicMaterialPage> createState() => _PublicMaterialPageState();
}

class _PublicMaterialPageState extends State<PublicMaterialPage> {
  final MaterialService _materialService = MaterialService();
  final FileService _fileService = FileService();
  final ScrollController _scrollController = ScrollController();

  // 添加图片缓存
  final Map<String, Uint8List> _imageCache = {};

  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  String _currentType = 'image';

  final Map<String, List<Map<String, dynamic>>> _materialsByType = {
    'image': [],
    'template': [],
    'prefix': [],
    'suffix': [],
  };

  final Map<String, int> _totalsByType = {
    'image': 0,
    'template': 0,
    'prefix': 0,
    'suffix': 0,
  };

  // 分类列表
  final List<Map<String, dynamic>> _categories = [
    {'type': 'image', 'label': '图片'},
    {'type': 'template', 'label': '模板'},
    {'type': 'prefix', 'label': '前缀词'},
    {'type': 'suffix', 'label': '后缀词'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadData(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // 清除缓存
    _imageCache.clear();
    super.dispose();
  }

  void _changeCategory(String type) {
    if (type != _currentType) {
      setState(() {
        _currentType = type;
        _currentPage = 1;
        _hasMore = true;
        _materialsByType[_currentType] = [];
      });
      _loadData(refresh: true);
    }
  }

  void _handleScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _loadData();
      }
    }
  }

  void _showToast(String message, {ToastType type = ToastType.info}) {
    if (!mounted) return;
    final BuildContext currentContext = context;
    CustomToast.show(
      currentContext,
      message: message,
      type: type,
    );
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
        _materialsByType[_currentType] = [];
      }
    });

    try {
      final response = await _materialService.getPublicMaterials(
        page: _currentPage,
        pageSize: _pageSize,
        type: _currentType,
      );

      if (!mounted) return;

      setState(() {
        if (refresh) {
          _materialsByType[_currentType] =
              List<Map<String, dynamic>>.from(response['items']);
        } else {
          _materialsByType[_currentType]
              ?.addAll(List<Map<String, dynamic>>.from(response['items']));
        }
        _totalsByType[_currentType] = response['total'];
        _hasMore =
            (_materialsByType[_currentType]?.length ?? 0) < response['total'];
        _currentPage += 1;
      });
    } catch (e) {
      if (!mounted) return;
      _showToast(
        e.toString(),
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 添加图片缓存获取方法
  Future<Uint8List> _getCachedImage(String uri) async {
    // 如果缓存中已有图片，直接返回
    if (_imageCache.containsKey(uri)) {
      return _imageCache[uri]!;
    }

    // 否则从服务器获取并缓存
    final result = await _fileService.getFile(uri);
    _imageCache[uri] = result.data;
    return result.data;
  }

  // 添加图片查看器对话框
  void _showImageViewer(BuildContext context, Uint8List imageData) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 使用InteractiveViewer替代PhotoView实现缩放功能
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.memory(
                    imageData,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // 关闭按钮
              Positioned(
                top: MediaQuery.of(context).padding.top + 16.h,
                right: 16.w,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return '刚刚';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}分钟前';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}小时前';
      } else if (difference.inDays < 30) {
        return '${difference.inDays}天前';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months个月前';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years年前';
      }
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildMaterialList(String type) {
    final materials = _materialsByType[type] ?? [];

    if (materials.isEmpty) {
      if (_isLoading && _currentPage == 1) {
        if (type == 'image') {
          // 图片的骨架屏
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              childAspectRatio: 0.75,
            ),
            padding: EdgeInsets.zero,
            itemCount: 10,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor.withOpacity(0.1),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 0.75,
                      child: Shimmer.fromColors(
                        baseColor: AppTheme.cardBackground,
                        highlightColor:
                            AppTheme.cardBackground.withOpacity(0.5),
                        child: Container(
                          color: AppTheme.cardBackground,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppTheme.background.withOpacity(0.9),
                              AppTheme.background.withOpacity(0),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Shimmer.fromColors(
                              baseColor: AppTheme.cardBackground,
                              highlightColor:
                                  AppTheme.cardBackground.withOpacity(0.5),
                              child: Container(
                                width: 60.w,
                                height: 14.h,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusXSmall),
                                ),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Shimmer.fromColors(
                              baseColor: AppTheme.cardBackground,
                              highlightColor:
                                  AppTheme.cardBackground.withOpacity(0.5),
                              child: Container(
                                width: 40.w,
                                height: 12.h,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusXSmall),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        } else {
          // 文本列表的骨架屏
          return ListView.builder(
            itemCount: 10,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.border.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 200.w,
                            height: 16.h,
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusXSmall),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            width: 100.w,
                            height: 12.h,
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusXSmall),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
      }
      return _buildEmptyState(
        message: '暂无${_getTypeLabel(type)}',
        icon: _getTypeIcon(type),
      );
    }

    if (type == 'image') {
      return GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 0,
          crossAxisSpacing: 0,
          childAspectRatio: 0.75,
        ),
        itemCount: materials.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == materials.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                      )
                    : Text(
                        '到底了',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.captionSize,
                        ),
                      ),
              ),
            );
          }

          final material = materials[index];
          return _buildImageMaterialItem(material);
        },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: materials.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == materials.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: _isLoading
                  ? CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    )
                  : Text(
                      '到底了',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.captionSize,
                      ),
                    ),
            ),
          );
        }

        final material = materials[index];
        return _buildMaterialItem(material);
      },
    );
  }

  Widget _buildImageMaterialItem(Map<String, dynamic> material) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          FutureBuilder<Uint8List>(
            // 使用缓存方法替代直接请求
            future: _getCachedImage(material['metadata']),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.hasError) {
                return Shimmer.fromColors(
                  baseColor: AppTheme.cardBackground,
                  highlightColor: AppTheme.cardBackground.withOpacity(0.5),
                  child: Container(
                    color: AppTheme.cardBackground,
                    child: AspectRatio(
                      aspectRatio: 0.75,
                      child: Container(
                        color: AppTheme.cardBackground,
                      ),
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  // 添加点击事件打开图片查看器
                  GestureDetector(
                    onTap: () => _showImageViewer(context, snapshot.data!),
                    child: Hero(
                      tag: 'image_${material['id']}',
                      child: AspectRatio(
                        aspectRatio: 0.75,
                        child: Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppTheme.background.withOpacity(0.9),
                            AppTheme.background.withOpacity(0),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            material['description'].length > 7
                                ? '${material['description'].substring(0, 7)}...'
                                : material['description'],
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.bodySize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '@${material['author_name']}',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.captionSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialItem(Map<String, dynamic> material) {
    return GestureDetector(
      onTap: () {
        // 显示详情弹窗
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMedium)),
          ),
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getTypeLabel(material['type']),
                          style: TextStyle(
                            fontSize: AppTheme.subheadingSize,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: AppTheme.textPrimary,
                            size: 24.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      material['description'],
                      style: TextStyle(
                        fontSize: AppTheme.bodySize,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: SelectableText(
                        material['metadata'] ?? '',
                        style: TextStyle(
                          fontSize: AppTheme.bodySize,
                          height: 1.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      '@${material['author_name']} · ${_formatTime(material['created_at'])}',
                      style: TextStyle(
                        fontSize: AppTheme.captionSize,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.border.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material['description'],
                    style: TextStyle(
                      fontSize: AppTheme.bodySize,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Text(
                        '@${material['author_name']}',
                        style: TextStyle(
                          fontSize: AppTheme.captionSize,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _formatTime(material['created_at']),
                        style: TextStyle(
                          fontSize: AppTheme.captionSize,
                          color: AppTheme.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'image':
        return '图片';
      case 'template':
        return '模板';
      case 'prefix':
        return '前缀词';
      case 'suffix':
        return '后缀词';
      default:
        return '';
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image_outlined;
      case 'template':
        return Icons.description_outlined;
      case 'prefix':
      case 'suffix':
        return Icons.format_quote;
      default:
        return Icons.folder_outlined;
    }
  }

  Widget _buildEmptyState({
    required String message,
    required IconData icon,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64.sp,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: AppTheme.bodySize,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // 构建现代化的分类选择器
  Widget _buildModernCategorySelector() {
    return SizedBox(
      height: 50.h,
      child: Row(
        children: _categories.map((category) {
          final bool isSelected = _currentType == category['type'];
          final int index = _categories.indexOf(category);

          return Expanded(
            child: GestureDetector(
              onTap: () => _changeCategory(category['type']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  right: index < _categories.length - 1 ? 8.w : 0,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: AppTheme.buttonGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8.r,
                            offset: Offset(0, 4.h),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: AppTheme.shadowColor.withOpacity(0.05),
                            blurRadius: 4.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getCategoryIcon(category['type']),
                        size: 20.sp,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        category['label'],
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 获取分类图标
  IconData _getCategoryIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image_outlined;
      case 'template':
        return Icons.description_outlined;
      case 'prefix':
        return Icons.format_quote_outlined;
      case 'suffix':
        return Icons.format_quote_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  // 构建简单的文本分类器（保留作为备用）
  Widget _buildCategorySelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.border.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _categories.map((category) {
          final bool isSelected = _currentType == category['type'];
          return InkWell(
            onTap: () => _changeCategory(category['type']),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                category['label'],
                style: TextStyle(
                  fontSize: AppTheme.bodySize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 优化后的顶部导航栏
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.shadowColor.withOpacity(0.1),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: AppTheme.textPrimary,
                              size: 18.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '公共素材库',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '发现更多创作素材',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    // 优化后的分类选择器
                    _buildModernCategorySelector(),
                  ],
                ),
              ),
            Expanded(
              child: _buildMaterialList(_currentType),
            ),
          ],
        ),
      ),
    );
  }
}
