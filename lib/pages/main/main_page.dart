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

  // 标记页面是否已初始化
  final List<bool> _pageInitialized = [true, false, false, false, false];

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

  // 静默刷新当前页面，不显示加载状态
  void _refreshCurrentPage() {
    switch (_currentIndex) {
      case 0:
        if (_pageInitialized[0]) {
          homeKey.currentState?.refresh();
        }
        break;
      case 1:
        if (_pageInitialized[1]) {
          messageKey.currentState?.refresh();
        }
        break;
      case 4:
        if (_pageInitialized[4]) {
          profileKey.currentState?.refresh();
        }
        break;
    }
  }

  // 初始化对应索引的页面
  void _initializePage(int index) {
    if (_pageInitialized[index]) return;

    setState(() {
      _pageInitialized[index] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 预先创建所有页面，但只有需要时才初始化内容
    final List<Widget> pages = [
      HomePage(key: homeKey),
      _pageInitialized[1]
          ? MessagePage(
              key: messageKey,
              unreadCount: _unreadCount,
              onUnreadCountChanged: _fetchUnreadCount,
            )
          : Container(),
      const SizedBox(),
      const SizedBox(),
      _pageInitialized[4] ? ProfilePage(key: profileKey) : Container(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      // 使用IndexedStack保持所有页面的状态
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

        // 第一次切换到该页面时初始化
        _initializePage(index);

        setState(() {
          _currentIndex = index;
        });

        // 切换页面后，静默刷新新页面
        if (index == 1) {
          // 消息页面特殊处理，需要获取未读数
          _fetchUnreadCount();
        }

        // 使用Future.microtask确保页面切换后再刷新数据
        Future.microtask(() {
          _refreshCurrentPage();
        });
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
