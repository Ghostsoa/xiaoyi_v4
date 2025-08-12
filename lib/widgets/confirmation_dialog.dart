import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 通用确认对话框组件
/// 
/// 使用示例：
/// ```dart
/// final result = await ConfirmationDialog.show(
///   context: context,
///   title: '确认删除',
///   content: '确定要删除这条消息吗？此操作不可恢复。',
///   confirmText: '删除',
///   isDangerous: true,
/// );
/// if (result == true) {
///   // 用户确认了操作
/// }
/// ```
class ConfirmationDialog extends StatefulWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final bool isDangerous;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showRememberOption;
  final String? rememberKey;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = '确定',
    this.cancelText = '取消',
    this.isDangerous = false,
    this.onConfirm,
    this.onCancel,
    this.showRememberOption = false,
    this.rememberKey,
  });

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();

  /// 检查是否已选择不再提醒
  static Future<bool> _shouldSkipReminder(String rememberKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('skip_reminder_$rememberKey') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 显示确认对话框
  ///
  /// [context] - 上下文
  /// [title] - 对话框标题
  /// [content] - 对话框内容
  /// [confirmText] - 确认按钮文本，默认为"确定"
  /// [cancelText] - 取消按钮文本，默认为"取消"
  /// [isDangerous] - 是否为危险操作，影响确认按钮颜色，默认为false
  /// [showRememberOption] - 是否显示"今后不再提醒"选项，默认为false
  /// [rememberKey] - 记忆键，用于标识不同类型的提醒
  ///
  /// 返回值：true表示用户确认，false表示用户取消，null表示对话框被其他方式关闭
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '确定',
    String cancelText = '取消',
    bool isDangerous = false,
    bool showRememberOption = false,
    String? rememberKey,
  }) async {
    // 如果启用了记忆功能且用户之前选择了不再提醒，直接返回确认
    if (showRememberOption && rememberKey != null) {
      final shouldSkip = await _shouldSkipReminder(rememberKey);
      if (shouldSkip) {
        return true; // 直接确认，不显示对话框
      }
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 防止点击外部关闭
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: title,
          content: content,
          confirmText: confirmText,
          cancelText: cancelText,
          isDangerous: isDangerous,
          showRememberOption: showRememberOption,
          rememberKey: rememberKey,
        );
      },
    );
  }
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  bool _rememberChoice = false;

  /// 保存不再提醒的选择
  Future<void> _saveRememberChoice(String rememberKey, bool remember) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('skip_reminder_$rememberKey', remember);
    } catch (e) {
      debugPrint('保存记忆选择失败: $e');
    }
  }

  void _handleConfirm() async {
    // 如果用户选择了记住，保存选择
    if (widget.showRememberOption &&
        widget.rememberKey != null &&
        _rememberChoice) {
      await _saveRememberChoice(widget.rememberKey!, true);
    }

    if (widget.onConfirm != null) {
      widget.onConfirm!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      title: Text(
        widget.title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: widget.isDangerous ? Colors.red[700] : null,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.content,
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),
          // 添加"今后不再提醒"选项
          if (widget.showRememberOption) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Checkbox(
                  value: _rememberChoice,
                  onChanged: (value) {
                    setState(() {
                      _rememberChoice = value ?? false;
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '今后不再提醒',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        // 取消按钮
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleCancel,
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Text(
                widget.cancelText,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        // 确认按钮
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleConfirm,
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: widget.isDangerous
                    ? Colors.red[500]
                    : Theme.of(context).primaryColor,
              ),
              child: Text(
                widget.confirmText,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
