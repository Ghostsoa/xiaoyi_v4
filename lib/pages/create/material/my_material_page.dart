import 'package:flutter/material.dart';
import '../services/material_service.dart';
import '../../../services/file_service.dart';
import 'dart:async';
import 'edit_material_page.dart';
import '../../../widgets/custom_toast.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import 'dart:typed_data';

class MyMaterialPage extends StatefulWidget {
  const MyMaterialPage({super.key});

  @override
  State<MyMaterialPage> createState() => _MyMaterialPageState();
}

class _MyMaterialPageState extends State<MyMaterialPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scrollController.addListener(_handleScroll);
    _loadData(refresh: true);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.dispose();
    // 清除缓存
    _imageCache.clear();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentType = _getCurrentType();
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

  String _getCurrentType() {
    switch (_tabController.index) {
      case 0:
        return 'image';
      case 1:
        return 'template';
      case 2:
        return 'prefix';
      case 3:
        return 'suffix';
      default:
        return 'image';
    }
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
      final response = await _materialService.getMaterials(
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

  Future<void> _handleDelete(
      Map<String, dynamic> material, BuildContext dialogContext) async {
    // 先关闭对话框
    Navigator.pop(dialogContext);

    if (!mounted) return;

    try {
      // 如果是公开状态的素材，显示提示
      if (material['status'] == 'published') {
        _showToast(
          '已公开的素材不能删除，请先设为私有',
          type: ToastType.warning,
        );
        return;
      }

      await _materialService.deleteMaterial(
        material['id'].toString(),
      );
      if (!mounted) return;

      // 使用 BuildContext 扩展方法来显示 Toast
      _showToast(
        '删除成功',
        type: ToastType.success,
      );
      _loadData(refresh: true);
    } catch (e) {
      if (!mounted) return;

      String errorMsg = e.toString();
      if (errorMsg.contains('已公开的素材不能删除')) {
        errorMsg = '已公开的素材不能删除，请先设为私有';
      }
      _showToast(
        errorMsg,
        type: ToastType.error,
      );
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
                      child: Container(
                        color: AppTheme.cardBackground,
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
                            Container(
                              width: 60.w,
                              height: 14.h,
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXSmall),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              width: 40.w,
                              height: 12.h,
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXSmall),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
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
              Widget imageWidget;
              if (!snapshot.hasData || snapshot.hasError) {
                final random = material['id'].hashCode % 3;
                double aspectRatio = 1.0;
                if (random == 0) {
                  aspectRatio = 3 / 4;
                } else if (random == 1) {
                  aspectRatio = 4 / 3;
                }

                imageWidget = Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: aspectRatio,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    material['description'].length > 7
                                        ? '${material['description'].substring(0, 7)}...'
                                        : material['description'],
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: AppTheme.bodySize,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      await _materialService
                                          .toggleMaterialStatus(
                                              material['id'].toString());
                                      _showToast(
                                        '状态切换成功',
                                        type: ToastType.success,
                                      );
                                      _loadData(refresh: true);
                                    } catch (e) {
                                      _showToast(
                                        e.toString(),
                                        type: ToastType.error,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: material['status'] == 'published'
                                          ? AppTheme.primaryColor
                                          : AppTheme.textSecondary,
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusXSmall),
                                    ),
                                    child: Text(
                                      material['status'] == 'published'
                                          ? '公开'
                                          : '私有',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: AppTheme.captionSize,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
              } else {
                final random = material['id'].hashCode % 3;
                double aspectRatio = 1.0;
                if (random == 0) {
                  aspectRatio = 3 / 4;
                } else if (random == 1) {
                  aspectRatio = 4 / 3;
                }

                imageWidget = Stack(
                  children: [
                    // 添加点击查看大图功能
                    GestureDetector(
                      onTap: () => _showImageViewer(context, snapshot.data!),
                      child: Hero(
                        tag: 'image_${material['id']}',
                        child: AspectRatio(
                          aspectRatio: aspectRatio,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    material['description'].length > 7
                                        ? '${material['description'].substring(0, 7)}...'
                                        : material['description'],
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: AppTheme.bodySize,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      await _materialService
                                          .toggleMaterialStatus(
                                              material['id'].toString());
                                      _showToast(
                                        '状态切换成功',
                                        type: ToastType.success,
                                      );
                                      _loadData(refresh: true);
                                    } catch (e) {
                                      _showToast(
                                        e.toString(),
                                        type: ToastType.error,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: material['status'] == 'published'
                                          ? AppTheme.primaryColor
                                          : AppTheme.textSecondary,
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusXSmall),
                                    ),
                                    child: Text(
                                      material['status'] == 'published'
                                          ? '公开'
                                          : '私有',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: AppTheme.captionSize,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
              }
              return imageWidget;
            },
          ),
          Positioned(
            top: 8.h,
            right: 8.w,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: AppTheme.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    title: Text(
                      '确认删除',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppTheme.subheadingSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    content: Text(
                      '确定要删除这张图片吗？',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppTheme.bodySize,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          '取消',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.bodySize,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _handleDelete(material, dialogContext),
                        child: Text(
                          '删除',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: AppTheme.bodySize,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: AppTheme.textPrimary,
                  size: 18.sp,
                ),
              ),
            ),
          ),
        ],
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

  Widget _buildMaterialItem(Map<String, dynamic> material) {
    return InkWell(
      onTap: () {
        if (material['type'] != 'image') {
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
                        child: Text(
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
                        '@${material['author_name']} · ${material['created_at'].toString().substring(0, 16)}',
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
        }
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          material['description'],
                          style: TextStyle(
                            fontSize: AppTheme.bodySize,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: () async {
                          try {
                            await _materialService.toggleMaterialStatus(
                                material['id'].toString());
                            _showToast(
                              '状态切换成功',
                              type: ToastType.success,
                            );
                            _loadData(refresh: true);
                          } catch (e) {
                            _showToast(
                              e.toString(),
                              type: ToastType.error,
                            );
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: material['status'] == 'published'
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusXSmall),
                          ),
                          child: Text(
                            material['status'] == 'published' ? '公开' : '私有',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppTheme.captionSize,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '@${material['author_name']}',
                    style: TextStyle(
                      fontSize: AppTheme.captionSize,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (material['type'] != 'image') ...[
                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditMaterialPage(
                            material: material,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadData(refresh: true);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 32.w,
                      minHeight: 32.w,
                    ),
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18.sp,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(width: 4.w),
                ],
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: AppTheme.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        title: Text(
                          '确认删除',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: AppTheme.subheadingSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          '确定要删除这个素材吗？',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: AppTheme.bodySize,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              '取消',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: AppTheme.bodySize,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                _handleDelete(material, dialogContext),
                            child: Text(
                              '删除',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: AppTheme.bodySize,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 32.w,
                    minHeight: 32.w,
                  ),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18.sp,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
              // 使用InteractiveViewer实现缩放功能
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

  // 构建简单的文本分类器
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppTheme.textPrimary,
                      size: 24.sp,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 24.w,
                      minHeight: 24.w,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      '我的素材库',
                      style: TextStyle(
                        fontSize: AppTheme.headingSize,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditMaterialPage(
                            initialType: _currentType,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadData(refresh: true);
                      }
                    },
                    icon: Icon(Icons.add, size: 20.sp),
                    label: Text(
                      '创建',
                      style: TextStyle(
                        fontSize: AppTheme.bodySize,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 使用简单的文本分类器替代TabBar
            _buildCategorySelector(),
            Expanded(
              child: _buildMaterialList(_currentType),
            ),
          ],
        ),
      ),
    );
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
}
