import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'theme_config.dart';

class AppTheme {
  static late ThemeConfig _config;
  static bool _initialized = false;

  // 初始化主题配置
  static Future<void> initialize() async {
    if (!_initialized) {
      _config = await ThemeConfig.load();
      _initialized = true;
    }
  }

  // 更新主题配置
  static void updateConfig(ThemeConfig config) {
    _config = config;
  }

  // 主色调 - 渐变色系
  static Color get primaryColor =>
      _initialized ? _config.getColor('primary') : const Color(0xFF6B46C1);
  static Color get primaryLight =>
      _initialized ? _config.getColor('primaryLight') : const Color(0xFF8B5CF6);
  static Color get primaryDark =>
      _initialized ? _config.getColor('primaryDark') : const Color(0xFF4C1D95);

  // 渐变色
  static List<Color> get primaryGradient => _initialized
      ? _config.getGradient('primary')
      : const [
          Color(0xFF4C1D95),
          Color(0xFF6B46C1),
          Color(0xFF8B5CF6),
        ];

  static List<Color> get accentGradient => _initialized
      ? _config.getGradient('accent')
      : const [
          Color(0xFF7C3AED),
          Color(0xFF8B5CF6),
          Color(0xFFB794F4),
        ];

  static List<Color> get backgroundGradient => _initialized
      ? _config.getGradient('background')
      : const [
          Color(0xFF121212),
          Color(0xFF1A1A1A),
          Color(0xFF262626),
        ];

  static List<Color> get cardGradient => _initialized
      ? _config.getGradient('card')
      : const [
          Color(0xFF1E1E1E),
          Color(0xFF2D2D2D),
        ];

  static List<Color> get buttonGradient => _initialized
      ? _config.getGradient('button')
      : const [
          Color(0xFF6B46C1),
          Color(0xFF8B5CF6),
        ];

  static List<Color> get textGradient => _initialized
      ? _config.getGradient('text')
      : const [
          Color(0xFFF8FAFC),
          Color(0xFFE2E8F0),
        ];

  static List<Color> get borderGradient => _initialized
      ? _config.getGradient('border')
      : const [
          Color(0xFF4338CA),
          Color(0xFF6366F1),
        ];

  static List<Color> get successGradient => _initialized
      ? _config.getGradient('success')
      : const [
          Color(0xFF34D399),
          Color(0xFF10B981),
        ];

  static List<Color> get warningGradient => _initialized
      ? _config.getGradient('warning')
      : const [
          Color(0xFFFBBF24),
          Color(0xFFD97706),
        ];

  static List<Color> get errorGradient => _initialized
      ? _config.getGradient('error')
      : const [
          Color(0xFFEF4444),
          Color(0xFFDC2626),
        ];

  // 辅助色系
  static Color get accentPink => const Color(0xFF9F7AEA);
  static Color get accentOrange => const Color(0xFFB794F4);
  static Color get accentRed => const Color(0xFFD6BCFA);

  // 背景色
  static Color get background =>
      _initialized ? _config.getColor('background') : const Color(0xFF121212);
  static Color get cardBackground => _initialized
      ? _config.getColor('cardBackground')
      : const Color(0xFF1E1E1E);

  // 文字颜色
  static Color get textPrimary =>
      _initialized ? _config.getColor('textPrimary') : const Color(0xFFF8FAFC);
  static Color get textSecondary => _initialized
      ? _config.getColor('textSecondary')
      : const Color(0xFFE2E8F0);
  static Color get textHint => const Color(0xFFADB5BD);

  // 边框颜色
  static Color get border =>
      _initialized ? _config.getColor('border') : const Color(0xFF4338CA);

  // 错误颜色
  static const Color error = Color(0xFFFF6B6B);

  // 成功颜色
  static const Color success = Color(0xFF51CF66);

  // 警告颜色
  static const Color warning = Color(0xFFFFD93D);

  // 阴影颜色
  static const Color shadowColor = Color(0x40000000);

  // 字体大小
  static double get headingSize => 28.sp;
  static double get subheadingSize => 20.sp;
  static double get titleSize => 18.sp;
  static double get bodySize => 16.sp;
  static double get captionSize => 14.sp;
  static double get smallSize => 12.sp;

  // 圆角尺寸
  static double get radiusLarge => 16.r;
  static double get radiusMedium => 12.r;
  static double get radiusSmall => 8.r;
  static double get radiusXSmall => 4.r;

