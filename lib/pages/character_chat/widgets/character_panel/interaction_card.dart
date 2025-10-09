import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/expandable_text_field.dart';
import '../../../../widgets/text_editor_page.dart';

class InteractionCard extends StatelessWidget {
  final Map<String, dynamic> sessionData;
  final Function(String, dynamic) onUpdateField;
  final TextEditingController greetingController;
  final TextEditingController prefixController;
  final TextEditingController suffixController;
  final String uiSettings;
  final Function(String) onUiSettingsChanged;

  const InteractionCard({
    super.key,
    required this.sessionData,
    required this.onUpdateField,
    required this.greetingController,
    required this.prefixController,
    required this.suffixController,
    required this.uiSettings,
    required this.onUiSettingsChanged,
  });

  // 判断前后缀是否可编辑
  bool get _isPrefixSuffixEditable => sessionData['prefix_suffix_editable'] == true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditableInfoItem(
          '开场白',
          'greeting',
          greetingController,
          isMultiLine: true,
          accentColor: AppTheme.primaryColor,
        ),
        // 如果前后缀不可编辑，显示锁定提示
        if (!_isPrefixSuffixEditable) _buildPrefixSuffixLockedNotice(),
        // 如果前后缀可编辑，显示编辑框
        if (_isPrefixSuffixEditable) ...[
          _buildEditableInfoItem(
            '前缀',
            'prefix',
            prefixController,
            accentColor: AppTheme.primaryLight,
          ),
          _buildEditableInfoItem(
            '后缀',
            'suffix',
            suffixController,
            accentColor: AppTheme.accentPink,
          ),
        ],
        _buildUiSettingsItem(),
      ],
    );
  }

  // 构建前后缀锁定提示
  Widget _buildPrefixSuffixLockedNotice() {
    final accentColor = AppTheme.warning;

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
              '前后缀设定不可查看',
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

  Widget _buildEditableInfoItem(
    String label,
    String field,
    TextEditingController controller, {
    bool isMultiLine = false,
    required Color accentColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ExpandableTextField(
        title: label,
        controller: controller,
        hintText: _getHintForField(field),
        selectType: _getSelectType(field),
        previewLines: isMultiLine ? 4 : 1,
        helpIcon: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Icon(
            _getIconForField(field),
            color: accentColor,
            size: 12.sp,
          ),
        ),
        onChanged: () {
          onUpdateField(field, controller.text);
        },
      ),
    );
  }

  // 根据字段类型返回对应的选择类型
  TextSelectType? _getSelectType(String field) {
    switch (field) {
      case 'prefix':
        return TextSelectType.prefix;
      case 'suffix':
        return TextSelectType.suffix;
      default:
        return null;
    }
  }

  String _getHintForField(String field) {
    switch (field) {
      case 'greeting':
        return '角色的开场白...';
      case 'prefix':
        return '添加到每个用户消息前的前缀...';
      case 'suffix':
        return '添加到每个用户消息后的后缀...';
      default:
        return '';
    }
  }

  IconData _getIconForField(String field) {
    switch (field) {
      case 'greeting':
        return Icons.chat_bubble_outline;
      case 'prefix':
        return Icons.format_indent_increase;
      case 'suffix':
        return Icons.format_indent_decrease;
      default:
        return Icons.settings;
    }
  }

  Widget _buildUiSettingsItem() {
    final accentColor = AppTheme.primaryColor;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.format_paint,
                  color: accentColor,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                '界面渲染类型',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '可编辑',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppTheme.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUiSettingOption(
                    'markdown', '标准渲染', AppTheme.success),
                SizedBox(height: 8.h),
                _buildUiSettingOption('disabled', '不启用渲染', AppTheme.error),
                SizedBox(height: 8.h),
                _buildUiSettingOption(
                    'html', 'HTML渲染', AppTheme.primaryLight),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppTheme.background.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14.sp,
                  color: accentColor,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _getUiSettingsDescription(),
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12.sp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUiSettingOption(String value, String label, Color optionColor) {
    final isSelected = uiSettings == value;

    return GestureDetector(
      onTap: () => onUiSettingsChanged(value),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color:
              isSelected ? optionColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: isSelected ? optionColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getIconForOption(value),
              color: optionColor,
              size: 18.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: optionColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: optionColor,
                  size: 14.sp,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForOption(String value) {
    switch (value) {
      case 'markdown':
        return Icons.text_format;
      case 'disabled':
        return Icons.chat_outlined;
      case 'html':
        return Icons.code;
      default:
        return Icons.settings;
    }
  }

  String _getUiSettingsDescription() {
    switch (uiSettings) {
      case 'markdown':
        return '使用标准渲染模式，支持Markdown格式';
      case 'disabled':
        return '不启用渲染功能';
      case 'html':
        return '使用HTML渲染，支持更丰富的显示效果';
      default:
        return '';
    }
  }
}
