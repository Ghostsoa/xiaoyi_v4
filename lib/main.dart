import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'pages/login/login_page.dart';
import 'theme/theme_controller.dart';
import 'package:provider/provider.dart';
import 'net/http_client.dart';
import 'widgets/unfocus_wrapper.dart';
import 'theme/app_theme.dart';
import 'services/network_monitor_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.initialize(); // 初始化主题配置

  // 请求必要的权限
  await Permission.storage.request();
  await Permission.photos.request();
  await Permission.camera.request();
  await Permission.microphone.request();

  // 初始化网络监控服务 - 不等待其完成，让它在后台运行
  NetworkMonitorService().initializeAsync();

  // 强制竖屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 设置系统UI为深色模式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 初始化主题控制器
  final themeController = ThemeController();
  themeController.initSystemUIOverlayStyle();

  runApp(
    ChangeNotifierProvider.value(
      value: themeController,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取主题控制器
    final themeController = Provider.of<ThemeController>(context);

    return UnfocusWrapper(
      child: ScreenUtilInit(
        designSize: const Size(375, 812), // 设计图尺寸
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return MaterialApp(
            navigatorKey: HttpClient.navigatorKey, // 添加navigatorKey用于全局导航
            title: '小懿AI',
            debugShowCheckedModeBanner: false,
            theme: themeController.themeData,
            themeMode: ThemeMode.dark,
            darkTheme: themeController.themeData,
            // 登录页面作为首页
            home: Container(
              color: AppTheme.background,
              child: const LoginPage(),
            ),
          );
        },
      ),
    );
  }
}
