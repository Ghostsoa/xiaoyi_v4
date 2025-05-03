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

    final List<Map<String, String>> declarations = [
      {
        'title': '内容原创',
        'content': '1. 您在平台上发布的所有创作内容必须是原创作品。\n'
            '2. 严禁抄袭、剽窃他人作品或侵犯他人知识产权。\n'
            '3. 如发现任何侵权行为，平台将采取相应措施，包括但不限于删除内容、封禁账号等。',
      },
      {
        'title': '内容规范',
        'content': '1. 创作内容必须遵守相关法律法规。\n'
            '2. 禁止发布含有暴力、色情、歧视、政治敏感等不当内容。\n'
            '3. 遵守社区规范，维护良好的创作环境。',
      },
      {
        'title': '版权声明',
        'content': '1. 您发布的原创内容版权归您所有。\n'
            '2. 授权平台对您的作品进行展示、推广等合理使用。\n'
            '3. 未经授权，其他用户不得擅自使用您的作品。',
      },
      {
        'title': '免责声明',
        'content': '1. 平台不对用户发布的内容承担责任。\n'
            '2. 因违规内容造成的任何损失由发布者承担。\n'
            '3. 平台保留对违规内容进行处理的权利。',
      },
      {
        'title': '处罚规则',
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
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: textPrimary,
                      size: 20.sp,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '必读声明',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20.sp),
                ],
              ),
            ),

            // 顶部警告提示
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.error,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  '请仔细阅读以下声明',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // 声明内容
            ...declarations.map((declaration) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      declaration['title']!,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      declaration['content']!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.6,
                        color: textSecondary,
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                )),

            // 底部确认文本
            SizedBox(height: 8.h),
            Text(
              '开始创作即代表您已阅读并同意以上声明内容。如有违反，平台将保留追究责任的权利。',
              style: TextStyle(
                fontSize: 13.sp,
                color: textSecondary,
                height: 1.6,
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
