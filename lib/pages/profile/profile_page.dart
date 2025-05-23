import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_toast.dart';
import '../../dao/user_dao.dart';
import '../login/login_page.dart';
import '../admin/admin_page.dart';
import 'profile_server.dart';
import 'asset_records_page.dart';
import 'edit_profile_page.dart';
import 'earn_coin_page.dart';
import 'theme_settings_page.dart';
import 'api_key_manage_page.dart';
import 'exchange_page.dart';
import 'widgets/user_info_widget.dart';
import 'widgets/user_assets_widget.dart';
import 'widgets/settings_widget.dart';
import 'widgets/earning_coin_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final UserDao _userDao = UserDao();
  final ProfileServer _profileServer = ProfileServer();

  String _username = '加载中...';
  int _userId = 0;
  int _userRole = 0;
  String _roleDescription = '';
  bool _isAdmin = false;
  bool _isOperator = false;

  // 资产相关
  int _level = 0;
  String _levelName = '';
  double _coin = 0.0;
  double _exp = 0.0;
  double _playTime = 0.0;
  String? _playTimeExpireAt;

  bool _isLoading = true;
  bool _isAssetLoading = false;
  bool _refreshSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadUserAssets();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final username = await _userDao.getUsername();
      final userId = await _userDao.getUserId();
      final userRole = await _userDao.getUserRole();
      final roleDescription = await _userDao.getUserRoleDescription();
      final isAdmin = await _userDao.isAdmin();
      final isOperator = await _userDao.isOperator();

      setState(() {
        _username = username ?? '未知用户';
        _userId = userId ?? 0;
        _userRole = userRole ?? 0;
        _roleDescription = roleDescription;
        _isAdmin = isAdmin;
        _isOperator = isOperator;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showErrorToast('加载用户信息失败');
      }
    }
  }

  Future<void> _loadUserAssets() async {
    setState(() {
      _isAssetLoading = true;
    });

    try {
      final result = await _profileServer.getUserAssets();

      setState(() {
        if (result['success']) {
          final assets = result['data'];
          _level = assets['level'] ?? 0;
          _levelName = assets['level_name'] ?? '';
          _coin = (assets['assets']['coin'] ?? 0).toDouble();
          _exp = (assets['assets']['exp'] ?? 0).toDouble();
          _playTime = (assets['assets']['play_time'] ?? 0).toDouble();
          _playTimeExpireAt = assets['assets']['play_time_expire_at'];
        } else {
          // 显示错误消息
          if (mounted) {
            _showErrorToast(result['msg']);
          }
        }
        _isAssetLoading = false;
      });
    } catch (e) {
      setState(() {
        _isAssetLoading = false;
      });

      if (mounted) {
        _showErrorToast('加载用户资产失败: $e');
      }
    }
  }

  Future<void> _refreshAssets() async {
    setState(() {
      _isAssetLoading = true;
      _refreshSuccess = false;
    });

    try {
      final result = await _profileServer.getUserAssets();

      setState(() {
        if (result['success']) {
          final assets = result['data'];
          _level = assets['level'] ?? 0;
          _levelName = assets['level_name'] ?? '';
          _coin = (assets['assets']['coin'] ?? 0).toDouble();
          _exp = (assets['assets']['exp'] ?? 0).toDouble();
          _playTime = (assets['assets']['play_time'] ?? 0).toDouble();
          _playTimeExpireAt = assets['assets']['play_time_expire_at'];
          _refreshSuccess = true;
        } else {
          // 显示错误消息
          if (mounted) {
            _showErrorToast(result['msg']);
          }
          _refreshSuccess = false;
        }
        _isAssetLoading = false;
      });

      // 3秒后重置成功状态
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _refreshSuccess = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isAssetLoading = false;
      });

      // 使用CustomToast提示失败
      if (mounted) {
        _showErrorToast('资产信息刷新失败');
      }
    }
  }

  void _handleAssetTap(String assetType) {
    String title;
    switch (assetType) {
      case 'coin':
        title = '小懿币记录';
        break;
      case 'exp':
        title = '经验值记录';
        break;
      case 'play_time':
        title = '畅玩时长记录';
        break;
      default:
        title = '资产记录';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssetRecordsPage(
          assetType: assetType,
          title: title,
        ),
      ),
    );
  }

  void _navigateToEarnCoinPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EarnCoinPage(),
      ),
    );
  }

  void _handleSettingTap(SettingItemType type) async {
    switch (type) {
      case SettingItemType.theme:
        // 跳转到主题设置页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ThemeSettingsPage(),
          ),
        );
        break;

      case SettingItemType.help:
        _showInfoToast('查看帮助与反馈');
        break;

      case SettingItemType.about:
        _showInfoToast('查看关于我们');
        break;

      case SettingItemType.apiKey:
        // 跳转到API Key管理页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ApiKeyManagePage(),
          ),
        );
        break;

      case SettingItemType.admin:
        // 直接跳转到后台管理页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminPage(),
          ),
        );
        break;

      case SettingItemType.logout:
        // 显示确认对话框
        final bool confirm = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                title: Text(
                  '确认退出登录',
                  style: AppTheme.titleStyle,
                ),
                content: Text(
                  '您确定要退出当前账号吗？',
                  style: AppTheme.bodyStyle,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                    ),
                    child: Text(
                      '取消',
                      style: AppTheme.buttonTextStyle.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                    child: Text(
                      '确认',
                      style: AppTheme.buttonTextStyle.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ) ??
            false;

        if (confirm) {
          try {
            // 使用UserDao清除用户数据
            await _userDao.clearUserInfo();

            // 清除登录凭据
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('email');
            await prefs.remove('password');
            await prefs.setBool('rememberMe', false);
            await prefs.setBool('isNewRegistered', false);

            _showSuccessToast('退出登录成功');

            // 导航到登录页面并清除导航栈
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false, // 清除所有路由历史
            );
          } catch (e) {
            _showErrorToast('退出登录失败: ${e.toString()}');
          }
        }
        break;

      default: // 处理 theme 和其他未知类型
        break;
    }
  }

  void _showErrorToast(String message) {
    if (!mounted) return;
    CustomToast.show(
      context,
      message: message,
      type: ToastType.error,
    );
  }

  void _showSuccessToast(String message) {
    if (!mounted) return;
    CustomToast.show(
      context,
      message: message,
      type: ToastType.success,
    );
  }

  void _showInfoToast(String message) {
    if (!mounted) return;
    CustomToast.show(
      context,
      message: message,
      type: ToastType.info,
    );
  }

  // 添加refresh方法供外部调用
  void refresh() {
    if (mounted) {
      setState(() {
        // 重新加载个人资料数据
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 32.sp,
                      height: 32.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
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
            : Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                ),
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 32.h),
                        // 用户基本信息组件
                        UserInfoWidget(
                          username: _username,
                          userId: _userId,
                          userRole: _userRole,
                          roleDescription: _roleDescription,
                          level: _level,
                          levelName: _levelName,
                          onEditPressed: () async {
                            final currentAvatar = await _userDao.getAvatar();
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfilePage(
                                  currentUsername: _username,
                                  currentAvatar: currentAvatar,
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadUserInfo();
                              _showSuccessToast('个人资料更新成功');
                            }
                          },
                        ),
                        SizedBox(height: 32.h),
                        // 用户资产组件
                        UserAssetsWidget(
                          coin: _coin,
                          exp: _exp,
                          playTime: _playTime,
                          playTimeExpireAt: _playTimeExpireAt,
                          isAssetLoading: _isAssetLoading,
                          refreshSuccess: _refreshSuccess,
                          onRefresh: _refreshAssets,
                          onAssetTap: _handleAssetTap,
                          onExchangeTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ExchangePage(),
                              ),
                            );

                            // 如果返回true，表示兑换成功，刷新资产
                            if (result == true) {
                              _refreshAssets();
                            }
                          },
                        ),
                        SizedBox(height: 32.h),
                        // 获取小懿币组件
                        EarningCoinWidget(
                          onEarnCoinTap: _navigateToEarnCoinPage,
                        ),
                        SizedBox(height: 32.h),
                        // 设置组件
                        SettingsWidget(
                          onSettingTap: _handleSettingTap,
                          showAdminEntry: _isAdmin || _isOperator,
                        ),
                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
