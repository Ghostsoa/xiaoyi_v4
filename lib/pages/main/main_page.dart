import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../home/home_page.dart';
import '../message/message_page.dart';
import '../profile/profile_page.dart';
import '../create/create_center_page.dart';
import '../message/notification_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUnreadCount();

    // 启动定时器，每15秒获取一次未读通知数量
    _startNotificationTimer();
  }

  void _startNotificationTimer() {
    // 取消已有的定时器
    _notificationTimer?.cancel();

    // 创建新的定时器，每15秒执行一次
    _notificationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _fetchUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    // 取消定时器
    _notificationTimer?.cancel();
    _notificationTimer = null;

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用回到前台时刷新未读消息
      _fetchUnreadCount();
      // 重新启动定时器
      _startNotificationTimer();
    } else if (state == AppLifecycleState.paused) {
      // 应用进入后台时暂停定时器，减少资源消耗
      _notificationTimer?.cancel();
      _notificationTimer = null;
    }
  }

  // 获取未读通知数量并更新消息页面
  Future<void> _fetchUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      // 忽略错误，避免因网络问题而崩溃
      debugPrint('获取未读通知数量失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 在build时构建页面列表，确保_unreadCount是最新的
    final List<Widget> pages = [
      const HomePage(),
      MessagePage(unreadCount: _unreadCount),
      const SizedBox(), // 占位，不会显示
      const SizedBox(), // 待定页面，暂时不实现
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem("首页", 0),
                _buildNavItem("消息", 1),
                _buildAddButton(),
                _buildNavItem("待定", 3),
                _buildNavItem("我的", 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建导航项
  Widget _buildNavItem(String title, int index) {
    final isSelected = _currentIndex == index;
    final bool showBadge = index == 1 && _unreadCount > 0; // 消息页面且有未读消息时显示角标

    return GestureDetector(
      onTap: () {
        // 如果当前已选中该项，不做任何操作
        if (_currentIndex == index) return;

        setState(() {
          _currentIndex = index;
        });

        // 切换到消息页时获取未读通知数量
        if (index == 1) {
          _fetchUnreadCount();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
            // 添加角标
            if (showBadge)
              Positioned(
                right: -8.w,
                top: -8.h,
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16.w,
                    minHeight: 16.w,
                  ),
                  child: Center(
                    child: Text(
                      _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
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

  // 构建中间的添加按钮 - 渐变样式，点击跳转到创作中心
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        // 跳转到创作中心页面
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CreateCenterPage(),
          ),
        );
      },
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppTheme.buttonGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            transform: const GradientRotation(0.4),
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppTheme.buttonGradient.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 24.sp,
        ),
      ),
    );
  }
}
