import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../services/material_service.dart';
import '../../../widgets/custom_toast.dart';

enum TextSelectSource {
  myMaterial,
  publicMaterial,
}

enum TextSelectType {
  setting,
  prefix,
  suffix,
}

class SelectTextPage extends StatefulWidget {
  final TextSelectSource source;
  final TextSelectType type;

  const SelectTextPage({
    super.key,
    required this.source,
    required this.type,
  });

  @override
  State<SelectTextPage> createState() => _SelectTextPageState();
}

class _SelectTextPageState extends State<SelectTextPage> {
  final MaterialService _materialService = MaterialService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  List<Map<String, dynamic>> _materials = [];
  int _total = 0;
  late TextSelectSource _currentSource;

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
    String type = switch (widget.type) {
      TextSelectType.setting => '角色设定',
      TextSelectType.prefix => '前缀词',
      TextSelectType.suffix => '后缀词',
    };
    return '选择$type';
  }

  // 切换源
  void _changeSource(TextSelectSource source) {
    if (_currentSource != source) {
      setState(() {
        _currentSource = source;
        _loadData(refresh: true);
      });
    }
  }

  // 现代化的源选择器
  Widget _buildModernSourceSelector() {
    return SizedBox(
      height: 50.h,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _changeSource(TextSelectSource.myMaterial),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  gradient: _currentSource == TextSelectSource.myMaterial
                      ? LinearGradient(
                          colors: AppTheme.buttonGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _currentSource == TextSelectSource.myMaterial ? null : AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: _currentSource == TextSelectSource.myMaterial
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
                        color: _currentSource == TextSelectSource.myMaterial ? Colors.white : AppTheme.textSecondary,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '我的素材',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: _currentSource == TextSelectSource.myMaterial ? FontWeight.w600 : FontWeight.w500,
                          color: _currentSource == TextSelectSource.myMaterial ? Colors.white : AppTheme.textSecondary,
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
              onTap: () => _changeSource(TextSelectSource.publicMaterial),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: _currentSource == TextSelectSource.publicMaterial
                      ? LinearGradient(
                          colors: AppTheme.buttonGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _currentSource == TextSelectSource.publicMaterial ? null : AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: _currentSource == TextSelectSource.publicMaterial
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
                        color: _currentSource == TextSelectSource.publicMaterial ? Colors.white : AppTheme.textSecondary,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '公开素材',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: _currentSource == TextSelectSource.publicMaterial ? FontWeight.w600 : FontWeight.w500,
                          color: _currentSource == TextSelectSource.publicMaterial ? Colors.white : AppTheme.textSecondary,
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
              source: TextSelectSource.myMaterial,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _buildSourceButton(
              title: '公开素材',
              icon: Icons.folder_shared_outlined,
              source: TextSelectSource.publicMaterial,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceButton({
    required String title,
    required IconData icon,
    required TextSelectSource source,
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

  String _getMaterialType() {
    return switch (widget.type) {
      TextSelectType.setting => 'template',
      TextSelectType.prefix => 'prefix',
      TextSelectType.suffix => 'suffix',
    };
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
      final response = _currentSource == TextSelectSource.myMaterial
          ? await _materialService.getMaterials(
              page: _currentPage,
              pageSize: _pageSize,
              type: _getMaterialType(),
            )
          : await _materialService.getPublicMaterials(
              page: _currentPage,
              pageSize: _pageSize,
              type: _getMaterialType(),
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
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
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
        return _buildMaterialItem(material);
      },
    );
  }

  Widget _buildMaterialItem(Map<String, dynamic> material) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop(material['metadata']);
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
                      if (_currentSource == TextSelectSource.publicMaterial)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusXSmall),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '公开',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: AppTheme.smallSize,
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
            Icon(
              Icons.chevron_right,
              size: 20.sp,
              color: AppTheme.textSecondary.withOpacity(0.5),
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
            Icons.format_quote,
            size: 64.sp,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            '暂无${_getTypeLabel()}',
            style: TextStyle(
              fontSize: AppTheme.bodySize,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel() {
    return switch (widget.type) {
      TextSelectType.setting => '角色设定',
      TextSelectType.prefix => '前缀词',
      TextSelectType.suffix => '后缀词',
    };
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
                              _getTitle(),
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '从素材库中选择合适的文本',
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