  // 文本样式预设
  static TextStyle get headingStyle => TextStyle(
        fontSize: headingSize,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  static TextStyle get subheadingStyle => TextStyle(
        fontSize: subheadingSize,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get titleStyle => TextStyle(
        fontSize: titleSize,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodyStyle => TextStyle(
        fontSize: bodySize,
        color: textPrimary,
      );

  static TextStyle get secondaryStyle => TextStyle(
        fontSize: captionSize,
        color: textSecondary,
      );

  static TextStyle get hintStyle => TextStyle(
        fontSize: captionSize,
        color: textHint,
      );

  static TextStyle get buttonTextStyle => TextStyle(
        fontSize: bodySize,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get linkStyle => TextStyle(
        fontSize: captionSize,
        fontWeight: FontWeight.w500,
        color: primaryLight,
      );

  // 容器样式预设
  static BoxDecoration get cardDecoration => BoxDecoration(
        gradient: LinearGradient(
          colors: cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get inputDecoration => BoxDecoration(
        gradient: LinearGradient(
          colors: cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get buttonDecoration => BoxDecoration(
        gradient: LinearGradient(
          colors: buttonGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: GradientRotation(0.4), // 调整渐变角度
        ),
        borderRadius: BorderRadius.circular(radiusMedium),
        boxShadow: [
          BoxShadow(
            color: buttonGradient.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get accentButtonDecoration => BoxDecoration(
        gradient: LinearGradient(
          colors: accentGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: GradientRotation(0.4), // 调整渐变角度
        ),
        borderRadius: BorderRadius.circular(radiusMedium),
        boxShadow: [
          BoxShadow(
            color: accentGradient.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get backButtonDecoration => BoxDecoration(
        gradient: LinearGradient(
          colors: buttonGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(color: border, width: 1),
      );

  static BoxDecoration get socialButtonDecoration => BoxDecoration(
        gradient: LinearGradient(
          colors: accentGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // Material主题
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: background,
    brightness: _getBrightness(),
    colorScheme: _getColorScheme(),
    textTheme: TextTheme(
      displayLarge: headingStyle.copyWith(
        fontSize: headingSize * 1.2,
        color: primaryLight,
      ),
      displayMedium: headingStyle.copyWith(color: primaryLight),
      displaySmall: subheadingStyle.copyWith(color: primaryLight),
      headlineMedium: subheadingStyle.copyWith(color: primaryLight),
      headlineSmall: titleStyle.copyWith(color: textPrimary),
      titleLarge: titleStyle,
      titleMedium: bodyStyle.copyWith(fontWeight: FontWeight.w500),
      titleSmall: secondaryStyle.copyWith(fontWeight: FontWeight.w500),
      bodyLarge: bodyStyle,
      bodyMedium: secondaryStyle,
      bodySmall: hintStyle,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      titleTextStyle: titleStyle.copyWith(color: textPrimary),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withOpacity(0.1);
            }
            return null;
          },
        ),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
        elevation: WidgetStateProperty.all(0),
        textStyle: WidgetStateProperty.all(
          buttonTextStyle.copyWith(letterSpacing: 0.5),
        ),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        foregroundColor: WidgetStateProperty.all(primaryLight),
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.pressed)) {
              return primaryLight.withOpacity(0.1);
            }
            return null;
          },
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
        textStyle: WidgetStateProperty.all(
          linkStyle.copyWith(decoration: TextDecoration.underline),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: primaryLight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: error, width: 1),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ),
      hintStyle: hintStyle,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.transparent;
      }),
      side: BorderSide(color: border, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXSmall),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: border,
      thickness: 1,
      space: 1,
    ),
  );

  // 判断当前是否是亮色主题
  static bool get isLightTheme {
    final backgroundColor = background;
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5;
  }

  // 获取亮暗主题
  static Brightness _getBrightness() {
    return isLightTheme ? Brightness.light : Brightness.dark;
  }

  // 获取颜色方案
  static ColorScheme _getColorScheme() {
    if (isLightTheme) {
      return ColorScheme.light(
        primary: primaryColor,
        secondary: accentPink,
        tertiary: accentOrange,
        surface: cardBackground,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      );
    } else {
      return ColorScheme.dark(
        primary: primaryColor,
        secondary: accentPink,
        tertiary: accentOrange,
        surface: cardBackground,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      );
    }
  }

  // 自定义渐变按钮样式
  static ButtonStyle gradientButtonStyle({
    List<Color>? gradientColors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.all(Colors.transparent),
      foregroundColor: WidgetStateProperty.all(Colors.white),
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withOpacity(0.1);
          }
          return null;
        },
      ),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      elevation: WidgetStateProperty.all(0),
      textStyle: WidgetStateProperty.all(
        buttonTextStyle.copyWith(letterSpacing: 0.5),
      ),
    );
  }

  // 渐变文本样式
  static TextStyle gradientTextStyle({
    required List<Color> colors,
    double? fontSize,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize ?? bodySize,
      fontWeight: fontWeight ?? FontWeight.normal,
      decoration: decoration,
      letterSpacing: letterSpacing,
      height: height,
      foreground: Paint()
        ..shader = LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
    );
  }

  // 渐变文本样式预设
  static TextStyle get gradientHeadingStyle => gradientTextStyle(
        colors: [Colors.white, Colors.white70],
        fontSize: headingSize,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get gradientMediumHeadingStyle => gradientTextStyle(
        colors: [Colors.white, Colors.white70],
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get gradientTitleStyle => gradientTextStyle(
        colors: primaryGradient,
        fontSize: titleSize,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get gradientSubtitleStyle => gradientTextStyle(
        colors: [Colors.white60, Colors.white38],
        fontSize: bodySize,
      );

  static TextStyle get gradientTagStyle => gradientTextStyle(
        colors: primaryGradient,
        fontSize: smallSize,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get gradientActionStyle => gradientTextStyle(
        colors: primaryGradient,
        fontSize: captionSize,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get gradientLabelStyle => gradientTextStyle(
        colors: [Colors.white70, Colors.white54],
        fontSize: captionSize,
      );
}
