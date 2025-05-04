import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';

class DeclarationPage extends StatelessWidget {
  const DeclarationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;
    final background = AppTheme.background;

    final List<Map<String, dynamic>> declarations = [
      {
        'title': '内容原创',
        'icon': Icons.copyright,
        'color': Color(0xFF6366F1),
        'content': '1. 您在平台上发布的所有创作内容必须是原创作品。\n'
            '2. 严禁抄袭、剽窃他人作品或侵犯他人知识产权。\n'
            '3. 如发现任何侵权行为，平台将采取相应措施，包括但不限于删除内容、封禁账号等。',
      },
      {
        'title': '内容规范',
        'icon': Icons.rule,
        'color': Color(0xFF10B981),
        'content': '1. 创作内容必须遵守相关法律法规。\n'
            '2. 禁止发布含有暴力、色情、歧视、政治敏感等不当内容。\n'
            '3. 遵守社区规范，维护良好的创作环境。',
      },
      {
        'title': '版权声明',
        'icon': Icons.verified_user,
        'color': Color(0xFFF59E0B),
        'content': '1. 您发布的原创内容版权归您所有。\n'
            '2. 授权平台对您的作品进行展示、推广等合理使用。\n'
            '3. 未经授权，其他用户不得擅自使用您的作品。',
      },
      {
        'title': '免责声明',
        'icon': Icons.gavel,
        'color': Color(0xFF8B5CF6),
        'content': '1. 平台不对用户发布的内容承担责任。\n'
            '2. 因违规内容造成的任何损失由发布者承担。\n'
            '3. 平台保留对违规内容进行处理的权利。',
      },
      {
        'title': '处罚规则',
        'icon': Icons.warning,
        'color': Color(0xFFEF4444),
        'content': '1. 首次违规将收到警告。\n'
            '2. 多次违规可能导致账号被限制使用或永久封禁。\n'
            '3. 严重违规将直接封禁账号，且相关内容将被删除。',
      },
    ];

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          children: [
            // 顶部标题和返回按钮
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: textPrimary,
                      size: 24.sp,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 24.w,
                      minHeight: 24.w,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '必读声明',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTheme.headingSize,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 24.w),
                ],
              ),
            ),

            // 顶部警告提示
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: AppTheme.error.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.error,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      '请仔细阅读以下声明',
                      style: TextStyle(
                        fontSize: AppTheme.bodySize,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // 声明内容
            ...declarations.map((declaration) => Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: (declaration['color'] as Color).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color:
                              (declaration['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(AppTheme.radiusSmall),
                            topRight: Radius.circular(AppTheme.radiusSmall),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              declaration['icon'] as IconData,
                              color: declaration['color'] as Color,
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              declaration['title'] as String,
                              style: TextStyle(
                                fontSize: AppTheme.subheadingSize,
                                fontWeight: FontWeight.w600,
                                color: declaration['color'] as Color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Text(
                          declaration['content'] as String,
                          style: TextStyle(
                            fontSize: AppTheme.bodySize,
                            height: 1.6,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

            // 底部确认文本
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryColor,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      '开始创作即代表您已阅读并同意以上声明内容。如有违反，平台将保留追究责任的权利。',
                      style: TextStyle(
                        fontSize: AppTheme.bodySize,
                        color: textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
