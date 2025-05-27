import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 小说设置数据访问对象
/// 负责存储和获取小说阅读设置相关信息
class NovelSettingsDao {
  static final NovelSettingsDao _instance = NovelSettingsDao._internal();

  factory NovelSettingsDao() => _instance;

  NovelSettingsDao._internal();

  // 键名常量
  static const String _contentFontSizeKey = 'novel_content_font_size';
  static const String _titleFontSizeKey = 'novel_title_font_size';
  static const String _backgroundColorKey = 'novel_background_color';
  static const String _textColorKey = 'novel_text_color';

  // 默认值
  static const double defaultContentFontSize = 16.0;
  static const double defaultTitleFontSize = 18.0;
  static final Color defaultBackgroundColor = const Color(0xFF121212);
  static final Color defaultTextColor = Colors.white;

  // 获取内容字体大小
  Future<double> getContentFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_contentFontSizeKey) ?? defaultContentFontSize;
  }

  // 设置内容字体大小
  Future<void> saveContentFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_contentFontSizeKey, size);
  }

  // 获取标题字体大小
  Future<double> getTitleFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_titleFontSizeKey) ?? defaultTitleFontSize;
  }

  // 设置标题字体大小
  Future<void> saveTitleFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_titleFontSizeKey, size);
  }

  // 获取背景颜色
  Future<Color> getBackgroundColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_backgroundColorKey);
    return colorValue != null ? Color(colorValue) : defaultBackgroundColor;
  }

  // 设置背景颜色
  Future<void> saveBackgroundColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backgroundColorKey, color.value);
  }

  // 获取文本颜色
  Future<Color> getTextColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_textColorKey);
    return colorValue != null ? Color(colorValue) : defaultTextColor;
  }

  // 设置文本颜色
  Future<void> saveTextColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_textColorKey, color.value);
  }

  // 一次性加载所有设置
  Future<Map<String, dynamic>> loadAllSettings() async {
    return {
      'contentFontSize': await getContentFontSize(),
      'titleFontSize': await getTitleFontSize(),
      'backgroundColor': await getBackgroundColor(),
      'textColor': await getTextColor(),
    };
  }

  // 一次性保存所有设置
  Future<void> saveAllSettings({
    required double contentFontSize,
    required double titleFontSize,
    required Color backgroundColor,
    required Color textColor,
  }) async {
    await saveContentFontSize(contentFontSize);
    await saveTitleFontSize(titleFontSize);
    await saveBackgroundColor(backgroundColor);
    await saveTextColor(textColor);
  }
}
