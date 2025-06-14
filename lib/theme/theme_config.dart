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

  // 预定义主题配色 - 渐变粉
  static final Map<String, Color> pinkGradientColors = {
    'primary': const Color(0xFFEC4899),
    'primaryLight': const Color(0xFFF472B6),
    'primaryDark': const Color(0xFFBE185D),
    'background': const Color(0xFF160D12),
    'cardBackground': const Color(0xFF1E1218),
    'textPrimary': const Color(0xFFF8FAFC),
    'textSecondary': const Color(0xFFE2E8F0),
    'border': const Color(0xFFBE185D),
  };

  static final Map<String, List<Color>> pinkGradientGradients = {
    'primary': [
      const Color(0xFFBE185D),
      const Color(0xFFEC4899),
      const Color(0xFFF472B6)
    ],
    'accent': [
      const Color(0xFFDB2777),
      const Color(0xFFF472B6),
      const Color(0xFFFBCFE8)
    ],
    'background': [
      const Color(0xFF160D12),
      const Color(0xFF1D1019),
      const Color(0xFF28121D)
    ],
    'card': [const Color(0xFF1E1218), const Color(0xFF2D1A24)],
    'button': [const Color(0xFFBE185D), const Color(0xFFEC4899)],
    'text': [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
    'border': [const Color(0xFFBE185D), const Color(0xFFF472B6)],
    'success': [const Color(0xFF34D399), const Color(0xFF10B981)],
    'warning': [const Color(0xFFFBBF24), const Color(0xFFD97706)],
    'error': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
  };

  // 预定义主题配色 - 活力蓝
  static final Map<String, Color> blueGradientColors = {
    'primary': const Color(0xFF3B82F6),
    'primaryLight': const Color(0xFF60A5FA),
    'primaryDark': const Color(0xFF1D4ED8),
    'background': const Color(0xFF0D1424),
    'cardBackground': const Color(0xFF13192E),
    'textPrimary': const Color(0xFFF8FAFC),
    'textSecondary': const Color(0xFFE2E8F0),
    'border': const Color(0xFF1D4ED8),
  };

  static final Map<String, List<Color>> blueGradientGradients = {
    'primary': [
      const Color(0xFF1D4ED8),
      const Color(0xFF3B82F6),
      const Color(0xFF60A5FA)
    ],
    'accent': [
      const Color(0xFF2563EB),
      const Color(0xFF60A5FA),
      const Color(0xFFBAE6FD)
    ],
    'background': [
      const Color(0xFF0D1424),
      const Color(0xFF12182C),
      const Color(0xFF192036)
    ],
    'card': [const Color(0xFF13192E), const Color(0xFF1E263D)],
    'button': [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)],
    'text': [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
    'border': [const Color(0xFF1D4ED8), const Color(0xFF60A5FA)],
    'success': [const Color(0xFF34D399), const Color(0xFF10B981)],
    'warning': [const Color(0xFFFBBF24), const Color(0xFFD97706)],
    'error': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
  };

  // 预定义主题配色 - 柠檬绿
  static final Map<String, Color> limeGradientColors = {
    'primary': const Color(0xFF84CC16),
    'primaryLight': const Color(0xFFA3E635),
    'primaryDark': const Color(0xFF4D7C0F),
    'background': const Color(0xFF0F1A0E),
    'cardBackground': const Color(0xFF162314),
    'textPrimary': const Color(0xFFF8FAFC),
    'textSecondary': const Color(0xFFE2E8F0),
    'border': const Color(0xFF4D7C0F),
  };

  static final Map<String, List<Color>> limeGradientGradients = {
    'primary': [
      const Color(0xFF4D7C0F),
      const Color(0xFF84CC16),
      const Color(0xFFA3E635)
    ],
    'accent': [
      const Color(0xFF65A30D),
      const Color(0xFFA3E635),
      const Color(0xFFD9F99D)
    ],
    'background': [
      const Color(0xFF0F1A0E),
      const Color(0xFF141F12),
      const Color(0xFF1A271A)
    ],
    'card': [const Color(0xFF162314), const Color(0xFF212F1C)],
    'button': [const Color(0xFF4D7C0F), const Color(0xFF84CC16)],
    'text': [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
    'border': [const Color(0xFF4D7C0F), const Color(0xFFA3E635)],
    'success': [const Color(0xFF34D399), const Color(0xFF10B981)],
    'warning': [const Color(0xFFFBBF24), const Color(0xFFD97706)],
    'error': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
  };

  // 预定义主题配色 - 青春橙
  static final Map<String, Color> orangeGradientColors = {
    'primary': const Color(0xFFF97316),
    'primaryLight': const Color(0xFFFB923C),
    'primaryDark': const Color(0xFFC2410C),
    'background': const Color(0xFF1A120E),
    'cardBackground': const Color(0xFF241A14),
    'textPrimary': const Color(0xFFF8FAFC),
    'textSecondary': const Color(0xFFE2E8F0),
    'border': const Color(0xFFC2410C),
  };

  static final Map<String, List<Color>> orangeGradientGradients = {
    'primary': [
      const Color(0xFFC2410C),
      const Color(0xFFF97316),
      const Color(0xFFFB923C)
    ],
    'accent': [
      const Color(0xFFEA580C),
      const Color(0xFFFB923C),
      const Color(0xFFFED7AA)
    ],
    'background': [
      const Color(0xFF1A120E),
      const Color(0xFF21170F),
      const Color(0xFF2A1D14)
    ],
    'card': [const Color(0xFF241A14), const Color(0xFF30241C)],
    'button': [const Color(0xFFC2410C), const Color(0xFFF97316)],
    'text': [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
    'border': [const Color(0xFFC2410C), const Color(0xFFFB923C)],
    'success': [const Color(0xFF34D399), const Color(0xFF10B981)],
    'warning': [const Color(0xFFFBBF24), const Color(0xFFD97706)],
    'error': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
  };

  // 预定义主题配色 - 明亮主题
  static final Map<String, Color> lightThemeColors = {
    'primary': const Color(0xFF6B46C1),
    'primaryLight': const Color(0xFF8B5CF6),
    'primaryDark': const Color(0xFF4C1D95),
    'background': const Color(0xFFF8FAFC),
    'cardBackground': const Color(0xFFFFFFFF),
    'textPrimary': const Color(0xFF1E293B),
    'textSecondary': const Color(0xFF475569),
    'border': const Color(0xFFCBD5E1),
  };

  static final Map<String, List<Color>> lightThemeGradients = {
    'primary': [
      const Color(0xFF4C1D95),
      const Color(0xFF6B46C1),
      const Color(0xFF8B5CF6)
    ],
    'accent': [
      const Color(0xFF7C3AED),
      const Color(0xFF8B5CF6),
      const Color(0xFFB794F4)
    ],
    'background': [
      const Color(0xFFF8FAFC),
      const Color(0xFFF1F5F9),
      const Color(0xFFE2E8F0)
    ],
    'card': [const Color(0xFFFFFFFF), const Color(0xFFF8FAFC)],
    'button': [const Color(0xFF6B46C1), const Color(0xFF8B5CF6)],
    'text': [const Color(0xFF1E293B), const Color(0xFF334155)],
    'border': [const Color(0xFFCBD5E1), const Color(0xFFE2E8F0)],
    'success': [const Color(0xFF34D399), const Color(0xFF10B981)],
    'warning': [const Color(0xFFFBBF24), const Color(0xFFD97706)],
    'error': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
  };

  // 主题名称枚举
  static const Map<String, String> themeNames = {
    'default': '默认紫色',
    'pink': '渐变粉',
    'blue': '活力蓝',
    'lime': '柠檬绿',
    'orange': '青春橙',
    'light': '明亮模式',
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

  // 应用预设主题
  void applyPresetTheme(String themeName) {
    switch (themeName) {
      case 'pink':
        colors = Map.from(pinkGradientColors);
        gradients = Map.from(pinkGradientGradients);
        break;
      case 'blue':
        colors = Map.from(blueGradientColors);
        gradients = Map.from(blueGradientGradients);
        break;
      case 'lime':
        colors = Map.from(limeGradientColors);
        gradients = Map.from(limeGradientGradients);
        break;
      case 'orange':
        colors = Map.from(orangeGradientColors);
        gradients = Map.from(orangeGradientGradients);
        break;
      case 'light':
        colors = Map.from(lightThemeColors);
        gradients = Map.from(lightThemeGradients);
        break;
      case 'default':
      default:
        resetToDefault();
        break;
    }
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
