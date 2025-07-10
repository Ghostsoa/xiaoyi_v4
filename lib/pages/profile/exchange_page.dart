import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_toast.dart';
import 'profile_server.dart';

class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage> {
  final ProfileServer _profileServer = ProfileServer();
  final TextEditingController _coinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  final String _exchangeRate = "100小懿币 = 3小时本源魔法师时长"; // 更新兑换比例描述
  double _playTimeHours = 0; // 可兑换的本源魔法师时长

  @override
  void initState() {
    super.initState();
    _coinController.addListener(_updatePlayTimeHours);
  }

  @override
  void dispose() {
    _coinController.removeListener(_updatePlayTimeHours);
    _coinController.dispose();
    super.dispose();
  }

  void _updatePlayTimeHours() {
    if (_coinController.text.isEmpty) {
      setState(() {
        _playTimeHours = 0;
      });
      return;
    }

    try {
      final coinAmount = double.parse(_coinController.text);
      // 按照100小懿币=3小时的比例计算
      setState(() {
        _playTimeHours = (coinAmount / 100) * 3;
      });
    } catch (e) {
      setState(() {
        _playTimeHours = 0;
      });
    }
  }

  Future<void> _exchangePlayTime() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final coinAmount = double.parse(_coinController.text);

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _profileServer.exchangePlayTime(
        coin: coinAmount,
      );

      if (mounted) {
        if (result['success']) {
          _showSuccessToast(
              '兑换成功！获得${_playTimeHours.toStringAsFixed(1)}小时本源魔法师时长');
          _coinController.clear();

          // 返回上一页并刷新资产
          Navigator.pop(context, true);
        } else {
          _showErrorToast(result['msg']);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorToast('兑换失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessToast(String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.success,
    );
  }

  void _showErrorToast(String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部返回按钮和标题
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 20.sp,
                      color: AppTheme.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    '小懿币兑换',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // 主内容区域
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 兑换说明
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppTheme.primaryColor,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '兑换说明',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                _exchangeRate,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                '• 兑换后的本源魔法师特权将立即生效',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '• 兑换为一次性操作，无法撤销',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // 本源魔法师特权优势说明
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
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
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '本源魔法师特权',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              _buildAdvantageItem(
                                  '体验全部新功能', '第一时间体验所有最新发布的高级功能'),
                              SizedBox(height: 12.h),
                              _buildAdvantageItem(
                                  '专属回复增强技术', '享受更高质量的AI回复和更智能的问答互动体验'),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // 小懿币获取提示
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.campaign_outlined,
                                color: Colors.amber,
                                size: 24.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  '小懿币濒临绝版，目前唯一获取渠道为邀请好友注册',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.amber.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // 兑换表单
                        Text(
                          '兑换数量',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _coinController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            hintText: '请输入要兑换的小懿币数量',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14.sp,
                            ),
                            suffixText: '小懿币',
                            suffixStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入小懿币数量';
                            }
                            try {
                              final amount = double.parse(value);
                              if (amount <= 0) {
                                return '兑换数量必须大于0';
                              }
                              if (amount < 100) {
                                return '最低兑换100小懿币';
                              }
                            } catch (e) {
                              return '请输入有效的数字';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16.h),

                        // 兑换预览
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '可兑换本源魔法师特权时长',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                '${_playTimeHours.toStringAsFixed(1)}小时',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 32.h),

                        // 兑换按钮
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _exchangePlayTime,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              disabledBackgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.5),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 24.w,
                                    height: 24.w,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    '立即兑换',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvantageItem(String title, String description) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: Colors.green,
          size: 20.sp,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
