import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NovelSmallIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isRotating;
  final Color? color;
  final Animation<double>? rotationAnimation;

  const NovelSmallIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.isRotating = false,
    this.color,
    this.rotationAnimation,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(icon, color: color ?? Colors.white70, size: 18.sp);

    if (isRotating && rotationAnimation != null) {
      iconWidget = RotationTransition(
        turns: rotationAnimation!,
        child: iconWidget,
      );
    }

    return IconButton(
      icon: iconWidget,
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 18.r,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints(
        minWidth: 28.w,
        minHeight: 28.h,
      ),
    );
  }
}
