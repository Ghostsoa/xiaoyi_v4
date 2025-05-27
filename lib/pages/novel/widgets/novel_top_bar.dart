import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NovelTopBar extends StatelessWidget {
  final String novelTitle;
  final VoidCallback onExit;

  const NovelTopBar({
    super.key,
    required this.novelTitle,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      height: kToolbarHeight / 2,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.exit_to_app,
              color: Colors.white,
              size: 22.sp,
            ),
            onPressed: onExit,
            tooltip: '退出阅读页面',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20.r,
          ),
          Text(
            novelTitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
