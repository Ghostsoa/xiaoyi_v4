import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_theme.dart';
import 'data_analysis_page.dart';
import 'user_management/user_management_page.dart';
import 'card_management/card_management_page.dart';
import 'notification_management/notification_management_page.dart';
import 'model_management/model_management_page.dart';
import 'material_management/material_management_page.dart';
import 'character_management/character_management_page.dart';
import 'report_management/report_management_page.dart'; // 添加举报管理页面导入

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _currentIndex = 0;

  // 管理页面
  final List<Map<String, dynamic>> _adminPages = [
    {
      'title': '数据分析',
      'icon': Icons.analytics_outlined,
      'page': const DataAnalysisPage(),
    },
    {
      'title': '用户管理',
      'icon': Icons.people_outlined,
      'page': const UserManagementPage(),
    },
    {
      'title': '卡密管理',
      'icon': Icons.credit_card_outlined,
      'page': const CardManagementPage(),
    },
    {
      'title': '通知管理',
      'icon': Icons.notifications_outlined,
      'page': const NotificationManagementPage(),
    },
    {
      'title': '大模型管理',
      'icon': Icons.smart_toy_outlined,
      'page': const ModelManagementPage(),
    },
    {
      'title': '素材库管理',
      'icon': Icons.image_outlined,
      'page': const MaterialManagementPage(),
    },
    {
      'title': '角色卡管理',
      'icon': Icons.face_outlined,
      'page': const CharacterManagementPage(),
    },
    {
      'title': '举报管理',
      'icon': Icons.report_problem_outlined,
      'page': const ReportManagementPage(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryColor;
    final background = AppTheme.background;
    final surfaceColor = AppTheme.cardBackground;
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        title: Text(
          _adminPages[_currentIndex]['title'],
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: textPrimary,
            ),
            onPressed: () {
              // 通知功能
            },
          ),
        ],
      ),
      drawer: ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12.r),
          bottomRight: Radius.circular(12.r),
        ),
        child: Drawer(
          width: 230.w,
          backgroundColor: surfaceColor,
          child: SafeArea(
            child: Column(
              children: [
                // 抽屉头部
                Container(
                  height: 90.h,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16.r,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: primaryColor,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '管理员',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '系统管理员',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 菜单项
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Column(
                    children: List.generate(
                      _adminPages.length,
                      (index) => _buildDrawerItem(
                        icon: _adminPages[index]['icon'],
                        title: _adminPages[index]['title'],
                        isSelected: _currentIndex == index,
                        onTap: () {
                          setState(() {
                            _currentIndex = index;
                          });
                          Navigator.pop(context); // 关闭抽屉
                        },
                        textPrimary: textPrimary,
                        primaryColor: primaryColor,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // 底部按钮
                Padding(
                  padding:
                      EdgeInsets.only(left: 12.w, right: 12.w, bottom: 12.h),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6.r),
                    onTap: () {
                      Navigator.pop(context); // 关闭抽屉
                      Navigator.pop(context); // 返回用户页面
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.exit_to_app,
                            size: 14.sp,
                            color: primaryColor,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '返回用户页面',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _adminPages[_currentIndex]['page'],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color primaryColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        color: isSelected ? primaryColor.withOpacity(0.05) : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: isSelected ? primaryColor : textPrimary.withOpacity(0.7),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  color: isSelected ? primaryColor : textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 3.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
