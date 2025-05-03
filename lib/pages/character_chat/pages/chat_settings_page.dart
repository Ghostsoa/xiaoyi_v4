import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../dao/chat_settings_dao.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../widgets/custom_toast.dart';

class ChatSettingsPage extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final VoidCallback? onSettingsChanged;

  const ChatSettingsPage({
    super.key,
    required this.sessionData,
    this.onSettingsChanged,
  });

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  final ChatSettingsDao _settingsDao = ChatSettingsDao();

  // 设置状态
  double _backgroundOpacity = 0.5;
  bool _enableMarkdown = true;
  Color _bubbleColor = AppTheme.cardBackground;
  double _bubbleOpacity = 0.8;
  Color _textColor = AppTheme.textPrimary;
  Color _userBubbleColor = AppTheme.primaryColor;
  double _userBubbleOpacity = 0.8;
  Color _userTextColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsDao.getAllSettings();
    setState(() {
      _backgroundOpacity = settings['backgroundOpacity'];
      _enableMarkdown = settings['markdownEnabled'];
      _bubbleColor = _hexToColor(settings['bubbleColor']);
      _bubbleOpacity = settings['bubbleOpacity'];
      _textColor = _hexToColor(settings['textColor']);
      _userBubbleColor = _hexToColor(settings['userBubbleColor']);
      _userBubbleOpacity = settings['userBubbleOpacity'];
      _userTextColor = _hexToColor(settings['userTextColor']);
    });
  }

  Color _hexToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  Future<void> _saveSettings() async {
    try {
      await _settingsDao.saveAllSettings({
        'backgroundOpacity': _backgroundOpacity,
        'markdownEnabled': _enableMarkdown,
        'bubbleColor': _colorToHex(_bubbleColor),
        'bubbleOpacity': _bubbleOpacity,
        'textColor': _colorToHex(_textColor),
        'userBubbleColor': _colorToHex(_userBubbleColor),
        'userBubbleOpacity': _userBubbleOpacity,
        'userTextColor': _colorToHex(_userTextColor),
      });

      if (mounted) {
        CustomToast.show(
          context,
          message: '设置已保存',
          type: ToastType.success,
        );
      }

      // 调用回调函数
      widget.onSettingsChanged?.call();
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '保存失败: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _showColorPicker(Color currentColor, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            '选择颜色',
            style: TextStyle(
              color: AppTheme.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: onColorChanged,
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '确定',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // 自定义顶部栏
          Container(
            padding: EdgeInsets.only(top: statusBarHeight),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 56.h,
                  child: Row(
                    children: [
                      SizedBox(width: 4.w),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: AppTheme.textPrimary,
                          size: 20.sp,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '聊天设置',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      TextButton(
                        onPressed: _saveSettings,
                        child: Text(
                          '保存',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  color: AppTheme.border,
                ),
              ],
            ),
          ),
          // 设置列表
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _buildSection(
                  title: '显示设置',
                  children: [
                    _buildSliderItem(
                      title: '背景透明度',
                      subtitle: '调整背景图片的透明度',
                      value: _backgroundOpacity,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        setState(() => _backgroundOpacity = value);
                      },
                    ),
                    _buildSwitchItem(
                      title: 'Markdown 格式化',
                      subtitle: '启用 Markdown 格式化显示',
                      value: _enableMarkdown,
                      onChanged: (value) {
                        setState(() => _enableMarkdown = value);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                _buildSection(
                  title: '对话气泡设置',
                  children: [
                    _buildColorPickerItem(
                      title: '接收气泡颜色',
                      subtitle: '设置接收消息气泡的颜色',
                      color: _bubbleColor,
                      onTap: () {
                        _showColorPicker(_bubbleColor, (color) {
                          setState(() => _bubbleColor = color);
                        });
                      },
                    ),
                    _buildSliderItem(
                      title: '接收气泡透明度',
                      subtitle: '调整接收消息气泡的透明度',
                      value: _bubbleOpacity,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        setState(() => _bubbleOpacity = value);
                      },
                    ),
                    _buildColorPickerItem(
                      title: '接收文字颜色',
                      subtitle: '设置接收消息文字的颜色',
                      color: _textColor,
                      onTap: () {
                        _showColorPicker(_textColor, (color) {
                          setState(() => _textColor = color);
                        });
                      },
                    ),
                    Divider(
                      color: AppTheme.border,
                      height: 1,
                    ),
                    _buildColorPickerItem(
                      title: '发送气泡颜色',
                      subtitle: '设置发送消息气泡的颜色',
                      color: _userBubbleColor,
                      onTap: () {
                        _showColorPicker(_userBubbleColor, (color) {
                          setState(() => _userBubbleColor = color);
                        });
                      },
                    ),
                    _buildSliderItem(
                      title: '发送气泡透明度',
                      subtitle: '调整发送消息气泡的透明度',
                      value: _userBubbleOpacity,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        setState(() => _userBubbleOpacity = value);
                      },
                    ),
                    _buildColorPickerItem(
                      title: '发送文字颜色',
                      subtitle: '设置发送消息文字的颜色',
                      color: _userTextColor,
                      onTap: () {
                        _showColorPicker(_userTextColor, (color) {
                          setState(() => _userTextColor = color);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.w, bottom: 8.h),
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16.sp,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12.sp,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
        inactiveThumbColor: Colors.grey[600],
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
    );
  }

  Widget _buildSliderItem({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 12.h,
            bottom: 4.h,
          ),
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16.sp,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            bottom: 4.h,
          ),
          child: Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 100,
          label: '${(value * 100).toStringAsFixed(0)}%',
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
          inactiveColor: Colors.white24,
        ),
      ],
    );
  }

  Widget _buildColorPickerItem({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppTheme.border,
                    width: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
