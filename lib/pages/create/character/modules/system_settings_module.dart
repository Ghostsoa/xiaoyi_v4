import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import '../../material/select_text_page.dart';
import '../../../../widgets/custom_toast.dart';
import '../../../../net/http_client.dart';

class SystemSettingsModule extends StatefulWidget {
  final TextEditingController settingController;
  final TextEditingController greetingController;
  final TextEditingController userSettingController;
  final TextEditingController statusBarController;
  final bool settingEditable;
  final Function(bool) onSettingEditableChanged;

  const SystemSettingsModule({
    super.key,
    required this.settingController,
    required this.greetingController,
    required this.userSettingController,
    required this.statusBarController,
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

  // 添加AI生成状态栏的方法
  Future<void> _generateStatusBar() async {
    final TextEditingController inputController = TextEditingController();

    String? prompt = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            '生成状态栏',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.titleSize,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '请描述你希望生成的状态栏包含哪些元素：',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.captionSize,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: inputController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '例如：生成一个战士角色的状态栏，满血，有龙之力加成',
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.bodySize,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.bodySize,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, inputController.text);
              },
              child: Text(
                '生成',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: AppTheme.bodySize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (prompt != null && prompt.isNotEmpty) {
      try {
        setState(() {
          // 显示加载中
          widget.statusBarController.text = '正在生成状态栏...';
        });

        // 调用API生成状态栏
        final HttpClient httpClient = HttpClient();
        final response = await httpClient.post(
          '/status-bar',
          data: {
            'input': prompt,
          },
        );

        if (response.data['code'] == 0) {
          setState(() {
            // 直接填充API返回的状态栏内容
            widget.statusBarController.text =
                response.data['data']['status_bar'];
          });
          _showToast('状态栏生成成功', type: ToastType.success);
        } else {
          _showToast('状态栏生成失败: ${response.data['msg']}', type: ToastType.error);
          setState(() {
            // 恢复原来的内容
            widget.statusBarController.text =
                widget.statusBarController.text.replaceAll('正在生成状态栏...', '');
          });
        }
      } catch (e) {
        _showToast('状态栏生成失败: $e', type: ToastType.error);
        setState(() {
          // 恢复原来的内容
          widget.statusBarController.text =
              widget.statusBarController.text.replaceAll('正在生成状态栏...', '');
        });
      }
    }
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
                Text('状态栏', style: AppTheme.secondaryStyle),
                SizedBox(width: 4.w),
                Icon(
                  Icons.help_outline,
                  size: 16.sp,
                  color: AppTheme.textSecondary,
                ),
                const Spacer(),
                // AI生成按钮
                GestureDetector(
                  onTap: () {
                    _generateStatusBar();
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(6.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'AI生成',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildSelectButton(
                  title: '状态栏',
                  type: TextSelectType.setting,
                  onSelected: (value) {
                    final currentText = widget.statusBarController.text;
                    if (currentText.isEmpty) {
                      widget.statusBarController.text = value;
                    } else {
                      widget.statusBarController.text =
                          '$currentText\n\n$value';
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.sp,
                  ),
                  children: [
                    const TextSpan(text: '在对话界面顶部显示的'),
                    TextSpan(
                      text: '状态信息',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，内容需要用'),
                    TextSpan(
                      text: '```状态栏\n内容\n```',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '格式包裹'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: widget.statusBarController,
              decoration: InputDecoration(
                hintText: '例如：```状态栏\nHP: 100 | MP: 50 | 好感度: 80\n```',
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
              minLines: 3,
              maxLines: null,
            ),
          ],
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
