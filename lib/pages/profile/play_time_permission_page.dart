import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_toast.dart';
import 'exchange_page.dart';

class PlayTimePermissionPage extends StatefulWidget {
  final String? playTimeExpireAt;
  final double playTime; // 时长（小时）
  final bool isPlayTimeActive; // 激活状态

  const PlayTimePermissionPage({
    super.key,
    this.playTimeExpireAt,
    required this.playTime,
    required this.isPlayTimeActive,
  });

  @override
  State<PlayTimePermissionPage> createState() => _PlayTimePermissionPageState();
}

class _PlayTimePermissionPageState extends State<PlayTimePermissionPage> {
  String _formattedExpireTime = '';

  @override
  void initState() {
    super.initState();
    _formatExpireTime();
  }

  void _formatExpireTime() {
    if (widget.isPlayTimeActive &&
        widget.playTimeExpireAt != null &&
        widget.playTimeExpireAt!.isNotEmpty) {
      try {
        final expireDate = DateTime.parse(widget.playTimeExpireAt!)
            .add(const Duration(hours: 8));
        final now = DateTime.now();
        final difference = expireDate.difference(now);

        if (difference.inSeconds > 0) {
          // 格式化到期时间为 YYYY-MM-DD HH:mm
          final year = expireDate.year;
          final month = expireDate.month.toString().padLeft(2, '0');
          final day = expireDate.day.toString().padLeft(2, '0');
          final hour = expireDate.hour.toString().padLeft(2, '0');
          final minute = expireDate.minute.toString().padLeft(2, '0');

          _formattedExpireTime = '$year-$month-$day $hour:$minute 到期';
        } else {
          _formattedExpireTime = '已过期';
        }
      } catch (e) {
        _formattedExpireTime = widget.playTimeExpireAt!;
      }
    } else if (widget.isPlayTimeActive) {
      _formattedExpireTime = '永久有效';
    } else {
      _formattedExpireTime = '未激活';
    }
  }

  // 格式化时长，超过24小时显示为天数，不足1天显示小时数
  String _formatPlayTime(double hours) {
    if (hours >= 24) {
      final days = hours / 24;
      // 如果是整数天，不显示小数部分
      if (days == days.roundToDouble()) {
        return '${days.toInt()}天';
      }
      // 否则保留1位小数
      return '${days.toStringAsFixed(1)}天';
    } else {
      // 如果是整数小时，不显示小数部分
      if (hours == hours.roundToDouble()) {
        return '${hours.toInt()}小时';
      }
      // 否则保留1位小数
      return '${hours.toStringAsFixed(1)}小时';
    }
  }

  void _showToast(String message, ToastType type) {
    if (!mounted) return;
    CustomToast.show(context, message: message, type: type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 自定义顶部区域
              _buildCustomHeader(),

              SizedBox(height: 16.h),

              // 状态卡片
              _buildStatusCard(),

              SizedBox(height: 24.h),

              // 本源魔法师介绍
              _buildIntroduction(),

              SizedBox(height: 24.h),

              // 未激活时显示激活提示
              if (!widget.isPlayTimeActive) ...[
                _buildActivationPrompt(),
                SizedBox(height: 24.h),
              ],

              // 无论是否激活，都显示兑换按钮
              _buildExchangeButton(),

              // 底部留白
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  // 自定义顶部区域
  Widget _buildCustomHeader() {
    return Container(
      padding: EdgeInsets.only(top: 12.h, bottom: 12.h),
      child: Row(
        children: [
          // 返回按钮
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.all(8.w),
              child: Icon(
                Icons.arrow_back_ios,
                color: AppTheme.textPrimary,
                size: 20.sp,
              ),
            ),
          ),

          // 标题
          Expanded(
            child: Text(
              '本源魔法师特权',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 保持空间平衡
          SizedBox(width: 36.w),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isPlayTimeActive
              ? [Colors.green.shade700, Colors.green.shade500]
              : [Colors.grey.shade700, Colors.grey.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: widget.isPlayTimeActive
                ? Colors.green.withOpacity(0.3)
                : Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_fix_high,
                color: widget.isPlayTimeActive
                    ? Colors.amber
                    : Colors.grey.shade300,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                '本源魔法师',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  widget.isPlayTimeActive ? '已激活' : '未激活',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (widget.isPlayTimeActive) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Text(
                  '剩余时长:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _formatPlayTime(widget.playTime),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Text(
                  '有效期:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _formattedExpireTime,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntroduction() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本源魔法师特权',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),

          // 本源魔法师特权
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '特权详情:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                _buildMagicFeature('使用小懿特有的回复增强功能'),
                _buildMagicFeature('智能的密钥负载均衡和重试机制'),
                _buildMagicFeature('小懿特供模型'),
                _buildMagicFeature('小说功能等更多最新功能'),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // 使用说明
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '使用说明',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                _buildInfoItem('激活后即可使用全部高级功能'),
                _buildInfoItem('时长从激活开始持续计算，不会因不使用而暂停'),
                _buildInfoItem('可通过兑换码或赞助获得更多时长'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivationPrompt() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.amber.withOpacity(0.5),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.amber,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                '如何获得本源魔法师特权',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            '您可以通过以下方式获得本源魔法师特权:',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          _buildActivationStep(
            '1. 在"解锁更多特权"页面中进行赞助',
            AppTheme.textSecondary,
          ),
          SizedBox(height: 8.h),
          _buildActivationStep(
            '2. 使用兑换码激活特权',
            AppTheme.textSecondary,
          ),
          SizedBox(height: 8.h),
          _buildActivationStep(
            '3. 通过小懿币兑换获得',
            AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildMagicFeature(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 14.sp,
            color: Colors.amber,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14.sp,
            color: Colors.amber,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivationStep(String text, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle,
          color: Colors.amber,
          size: 16.sp,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeButton() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ExchangePage(),
          ),
        ).then((result) {
          // 如果返回true，表示兑换成功，需要刷新数据
          if (result == true && mounted) {
            Navigator.pop(context, true); // 返回上一页并传递刷新信号
          }
        });
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              widget.isPlayTimeActive ? '兑换更多时长' : '立即兑换本源魔法师特权',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
