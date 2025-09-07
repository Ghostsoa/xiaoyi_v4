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
  String? _selectedCategory;
  bool _isLoading = false;

  final List<Map<String, String>> _categories = [
    {
      'value': 'all',
      'label': '全部',
      'description': '显示所有分区的内容',
    },
    {
      'value': 'general',
      'label': '全性向',
      'description': '适合所有用户的内容',
    },
    {
      'value': 'female',
      'label': '女性向',
      'description': '主要面向女性用户的内容',
    },
    {
      'value': 'male',
      'label': '男性向',
      'description': '主要面向男性用户的内容',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 禁止返回
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 标题区域
                      Column(
                        children: [
                          Text(
                            '选择内容分区',
                            style: TextStyle(
                              color: Colors.white,
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
                              color: AppTheme.textSecondary.withOpacity(0.7),
                              fontSize: 14.sp,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 40.h),

                      // 分区选择列表
                      ...(_categories.map((category) => _buildCategoryCard(category))),
                    ],
                  ),
                ),

                // 确认按钮
                Container(
                  width: double.infinity,
                  height: 56.h,
                  margin: EdgeInsets.only(top: 24.h),
                  child: ElevatedButton(
                    onPressed: _selectedCategory != null && !_isLoading
                        ? _confirmSelection
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedCategory != null
                          ? AppTheme.primaryColor
                          : Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: _selectedCategory != null ? 8 : 0,
                      shadowColor: AppTheme.primaryColor.withOpacity(0.3),
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
                            '确认选择',
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

  Widget _buildCategoryCard(Map<String, String> category) {
    final bool isSelected = _selectedCategory == category['value'];

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = category['value'];
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.15),
                      AppTheme.primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.white.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // 文本内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['label']!,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      category['description']!,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14.sp,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // 选中指示器
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16.sp,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSelection() async {
    if (_selectedCategory == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 调用API更新分区偏好
      final result = await _homeService.updateHallPreferencesCategory(_selectedCategory!);

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
