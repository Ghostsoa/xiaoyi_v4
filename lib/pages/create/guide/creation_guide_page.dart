import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';

class CreationGuidePage extends StatelessWidget {
  const CreationGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;
    final background = AppTheme.background;

    final List<Map<String, dynamic>> guideItems = [
      {
        'title': '创作类型',
        'icon': Icons.create,
        'color': Color(0xFF6366F1),
        'items': [
          {
            'title': '角色卡',
            'icon': Icons.person,
            'content': '专门用于角色扮演的卡片：\n'
                '• 可以创建各种性格和设定的角色\n'
                '• 与角色进行沉浸式的对话和互动\n'
                '• 可以设定角色的背景故事和行为模式',
          },
          {
            'title': '小说卡',
            'icon': Icons.book,
            'content': '专门用于阅读AI创作的小说：\n'
                '• AI将全程负责小说创作、剧情发展、角色互动\n'
                '• 你可以通过交互引导剧情发展方向\n'
                '• 享受沉浸式的阅读体验',
          },
          {
            'title': '对话记忆说明',
            'icon': Icons.memory,
            'content': '关于对话记忆：\n'
                '• 市面上所谓的"永久记忆"都是虚假宣传\n'
                '• 我们会充分利用模型100万token、12.8万token的最大上下文窗口，并以此规定支持最多500轮对话\n'
                '• 当前会话的对话记录会一直保留\n',
          },
        ],
      },
      {
        'title': '世界书',
        'icon': Icons.public,
        'color': Color(0xFF10B981),
        'items': [
          {
            'title': '什么是世界书',
            'icon': Icons.help_outline,
            'content': '世界书是一个设定集合：\n'
                '• 可以通过数据库，额外存储设定以外的世界观、规则等设定\n'
                '• 当用户输入或大模型回复包含关键词时，会自动触发世界书条目临时加入上下文，并不会留存于历史记录\n'
                '• 我们提供高效的算法，确保世界书条目不会影响大模型推理速度\n'
                '• 每个卡最多支持100条世界书条目，且支持自定义关键词检索深度，最大支持10轮深度\n'
                '• 支持公开分享和复用',
          },
        ],
      },
      {
        'title': '前、后缀词',
        'icon': Icons.text_fields,
        'color': Color(0xFFF59E0B),
        'items': [
          {
            'title': '什么是前缀词、后缀词:',
            'icon': Icons.help_outline,
            'content': '前缀词、后缀词是用于引导大模型生成特定内容：\n'
                '• 前缀词：在用户输入时，会自动触发前缀词临时加入用户输入前\n'
                '• 比如：用户输入"我叫小明"，前缀词为"你好，"，则大模型会生成"你好，我是小明"\n'
                '• 后缀词：在用户输入时，会自动触发前缀词临时加入用户输入后\n'
                '• 比如：用户输入"我叫小明"，后缀词为"，很高兴认识你"，则大模型会生成"我叫小明，很高兴认识你"\n'
                '• 你可以同时设置前、后缀词，将会每次输入时都会生效于当前回复\n'
          },
        ],
      },
      {
        'title': '社区共享',
        'icon': Icons.share,
        'color': Color(0xFFEC4899),
        'items': [
          {
            'title': '素材库',
            'icon': Icons.folder_shared,
            'content': '社区共享的创作资源：\n'
                '• 所有内容均来自用户分享\n'
                '• 可以浏览和使用其他创作者分享的素材\n'
                '• 也欢迎分享你的创作成果',
          },
        ],
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
                      '创作指南',
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

            // 指南内容
            ...List.generate(
              guideItems.length,
              (sectionIndex) {
                final section = guideItems[sectionIndex];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sectionIndex > 0) SizedBox(height: 32.h),
                    // 章节标题
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: (section['color'] as Color).withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            section['icon'] as IconData,
                            color: section['color'] as Color,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            section['title'] as String,
                            style: TextStyle(
                              fontSize: AppTheme.subheadingSize,
                              fontWeight: FontWeight.w600,
                              color: section['color'] as Color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ...List.generate(
                      (section['items'] as List).length,
                      (index) {
                        final item = (section['items'] as List)[index]
                            as Map<String, dynamic>;
                        return Container(
                          margin: EdgeInsets.only(bottom: 16.h),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color:
                                  (section['color'] as Color).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    color: section['color'] as Color,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    item['title'] as String,
                                    style: TextStyle(
                                      fontSize: AppTheme.bodySize,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                item['content'] as String,
                                style: TextStyle(
                                  fontSize: AppTheme.bodySize,
                                  color: textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
