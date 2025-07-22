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

    final List<Map<String, dynamic>> guideSections = [
      {
        'title': '创作类型',
        'icon': Icons.palette_outlined,
        'color': const Color(0xFF6366F1),
        'items': [
          {
            'title': '角色卡',
            'icon': Icons.person_outline,
            'content': [
              '专门用于角色扮演的卡片',
              '可以创建各种性格和设定的角色',
              '与角色进行沉浸式的对话和互动',
              '可以设定角色的背景故事和行为模式',
            ],
          },
          {
            'title': '小说卡',
            'icon': Icons.book_outlined,
            'content': [
              '专门用于阅读AI创作的小说',
              'AI将全程负责小说创作、剧情发展、角色互动',
              '你可以通过交互引导剧情发展方向',
              '享受沉浸式的阅读体验',
            ],
          },
        ],
      },
      {
        'title': '对话记忆说明',
        'icon': Icons.memory_outlined,
        'color': const Color(0xFF10B981),
        'items': [
          {
            'title': '关于对话记忆',
            'icon': Icons.info_outline,
            'content': [
              '市面上所谓的"永久记忆"都是虚假宣传',
              '我们会充分利用模型100万token、12.8万token的最大上下文窗口，并以此规定支持最多500轮对话',
              '当前会话的对话记录会一直保留',
            ],
          },
        ],
      },
      {
        'title': '世界书',
        'icon': Icons.public_outlined,
        'color': const Color(0xFFF59E0B),
        'items': [
          {
            'title': '什么是世界书',
            'icon': Icons.help_outline,
            'content': [
              '世界书是一个设定集合，可以通过数据库，额外存储设定以外的世界观、规则等设定',
              '当用户输入或大模型回复包含关键词时，会自动触发世界书条目临时加入上下文，并不会留存于历史记录',
              '我们提供高效的算法，确保世界书条目不会影响大模型推理速度',
              '每个卡最多支持100条世界书条目，且支持自定义关键词检索深度，最大支持10轮深度',
              '支持公开分享和复用',
            ],
          },
        ],
      },
      {
        'title': '前、后缀词',
        'icon': Icons.text_fields_outlined,
        'color': const Color(0xFFEC4899),
        'items': [
          {
            'title': '什么是前缀词、后缀词',
            'icon': Icons.help_outline,
            'content': [
              '前缀词、后缀词是用于引导大模型生成特定内容',
              '前缀词：在用户输入时，会自动触发前缀词临时加入用户输入前',
              '后缀词：在用户输入时，会自动触发前缀词临时加入用户输入后',
              '你可以同时设置前、后缀词，将会每次输入时都会生效于当前回复',
            ],
          },
        ],
      },
      {
        'title': '社区共享',
        'icon': Icons.share_outlined,
        'color': const Color(0xFF8B5CF6),
        'items': [
          {
            'title': '素材库',
            'icon': Icons.folder_shared_outlined,
            'content': [
              '社区共享的创作资源，所有内容均来自用户分享',
              '可以浏览和使用其他创作者分享的素材',
              '也欢迎分享你的创作成果',
            ],
          },
        ],
      },
    ];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          '创作指南',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ),
      body: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        itemCount: guideSections.length,
        separatorBuilder: (context, index) => Divider(
          height: 48.h,
          color: AppTheme.border.withOpacity(0.2),
        ),
        itemBuilder: (context, sectionIndex) {
          final section = guideSections[sectionIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 章节标题
              Row(
                children: [
                  Icon(
                    section['icon'] as IconData,
                    color: section['color'] as Color,
                    size: 22.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    section['title'] as String,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              ...List.generate(
                (section['items'] as List).length,
                (index) {
                  final item =
                      (section['items'] as List)[index] as Map<String, dynamic>;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        ...List.generate(
                          (item['content'] as List).length,
                          (contentIndex) {
                            return Padding(
                              padding: EdgeInsets.only(left: 16.w, bottom: 8.h),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 6.h),
                                    child: Icon(
                                      Icons.circle,
                                      size: 6.sp,
                                      color: textSecondary,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Text(
                                      (item['content'] as List)[contentIndex],
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: textSecondary,
                                        height: 1.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
    );
  }
}
