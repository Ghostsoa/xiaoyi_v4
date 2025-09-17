import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/expandable_text_field.dart';
import '../../../../widgets/text_editor_page.dart';

class SettingCard extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final Function(String, dynamic) onUpdateField;
  final TextEditingController settingController;
  final TextEditingController userSettingController;
  // 添加其他设定字段的控制器
  final TextEditingController worldBackgroundController;
  final TextEditingController rulesController;
  final TextEditingController positiveDialogController;
  final TextEditingController negativeDialogController;
  final TextEditingController supplementSettingController;

  const SettingCard({
    super.key,
    required this.sessionData,
    required this.onUpdateField,
    required this.settingController,
    required this.userSettingController,
    required this.worldBackgroundController,
    required this.rulesController,
    required this.positiveDialogController,
    required this.negativeDialogController,
    required this.supplementSettingController,
  });

  @override
  State<SettingCard> createState() => _SettingCardState();
}

class _SettingCardState extends State<SettingCard> {
  // 全局可编辑状态
  bool get _isEditable => widget.sessionData['setting_editable'] == true;

  @override
  void initState() {
    super.initState();
    // 初始化监听器
    _initListeners();
  }

  void _initListeners() {
    // 将所有设定字段都添加到_editedData中
    // 不要在初始化时直接调用，改用帧回调
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAllFields();
    });

    // 添加监听器
    widget.settingController.addListener(() {
      widget.onUpdateField('setting', widget.settingController.text);
    });
    widget.worldBackgroundController.addListener(() {
      widget.onUpdateField(
          'world_background', widget.worldBackgroundController.text);
    });
    widget.rulesController.addListener(() {
      widget.onUpdateField('rules', widget.rulesController.text);
    });
    widget.positiveDialogController.addListener(() {
      widget.onUpdateField(
          'positive_dialog_examples', widget.positiveDialogController.text);
    });
    widget.negativeDialogController.addListener(() {
      widget.onUpdateField(
          'negative_dialog_examples', widget.negativeDialogController.text);
    });
    widget.supplementSettingController.addListener(() {
      widget.onUpdateField(
          'supplement_setting', widget.supplementSettingController.text);
    });
    widget.userSettingController.addListener(() {
      widget.onUpdateField('user_setting', widget.userSettingController.text);
    });
  }

  // 确保所有设定字段都被更新到_editedData中
  void _updateAllFields() {
    widget.onUpdateField('setting', widget.settingController.text);
    widget.onUpdateField(
        'world_background', widget.worldBackgroundController.text);
    widget.onUpdateField('rules', widget.rulesController.text);
    widget.onUpdateField(
        'positive_dialog_examples', widget.positiveDialogController.text);
    widget.onUpdateField(
        'negative_dialog_examples', widget.negativeDialogController.text);
    widget.onUpdateField(
        'supplement_setting', widget.supplementSettingController.text);
    widget.onUpdateField('user_setting', widget.userSettingController.text);
  }

  @override
  void dispose() {
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 不可编辑状态时，显示一条提示信息
        if (!_isEditable) _buildNonEditableNotice(),

        // 可编辑状态时，显示所有设定项
        if (_isEditable) ...[
          _buildSettingField(
            '角色设定',
            'setting',
            widget.settingController,
            icon: Icons.psychology,
            accentColor: AppTheme.primaryColor,
            description: '角色的核心设定，包括性格、背景、特点等',
          ),
          _buildSettingField(
            '世界设定',
            'world_background',
            widget.worldBackgroundController,
            icon: Icons.public,
            accentColor: AppTheme.primaryLight,
            description: '角色所在的世界观、时代背景等信息',
          ),
          _buildSettingField(
            '规则约束',
            'rules',
            widget.rulesController,
            icon: Icons.rule,
            accentColor: AppTheme.accentPink,
            description: '角色行为的规则限制，包括禁止事项等',
          ),
          _buildSettingField(
            '正对话示例',
            'positive_dialog_examples',
            widget.positiveDialogController,
            icon: Icons.thumb_up_alt_outlined,
            accentColor: AppTheme.success,
            description: '理想的对话示例，帮助角色理解预期的回复风格',
          ),
          _buildSettingField(
            '反对话示例',
            'negative_dialog_examples',
            widget.negativeDialogController,
            icon: Icons.thumb_down_alt_outlined,
            accentColor: AppTheme.error,
            description: '不良的对话示例，帮助角色避免不当回复',
          ),
          _buildSettingField(
            '补充设定',
            'supplement_setting',
            widget.supplementSettingController,
            icon: Icons.add_circle_outline,
            accentColor: AppTheme.warning,
            description: '其他补充信息，如特殊指令或额外设定',
          ),
        ],

        // 用户设定始终显示，不受限制
        _buildUserSettingField(),
      ],
    );
  }

  // 构建不可编辑状态的提示
  Widget _buildNonEditableNotice() {
    final accentColor = AppTheme.primaryLight;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              Icons.lock_outline,
              color: accentColor,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '相关设定不可查看',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建普通设定字段
  Widget _buildSettingField(
    String label,
    String field,
    TextEditingController controller, {
    required IconData icon,
    required Color accentColor,
    String? description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ExpandableTextField(
        title: label,
        controller: controller,
        hintText: '点击这里编辑$label...',
        selectType: _getSelectType(field),
        previewLines: 4,
        helpIcon: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: 12.sp,
          ),
        ),
        description: description != null ? Text(
          description,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12.sp,
            fontStyle: FontStyle.italic,
          ),
        ) : null,
        onChanged: () {
          widget.onUpdateField(field, controller.text);
        },
      ),
    );
  }

  // 根据字段类型返回对应的选择类型
  TextSelectType? _getSelectType(String field) {
    switch (field) {
      case 'setting':
        return TextSelectType.setting;
      case 'prefix':
        return TextSelectType.prefix;
      case 'suffix':
        return TextSelectType.suffix;
      default:
        return null;
    }
  }

  // 构建用户设定字段（没有高度限制）
  Widget _buildUserSettingField() {
    final accentColor = AppTheme.primaryColor;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ExpandableTextField(
        title: '用户设定',
        controller: widget.userSettingController,
        hintText: '点击这里编辑用户设定...',
        previewLines: 6, // 用户设定显示更多行
        helpIcon: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Icon(
            Icons.person_outline,
            color: accentColor,
            size: 12.sp,
          ),
        ),
        description: Text(
          '设定用户的身份、特点等信息，帮助角色更好地理解用户',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12.sp,
            fontStyle: FontStyle.italic,
          ),
        ),
        onChanged: () {
          widget.onUpdateField('user_setting', widget.userSettingController.text);
        },
      ),
    );
  }
}
