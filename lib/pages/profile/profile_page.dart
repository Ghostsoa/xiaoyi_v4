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
import 'network_settings_page.dart';
import 'exchange_page.dart';
import 'widgets/user_info_widget.dart';
import 'widgets/user_assets_widget.dart';
import 'widgets/settings_widget.dart';
import 'widgets/earning_coin_widget.dart';
import 'vip_details_page.dart';
import 'play_time_permission_page.dart';

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
  bool _isVip = false;
  bool _isPlayTimeActive = false; // 添加本源魔法师激活状态
  String? _vipExpireAt;

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

          // 修改判断时长是否激活的逻辑 - 需要检查是否已经过期，并考虑时差
          _isPlayTimeActive =
              _playTime > 0 || (_isPlayTimeNotExpired(_playTimeExpireAt));

          _isVip = assets['assets']['vip'] ?? false;
          _vipExpireAt = assets['assets']['vip_expire_at'];
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

  // 添加检查时间是否过期的方法，考虑8小时时差
  bool _isPlayTimeNotExpired(String? expireTimeStr) {
    if (expireTimeStr == null || expireTimeStr.isEmpty) {
      return false;
    }

    try {
      // 解析时间并添加8小时时差
      final expireDate =
          DateTime.parse(expireTimeStr).add(const Duration(hours: 8));
      final now = DateTime.now();

      // 比较日期，如果过期时间晚于当前时间，则未过期
      return expireDate.isAfter(now);
    } catch (e) {
      debugPrint('解析过期时间出错: $e');
      return false;
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

          // 使用相同的逻辑判断是否激活
          _isPlayTimeActive =
              _playTime > 0 || (_isPlayTimeNotExpired(_playTimeExpireAt));

          _isVip = assets['assets']['vip'] ?? false;
          _vipExpireAt = assets['assets']['vip_expire_at'];
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
        // 移除点击小懿币的跳转逻辑
        return;
      case 'play_time':
        title = '本源魔法师记录';
        break;
      case 'asset_details':
        // 跳转到资产详情页，默认显示小懿币记录
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssetRecordsPage(
              assetType: 'coin', // 默认显示小懿币记录
              title: '资产详情',
              showFilter: true, // 显示筛选选项
            ),
          ),
        );
        return;
      case 'play_time_permission_exchange':
        // 处理本源魔法师的兑换逻辑
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ExchangePage(),
          ),
        ).then((result) {
          // 如果返回true，表示兑换成功，刷新资产
          if (result == true) {
            _refreshAssets();
          }
        });
        return;
      case 'play_time_permission':
        // 跳转到本源魔法师权限详情页
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayTimePermissionPage(
              playTimeExpireAt: _playTimeExpireAt,
              playTime: _playTime,
              isPlayTimeActive: _isPlayTimeActive,
            ),
          ),
        ).then((result) {
          // 如果返回true，表示可能在详情页面进行了兑换，需要刷新资产
          if (result == true) {
            _refreshAssets();
          }
        });
        return; // 提前返回，不执行下面的跳转
      case 'vip':
        // 无论是否激活，都跳转到VIP详情页
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VipDetailsPage(
              vipExpireAt: _vipExpireAt,
              isVip: _isVip,
            ),
          ),
        );
        return; // 提前返回，不执行下面的跳转
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
      case SettingItemType.network:
        // 跳转到网络节点设置页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NetworkSettingsPage(),
          ),
        );
        break;

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

            // 只清除登录状态，保留账号密码
            final prefs = await SharedPreferences.getInstance();
            // 保留email和password，不清除
            // 只修改自动登录状态
            await prefs.setBool('autoLogin', false);
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
                          exp: _exp,
                          onEditPressed: () async {
                            final currentAvatar = await _userDao.getAvatar();
                            debugPrint('当前用户头像URI: $currentAvatar'); // 添加日志
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
                          isVip: _isVip,
                          isPlayTimeActive: _isPlayTimeActive,
                          vipExpireAt: _vipExpireAt,
                          isAssetLoading: _isAssetLoading,
                          refreshSuccess: _refreshSuccess,
                          onRefresh: _refreshAssets,
                          onAssetTap: _handleAssetTap,
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
