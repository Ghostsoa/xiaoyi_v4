import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../services/material_service.dart';
import '../../../services/file_service.dart';
import '../../../widgets/custom_toast.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

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
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  List<Map<String, dynamic>> _materials = [];
  int _total = 0;
  late ImageSelectSource _currentSource;
  String? _keyword; // 搜索关键词
  Timer? _debounceTimer; // 防抖定时器

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
    _searchController.dispose();
    _debounceTimer?.cancel();
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

  // 切换源
  void _changeSource(ImageSelectSource source) {
    if (_currentSource != source) {
      setState(() {
        _currentSource = source;
        _loadData(refresh: true);
      });
    }
  }

  // 处理搜索输入（带防抖）
  void _handleSearchInput(String value) {
    // 取消之前的定时器
    _debounceTimer?.cancel();
    
    // 创建新的防抖定时器，延迟500毫秒
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_keyword != value) {
        setState(() {
          _keyword = value.isEmpty ? null : value;
          _currentPage = 1;
          _hasMore = true;
          _materials = [];
        });
        _loadData(refresh: true);
      }
    });
  }

  // 清除搜索
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _keyword = null;
      _currentPage = 1;
      _hasMore = true;
      _materials = [];
    });
    _loadData(refresh: true);
  }

  // 现代化的源选择器
  Widget _buildModernSourceSelector() {
    return SizedBox(
      height: 50.h,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _changeSource(ImageSelectSource.myMaterial),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  gradient: _currentSource == ImageSelectSource.myMaterial
                      ? LinearGradient(
                          colors: AppTheme.buttonGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _currentSource == ImageSelectSource.myMaterial ? null : AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: _currentSource == ImageSelectSource.myMaterial
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
                        Icons.folder_outlined,
                        size: 20.sp,
                        color: _currentSource == ImageSelectSource.myMaterial ? Colors.white : AppTheme.textSecondary,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '我的素材',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: _currentSource == ImageSelectSource.myMaterial ? FontWeight.w600 : FontWeight.w500,
                          color: _currentSource == ImageSelectSource.myMaterial ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _changeSource(ImageSelectSource.publicMaterial),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: _currentSource == ImageSelectSource.publicMaterial
                      ? LinearGradient(
                          colors: AppTheme.buttonGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _currentSource == ImageSelectSource.publicMaterial ? null : AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: _currentSource == ImageSelectSource.publicMaterial
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
                        Icons.folder_shared_outlined,
                        size: 20.sp,
                        color: _currentSource == ImageSelectSource.publicMaterial ? Colors.white : AppTheme.textSecondary,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '公开素材',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: _currentSource == ImageSelectSource.publicMaterial ? FontWeight.w600 : FontWeight.w500,
                          color: _currentSource == ImageSelectSource.publicMaterial ? Colors.white : AppTheme.textSecondary,
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
    );
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
              keyword: _keyword,
            )
          : await _materialService.getPublicMaterials(
              page: _currentPage,
              pageSize: _pageSize,
              type: 'image',
              keyword: _keyword,
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
            // 优化后的顶部导航栏
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.shadowColor.withOpacity(0.1),
                                blurRadius: 6.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: AppTheme.textPrimary,
                            size: 16.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        _getTitle(),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  // 搜索框
                  Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowColor.withOpacity(0.05),
                          blurRadius: 4.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _handleSearchInput,
                      decoration: InputDecoration(
                        hintText: '搜索图片...',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.textSecondary,
                          size: 18.sp,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: AppTheme.textSecondary,
                                  size: 18.sp,
                                ),
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                      ),
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // 优化后的源选择器
                  _buildModernSourceSelector(),
                ],
              ),
            ),
            Expanded(
              child: _buildMaterialList(),
            ),
          ],
        ),
      ),
    );
  }
}
