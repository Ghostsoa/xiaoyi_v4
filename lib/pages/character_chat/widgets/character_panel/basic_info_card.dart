import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        _buildInfoItem('名称', sessionData['name'] ?? '未知'),
        _buildInfoItem('描述', sessionData['description'] ?? '暂无描述'),
        if (sessionData['tags'] != null)
          _buildInfoItem(
            '标签',
            (sessionData['tags'] as List<dynamic>)
                .map((tag) => '#$tag')
                .join(' '),
          ),
        _buildInfoItem('作者', sessionData['author_name'] ?? '未知'),
        _buildInfoItem('创建时间', _formatDateTime(sessionData['created_at'])),
        _buildInfoItem('更新时间', _formatDateTime(sessionData['updated_at'])),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
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
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white,
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
