import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'base_card.dart';

class BasicInfoCard extends StatelessWidget {
  final Map<String, dynamic> sessionData;

  const BasicInfoCard({
    super.key,
    required this.sessionData,
  });

  @override
  Widget build(BuildContext context) {
    final Color pageColor = Colors.blue.shade400; // 使用分页的蓝色

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 移除标题部分
        _buildInfoItem(
            '名称', sessionData['name'] ?? '未知', Icons.person, Colors.blue),
        if (sessionData['tags'] != null)
          _buildInfoItem(
            '标签',
            (sessionData['tags'] as List<dynamic>)
                .map((tag) => '#$tag')
                .join(' '),
            Icons.tag,
            Colors.purple,
          ),
        _buildInfoItem('作者', sessionData['author_name'] ?? '未知',
            Icons.person_outline, Colors.green),
        _buildInfoItem('创建时间', _formatDateTime(sessionData['created_at']),
            Icons.access_time, Colors.orange),
        _buildInfoItem('更新时间', _formatDateTime(sessionData['updated_at']),
            Icons.update, Colors.pink),
      ],
    );
  }

  Widget _buildInfoItem(
      String label, String value, IconData icon, Color accentColor) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.2),
                  Colors.black.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withOpacity(0.8),
                        accentColor.withOpacity(0.5),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
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
                          color: Colors.white, // 改为白色，不再跟随容器颜色
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
