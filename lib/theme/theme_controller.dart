import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';

class ThemeController extends ChangeNotifier {
  // 单例模式
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal();

  // 获取主题数据
  ThemeData get themeData => AppTheme.theme;

  // 更新系统UI样式
  void _updateSystemUIOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        // 状态栏
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,

        // 导航栏
        systemNavigationBarColor: AppTheme.background,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,

        // 其他设置
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  // 初始化系统UI样式
  void initSystemUIOverlayStyle() {
    _updateSystemUIOverlayStyle();
  }
}
