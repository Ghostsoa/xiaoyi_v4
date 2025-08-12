import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_toast.dart';
import 'profile_server.dart';

class VipDetailsPage extends StatefulWidget {
  final String? vipExpireAt;
  final bool isVip;

  const VipDetailsPage({
    super.key,
    this.vipExpireAt,
    required this.isVip,
  });

  @override
  State<VipDetailsPage> createState() => _VipDetailsPageState();
}

class _VipDetailsPageState extends State<VipDetailsPage> {
  final ProfileServer _profileServer = ProfileServer();

  bool _isLoading = true;
  bool _isRefreshing = false;
  List<ModelQuota> _modelQuotas = [];
  String _formattedExpireTime = '';

  @override
  void initState() {
    super.initState();
    _formatExpireTime();

    // 只有激活状态才加载配额数据
    if (widget.isVip) {
      _loadModelQuotas();
    } else {
      // 未激活状态显示示例数据
      _setPlaceholderModelQuotas();
    }
  }

  // 为未激活状态设置示例配额数据
  void _setPlaceholderModelQuotas() {
    setState(() {
      _modelQuotas = [
        ModelQuota(
          modelName: 'gemini-2.5-pro',
          description: '高性能AI大语言模型',
          dailyLimit: 200,
          usedQuota: 0,
          remainQuota: 0,
        ),
        ModelQuota(
          modelName: 'gemini-2.5-flash',
          description: '响应速度更快的AI模型',
          dailyLimit: 500,
          usedQuota: 0,
          remainQuota: 0,
        ),
        ModelQuota(
          modelName: 'gemini-2.5-flash-lite-preview-06-17',
          description: '轻量级AI模型，无限制使用',
          dailyLimit: -1,
          usedQuota: 0,
          remainQuota: 0,
        ),
        ModelQuota(
          modelName: 'gemini-2.0-flash',
          description: '稳定性更高的AI模型',
          dailyLimit: 500,
          usedQuota: 0,
          remainQuota: 0,
        ),
        ModelQuota(
          modelName: 'gemini-2.0-flash-exp',
          description: '实验性AI模型，更多新功能',
          dailyLimit: 500,
          usedQuota: 0,
          remainQuota: 0,
        ),
      ];
      _isLoading = false;
    });
  }

  void _formatExpireTime() {
    if (widget.isVip &&
        widget.vipExpireAt != null &&
        widget.vipExpireAt!.isNotEmpty) {
      try {
        // 解析服务器UTC时间
        final expireDate = DateTime.parse(widget.vipExpireAt!);
        final now = DateTime.now();

        // 计算剩余时间：直接用UTC时间比较
        final difference = expireDate.difference(now);

        debugPrint('原始到期时间: ${widget.vipExpireAt}');
        debugPrint('解析到期时间(UTC): $expireDate');
        debugPrint('当前时间: $now');
        debugPrint('时间差(小时): ${difference.inHours}');
        debugPrint('时间差(分钟): ${difference.inMinutes}');

        if (difference.inSeconds > 0) {
          // 计算剩余天数，使用更简单的方式
          final totalDays = difference.inHours / 24.0;
          debugPrint('计算天数: ${difference.inHours} / 24 = $totalDays');

          // 计算剩余天数显示，不足0.1天时显示0.1天
          double displayDays = totalDays;
          if (totalDays > 0 && totalDays < 0.1) {
            displayDays = 0.1;
          }
          debugPrint('显示天数: $displayDays');

          // 格式化到期时间为 YYYY-MM-DD HH:mm（显示本地时间，需要加8小时）
          final localExpireDate = expireDate.add(const Duration(hours: 8));
          final year = localExpireDate.year;
          final month = localExpireDate.month.toString().padLeft(2, '0');
          final day = localExpireDate.day.toString().padLeft(2, '0');
          final hour = localExpireDate.hour.toString().padLeft(2, '0');
          final minute = localExpireDate.minute.toString().padLeft(2, '0');

          // 显示剩余天数和到期时间（分两行）
          String remainingDaysStr;
          if (displayDays == displayDays.truncateToDouble()) {
            remainingDaysStr = '剩余天数：${displayDays.toInt()}天';
          } else {
            remainingDaysStr = '剩余天数：${displayDays.toStringAsFixed(1)}天';
          }
          _formattedExpireTime = '$remainingDaysStr\n有效期：$year-$month-$day $hour:$minute';
        } else {
          _formattedExpireTime = '已过期';
        }
      } catch (e) {
        _formattedExpireTime = widget.vipExpireAt!;
      }
    } else if (widget.isVip) {
      _formattedExpireTime = '永久有效';
    } else {
      _formattedExpireTime = '未激活';
    }
  }

