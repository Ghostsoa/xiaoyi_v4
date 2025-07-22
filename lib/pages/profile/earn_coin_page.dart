import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_toast.dart';
import '../../dao/user_dao.dart';
import 'profile_server.dart';

class EarnCoinPage extends StatefulWidget {
  const EarnCoinPage({super.key});

  @override
  State<EarnCoinPage> createState() => _EarnCoinPageState();
}

class _EarnCoinPageState extends State<EarnCoinPage> {
  final ProfileServer _profileServer = ProfileServer();
  final UserDao _userDao = UserDao();
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSyncingAssets = false;
  int _userId = 0;
  bool _isLoadingUserId = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final userId = await _userDao.getUserId();
      setState(() {
        _userId = userId ?? 0;
        _isLoadingUserId = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUserId = false;
      });
      if (mounted) {
        CustomToast.show(
          context,
          message: '获取用户ID失败',
          type: ToastType.error,
        );
      }
    }
  }

  void _copyUserId() {
    Clipboard.setData(ClipboardData(text: _userId.toString())).then((_) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '已复制邀请ID: $_userId',
          type: ToastType.success,
        );
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeemCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _profileServer.redeemCard(
        cardSecret: _codeController.text.trim(),
      );

      if (mounted) {
        if (result['success']) {
          // 兑换成功
          CustomToast.show(
            context,
            message: result['msg'],
            type: ToastType.success,
          );

          // 清空输入框
          _codeController.clear();

          // 无论兑换什么，都显示相同的成功提示
          _showRedeemSuccessDialog(
            '兑换成功',
            '请刷新资产',
          );
        } else {
          // 兑换失败
          CustomToast.show(
            context,
            message: result['msg'],
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '兑换失败: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showRedeemSuccessDialog(String title, String subtitle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 60.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '确定',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 打开赞助网页
  Future<void> _launchSponsorUrl() async {
    final Uri url = Uri.parse('http://zanzhu.xiaoyi.ink');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          CustomToast.show(
            context,
            message: '无法打开网页，请手动访问',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '打开网页失败: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _syncOldAssets() async {
    setState(() {
      _isSyncingAssets = true;
    });

    try {
      final result = await _profileServer.syncOldAssets();

      if (mounted) {
        if (result['success']) {
          // 同步成功
          CustomToast.show(
            context,
            message: result['msg'],
            type: ToastType.success,
          );

          // 获取同步信息
          final syncData = result['data'];
          if (syncData != null && syncData['sync_result'] != null) {
            final syncResult = syncData['sync_result'];
            final currentAssets = syncData['current_assets'] ?? {};

            // 显示同步结果
            _showSyncResultDialog(
              syncResult: syncResult,
              currentAssets: currentAssets,
              playTimeExpireAt: syncData['play_time_expire_at'],
            );
          }
        } else {
          // 同步失败
          CustomToast.show(
            context,
            message: result['msg'],
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '同步失败: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingAssets = false;
        });
      }
    }
  }

  void _showSyncResultDialog({
    required Map<String, dynamic> syncResult,
    required Map<String, dynamic> currentAssets,
    String? playTimeExpireAt,
  }) {
    List<Widget> resultItems = [];

    // 添加同步的小懿币信息
    if (syncResult.containsKey('coin') && syncResult['coin'] != null) {
      resultItems.add(_buildSyncResultItem(
        '小懿币',
        '+${syncResult['coin']}',
        '当前余额: ${currentAssets['coin'] ?? 0}',
      ));
    }

    // 添加同步的经验值信息
    if (syncResult.containsKey('exp') && syncResult['exp'] != null) {
      resultItems.add(_buildSyncResultItem(
        '经验值',
        '+${syncResult['exp']}',
        '当前经验: ${currentAssets['exp'] ?? 0}',
      ));
    }

    // 添加同步的本源魔法师信息
    if (syncResult.containsKey('play_time') &&
        syncResult['play_time'] != null) {
      String subtitle = '当前时长: ${currentAssets['play_time'] ?? 0}小时';
      if (playTimeExpireAt != null) {
        final expiryDateStr =
            playTimeExpireAt.toString().substring(0, 16).replaceAll('T', ' ');
        subtitle += '\n有效期至: $expiryDateStr';
      }

      resultItems.add(_buildSyncResultItem(
        '本源魔法师',
        '+${syncResult['play_time']}小时',
        subtitle,
      ));
    }

    // 如果没有同步到任何资产
    if (resultItems.isEmpty) {
      resultItems.add(
        Text(
          '未找到可同步的旧资产数据',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Column(
            children: [
              Icon(
                Icons.sync_outlined,
                color: Colors.green,
                size: 60.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                '资产同步成功',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: resultItems,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '确定',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSyncResultItem(String title, String value, String subtitle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Divider(color: AppTheme.textSecondary.withOpacity(0.3)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: Text(
          '解锁更多特权',
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
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 兑换码兑换卡片
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
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
                  // 标题
                  Row(
                    children: [
                      Icon(
                        Icons.card_giftcard_outlined,
                        color: AppTheme.primaryColor,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '兑换码兑换',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  Text(
                    '请输入您收到的兑换码，兑换后将立即获得相应的奖励。',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // 兑换码输入表单
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        hintText: '请输入兑换码',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.5),
                          fontSize: 14.sp,
                        ),
                        filled: true,
                        fillColor: AppTheme.cardBackground.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 粘贴按钮
                            IconButton(
                              icon: Icon(
                                Icons.content_paste_rounded,
                                color: AppTheme.primaryColor.withOpacity(0.7),
                                size: 22.sp,
                              ),
                              tooltip: '从剪切板粘贴',
                              onPressed: () async {
                                final clipboardData = await Clipboard.getData(
                                    Clipboard.kTextPlain);
                                if (clipboardData != null &&
                                    clipboardData.text != null &&
                                    clipboardData.text!.isNotEmpty) {
                                  _codeController.text =
                                      clipboardData.text!.trim();
                                  CustomToast.show(
                                    context,
                                    message: '已粘贴兑换码',
                                    type: ToastType.success,
                                  );
                                } else {
                                  CustomToast.show(
                                    context,
                                    message: '剪切板为空',
                                    type: ToastType.info,
                                  );
                                }
                              },
                            ),
                            // 清除按钮
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppTheme.textSecondary.withOpacity(0.5),
                                size: 22.sp,
                              ),
                              tooltip: '清除输入',
                              onPressed: () {
                                _codeController.clear();
                              },
                            ),
                          ],
                        ),
                      ),
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14.sp,
                      ),
                      maxLines: 1,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入兑换码';
                        }
                        return null;
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9\-]'),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // 兑换按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _redeemCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        disabledBackgroundColor:
                            AppTheme.primaryColor.withOpacity(0.6),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.w,
                              ),
                            )
                          : Text(
                              '立即兑换',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // 赞助我们获取兑换码卡片
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
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
                  // 标题
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_outline,
                        color: Colors.redAccent,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '赞助我们',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  Text(
                    '您的赞助是小懿持续提供优质服务的动力，每一份支持都将帮助我们创造更好的AI体验！',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // 赞助好处列表
                  _buildSponsorItem(
                    '解锁契约魔法师特权，体验最新AI技术',
                    AppTheme.textSecondary,
                  ),
                  SizedBox(height: 8.h),
                  _buildSponsorItem(
                    '支持我们持续开发，打造更智能的小懿',
                    AppTheme.textSecondary,
                  ),
                  SizedBox(height: 8.h),
                  _buildSponsorItem(
                    '获得专属兑换码，畅享所有高级功能',
                    AppTheme.textSecondary,
                  ),

                  SizedBox(height: 24.h),

                  // 赞助按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _launchSponsorUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: Text(
                        '立即赞助',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // 邀请好友获取小懿币卡片
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
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
                  // 标题
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        color: AppTheme.primaryColor,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '邀请好友',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  Text(
                    '邀请好友注册并使用小懿，双方均可获得小懿币奖励：',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // 邀请规则列表
                  _buildRuleItem(
                    '1. 协助好友成为小懿AI魔法师！双方均可可以获得58小懿币魔法能量！',
                    AppTheme.textSecondary,
                  ),
                  SizedBox(height: 8.h),
                  _buildRuleItem('2. 被每次协助魔法师进阶契约魔法师或本源魔法师后均可以向您回报10%的魔法能量！',
                      AppTheme.textSecondary),
                  SizedBox(height: 8.h),
                  // 邀请ID显示
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[800]!.withOpacity(0.3),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '您的邀请ID',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              _isLoadingUserId
                                  ? SizedBox(
                                      height: 18.sp,
                                      width: 50.w,
                                      child: LinearProgressIndicator(
                                        backgroundColor: Colors.grey[700],
                                        color: AppTheme.primaryColor,
                                      ),
                                    )
                                  : Text(
                                      _userId.toString(),
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _isLoadingUserId ? null : _copyUserId,
                          icon: Icon(
                            Icons.copy,
                            color: AppTheme.primaryColor,
                            size: 20.sp,
                          ),
                          tooltip: '复制邀请ID',
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  Text(
                    '将您的邀请ID分享给好友，让好友在注册时填写，双方均可获得奖励',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // 同步旧资产卡片
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
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
                  // 标题
                  Row(
                    children: [
                      Icon(
                        Icons.sync_outlined,
                        color: AppTheme.primaryColor,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '同步旧资产',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  Text(
                    '如果您在旧版应用中有未同步的资产，可以点击下方按钮进行同步。',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // 同步旧资产说明列表
                  _buildRuleItem(
                    '1. 系统会自动查找与您账号关联的旧资产数据',
                    AppTheme.textSecondary,
                  ),
                  SizedBox(height: 8.h),
                  _buildRuleItem(
                    '2. 同步成功后，旧资产将自动添加到您的当前账户',
                    AppTheme.textSecondary,
                  ),
                  SizedBox(height: 8.h),
                  _buildRuleItem(
                    '3. 每个账户仅能同步一次旧资产数据',
                    AppTheme.textSecondary,
                  ),

                  SizedBox(height: 24.h),

                  // 同步按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSyncingAssets ? null : _syncOldAssets,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        disabledBackgroundColor:
                            AppTheme.primaryColor.withOpacity(0.6),
                      ),
                      child: _isSyncingAssets
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.w,
                              ),
                            )
                          : Text(
                              '立即同步',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String text, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

  Widget _buildSponsorItem(String text, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle,
          color: Colors.redAccent,
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
