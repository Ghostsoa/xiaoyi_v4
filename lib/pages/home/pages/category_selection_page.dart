import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_theme.dart';
import '../services/home_service.dart';
import '../../../widgets/custom_toast.dart';

class CategorySelectionPage extends StatefulWidget {
  const CategorySelectionPage({super.key});

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  final HomeService _homeService = HomeService();
  List<String> _selectedCategories = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'value': 'all',
      'label': '全部',
      'description': '显示所有分区的内容',
      'icon': Icons.apps_rounded,
      'gradient': [Color(0xFF667eea), Color(0xFF764ba2)],
      'isSpecial': true,
    },
    {
      'value': 'general',
      'label': '全性向',
      'description': '适合所有用户的内容',
      'icon': Icons.diversity_3_rounded,
      'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)],
      'isSpecial': false,
    },
    {
      'value': 'female',
      'label': '女性向',
      'description': '主要面向女性用户的内容',
      'icon': Icons.female_rounded,
      'gradient': [Color(0xFFf093fb), Color(0xFFf5576c)],
      'isSpecial': false,
    },
    {
      'value': 'male',
      'label': '男性向',
      'description': '主要面向男性用户的内容',
      'icon': Icons.male_rounded,
      'gradient': [Color(0xFF4facfe), Color(0xFF00f2fe)],
      'isSpecial': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 禁止返回
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 40.h),

                        // 标题区域
                        Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: AppTheme.primaryColor,
                                size: 32.sp,
                              ),
                            ),
                            SizedBox(height: 24.h),
                            Text(
                              '选择内容分区',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              '请选择您偏好的内容分区类型',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16.sp,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '这将影响为您展示的内容',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                                fontSize: 14.sp,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 40.h),

                        // 分区选择区域
                        _buildCategorySelection(),

                        SizedBox(height: 32.h),

                        // 选择规则提示
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppTheme.primaryColor,
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '选择规则',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                '• "全部"与其他分区互斥\n• 其他分区可以多选（最多2个）\n• 必须至少选择一个分区',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12.sp,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 确认按钮
                Container(
                  width: double.infinity,
                  height: 56.h,
                  margin: EdgeInsets.only(top: 24.h),
                  child: ElevatedButton(
                    onPressed: _selectedCategories.isNotEmpty && !_isLoading
                        ? _confirmSelection
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedCategories.isNotEmpty
                          ? AppTheme.primaryColor
                          : Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: _selectedCategories.isNotEmpty ? 8 : 0,
                      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _selectedCategories.isEmpty
                                ? '请选择分区'
                                : '确认选择 (${_selectedCategories.length})',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      children: [
        // 所有分区选项 - 每个都占一行，紧凑设计
        ..._categories.map((category) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildCompactCategoryCard(category),
          );
        }),
      ],
    );
  }

  Widget _buildCompactCategoryCard(Map<String, dynamic> category) {
    final isSelected = _selectedCategories.contains(category['value']);
    final categoryValue = category['value'];

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (categoryValue == 'all') {
              if (isSelected) {
                // 如果当前选中"全部"，取消选择
                _selectedCategories = [];
              } else {
                // 选择"全部"，清空其他选择
                _selectedCategories = ['all'];
              }
            } else {
              // 选择其他分区
              final hasAllSelected = _selectedCategories.contains('all');
              final canSelect = !hasAllSelected && (_selectedCategories.length < 2 || isSelected);

              if (canSelect) {
                List<String> newCategories = List.from(_selectedCategories);

                // 移除"全部"选项
                newCategories.remove('all');

                if (isSelected) {
                  // 如果已选中，则取消选择
                  newCategories.remove(categoryValue);
                } else {
                  // 如果未选中，则添加选择
                  newCategories.add(categoryValue);
                }

                _selectedCategories = newCategories;
              }
            }
          });
        },
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: category['gradient'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.3)
                  : AppTheme.textSecondary.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: category['gradient'][0].withValues(alpha: 0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isSelected ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  category['icon'],
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      category['description'],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppTheme.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.textSecondary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isSelected ? Icons.check_rounded : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  size: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Future<void> _confirmSelection() async {
    if (_selectedCategories.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 调用新的API更新分区偏好
      final result = await _homeService.updateUserPreferences(
        likedTags: [],
        dislikedTags: [],
        likedAuthors: [],
        dislikedAuthors: [],
        likedKeywords: [],
        dislikedKeywords: [],
        preferenceStrength: 1,
        applyToHall: 1,
        preferredCategories: _selectedCategories,
      );

      if (result['code'] == 0) {
        // 更新成功，保存本地标记
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('category_selection_completed', true);

        if (mounted) {
          CustomToast.show(
            context,
            message: '分区偏好设置成功',
            type: ToastType.success,
          );

          // 返回到主页并刷新
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          CustomToast.show(
            context,
            message: result['msg'] ?? '设置失败，请重试',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '设置失败，请检查网络连接',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
