import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import 'base_card.dart';

class SettingCard extends StatelessWidget {
  final Map<String, dynamic> sessionData;
  final Function(String, dynamic) onUpdateField;
  final TextEditingController settingController;
  final TextEditingController userSettingController;

  const SettingCard({
    super.key,
    required this.sessionData,
    required this.onUpdateField,
    required this.settingController,
    required this.userSettingController,
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
          icon: Icons.psychology,
        ),
        _buildEditableInfoItem(
          '用户设定',
          'user_setting',
          userSettingController,
          enabled: true,
          suffix: '可编辑',
          isMultiLine: true,
          icon: Icons.person_outline,
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
    IconData icon = Icons.edit,
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
                  color: enabled
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: enabled ? AppTheme.primaryColor : Colors.grey,
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
          SizedBox(height: 12.h),
          if (enabled)
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
                  hintStyle: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                onChanged: (value) => onUpdateField(field, value),
                maxLines: isMultiLine ? null : 1,
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppTheme.textPrimary.withOpacity(0.03),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppTheme.textPrimary.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Colors.grey,
                    size: 14.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '无法查看和编辑',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
