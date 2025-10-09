import 'package:shared_preferences/shared_preferences.dart';

/// 群聊聊天界面设置DAO - 独立于角色卡对话的设置
class GroupChatSettingsDao {
  static final GroupChatSettingsDao _instance = GroupChatSettingsDao._internal();
  factory GroupChatSettingsDao() => _instance;
  GroupChatSettingsDao._internal();

  // 键名常量 - 使用 group_chat_ 前缀区分
  static const String _keyBackgroundOpacity = 'group_chat_background_opacity';
  static const String _keyBubbleColor = 'group_chat_bubble_color';
  static const String _keyBubbleOpacity = 'group_chat_bubble_opacity';
  static const String _keyTextColor = 'group_chat_text_color';
  static const String _keyUserBubbleColor = 'group_chat_user_bubble_color';
  static const String _keyUserBubbleOpacity = 'group_chat_user_bubble_opacity';
  static const String _keyUserTextColor = 'group_chat_user_text_color';
  static const String _keyFontSize = 'group_chat_font_size';

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
    };
  }
}

