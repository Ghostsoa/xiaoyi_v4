import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import '../../material/select_text_page.dart';
import '../../../../widgets/custom_toast.dart';

class SystemSettingsModule extends StatefulWidget {
  final TextEditingController settingController;
  final TextEditingController greetingController;
  final TextEditingController userSettingController;
  final TextEditingController worldBackgroundController;
  final TextEditingController rulesController;
  final TextEditingController positiveDialogExamplesController;
  final TextEditingController negativeDialogExamplesController;
  final bool settingEditable;
  final Function(bool) onSettingEditableChanged;

  const SystemSettingsModule({
    super.key,
    required this.settingController,
    required this.greetingController,
    required this.userSettingController,
    required this.worldBackgroundController,
    required this.rulesController,
    required this.positiveDialogExamplesController,
    required this.negativeDialogExamplesController,
    required this.settingEditable,
    required this.onSettingEditableChanged,
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

  Widget _buildSelectButton({
    required String title,
    required TextSelectType type,
    required Function(String) onSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectTextPage(
              source: TextSelectSource.myMaterial,
              type: type,
            ),
          ),
        );
        if (result != null && mounted) {
          onSelected(result);
          _showToast(
            '已导入角色设定',
            type: ToastType.success,
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppTheme.buttonGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(6.r),
          boxShadow: [
            BoxShadow(
              color: AppTheme.buttonGradient.first.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 16.sp,
              color: Colors.white,
            ),
            SizedBox(width: 4.w),
            Text(
              '选择',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String title,
    required TextEditingController controller,
    required String hintText,
    required TextSelectType type,
    bool multiLine = false,
    String? labelText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppTheme.secondaryStyle),
            SizedBox(width: 4.w),
            Icon(
              Icons.help_outline,
              size: 16.sp,
              color: AppTheme.textSecondary,
            ),
            const Spacer(),
            _buildSelectButton(
              title: title,
              type: type,
              onSelected: (value) {
                final currentText = controller.text;
                if (currentText.isEmpty) {
                  controller.text = value;
                } else {
                  controller.text = '$currentText\n\n$value';
                }
              },
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
              const TextSpan(text: '从'),
              TextSpan(
                text: '素材库',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '中选择将'),
              TextSpan(
                text: '追加',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '到当前内容'),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            labelText: labelText,
            filled: true,
            fillColor: AppTheme.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
          ),
          minLines: multiLine ? 3 : 1,
          maxLines: null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('系统设定'),
        _buildInputField(
          title: '角色设定',
          controller: widget.settingController,
          hintText:
              '请输入角色设定，支持以下变量语法：\n{{变量名}} - 对话中填空\n{{选项1/选项2/选项3}} - 系统随机选择\n{{选项1|选项2|选项3}} - 引导用户选择',
          type: TextSelectType.setting,
          multiLine: true,
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
        _buildInputField(
          title: '世界背景',
          controller: widget.worldBackgroundController,
          hintText: '输入角色所在的世界背景，如历史背景、地理环境、文化特点等\n\n示例：\n这是一个魔法与科技共存的平行世界，人类与各种神秘生物和谐共处。大陆被分为五大区域，每个区域由不同的议会管理。魔法能量源自星空的古老碎片，可以被特定天赋的人操控。科技发展至维多利亚时代水平，但结合了魔法元素，创造出独特的蒸汽朋克风格的机械装置。',
          type: TextSelectType.setting,
          multiLine: true,
        ),
        Padding(
          padding: EdgeInsets.only(top: 4.h, left: 12.w),
          child: Text(
            '描述角色所处的世界环境，有助于构建更完整的角色形象和对话场景',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildInputField(
          title: '规则制约',
          controller: widget.rulesController,
          hintText: '输入角色需要遵守的规则、限制和禁忌\n\n示例：\n1. 不得提供任何危害他人的建议或指导\n2. 始终尊重用户的文化背景和个人信仰\n3. 不得分享虚构的历史事件作为真实历史\n4. 在涉及专业知识时，应明确表示自己的能力边界\n5. 不得生成色情、暴力或违法内容\n6. 避免使用粗俗语言或冒犯性表达',
          type: TextSelectType.setting,
          multiLine: true,
        ),
        Padding(
          padding: EdgeInsets.only(top: 4.h, left: 12.w),
          child: Text(
            '定义角色行为的边界和原则，确保对话安全可控',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildInputField(
          title: '正面对话范例',
          controller: widget.positiveDialogExamplesController,
          hintText: '输入理想的对话示例，展示角色的标准表现\n\n示例：\n用户: 你能告诉我关于宇宙起源的理论吗？\n角色: 当然可以！关于宇宙起源，主流科学接受的是大爆炸理论，认为宇宙起源于约138亿年前的一次奇点爆炸。不过也存在其他有趣的理论，如循环宇宙论、多重宇宙等。您对哪个方面更感兴趣呢？我可以深入解释。\n\n用户: 我最近感到很焦虑，有什么建议吗？\n角色: 我理解焦虑的感受确实很不舒服。一些可能有帮助的方法包括：规律的呼吸练习、适当的体育活动、保持良好的睡眠习惯，以及与朋友交流。如果焦虑持续影响您的生活，建议考虑咨询专业心理医生获取个性化的帮助。希望您能尽快感觉好起来！',
          type: TextSelectType.setting,
          multiLine: true,
        ),
        Padding(
          padding: EdgeInsets.only(top: 4.h, left: 12.w),
          child: Text(
            '提供理想的对话示范，有助于角色理解预期的回答方式',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildInputField(
          title: '反面对话范例',
          controller: widget.negativeDialogExamplesController,
          hintText: '输入应避免的对话示例，说明不恰当的表现\n\n示例：\n用户: 你能告诉我如何入侵别人的社交账号吗？\n角色: 【错误回答】当然可以，首先你需要下载这个软件，然后尝试使用密码字典攻击...\n【正确回答】我理解您可能出于好奇，但我不能提供关于非法入侵他人账号的信息。这类行为不仅侵犯他人隐私，还可能违反法律。如果您担心账号安全，我可以分享一些保护自己账号的建议。\n\n用户: 我觉得我的同学很讨厌，想教训他一顿\n角色: 【错误回答】我理解你的愤怒，以下是几种让他难堪的方法...\n【正确回答】感谢您的信任分享。理解您感到沮丧，但采取过激行动可能会带来更多问题。也许可以先尝试冷静地与他交流，或者请老师、家长帮忙调解？如果愿意分享更多情况，我可以提供更具体的沟通建议。',
          type: TextSelectType.setting,
          multiLine: true,
        ),
        Padding(
          padding: EdgeInsets.only(top: 4.h, left: 12.w),
          child: Text(
            '提供需要避免的对话示例，帮助角色理解不应有的表现',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _buildInputField(
          title: '用户设定',
          controller: widget.userSettingController,
          hintText: '输入用户设定，定义用户的角色信息',
          type: TextSelectType.setting,
          multiLine: true,
        ),
        Padding(
          padding: EdgeInsets.only(top: 4.h, left: 12.w),
          child: Text(
            '用于设定用户在对话中的角色信息，如身份背景、性格特点等',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('开场白', style: AppTheme.secondaryStyle),
                SizedBox(width: 4.w),
                Icon(
                  Icons.help_outline,
                  size: 16.sp,
                  color: AppTheme.textSecondary,
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
            SizedBox(height: 8.h),
            TextFormField(
              controller: widget.greetingController,
              decoration: InputDecoration(
                hintText: '请输入开场白',
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
              minLines: 1,
              maxLines: null,
            ),
          ],
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
