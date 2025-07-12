import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';

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
    final Color pageColor = Colors.orange.shade400; // 使用分页的橙色

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 移除标题部分
        _buildEditableInfoItem(
          '开场白',
          'greeting',
          greetingController,
          suffix: '可编辑',
          isMultiLine: true,
          accentColor: Colors.teal,
        ),
        _buildEditableInfoItem(
          '前缀',
          'prefix',
          prefixController,
          suffix: '可编辑',
          accentColor: Colors.indigo,
        ),
        _buildEditableInfoItem(
          '后缀',
          'suffix',
          suffixController,
          suffix: '可编辑',
          accentColor: Colors.purple,
        ),
        _buildUiSettingsItem(),
        _buildInfoItem(
          '设定可编辑',
          sessionData['setting_editable'] == true ? '是' : '否',
          accentColor: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildEditableInfoItem(
    String label,
    String field,
    TextEditingController controller, {
    String? suffix,
    bool isMultiLine = false,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.2),
                  Colors.black.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withOpacity(0.8),
                              accentColor.withOpacity(0.5),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _getIconForField(field),
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
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
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor.withOpacity(0.8),
                                accentColor.withOpacity(0.5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            suffix,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: controller,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 1,
                            offset: Offset(0, 1),
                          ),
                        ],
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
                          color: Colors.white.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      onChanged: (value) => onUpdateField(field, value),
                      maxLines: isMultiLine ? null : 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildInfoItem(String label, String value,
      {required Color accentColor}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.2),
                  Colors.black.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withOpacity(0.8),
                        accentColor.withOpacity(0.5),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIconForInfoItem(label),
                    color: Colors.white,
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
                          color: accentColor.withOpacity(0.9),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final accentColor = Colors.cyan;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.2),
                  Colors.black.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withOpacity(0.8),
                              accentColor.withOpacity(0.5),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.format_paint,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'UI格式化类型',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withOpacity(0.8),
                              accentColor.withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '可编辑',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUiSettingOption(
                            'markdown', 'Markdown模式', Colors.green),
                        SizedBox(height: 12.h),
                        _buildUiSettingOption('disabled', '不启用状态栏', Colors.red),
                        SizedBox(height: 12.h),
                        _buildUiSettingOption(
                            'legacy_bar', '新版UI样式', Colors.blue),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14.sp,
                          color: accentColor.withOpacity(0.9),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _getUiSettingsDescription(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12.sp,
                              fontStyle: FontStyle.italic,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 1,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUiSettingOption(String value, String label, Color optionColor) {
    final isSelected = uiSettings == value;

    return GestureDetector(
      onTap: () => onUiSettingsChanged(value),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    optionColor.withOpacity(0.6),
                    optionColor.withOpacity(0.3),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected
                ? optionColor.withOpacity(0.8)
                : optionColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: optionColor.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              _getIconForOption(value),
              color: isSelected ? Colors.white : optionColor.withOpacity(0.8),
              size: 18.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: isSelected ? 2 : 1,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: optionColor.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
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
