import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';

enum SettingItemType {
  network,
  theme,
  help,
  about,
  admin,
  apiKey,
  logout,
}

class SettingsWidget extends StatelessWidget {
  final Function(SettingItemType) onSettingTap;
  final bool showAdminEntry;

  const SettingsWidget({
    super.key,
    required this.onSettingTap,
    this.showAdminEntry = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.border.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '设置',
            style: AppTheme.titleStyle,
          ),
          SizedBox(height: 16.h),
          _buildSettingItem(
            icon: Icons.language,
            title: '网络节点设置',
            onTap: () => onSettingTap(SettingItemType.network),
          ),
          _buildSettingItem(
            icon: Icons.palette_outlined,
            title: '主题设置',
            onTap: () => onSettingTap(SettingItemType.theme),
          ),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: '帮助与反馈',
            onTap: () => onSettingTap(SettingItemType.help),
          ),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: '关于我们',
            onTap: () => onSettingTap(SettingItemType.about),
          ),
          _buildSettingItem(
            icon: Icons.vpn_key_outlined,
            title: 'API Key管理',
            onTap: () => onSettingTap(SettingItemType.apiKey),
          ),
          if (showAdminEntry)
            _buildSettingItem(
              icon: Icons.admin_panel_settings_outlined,
              title: '后台管理',
              onTap: () => onSettingTap(SettingItemType.admin),
            ),
          _buildSettingItem(
            icon: Icons.logout,
            title: '退出登录',
            onTap: () => onSettingTap(SettingItemType.logout),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.textPrimary,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.bodyStyle,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textSecondary,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            color: AppTheme.border.withOpacity(0.1),
            height: 1.h,
          ),
      ],
    );
  }
}
