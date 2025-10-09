import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/custom_toast.dart';
import '../../../../widgets/expandable_text_field.dart';
import '../../../../widgets/text_editor_page.dart';

class SystemSettingsModule extends StatefulWidget {
  final TextEditingController settingController;
  final TextEditingController greetingController;
  final TextEditingController userSettingController;
  final TextEditingController worldBackgroundController;
  final TextEditingController rulesController;
  final TextEditingController positiveDialogExamplesController;
  final TextEditingController negativeDialogExamplesController;
  final TextEditingController supplementSettingController;
  final bool settingEditable;
  final bool prefixSuffixEditable;
  final Function(bool) onSettingEditableChanged;
  final Function(bool) onPrefixSuffixEditableChanged;

  const SystemSettingsModule({
    super.key,
    required this.settingController,
    required this.greetingController,
    required this.userSettingController,
    required this.worldBackgroundController,
    required this.rulesController,
    required this.positiveDialogExamplesController,
    required this.negativeDialogExamplesController,
    required this.supplementSettingController,
    required this.settingEditable,
    required this.prefixSuffixEditable,
    required this.onSettingEditableChanged,
    required this.onPrefixSuffixEditableChanged,
  });

  @override
  State<SystemSettingsModule> createState() => _SystemSettingsModuleState();
}

class _SystemSettingsModuleState extends State<SystemSettingsModule> {
  void _showToast(String message, {ToastType type = ToastType.info}) {
    if (!mounted) return;
    CustomToast.show(context, message: message, type: type);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h, bottom: 16.h),
      child: Text(
        title,
        style: AppTheme.titleStyle.copyWith(
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildExpandableTextField({
    required String title,
    required TextEditingController controller,
    required String hintText,
    required TextSelectType type,
    Widget? description,
  }) {
    return ExpandableTextField(
      title: title,
      controller: controller,
      hintText: hintText,
      selectType: type,
      helpIcon: Icon(
        Icons.help_outline,
        size: 16.sp,
        color: AppTheme.textSecondary,
      ),
      description: description,
      onChanged: () => setState(() {}), // 触发界面刷新
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('系统设定'),
        _buildExpandableTextField(
          title: '角色设定',
          controller: widget.settingController,
          hintText: '请输入角色设定，支持变量语法：{{变量名}}、{{选项1/选项2/选项3}}等',
          type: TextSelectType.setting,
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.h, left: 12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14.sp,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '变量语法说明：',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.sp,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: '{{变量名}} ',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: '- 在'),
                    TextSpan(
                      text: '对话中',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: '手动填写',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: '内容\n'),
                    TextSpan(
                      text: '{{选项1/选项2/选项3}} ',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: '- '),
                    TextSpan(
                      text: '系统',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: '将'),
                    TextSpan(
                      text: '随机',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: '选择一个选项\n'),
                    TextSpan(
                      text: '{{选项1|选项2|选项3}} ',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: '- 让'),
                    TextSpan(
                      text: '用户',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: '主动选择',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: '一个选项'),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        _buildExpandableTextField(
          title: '补充设定',
          controller: widget.supplementSettingController,
          hintText: '输入角色的补充设定信息，如特殊能力、背景故事、性格细节等',
          type: TextSelectType.setting,
          description: RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
              children: [
                const TextSpan(text: '补充设定具有'),
                TextSpan(
                  text: '较高优先级',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '，可存放'),
                TextSpan(
                  text: '强制约束',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '和'),
                TextSpan(
                  text: '核心设定',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '内容'),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 4.h, left: 12.w),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
              children: [
                const TextSpan(text: '补充设定具有'),
                TextSpan(
                  text: '较高优先级',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '，可存放'),
                TextSpan(
                  text: '强制约束',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '和'),
                TextSpan(
                  text: '核心设定',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '内容'),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildExpandableTextField(
          title: '世界背景',
          controller: widget.worldBackgroundController,
          hintText: '输入角色所在的世界背景，如历史背景、地理环境、文化特点等',
          type: TextSelectType.setting,
          description: Text(
            '描述角色所处的世界环境，有助于构建更完整的角色形象和对话场景',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildExpandableTextField(
          title: '规则制约',
          controller: widget.rulesController,
          hintText: '输入角色需要遵守的规则、限制和禁忌，定义行为边界',
          type: TextSelectType.setting,
          description: Text(
            '定义角色行为的边界和原则，确保对话安全可控',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildExpandableTextField(
          title: '正面对话范例',
          controller: widget.positiveDialogExamplesController,
          hintText: '输入理想的对话示例，展示角色应有的标准表现和回应方式',
          type: TextSelectType.setting,
          description: Text(
            '提供理想的对话示范，有助于角色理解预期的回答方式',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildExpandableTextField(
          title: '反面对话范例',
          controller: widget.negativeDialogExamplesController,
          hintText: '输入应避免的对话示例，说明角色不应有的表现和回应方式',
          type: TextSelectType.setting,
          description: Text(
            '提供需要避免的对话示例，帮助角色理解不应有的表现',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildExpandableTextField(
          title: '用户设定',
          controller: widget.userSettingController,
          hintText: '输入用户设定，定义用户的角色信息',
          type: TextSelectType.setting,
          description: Text(
            '用于设定用户在对话中的角色信息，如身份背景、性格特点等',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildExpandableTextField(
          title: '开场白',
          controller: widget.greetingController,
          hintText: '请输入开场白',
          type: TextSelectType.setting,
          description: RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
              children: [
                const TextSpan(text: '角色的'),
                TextSpan(
                  text: '第一句话',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '，建议包含'),
                TextSpan(
                  text: '自我介绍',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '和'),
                TextSpan(
                  text: '互动引导',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text('允许修改设定', style: AppTheme.bodyStyle),
              value: widget.settingEditable,
              onChanged: widget.onSettingEditableChanged,
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
                    const TextSpan(text: '角色设定，将'),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text('允许修改前后缀设定', style: AppTheme.bodyStyle),
              value: widget.prefixSuffixEditable,
              onChanged: widget.onPrefixSuffixEditableChanged,
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
