import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import 'base_card.dart';

class BasicInfoCard extends StatelessWidget {
  final Map<String, dynamic> sessionData;

  const BasicInfoCard({
    super.key,
    required this.sessionData,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      title: '基本信息',
      children: [
        _buildInfoItem('名称', sessionData['name'] ?? '未知', Icons.person),
        if (sessionData['tags'] != null)
          _buildInfoItem(
            '标签',
            (sessionData['tags'] as List<dynamic>)
                .map((tag) => '#$tag')
                .join(' '),
            Icons.tag,
          ),
        _buildInfoItem(
            '作者', sessionData['author_name'] ?? '未知', Icons.person_outline),
        _buildInfoItem('创建时间', _formatDateTime(sessionData['created_at']),
            Icons.access_time),
        _buildInfoItem(
            '更新时间', _formatDateTime(sessionData['updated_at']), Icons.update),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor.withOpacity(0.7),
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white,
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
