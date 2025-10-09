import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/expandable_text_field.dart';
import '../../html/html_template_selector_page.dart';

class AdvancedSettingsModule extends StatefulWidget {
  final TextEditingController greetingController;
  final TextEditingController prefixController;
  final TextEditingController suffixController;
  final int memoryRounds;
  final int maxRoleControlCount;
  final String visibility;
  final String prefixSuffixEditable;
  final String htmlTemplates; // "100,200,300" 格式
  final Function(int) onMemoryRoundsChanged;
  final Function(int) onMaxRoleControlCountChanged;
  final Function(String) onVisibilityChanged;
  final Function(String) onPrefixSuffixEditableChanged;
  final Function(String) onHtmlTemplatesChanged;

  const AdvancedSettingsModule({
    super.key,
    required this.greetingController,
    required this.prefixController,
    required this.suffixController,
    required this.memoryRounds,
    required this.maxRoleControlCount,
    required this.visibility,
    required this.prefixSuffixEditable,
    required this.htmlTemplates,
    required this.onMemoryRoundsChanged,
    required this.onMaxRoleControlCountChanged,
    required this.onVisibilityChanged,
    required this.onPrefixSuffixEditableChanged,
    required this.onHtmlTemplatesChanged,
  });

  @override
  State<AdvancedSettingsModule> createState() => _AdvancedSettingsModuleState();
}

class _AdvancedSettingsModuleState extends State<AdvancedSettingsModule> {
  // 最大字数限制
  final int _maxGreetingCount = 10000;
  final int _maxPrefixCount = 1000;
  final int _maxSuffixCount = 1000;

