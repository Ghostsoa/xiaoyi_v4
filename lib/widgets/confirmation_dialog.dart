import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final bool isDangerous;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = '确定',
    this.cancelText = '取消',
    this.isDangerous = false,
    this.onConfirm,
    this.onCancel,
  });

  /// 显示确认对话框
  /// 
  /// [context] - 上下文
  /// [title] - 对话框标题
  /// [content] - 对话框内容
  /// [confirmText] - 确认按钮文本，默认为"确定"
  /// [cancelText] - 取消按钮文本，默认为"取消"
  /// [isDangerous] - 是否为危险操作，影响确认按钮颜色，默认为false
  /// 
  /// 返回值：true表示用户确认，false表示用户取消，null表示对话框被其他方式关闭
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '确定',
    String cancelText = '取消',
    bool isDangerous = false,
  }) {
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
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: isDangerous ? Colors.red[700] : null,
        ),
      ),
      content: Text(
        content,
        style: TextStyle(
          fontSize: 14.sp,
          height: 1.4,
        ),
      ),
      actions: [
        // 取消按钮
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onCancel,
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Text(
                cancelText,
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
            onTap: onConfirm,
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: isDangerous
                    ? Colors.red[500]
                    : Theme.of(context).primaryColor,
              ),
              child: Text(
                confirmText,
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
