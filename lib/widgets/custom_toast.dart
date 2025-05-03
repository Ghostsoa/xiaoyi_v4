import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';

enum ToastType { success, error, info, warning }

class CustomToast {
  static OverlayEntry? _currentOverlay;

  // 显示Toast
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 2),
    double? topMargin,
  }) {
    // 如果已经有一个Toast在显示，先移除它
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlay = Overlay.of(context);

    _currentOverlay = OverlayEntry(
      builder: (context) {
        return _ToastWidget(
          message: message,
          type: type,
          topMargin: topMargin,
        );
      },
    );

    overlay.insert(_currentOverlay!);

    // 设置定时器，自动移除Toast
    Future.delayed(duration, () {
      _currentOverlay?.remove();
      _currentOverlay = null;
    });
  }

  // 关闭Toast
  static void dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _ToastWidget extends StatelessWidget {
  final String message;
  final ToastType type;
  final double? topMargin;

  const _ToastWidget({
    required this.message,
    required this.type,
    this.topMargin,
  });

  @override
  Widget build(BuildContext context) {
    // 根据类型设置图标和颜色
    IconData icon;
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (type) {
      case ToastType.success:
        icon = Icons.check_circle_outline;
        backgroundColor = AppTheme.success;
        break;
      case ToastType.error:
        icon = Icons.error_outline;
        backgroundColor = AppTheme.error;
        break;
      case ToastType.warning:
        icon = Icons.warning_amber_outlined;
        backgroundColor = AppTheme.warning;
        break;
      case ToastType.info:
        icon = Icons.info_outline;
        backgroundColor = AppTheme.primaryColor;
        break;
    }

    return Positioned(
      top: topMargin ?? MediaQuery.of(context).padding.top + 20.h,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowColor.withOpacity(0.3),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: textColor, size: 20.sp),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
