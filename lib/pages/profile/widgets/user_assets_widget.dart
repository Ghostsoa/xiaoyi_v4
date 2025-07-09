import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';

class UserAssetsWidget extends StatelessWidget {
  final double coin;
  final double exp;
  final double playTime;
  final String? playTimeExpireAt;
  final bool isVip;
  final String? vipExpireAt;
  final bool isAssetLoading;
  final bool refreshSuccess;
  final VoidCallback onRefresh;
  final Function(String) onAssetTap;
  final VoidCallback onExchangeTap;

  const UserAssetsWidget({
    super.key,
    required this.coin,
    required this.exp,
    required this.playTime,
    this.playTimeExpireAt,
    this.isVip = false,
    this.vipExpireAt,
    required this.isAssetLoading,
    required this.refreshSuccess,
    required this.onRefresh,
    required this.onAssetTap,
    required this.onExchangeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和刷新按钮并排
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '我的资产',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: onExchangeTap,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '兑换',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // 刷新按钮
              GestureDetector(
                onTap: isAssetLoading ? null : onRefresh,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      isAssetLoading
                          ? SizedBox(
                              width: 14.w,
                              height: 14.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : refreshSuccess
                              ? Icon(
                                  Icons.check_circle_outline,
                                  size: 16.sp,
                                  color: Colors.green,
                                )
                              : Icon(
                                  Icons.refresh_rounded,
                                  size: 16.sp,
                                  color: AppTheme.primaryColor,
                                ),
                      SizedBox(width: 4.w),
                      Text(
                        isAssetLoading
                            ? '刷新中'
                            : refreshSuccess
                                ? '已更新'
                                : '刷新',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: refreshSuccess
                              ? Colors.green
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          // 资产内容区域 - 新布局，移除经验值，添加高阶魔法师
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildAssetItem(
                  context,
                  icon: Icons.monetization_on_outlined,
                  label: '小懿币',
                  value: coin.toStringAsFixed(0),
                  iconColor: Colors.amber,
                  onTap: () => onAssetTap('coin'),
                ),
              ),
              Expanded(
                child: _buildAssetItem(
                  context,
                  icon: Icons.access_time,
                  label: '畅玩时长',
                  value: _formatPlayTime(playTime),
                  iconColor: Colors.green,
                  onTap: () => onAssetTap('play_time'),
                ),
              ),
              Expanded(
                child: _buildAssetItem(
                  context,
                  icon: Icons.auto_awesome,
                  label: '高阶魔法师',
                  value: isVip ? '已激活' : '未激活',
                  iconColor: Colors.purple,
                  onTap: () => onAssetTap('vip'),
                  isActive: isVip,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 格式化畅玩时长，超过24小时显示为天数，不足1天显示小时数
  String _formatPlayTime(double hours) {
    if (hours >= 24) {
      final days = hours / 24; // 保留小数部分
      return '${days.toStringAsFixed(1)}天'; // 显示1位小数
    } else {
      return '${hours.toStringAsFixed(1)}小时'; // 显示1位小数
    }
  }

  Widget _buildAssetItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    VoidCallback? onTap,
    bool isActive = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: isActive ? iconColor : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: isActive ? AppTheme.textPrimary : Colors.grey,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: isActive ? AppTheme.textSecondary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
