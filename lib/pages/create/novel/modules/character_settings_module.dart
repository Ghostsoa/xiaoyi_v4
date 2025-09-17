import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/expandable_text_field.dart';
import '../../../../widgets/text_editor_page.dart';

class NovelCharacterSettingsModule extends StatefulWidget {
  final TextEditingController protagonistSetController;
  final TextEditingController npcSettingsController;
  final TextEditingController supplementarySetController;

  const NovelCharacterSettingsModule({
    super.key,
    required this.protagonistSetController,
    required this.npcSettingsController,
    required this.supplementarySetController,
  });

  @override
  State<NovelCharacterSettingsModule> createState() =>
      _NovelCharacterSettingsModuleState();
}

class _NovelCharacterSettingsModuleState
    extends State<NovelCharacterSettingsModule> {
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 16.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppTheme.titleSize,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textSecondary = AppTheme.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('角色设定'),

        // 主角设定
        ExpandableTextField(
          title: '主角设定',
          controller: widget.protagonistSetController,
          hintText: '请输入主角设定，包括性格、背景、能力等',
          selectType: TextSelectType.setting,
          previewLines: 3,
          description: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: AppTheme.captionSize,
                color: textSecondary,
              ),
              children: [
                const TextSpan(text: '详细描述'),
                TextSpan(
                  text: '主角特征',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '，包括'),
                TextSpan(
                  text: '性格',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '、'),
                TextSpan(
                  text: '背景',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '和'),
                TextSpan(
                  text: '能力',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          onChanged: () => setState(() {}),
        ),
        SizedBox(height: 24.h),

        // NPC设定
        ExpandableTextField(
          title: 'NPC设定',
          controller: widget.npcSettingsController,
          hintText: '请输入NPC设定，包括重要配角、敌人等',
          selectType: TextSelectType.setting,
          previewLines: 3,
          description: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: AppTheme.captionSize,
                color: textSecondary,
              ),
              children: [
                const TextSpan(text: '描述故事中的'),
                TextSpan(
                  text: '重要配角',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '、'),
                TextSpan(
                  text: '敌人',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '及其与'),
                TextSpan(
                  text: '主角的关系',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          onChanged: () => setState(() {}),
        ),
        SizedBox(height: 24.h),

        // 补充设定
        ExpandableTextField(
          title: '补充设定',
          controller: widget.supplementarySetController,
          hintText: '请输入其他补充设定，如特殊道具、系统规则等',
          selectType: TextSelectType.setting,
          previewLines: 3,
          description: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: AppTheme.captionSize,
                    color: textSecondary,
                  ),
                  children: [
                    const TextSpan(text: '添加其他需要补充的设定，如'),
                    TextSpan(
                      text: '特殊道具',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '、'),
                    TextSpan(
                      text: '系统规则',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '等'),
                  ],
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.priority_high,
                      color: Colors.amber,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: AppTheme.captionSize,
                            color: textSecondary,
                          ),
                          children: [
                            const TextSpan(text: '此处填写的设定拥有'),
                            TextSpan(
                              text: '较高优先级',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: '，会'),
                            TextSpan(
                              text: '覆盖其他冲突设定',
                              style: TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: '，可用于'),
                            TextSpan(
                              text: '强调关键元素',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          onChanged: () => setState(() {}),
        ),
      ],
    );
  }
}
