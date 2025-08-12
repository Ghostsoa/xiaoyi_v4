import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class ChatSettingsDao {
  static final ChatSettingsDao _instance = ChatSettingsDao._internal();
  factory ChatSettingsDao() => _instance;
  ChatSettingsDao._internal();

  // 键名常量
  static const String _keyBackgroundOpacity = 'chat_background_opacity';
  static const String _keyMarkdownEnabled = 'chat_markdown_enabled';
  static const String _keyBubbleColor = 'chat_bubble_color';
  static const String _keyBubbleOpacity = 'chat_bubble_opacity';
  static const String _keyTextColor = 'chat_text_color';
  static const String _keyUserBubbleColor = 'chat_user_bubble_color';
  static const String _keyUserBubbleOpacity = 'chat_user_bubble_opacity';
  static const String _keyUserTextColor = 'chat_user_text_color';
  static const String _keyFontSize = 'chat_font_size';
  static const String _keyCustomTagStyles = 'custom_tag_styles';

  // UI设置相关的key
  static const String _keyUiMode = 'ui_mode';
  static const String _keyFormatOptions = 'format_options';
  static const String _keyCustomFormats = 'custom_formats';
  static const String _keyCodeBlockFormat = 'code_block_format';

  // 默认值
  static const double defaultBackgroundOpacity = 0.5;
  static const double defaultBubbleOpacity = 1.0;
  static const String defaultBubbleColor = '#F5F5F5';
  static const String defaultTextColor = '#2C2C2C';
  static const String defaultUserBubbleColor = '#3D5CFF';
  static const String defaultUserTextColor = '#FFFFFF';
  static const double defaultUserBubbleOpacity = 1.0;
  static const double defaultFontSize = 14.0;

  // 保存背景透明度
  Future<void> saveBackgroundOpacity(double opacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBackgroundOpacity, opacity);
  }

  // 获取背景透明度
  Future<double> getBackgroundOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyBackgroundOpacity) ?? defaultBackgroundOpacity;
  }

  // 保存 Markdown 启用状态
  Future<void> saveMarkdownEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMarkdownEnabled, enabled);
  }

  // 获取 Markdown 启用状态
  Future<bool> getMarkdownEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMarkdownEnabled) ?? true;
  }

  // 保存气泡颜色
  Future<void> saveBubbleColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBubbleColor, color);
  }

  // 获取气泡颜色
  Future<String> getBubbleColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBubbleColor) ?? defaultBubbleColor;
  }

  // 保存气泡透明度
  Future<void> saveBubbleOpacity(double opacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBubbleOpacity, opacity);
  }

  // 获取气泡透明度
  Future<double> getBubbleOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyBubbleOpacity) ?? defaultBubbleOpacity;
  }

  // 保存文字颜色
  Future<void> saveTextColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTextColor, color);
  }

  // 获取文字颜色
  Future<String> getTextColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTextColor) ?? defaultTextColor;
  }

  // 保存用户气泡颜色
  Future<void> saveUserBubbleColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserBubbleColor, color);
  }

  // 获取用户气泡颜色
  Future<String> getUserBubbleColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserBubbleColor) ?? defaultUserBubbleColor;
  }

  // 保存用户气泡透明度
  Future<void> saveUserBubbleOpacity(double opacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyUserBubbleOpacity, opacity);
  }

  // 获取用户气泡透明度
  Future<double> getUserBubbleOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyUserBubbleOpacity) ?? defaultUserBubbleOpacity;
  }

  // 保存用户文字颜色
  Future<void> saveUserTextColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserTextColor, color);
  }

  // 获取用户文字颜色
  Future<String> getUserTextColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserTextColor) ?? defaultUserTextColor;
  }

  // 保存字体大小
  Future<void> saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, size);
  }

  // 获取字体大小
  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyFontSize) ?? defaultFontSize;
  }

  // 保存所有设置
  Future<void> saveAllSettings(Map<String, dynamic> settings) async {
    await saveBackgroundOpacity(settings['backgroundOpacity']);
    await saveBubbleColor(settings['bubbleColor']);
    await saveBubbleOpacity(settings['bubbleOpacity']);
    await saveTextColor(settings['textColor']);
    await saveUserBubbleColor(settings['userBubbleColor']);
    await saveUserBubbleOpacity(settings['userBubbleOpacity']);
    await saveUserTextColor(settings['userTextColor']);
    if (settings.containsKey('fontSize')) {
      await saveFontSize(settings['fontSize']);
    }
    if (settings.containsKey('customTagStyles')) {
      await saveCustomTagStyles(settings['customTagStyles']);
    }
  }

  // 获取所有设置
  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'backgroundOpacity': await getBackgroundOpacity(),
      'bubbleColor': await getBubbleColor(),
      'bubbleOpacity': await getBubbleOpacity(),
      'textColor': await getTextColor(),
      'userBubbleColor': await getUserBubbleColor(),
      'userBubbleOpacity': await getUserBubbleOpacity(),
      'userTextColor': await getUserTextColor(),
      'fontSize': await getFontSize(),
      'customTagStyles': await getCustomTagStyles(),
    };
  }

  // 保存UI模式
  Future<void> saveUiMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUiMode, mode);
  }

  // 获取UI模式
  Future<String> getUiMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUiMode) ?? 'none';
  }

  // 保存格式化选项
  Future<void> saveFormatOptions(
      Map<String, Map<String, dynamic>> options) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(options);
    await prefs.setString(_keyFormatOptions, jsonString);
  }

  // 获取格式化选项
  Future<Map<String, Map<String, dynamic>>> getFormatOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyFormatOptions);
    if (jsonString == null) {
      return {};
    }
    final Map<String, dynamic> decoded = json.decode(jsonString);
    return decoded
        .map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
  }

  // 保存代码块格式设置
  Future<void> saveCodeBlockFormat(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCodeBlockFormat, enabled);
  }

  // 获取代码块格式设置
  Future<bool> getCodeBlockFormat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCodeBlockFormat) ?? false;
  }

  // 自定义标签样式相关方法

  /// 获取支持的标签列表
  static List<String> getSupportedTags() {
    return [
      'role', 'message', 'topic', 'feed', 'chat-list', 'chat-conversation',
      'status_on', 'status_off', 'archive', 'options_h', 'options_v', 'notebook'
    ];
  }

  /// 获取标签显示名称
  static String getTagDisplayName(String tagName) {
    const Map<String, String> displayNames = {
      'role': '角色标签',
      'message': '消息标签',
      'topic': '话题标签',
      'feed': '信息流标签',
      'chat-list': '聊天列表标签',
      'chat-conversation': '对话界面标签',
      'status_on': '状态开启标签',
      'status_off': '状态关闭标签',
      'archive': '归档标签',
      'options_h': '水平选项标签',
      'options_v': '垂直选项标签',
      'notebook': '笔记本标签',
    };
    return displayNames[tagName] ?? tagName;
  }

  /// 获取标签默认颜色（统一简洁配色）
  static Color getTagDefaultColor(String tagName) {
    // 所有标签使用统一的简洁灰色
    return const Color(0xFF6C7B7F);
  }

  /// 保存自定义标签样式
  Future<void> saveCustomTagStyles(Map<String, Map<String, dynamic>> styles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomTagStyles, json.encode(styles));
  }

  /// 获取自定义标签样式
  Future<Map<String, Map<String, dynamic>>> getCustomTagStyles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyCustomTagStyles);

    if (jsonString == null) {
      // 返回默认样式
      return _createDefaultTagStyles();
    }

    try {
      final Map<String, dynamic> decoded = json.decode(jsonString);
      final Map<String, Map<String, dynamic>> styles = {};

      decoded.forEach((key, value) {
        styles[key] = Map<String, dynamic>.from(value);
      });

      // 确保所有支持的标签都有样式
      final defaultStyles = _createDefaultTagStyles();
      defaultStyles.forEach((key, value) {
        if (!styles.containsKey(key)) {
          styles[key] = value;
        }
      });

      return styles;
    } catch (e) {
      // 如果解析失败，返回默认样式
      return _createDefaultTagStyles();
    }
  }

  /// 创建默认标签样式（统一简洁配色）
  Map<String, Map<String, dynamic>> _createDefaultTagStyles() {
    final Map<String, Map<String, dynamic>> styles = {};
    for (String tagName in getSupportedTags()) {
      styles[tagName] = {
        'backgroundColor': '0xFF6C7B7F', // 统一的简洁灰色
        'opacity': 0.15, // 适中的透明度
        'textColor': '0xFF2C2C2C', // 深灰色文字，确保可读性
      };
    }
    return styles;
  }
}
