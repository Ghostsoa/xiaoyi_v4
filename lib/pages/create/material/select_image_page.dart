import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../services/material_service.dart';
import '../../../services/file_service.dart';
import '../../../widgets/custom_toast.dart';
import 'package:shimmer/shimmer.dart';

enum ImageSelectSource {
  myMaterial,
  publicMaterial,
}

enum ImageSelectType {
  cover,
  background,
}

class SelectImagePage extends StatefulWidget {
  final ImageSelectSource source;
  final ImageSelectType type;

  const SelectImagePage({
    super.key,
    required this.source,
    required this.type,
  });

  @override
  State<SelectImagePage> createState() => _SelectImagePageState();
}

class _SelectImagePageState extends State<SelectImagePage> {
  final MaterialService _materialService = MaterialService();
  final FileService _fileService = FileService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  List<Map<String, dynamic>> _materials = [];
  int _total = 0;
  late ImageSelectSource _currentSource;

  @override
  void initState() {
    super.initState();
    _currentSource = widget.source;
    _scrollController.addListener(_handleScroll);
    _loadData(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _loadData();
      }
    }
  }

  String _getTitle() {
    String type = widget.type == ImageSelectType.cover ? '封面图片' : '背景图片';
    return '选择$type';
  }

  Widget _buildSourceSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: _buildSourceButton(
              title: '我的素材',
              icon: Icons.folder_outlined,
              source: ImageSelectSource.myMaterial,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _buildSourceButton(
              title: '公开素材',
              icon: Icons.folder_shared_outlined,
              source: ImageSelectSource.publicMaterial,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceButton({
    required String title,
    required IconData icon,
    required ImageSelectSource source,
  }) {
    final bool isSelected = _currentSource == source;
    return GestureDetector(
      onTap: () {
        if (_currentSource != source) {
          setState(() {
            _currentSource = source;
            _loadData(refresh: true);
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.border,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: AppTheme.bodySize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
        _materials = [];
      }
    });

    try {
      final response = _currentSource == ImageSelectSource.myMaterial
          ? await _materialService.getMaterials(
              page: _currentPage,
              pageSize: _pageSize,
              type: 'image',
            )
          : await _materialService.getPublicMaterials(
              page: _currentPage,
              pageSize: _pageSize,
              type: 'image',
            );

      if (!mounted) return;

      setState(() {
        if (refresh) {
          _materials = List<Map<String, dynamic>>.from(response['items']);
        } else {
          _materials.addAll(List<Map<String, dynamic>>.from(response['items']));
        }
        _total = response['total'];
        _hasMore = _materials.length < response['total'];
        _currentPage += 1;
      });
    } catch (e) {
      if (!mounted) return;
      _showToast(e.toString(), type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showToast(String message, {ToastType type = ToastType.info}) {
    if (!mounted) return;
    CustomToast.show(context, message: message, type: type);
  }

  Widget _buildMaterialList() {
    if (_materials.isEmpty) {
      if (_isLoading && _currentPage == 1) {
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
            return Shimmer.fromColors(
              baseColor: AppTheme.cardBackground,
              highlightColor: AppTheme.cardBackground.withOpacity(0.5),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                ),
                child: AspectRatio(
                  aspectRatio: 0.75,
                  child: Container(
                    color: AppTheme.cardBackground,
                  ),
                ),
              ),
            );
          },
        );
      }
      return _buildEmptyState();
    }

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        childAspectRatio: 0.75,
      ),
      itemCount: _materials.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _materials.length) {
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

        final material = _materials[index];
        return _buildImageMaterialItem(material);
      },
    );
  }

  Widget _buildImageMaterialItem(Map<String, dynamic> material) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(material['metadata']);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
        ),
        child: Stack(
          children: [
            FutureBuilder(
              future: _fileService.getFile(material['metadata']),
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

                return AspectRatio(
                  aspectRatio: 0.75,
                  child: Image.memory(
                    snapshot.data!.data,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.cardBackground,
                        child: Center(
                          child: Icon(
                            Icons.error_outline,
                            color: AppTheme.textSecondary.withOpacity(0.5),
                            size: 32.sp,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
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
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64.sp,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            '暂无图片',
            style: TextStyle(
              fontSize: AppTheme.bodySize,
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
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 8.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppTheme.textPrimary,
                        size: 18.sp,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _getTitle(),
                        style: TextStyle(
                          fontSize: AppTheme.titleSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 32.w),
                ],
              ),
            ),
            _buildSourceSelector(),
            Expanded(
              child: _buildMaterialList(),
            ),
          ],
        ),
      ),
    );
  }
}
