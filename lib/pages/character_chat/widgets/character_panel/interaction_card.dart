import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import 'base_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      title: '交互设置',
      children: [
        _buildEditableInfoItem(
          '开场白',
          'greeting',
          greetingController,
          suffix: '可编辑',
          isMultiLine: true,
        ),
        _buildEditableInfoItem(
          '前缀',
          'prefix',
          prefixController,
          suffix: '可编辑',
        ),
        _buildEditableInfoItem(
          '后缀',
          'suffix',
          suffixController,
          suffix: '可编辑',
        ),
        _buildUiSettingsItem(),
        _buildInfoItem(
            '设定可编辑', sessionData['setting_editable'] == true ? '是' : '否'),
      ],
    );
  }

  Widget _buildEditableInfoItem(
    String label,
    String field,
    TextEditingController controller, {
    String? suffix,
    bool isMultiLine = false,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.textPrimary.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForField(field),
                  color: AppTheme.primaryColor,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (suffix != null) ...[
                SizedBox(width: 4.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    suffix,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppTheme.textPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppTheme.textPrimary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: controller,
              style: TextStyle(
                fontSize: 15.sp,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                hintText: _getHintForField(field),
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
              onChanged: (value) => onUpdateField(field, value),
              maxLines: isMultiLine ? null : 1,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildInfoItem(String label, String value) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.textPrimary.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForInfoItem(label),
              color: AppTheme.primaryColor,
              size: 16.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForInfoItem(String label) {
    switch (label) {
      case '设定可编辑':
        return Icons.edit_note;
      case '总对话轮数':
        return Icons.repeat;
      case '最后消息':
        return Icons.message;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildUiSettingsItem() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.textPrimary.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.format_paint,
                  color: AppTheme.primaryColor,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'UI格式化类型',
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
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '可编辑',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppTheme.textPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUiSettingOption('markdown', 'Markdown模式'),
                SizedBox(height: 12.h),
                _buildUiSettingOption('disabled', '不启用状态栏'),
                SizedBox(height: 12.h),
                _buildUiSettingOption('legacy_bar', '新版UI样式'),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14.sp,
                  color: AppTheme.primaryColor.withOpacity(0.7),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _getUiSettingsDescription(),
                    style: TextStyle(
                      color: AppTheme.primaryColor.withOpacity(0.7),
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

  Widget _buildUiSettingOption(String value, String label) {
    final isSelected = uiSettings == value;

    return GestureDetector(
      onTap: () => onUiSettingsChanged(value),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textPrimary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getIconForOption(value),
              color: isSelected
                  ? Colors.white
                  : AppTheme.textPrimary.withOpacity(0.7),
              size: 18.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppTheme.textPrimary.withOpacity(0.7),
                fontSize: 15.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 18.sp,
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
      case 'legacy_bar':
        return Icons.view_stream;
      default:
        return Icons.settings;
    }
  }

  String _getUiSettingsDescription() {
    switch (uiSettings) {
      case 'markdown':
        return '使用Markdown模式渲染状态栏';
      case 'disabled':
        return '不启用状态栏功能';
      case 'legacy_bar':
        return '使用新版UI样式';
      default:
        return '';
    }
  }
}
