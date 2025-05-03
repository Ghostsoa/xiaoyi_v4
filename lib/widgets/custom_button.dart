import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final List<Color>? gradientColors;
  final AlignmentGeometry? gradientBegin;
  final AlignmentGeometry? gradientEnd;
  final double? width;
  final double? height;
  final Widget child;
  final VoidCallback? onPressed;
  final bool isAccent;
  final bool isOutlined;
  final bool isSmall;

  const CustomButton({
    super.key,
    this.gradientColors,
    this.gradientBegin,
    this.gradientEnd,
    this.width,
    this.height,
    required this.child,
    this.onPressed,
    this.isAccent = false,
    this.isOutlined = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? (isSmall ? 32.h : 44.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ??
              (isAccent ? AppTheme.accentGradient : AppTheme.buttonGradient),
          begin: gradientBegin ?? Alignment.topLeft,
          end: gradientEnd ?? Alignment.bottomRight,
          transform: GradientRotation(0.4),
        ),
        borderRadius: BorderRadius.circular(isSmall ? 4.r : 8.r),
        boxShadow: [
          BoxShadow(
            color: (gradientColors?.first ??
                    (isAccent
                        ? AppTheme.accentGradient.first
                        : AppTheme.buttonGradient.first))
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isSmall ? 4.r : 8.r),
          child: Center(
            child: DefaultTextStyle(
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 12.sp : 14.sp,
                fontWeight: FontWeight.w500,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry? margin;
  final Color? textColor;

  const CustomTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.margin,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          foregroundColor: textColor ?? AppTheme.primaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: AppTheme.captionSize,
            fontWeight: FontWeight.w500,
            color: textColor ?? AppTheme.primaryLight,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