  Future<void> _loadModelQuotas() async {
    if (_isLoading) {
      // 初次加载
      setState(() {
        _isLoading = true;
      });
    } else {
      // 刷新数据时使用静默加载
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final result = await _profileServer.getAvailableOfficialModels();

      if (result['success']) {
        List<ModelQuota> quotas = [];
        final modelData = result['data'] as List;

        for (var model in modelData) {
          quotas.add(ModelQuota(
            modelName: model['modelName'] ?? '',
            description: model['description'] ?? '',
            dailyLimit: model['dailyLimit'] ?? 0,
            usedQuota: model['usedQuota'] ?? 0,
            remainQuota: model['remainQuota'] ?? 0,
          ));
        }

        if (mounted) {
          setState(() {
            _modelQuotas = quotas;
            _isLoading = false;
            _isRefreshing = false;
          });
        }
      } else {
        _showToast(result['msg'], ToastType.error);
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isRefreshing = false;
          });
        }
      }
    } catch (e) {
      _showToast('加载模型配额信息失败: $e', ToastType.error);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _refreshModelQuotas() {
    // 只有激活状态下才能刷新
    if (widget.isVip && !_isRefreshing) {
      _loadModelQuotas();
    } else if (!widget.isVip) {
      _showToast('请先激活契约魔法师特权', ToastType.info);
    }
  }

  void _showToast(String message, ToastType type) {
    if (!mounted) return;
    CustomToast.show(context, message: message, type: type);
  }

  // 添加显示配额说明对话框的方法
  void _showQuotaInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              '配额说明',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '基础配额保障会根据谷歌官方API调整而相应变化。我们将及时跟进谷歌官方的配额政策，确保为高阶魔法师提供最优质的服务。',
          style: TextStyle(
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '了解',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        backgroundColor: AppTheme.cardBackground,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 32.sp,
                    height: 32.sp,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '加载中...',
                    style: AppTheme.secondaryStyle,
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  // 自定义顶部栏
                  _buildCustomHeader(),

                  // 内容区域
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        children: [
                          // VIP状态卡片
                          _buildVipStatusCard(),

                          SizedBox(height: 24.h),

                          // 高阶魔法师介绍
                          _buildVipIntroduction(),

                          SizedBox(height: 24.h),

                          // 模型配额列表
                          _buildModelQuotaList(),

                          SizedBox(height: 24.h),

                          // 未激活时显示激活提示
                          if (!widget.isVip) _buildActivationPrompt(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // 自定义顶部栏
  Widget _buildCustomHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
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

          SizedBox(width: 16.w),

          // 标题
          Expanded(
            child: Text(
              '契约魔法师特权',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // 刷新按钮
          if (widget.isVip)
            InkWell(
              onTap: _isRefreshing ? null : _refreshModelQuotas,
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: _isRefreshing
                    ? SizedBox(
                        width: 20.sp,
                        height: 20.sp,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.w,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : Icon(
                        Icons.refresh_rounded,
                        color: AppTheme.primaryColor,
                        size: 20.sp,
                      ),
              ),
            ),
        ],
      ),
    );
  }

  // 构建格式化的到期时间显示，数值部分加粗
  Widget _buildFormattedExpireTime() {
    final lines = _formattedExpireTime.split('\n');
    if (lines.length != 2) {
      return Text(
        _formattedExpireTime,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.white,
          height: 1.3,
        ),
      );
    }

    // 解析第一行：剩余天数：X.X天
    final firstLine = lines[0];
    final remainingMatch = RegExp(r'剩余天数：(.+)天').firstMatch(firstLine);

    // 解析第二行：有效期：YYYY-MM-DD HH:mm
    final secondLine = lines[1];
    final expireMatch = RegExp(r'有效期：(.+)').firstMatch(secondLine);

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.white,
          height: 1.3,
        ),
        children: [
          TextSpan(text: '剩余天数：'),
          TextSpan(
            text: remainingMatch?.group(1) ?? '',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: '天\n有效期：'),
          TextSpan(
            text: expireMatch?.group(1) ?? '',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildVipStatusCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isVip
              ? [Colors.purple.shade700, Colors.purple.shade500]
              : [Colors.grey.shade700, Colors.grey.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: widget.isVip
                ? Colors.purple.withOpacity(0.3)
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
                Icons.auto_awesome,
                color: widget.isVip ? Colors.amber : Colors.grey.shade300,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                '契约魔法师',
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
                  widget.isVip ? '已激活' : '未激活',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (widget.isVip) ...[
            SizedBox(height: 16.h),
            _buildFormattedExpireTime(),
          ],
        ],
      ),
    );
  }

  Widget _buildVipIntroduction() {
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
            '契约魔法师特权',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          _buildFeatureItem('包含本源魔法师全部功能，外加专属的模型调用权限'),
          SizedBox(height: 12.h),

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
                  '本源魔法师特权:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                _buildMagicFeature('使用小懿特有的回复增强功能'),
                _buildMagicFeature('全新记忆模组'),
                _buildMagicFeature('小懿特供模型'),
                _buildMagicFeature('小说功能等更多最新功能'),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // 高阶魔法师专属特权
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.purple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '小懿契约魔法师专属魔法特权:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                _buildMagicFeature('基础配额保障'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelQuotaList() {
    if (_modelQuotas.isEmpty) {
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
        child: Center(
          child: Text(
            '暂无可用模型配额信息',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '基础配额保障',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(width: 8.w),
            // 添加信息按钮
            InkWell(
              onTap: _showQuotaInfoDialog,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.all(4.w),
                child: Icon(
                  Icons.help_outline,
                  color: Colors.blue,
                  size: 18.sp,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12.sp,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '每天早上8点刷新',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ...List.generate(
          _modelQuotas.length,
          (index) => _buildModelQuotaItem(_modelQuotas[index]),
        ),
      ],
    );
  }

  Widget _buildModelQuotaItem(ModelQuota quota) {
    // 计算使用进度
    double progress = 0.0;
    bool isUnlimited = quota.dailyLimit == -1;
    bool isInactive = !widget.isVip;

    if (!isInactive && !isUnlimited && quota.dailyLimit > 0) {
      progress = quota.usedQuota / quota.dailyLimit;
      progress = progress.clamp(0.0, 1.0); // 确保进度在0-1之间
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  quota.modelName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isInactive
                        ? AppTheme.textSecondary
                        : AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isInactive
                      ? Colors.grey.withOpacity(0.1)
                      : (isUnlimited
                          ? Colors.green.withOpacity(0.1)
                          : Colors.purple.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  isInactive
                      ? '未激活'
                      : (isUnlimited ? '无限制' : '剩余: ${quota.remainQuota}'),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isInactive
                        ? Colors.grey
                        : (isUnlimited ? Colors.green : Colors.purple),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (quota.description.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              quota.description,
              style: TextStyle(
                fontSize: 14.sp,
                color: isInactive
                    ? AppTheme.textSecondary.withOpacity(0.7)
                    : AppTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 12.h),
          // 如果是无限制，显示特殊样式的进度条
          Stack(
            children: [
              Container(
                height: 6.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              Container(
                height: 6.h,
                width: isInactive
                    ? 0 // 未激活不显示进度
                    : (isUnlimited
                        ? MediaQuery.of(context).size.width *
                            0.8 // 如果是无限制，显示满的进度条
                        : MediaQuery.of(context).size.width * 0.8 * progress),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isInactive
                          ? Colors.grey.shade400
                          : (isUnlimited
                              ? Colors.green.shade400
                              : Colors.purple.shade300),
                      isInactive
                          ? Colors.grey.shade600
                          : (isUnlimited
                              ? Colors.green.shade700
                              : Colors.purple.shade600),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            isInactive
                ? isUnlimited
                    ? '激活后每日可使用: 无限制'
                    : '激活后每日可使用: ${quota.dailyLimit}次'
                : (isUnlimited
                    ? '每日限额: 无限制 | 已使用: ${quota.usedQuota}'
                    : '每日限额: ${quota.dailyLimit} | 已使用: ${quota.usedQuota}'),
            style: TextStyle(
              fontSize: 12.sp,
              color: isInactive
                  ? AppTheme.textSecondary.withOpacity(0.7)
                  : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle,
          color: Colors.purple,
          size: 18.sp,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
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
                '如何获得契约魔法师特权',
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
            '您可以通过以下方式获得契约魔法师特权:',
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
}

class ModelQuota {
  final String modelName;
  final String description;
  final int dailyLimit;
  final int usedQuota;
  final int remainQuota;

  ModelQuota({
    required this.modelName,
    required this.description,
    required this.dailyLimit,
    required this.usedQuota,
    required this.remainQuota,
  });
}
