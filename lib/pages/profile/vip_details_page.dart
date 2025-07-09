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
          modelName: 'gemini-2.5-Pro',
          description: '高性能AI大语言模型',
          dailyLimit: 50,
          usedQuota: 0,
          remainQuota: 0,
        ),
        ModelQuota(
          modelName: 'gemini-2.5-flash',
          description: '响应速度更快的AI模型',
          dailyLimit: 150,
          usedQuota: 0,
          remainQuota: 0,
        ),
        ModelQuota(
          modelName: 'gemini-2.0-flash',
          description: '稳定性更高的AI模型',
          dailyLimit: 150,
          usedQuota: 0,
          remainQuota: 0,
        ),
        ModelQuota(
          modelName: 'gemini-2.5flash-lite',
          description: '轻量级AI模型，无限制使用',
          dailyLimit: -1,
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
        final expireDate = DateTime.parse(widget.vipExpireAt!);
        _formattedExpireTime =
            '${expireDate.year}-${expireDate.month.toString().padLeft(2, '0')}-${expireDate.day.toString().padLeft(2, '0')} ${expireDate.hour.toString().padLeft(2, '0')}:${expireDate.minute.toString().padLeft(2, '0')}';
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
      _showToast('请先激活高阶魔法师特权', ToastType.info);
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
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: Text(
          '高阶魔法师特权',
          style: AppTheme.titleStyle,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textPrimary,
            size: 20.sp,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 只在激活状态下显示刷新按钮
          if (widget.isVip)
            _isRefreshing
                ? Container(
                    margin: EdgeInsets.only(right: 16.w),
                    width: 20.sp,
                    height: 20.sp,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: AppTheme.textPrimary,
                      size: 20.sp,
                    ),
                    onPressed: _refreshModelQuotas,
                    tooltip: '刷新配额',
                  ),
        ],
      ),
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
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // VIP状态卡片
                  _buildVipStatusCard(),

                  SizedBox(height: 24.h),

                  // 高阶魔法师介绍
                  _buildVipIntroduction(),

                  SizedBox(height: 24.h),

                  // 模型配额列表
                  _buildModelQuotaList(),

                  // 未激活时显示激活提示
                  if (!widget.isVip) ...[
                    SizedBox(height: 24.h),
                    _buildActivationPrompt(),
                  ],
                ],
              ),
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
                '高阶魔法师',
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
            Row(
              children: [
                Text(
                  '有效期至:',
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
            '高阶魔法师特权',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          _buildFeatureItem('包含时长卡全部功能，外加专属的模型调用权限'),
          SizedBox(height: 12.h),

          // 高阶魔法师特权详情
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
                  '小懿高阶魔法师专属魔法特权:',
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
                _buildMagicFeature('专属的模型调用权限'),
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
        Text(
          '模型使用配额',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
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
                ? '激活后可使用'
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
                '如何获得高阶魔法师特权',
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
            '您可以通过以下方式获得高阶魔法师特权:',
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
