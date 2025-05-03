import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeConfig {
  static const String _storageKey = 'theme_config';
  static const String _gradientStorageKey = 'theme_gradient_config';

  // 默认主题配置
  static final Map<String, Color> defaultColors = {
    'primary': AppTheme.primaryColor,
    'primaryLight': AppTheme.primaryLight,
    'primaryDark': AppTheme.primaryDark,
    'background': AppTheme.background,
    'cardBackground': AppTheme.cardBackground,
    'textPrimary': AppTheme.textPrimary,
    'textSecondary': AppTheme.textSecondary,
    'border': AppTheme.border,
  };

  // 默认渐变配置
  static final Map<String, List<Color>> defaultGradients = {
    'primary': AppTheme.primaryGradient,
    'accent': AppTheme.accentGradient,
    'background': [
      const Color(0xFF121212),
      const Color(0xFF1A1A1A),
      const Color(0xFF262626)
    ],
    'card': [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D)],
    'button': [const Color(0xFF6B46C1), const Color(0xFF8B5CF6)],
    'text': [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
    'border': [const Color(0xFF4338CA), const Color(0xFF6366F1)],
    'success': [const Color(0xFF34D399), const Color(0xFF10B981)],
    'warning': [const Color(0xFFFBBF24), const Color(0xFFD97706)],
    'error': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
  };

  Map<String, Color> colors;
  Map<String, List<Color>> gradients;

  ThemeConfig({
    Map<String, Color>? colors,
    Map<String, List<Color>>? gradients,
  })  : colors = colors ?? Map.from(defaultColors),
        gradients = gradients ?? Map.from(defaultGradients);

  // 从 SharedPreferences 加载配置
  static Future<ThemeConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedConfig = prefs.getString(_storageKey);
    final String? storedGradientConfig = prefs.getString(_gradientStorageKey);

    Map<String, Color> colors = Map.from(defaultColors);
    Map<String, List<Color>> gradients = Map.from(defaultGradients);

    if (storedConfig != null) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(storedConfig);
        jsonMap.forEach((key, value) {
          if (value is String && value.startsWith('#')) {
            colors[key] =
                Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
          }
        });
      } catch (e) {
        print('加载颜色配置失败: $e');
      }
    }

    if (storedGradientConfig != null) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(storedGradientConfig);
        jsonMap.forEach((key, value) {
          if (value is List) {
            gradients[key] = value.map((colorStr) {
              if (colorStr is String && colorStr.startsWith('#')) {
                return Color(
                    int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
              }
              return Colors.transparent;
            }).toList();
          }
        });
      } catch (e) {
        print('加载渐变配置失败: $e');
      }
    }

    return ThemeConfig(colors: colors, gradients: gradients);
  }

  // 保存配置到 SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    // 保存颜色配置
    final Map<String, String> colorMap = {};
    colors.forEach((key, value) {
      colorMap[key] = '#${value.value.toRadixString(16).substring(2)}';
    });
    await prefs.setString(_storageKey, json.encode(colorMap));

    // 保存渐变配置
    final Map<String, List<String>> gradientMap = {};
    gradients.forEach((key, value) {
      gradientMap[key] = value
          .map((color) => '#${color.value.toRadixString(16).substring(2)}')
          .toList();
    });
    await prefs.setString(_gradientStorageKey, json.encode(gradientMap));
  }

  // 重置为默认配置
  void resetToDefault() {
    colors = Map.from(defaultColors);
    gradients = Map.from(defaultGradients);
  }

  // 更新单个颜色
  void updateColor(String key, Color color) {
    if (colors.containsKey(key)) {
      colors[key] = color;
    }
  }

  // 更新渐变色
  void updateGradient(String key, List<Color> gradient) {
    if (gradients.containsKey(key)) {
      gradients[key] = gradient;
    }
  }

  // 应用配置到主题
  void apply() {
    AppTheme.updateConfig(this);
  }

  // 获取颜色值
  Color getColor(String key) {
    return colors[key] ?? defaultColors[key] ?? Colors.transparent;
  }

  // 获取渐变色
  List<Color> getGradient(String key) {
    return gradients[key] ??
        defaultGradients[key] ??
        [Colors.transparent, Colors.transparent];
  }

  // 获取主题名称
  static String getColorName(String key) {
    switch (key) {
      case 'primary':
        return '主色调';
      case 'primaryLight':
        return '浅色调';
      case 'primaryDark':
        return '深色调';
      case 'background':
        return '背景色';
      case 'cardBackground':
        return '卡片背景';
      case 'textPrimary':
        return '主要文本';
      case 'textSecondary':
        return '次要文本';
      case 'border':
        return '边框颜色';
      default:
        return key;
    }
  }

  // 获取渐变名称
  static String getGradientName(String key) {
    switch (key) {
      case 'primary':
        return '主要渐变';
      case 'accent':
        return '强调渐变';
      case 'background':
        return '背景渐变';
      case 'card':
        return '卡片渐变';
      case 'button':
        return '按钮渐变';
      case 'text':
        return '文本渐变';
      case 'border':
        return '边框渐变';
      case 'success':
        return '成功状态';
      case 'warning':
        return '警告状态';
      case 'error':
        return '错误状态';
      default:
        return key;
    }
  }
}
