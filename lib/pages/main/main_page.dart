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

  // 页面控制器
  final homeKey = GlobalKey<HomePageState>();
  final messageKey = GlobalKey<MessagePageState>();
  final profileKey = GlobalKey<ProfilePageState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUnreadCount();
    _startNotificationTimer();
  }

  void _startNotificationTimer() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _fetchUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchUnreadCount();
      _startNotificationTimer();
      _refreshCurrentPage();
    } else if (state == AppLifecycleState.paused) {
      _notificationTimer?.cancel();
      _notificationTimer = null;
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      debugPrint('获取未读通知数量失败: $e');
    }
  }

  void _refreshCurrentPage() {
    switch (_currentIndex) {
      case 0:
        homeKey.currentState?.refresh();
        break;
      case 1:
        messageKey.currentState?.refresh();
        break;
      case 4:
        profileKey.currentState?.refresh();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(key: homeKey),
      MessagePage(key: messageKey, unreadCount: _unreadCount),
      const SizedBox(),
      const SizedBox(),
      ProfilePage(key: profileKey),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: pages[_currentIndex],
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
                _buildNavItem(Icons.home_rounded, Icons.home_outlined, 0),
                _buildNavItem(Icons.chat_rounded, Icons.chat_outlined, 1),
                _buildAddButton(),
                _buildNavItem(Icons.explore_rounded, Icons.explore_outlined, 3),
                _buildNavItem(Icons.person_rounded, Icons.person_outlined, 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData selectedIcon, IconData unselectedIcon, int index) {
    final isSelected = _currentIndex == index;
    final bool showBadge = index == 1 && _unreadCount > 0;

    return GestureDetector(
      onTap: () {
        // 如果点击当前页面，不做任何操作
        if (_currentIndex == index) {
          return;
        }

        setState(() {
          _currentIndex = index;
        });

        // 切换页面后，刷新新页面
        Future.microtask(() {
          _refreshCurrentPage();
        });

        if (index == 1) {
          _fetchUnreadCount();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            isSelected
                ? ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        colors: AppTheme.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: Icon(
                      selectedIcon,
                      color: Colors.white,
                      size: 26.sp,
                    ),
                  )
                : Icon(
                    unselectedIcon,
                    color: AppTheme.textSecondary,
                    size: 26.sp,
                  ),
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

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
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
