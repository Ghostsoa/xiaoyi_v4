import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_theme.dart';

class NovelGeneratingIndicator extends StatelessWidget {
  final String message;
  final Color? textColor;

  const NovelGeneratingIndicator({
    super.key,
    required this.message,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color displayColor = textColor ?? Colors.white70;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Shimmer.fromColors(
        baseColor: AppTheme.primaryColor.withOpacity(0.6),
        highlightColor: Colors.white,
        period: const Duration(milliseconds: 1800),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories,
              size: 14.sp,
              color: displayColor,
            ),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: displayColor,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(width: 2.w),
            _buildAnimatedDots(displayColor),
          ],
        ),
      ),
    );
  }

  // 创建动态的点
  Widget _buildAnimatedDots(Color dotColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.w),
            child: Text(
              '.',
              style: TextStyle(
                fontSize: 14.sp,
                color: dotColor,
              ),
            ),
          ),
      ],
    );
  }
}