  /// 选择 HTML 模板
  Future<void> _selectHtmlTemplates() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => HtmlTemplateSelectorPage(
          initialSelected: widget.htmlTemplates,
        ),
      ),
    );

    if (result != null) {
      widget.onHtmlTemplatesChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 记忆轮数
        Text('记忆轮数', style: AppTheme.secondaryStyle),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
            children: [
              const TextSpan(text: '设置AI能够记忆的'),
              TextSpan(
                text: '对话轮数',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '（1-500轮）'),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.border.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前: ${widget.memoryRounds} 轮',
                      style: TextStyle(
                        fontSize: AppTheme.captionSize,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppTheme.primaryColor,
                        inactiveTrackColor: AppTheme.border.withOpacity(0.3),
                        thumbColor: AppTheme.primaryColor,
                        overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                        trackHeight: 4.h,
                      ),
                      child: Slider(
                        value: widget.memoryRounds.toDouble(),
                        min: 1,
                        max: 500,
                        divisions: 499,
                        onChanged: (value) {
                          widget.onMemoryRoundsChanged(value.round());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // SizedBox(height: 24.h),

        // 模型控制角色数量 - 已隐藏
        // Text('模型控制角色数量', style: AppTheme.secondaryStyle),
        // SizedBox(height: 4.h),
        // RichText(
        //   text: TextSpan(
        //     style: TextStyle(
        //       color: AppTheme.textSecondary,
        //       fontSize: 12.sp,
        //     ),
        //     children: [
        //       const TextSpan(text: '设置单个模型最多可以控制的'),
        //       TextSpan(
        //         text: '角色数量',
        //         style: TextStyle(
        //           color: Colors.amber,
        //           fontWeight: FontWeight.w600,
        //         ),
        //       ),
        //       const TextSpan(text: '（1-5个）'),
        //     ],
        //   ),
        // ),
        // SizedBox(height: 8.h),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: List.generate(5, (index) {
        //     final count = index + 1;
        //     final isSelected = widget.maxRoleControlCount == count;
        //     return GestureDetector(
        //       onTap: () => widget.onMaxRoleControlCountChanged(count),
        //       child: Container(
        //         width: 50.w,
        //         height: 50.w,
        //         decoration: BoxDecoration(
        //           color: isSelected 
        //               ? AppTheme.primaryColor.withOpacity(0.1)
        //               : AppTheme.cardBackground,
        //           borderRadius: BorderRadius.circular(12.r),
        //           border: Border.all(
        //             color: isSelected
        //                 ? AppTheme.primaryColor
        //                 : AppTheme.border.withOpacity(0.3),
        //             width: isSelected ? 2 : 1,
        //           ),
        //         ),
        //         child: Center(
        //           child: Text(
        //             count.toString(),
        //             style: TextStyle(
        //               fontSize: 18.sp,
        //               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        //               color: isSelected 
        //                   ? AppTheme.primaryColor 
        //                   : AppTheme.textSecondary,
        //             ),
        //           ),
        //         ),
        //       ),
        //     );
        //   }),
        // ),

        SizedBox(height: 24.h),

        // 开场白
        ExpandableTextField(
          title: '开场白',
          controller: widget.greetingController,
          hintText: '请输入开场白...\n\n例如：\n欢迎来到这个群聊！这里是一个充满魔法的世界...',
          maxLength: _maxGreetingCount,
          previewLines: 3,
          description: RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
              children: [
                const TextSpan(text: '群聊开始时的'),
                TextSpan(
                  text: '欢迎信息',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '，最多10000字'),
              ],
            ),
          ),
          onChanged: () => setState(() {}),
        ),

        SizedBox(height: 24.h),

        // 前缀
        ExpandableTextField(
          title: '前缀',
          controller: widget.prefixController,
          hintText: '请输入前缀内容...\n\n例如：\n在每次AI回复前添加的固定内容',
          maxLength: _maxPrefixCount,
          previewLines: 3,
          description: RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
              children: [
                const TextSpan(text: '在AI回复前添加的'),
                TextSpan(
                  text: '固定内容',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '，最多1000字'),
              ],
            ),
          ),
          onChanged: () => setState(() {}),
        ),

        SizedBox(height: 24.h),

        // 后缀
        ExpandableTextField(
          title: '后缀',
          controller: widget.suffixController,
          hintText: '请输入后缀内容...\n\n例如：\n在每次AI回复后添加的固定内容',
          maxLength: _maxSuffixCount,
          previewLines: 3,
          description: RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
              children: [
                const TextSpan(text: '在AI回复后添加的'),
                TextSpan(
                  text: '固定内容',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '，最多1000字'),
              ],
            ),
          ),
          onChanged: () => setState(() {}),
        ),

        SizedBox(height: 24.h),

        // HTML 模板选择器
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HTML模板',
              style: AppTheme.secondaryStyle,
            ),
            Text(
              '已选 ${widget.htmlTemplates.isEmpty ? 0 : widget.htmlTemplates.split(',').where((s) => s.trim().isNotEmpty).length} 个',
              style: AppTheme.hintStyle,
            ),
          ],
        ),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
            children: [
              const TextSpan(text: '为群聊绑定'),
              TextSpan(
                text: 'HTML模板',
                style: TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '，用于特殊渲染效果'),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _selectHtmlTemplates,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.buttonGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                transform: const GradientRotation(0.4),
              ),
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.buttonGradient.first.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.code,
                  size: 20.sp,
                  color: Colors.white,
                ),
                SizedBox(width: 8.w),
                Text(
                  '选择HTML模板',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTheme.bodySize,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24.h),

        // 允许修改主要设定开关
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text('允许修改主要设定', style: AppTheme.bodyStyle),
              subtitle: Text(
                '开启后，用户可在对话中查看和修改群聊的主要设定',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              value: widget.visibility == 'public',
              onChanged: (value) {
                widget.onVisibilityChanged(value ? 'public' : 'private');
              },
              tileColor: AppTheme.cardBackground,
              activeColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 4.h, left: 16.w),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.sp,
                  ),
                  children: [
                    const TextSpan(text: '开启后用户可在'),
                    TextSpan(
                      text: '对话中',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: '修改',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '群聊主要设定，将'),
                    TextSpan(
                      text: '暴露',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '你的'),
                    TextSpan(
                      text: '设定内容',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，建议'),
                    TextSpan(
                      text: '谨慎开启',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '。'),
                    TextSpan(
                      text: '该修改后，立刻生效',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // 允许修改前后缀设定开关
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text('允许修改前后缀设定', style: AppTheme.bodyStyle),
              subtitle: Text(
                '开启后，用户可在对话中修改前后缀内容',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              value: widget.prefixSuffixEditable == 'public',
              onChanged: (value) {
                widget.onPrefixSuffixEditableChanged(value ? 'public' : 'private');
              },
              tileColor: AppTheme.cardBackground,
              activeColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 4.h, left: 16.w),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.sp,
                  ),
                  children: [
                    const TextSpan(text: '开启后用户可在'),
                    TextSpan(
                      text: '对话中',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: '修改',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '前后缀内容，将'),
                    TextSpan(
                      text: '暴露',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '你的'),
                    TextSpan(
                      text: '前后缀设定',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，建议'),
                    TextSpan(
                      text: '谨慎开启',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '。'),
                    TextSpan(
                      text: '该修改后，立刻生效',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

