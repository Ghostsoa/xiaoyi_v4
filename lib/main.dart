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

  // 同步初始化网络监控服务，确保至少有一次节点检查完成
  await initNetworkMonitor();

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

/// 初始化网络监控服务
/// 同步等待第一次节点检测完成
Future<void> initNetworkMonitor() async {
  debugPrint('[App启动] 正在初始化网络监控服务...');

  try {
    // 获取API节点 - 这会触发必要的初始化和节点检测
    final endpoint = await NetworkMonitorService().getCurrentEndpoint();
    debugPrint('[App启动] 网络监控服务初始化成功，当前节点: $endpoint');

    // 修复：不再尝试访问HttpClient的私有成员
    debugPrint('[App启动] 已获取可用API节点，准备进入应用主界面');

    // 关键修复：同步等待HttpClient初始化完成
    debugPrint('[App启动] 正在等待HttpClient初始化...');
    await HttpClient().ensureInitialized();
    debugPrint('[App启动] HttpClient初始化成功');
  } catch (e) {
    // 即使初始化失败也继续启动应用
    debugPrint('[App启动] 初始化失败: $e');
  } finally {
    debugPrint('[App启动] 初始化流程已完成，即将显示登录界面');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 记录构建MyApp组件的日志
    debugPrint('[App启动] 正在构建MyApp组件');

    // 获取主题控制器
    final themeController = Provider.of<ThemeController>(context);

    // 构建应用
    final app = UnfocusWrapper(
      child: ScreenUtilInit(
        designSize: const Size(375, 812), // 设计图尺寸
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          debugPrint('[App启动] 正在构建MaterialApp');
          return MaterialApp(
            navigatorKey: HttpClient.navigatorKey, // 添加navigatorKey用于全局导航
            title: '小懿AI',
            debugShowCheckedModeBanner: false,
            theme: themeController.themeData,
            themeMode: ThemeMode.dark,
            darkTheme: themeController.themeData,
            // 登录页面作为首页
            home: Builder(
              builder: (context) {
                debugPrint('[App启动] 正在构建LoginPage');
                return Container(
                  color: AppTheme.background,
                  child: const LoginPage(),
                );
              },
            ),
          );
        },
      ),
    );

    debugPrint('[App启动] MyApp构建完成');
    return app;
  }
}
