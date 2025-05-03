import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/custom_toast.dart';
import '../../../theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WorldBookDetailPage extends StatelessWidget {
  final Map<String, dynamic> worldBook;

  const WorldBookDetailPage({
    super.key,
    required this.worldBook,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '世界书详情',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: AppTheme.titleSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.copy_outlined, color: AppTheme.textPrimary),
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: worldBook['content'] ?? ''));
              CustomToast.show(
                context,
                message: '内容已复制到剪贴板',
                type: ToastType.success,
              );
            },
            tooltip: '复制内容',
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),
              // 标题
              Text(
                worldBook['title'],
                style: TextStyle(
                  fontSize: AppTheme.subheadingSize,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),

              // 状态和使用信息
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: AppTheme.smallSize,
                  height: 1.4,
                  color: AppTheme.textSecondary,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: worldBook['status'] == 'published'
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : AppTheme.cardBackground,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusXSmall),
                      ),
                      child: Text(
                        worldBook['status'] == 'published' ? '已公开' : '私密',
                        style: TextStyle(
                          color: worldBook['status'] == 'published'
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text('@${worldBook['author_name'] ?? ''}'),
                    SizedBox(width: 12.w),
                    Icon(
                      Icons.bar_chart,
                      size: 14.sp,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(width: 2.w),
                    Text('${worldBook['usage_count'] ?? 0}次使用'),
                    SizedBox(width: 12.w),
                    Icon(
                      Icons.access_time,
                      size: 14.sp,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(width: 2.w),
                    Text(_formatDate(worldBook['updated_at'])),
                  ],
                ),
              ),

              // 关键词
              if (worldBook['keywords'] != null &&
                  (worldBook['keywords'] as List).isNotEmpty) ...[
                SizedBox(height: 16.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '关键词：',
                      style: TextStyle(
                        fontSize: AppTheme.smallSize,
                        height: 1.4,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children:
                            (worldBook['keywords'] as List).map((keyword) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusXSmall),
                            ),
                            child: Text(
                              keyword.toString(),
                              style: TextStyle(
                                fontSize: AppTheme.smallSize,
                                height: 1.4,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: 24.h),
              Text(
                worldBook['content'] ?? '',
                style: TextStyle(
                  fontSize: AppTheme.bodySize,
                  height: 1.8,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
