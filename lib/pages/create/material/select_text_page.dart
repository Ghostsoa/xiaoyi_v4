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

  @override
  void initState() {
    super.initState();
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
    String source = widget.source == TextSelectSource.myMaterial ? '我的' : '公共';
    String type = switch (widget.type) {
      TextSelectType.setting => '角色设定',
      TextSelectType.prefix => '前缀词',
      TextSelectType.suffix => '后缀词',
    };
    return '选择$type - $source素材库';
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
      final response = widget.source == TextSelectSource.myMaterial
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
                  ? const CircularProgressIndicator()
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
                      if (widget.source == TextSelectSource.publicMaterial)
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
                        borderRadius: BorderRadius.circular(8.r),
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
                          fontSize: 18.sp,
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
            Expanded(
              child: _buildMaterialList(),
            ),
          ],
        ),
      ),
    );
  }
}
