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
        _buildInfoItem('总对话轮数', (sessionData['total_turns'] ?? 0).toString()),
        if (sessionData['last_message']?.isNotEmpty == true)
          _buildInfoItem('最后消息', sessionData['last_message']),
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
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14.sp,
                ),
              ),
              if (suffix != null) ...[
                SizedBox(width: 4.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
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
          SizedBox(height: 8.h),
          TextFormField(
            controller: controller,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
            ),
            maxLines: isMultiLine ? null : 1,
            onChanged: (value) => onUpdateField(field, value),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUiSettingsItem() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'UI格式化类型',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 4.w,
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
          SizedBox(height: 12.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUiSettingOption('markdown', 'Markdown模式'),
              SizedBox(height: 8.h),
              _buildUiSettingOption('disabled', '不启用状态栏'),
              SizedBox(height: 8.h),
              _buildUiSettingOption('legacy_bar', '旧版状态栏'),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            _getUiSettingsDescription(),
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12.sp,
              fontStyle: FontStyle.italic,
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForOption(value),
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              size: 16.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        return '使用旧版状态栏样式';
      default:
        return '';
    }
  }
}
