import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import 'base_card.dart';

class SettingCard extends StatelessWidget {
  final Map<String, dynamic> sessionData;
  final Function(String, dynamic) onUpdateField;
  final TextEditingController settingController;
  final TextEditingController userSettingController;
  final TextEditingController statusBarController;

  const SettingCard({
    super.key,
    required this.sessionData,
    required this.onUpdateField,
    required this.settingController,
    required this.userSettingController,
    required this.statusBarController,
  });

  @override
  Widget build(BuildContext context) {
    if (sessionData['setting'] == null) return const SizedBox();

    return BaseCard(
      title: '人设信息',
      children: [
        _buildEditableInfoItem(
          '人设',
          'setting',
          settingController,
          enabled: sessionData['setting_editable'] == true,
          suffix: sessionData['setting_editable'] == true ? '可编辑' : '不可编辑',
          isMultiLine: true,
        ),
        _buildEditableInfoItem(
          '用户设定',
          'userSetting',
          userSettingController,
          enabled: true,
          suffix: '可编辑',
          isMultiLine: true,
        ),
        _buildEditableInfoItem(
          '状态栏',
          'statusBar',
          statusBarController,
          enabled: true,
          suffix: '可编辑',
          isMultiLine: true,
        ),
      ],
    );
  }

  Widget _buildEditableInfoItem(
    String label,
    String field,
    TextEditingController controller, {
    bool enabled = true,
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
                    color: enabled
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    suffix,
                    style: TextStyle(
                      color: enabled ? AppTheme.primaryColor : Colors.grey,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),
          if (enabled)
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
                hintText:
                    field == 'statusBar' ? '请用```状态栏\n...\n```包裹内容' : null,
                hintStyle: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              onChanged: (value) => onUpdateField(field, value),
              maxLines: isMultiLine ? null : 1,
            )
          else
            Text(
              '无法查看和编辑',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
