import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';

class BasicInfoCard extends StatelessWidget {
  final Map<String, dynamic> sessionData;

  const BasicInfoCard({
    super.key,
    required this.sessionData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoItem('名称', sessionData['name'] ?? '未知', Icons.person,
            AppTheme.primaryColor),
        if (sessionData['tags'] != null)
          _buildInfoItem(
            '标签',
            (sessionData['tags'] as List<dynamic>)
                .map((tag) => '#$tag')
                .join(' '),
            Icons.tag,
            AppTheme.accentPink,
          ),
        _buildInfoItem('作者', sessionData['author_name'] ?? '未知',
            Icons.person_outline, AppTheme.primaryLight),
        _buildInfoItem('创建时间', _formatDateTime(sessionData['created_at']),
            Icons.access_time, AppTheme.primaryColor.withBlue(180)),
        _buildInfoItem('更新时间', _formatDateTime(sessionData['updated_at']),
            Icons.update, AppTheme.primaryColor.withRed(180)),
      ],
    );
  }

  Widget _buildInfoItem(
      String label, String value, IconData icon, Color accentColor) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '未知';
    try {
      return DateTime.parse(dateTimeStr).toLocal().toString().split('.')[0];
    } catch (e) {
      return '未知';
    }
  }
}
