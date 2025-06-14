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

  // 检查是否是亮色主题
  bool get isLightTheme {
    final backgroundColor = AppTheme.background;
    // 计算颜色明度
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5; // 明度大于0.5认为是亮色主题
  }

  // 更新系统UI样式
  void _updateSystemUIOverlayStyle() {
    final isLight = isLightTheme;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        // 状态栏
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
        statusBarBrightness: isLight ? Brightness.light : Brightness.dark,

        // 导航栏
        systemNavigationBarColor: AppTheme.background,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isLight ? Brightness.dark : Brightness.light,

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

  // 当主题改变时调用此方法
  void updateSystemUI() {
    _updateSystemUIOverlayStyle();
    notifyListeners();
  }
}
