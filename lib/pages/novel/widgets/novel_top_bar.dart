import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NovelTopBar extends StatelessWidget {
  final String novelTitle;
  final VoidCallback onExit;
  final VoidCallback? onPullCache;
  final VoidCallback? onToggleSearch;
  final VoidCallback? onOverrideCache;
  final bool isLocalMode;
  final bool showPullCache;
  final bool showSearch;
  final bool showOverrideCache;

  const NovelTopBar({
    super.key,
    required this.novelTitle,
    required this.onExit,
    this.onPullCache,
    this.onToggleSearch,
    this.onOverrideCache,
    this.isLocalMode = false,
    this.showPullCache = false,
    this.showSearch = false,
    this.showOverrideCache = false,
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
          // 中间标题和状态
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  novelTitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isLocalMode) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      '本地',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 右侧功能按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSearch && onToggleSearch != null)
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                  onPressed: onToggleSearch,
                  tooltip: '搜索章节',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20.r,
                ),
              if (showOverrideCache && onOverrideCache != null)
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                  onPressed: onOverrideCache,
                  tooltip: '覆盖缓存',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20.r,
                ),
              if (showPullCache && onPullCache != null)
                IconButton(
                  icon: Icon(
                    Icons.cloud_download,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                  onPressed: onPullCache,
                  tooltip: '拉取缓存',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20.r,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
