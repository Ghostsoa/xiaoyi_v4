import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
import '../../../theme/app_theme.dart';
import '../../../dao/group_chat_settings_dao.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../widgets/custom_toast.dart';

class GroupChatSettingsPage extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final VoidCallback? onSettingsChanged;
  final Uint8List? backgroundImage;
  final double backgroundOpacity;

  const GroupChatSettingsPage({
    super.key,
    required this.sessionData,
    this.onSettingsChanged,
    this.backgroundImage,
    this.backgroundOpacity = 0.5,
  });

  @override
  State<GroupChatSettingsPage> createState() => _GroupChatSettingsPageState();
}

class _GroupChatSettingsPageState extends State<GroupChatSettingsPage> {
  final GroupChatSettingsDao _settingsDao = GroupChatSettingsDao();
  bool _isSaving = false;

  // 设置状态
  double _backgroundOpacity = 0.5;
  Color _bubbleColor = AppTheme.cardBackground;
  double _bubbleOpacity = 0.8;
  Color _textColor = AppTheme.textPrimary;
  Color _userBubbleColor = AppTheme.primaryColor;
  double _userBubbleOpacity = 0.8;
  Color _userTextColor = Colors.white;
  double _fontSize = 14.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsDao.getAllSettings();
    setState(() {
      _backgroundOpacity = settings['backgroundOpacity'];
      _bubbleColor = _hexToColor(settings['bubbleColor']);
      _bubbleOpacity = settings['bubbleOpacity'];
      _textColor = _hexToColor(settings['textColor']);
      _userBubbleColor = _hexToColor(settings['userBubbleColor']);
      _userBubbleOpacity = settings['userBubbleOpacity'];
      _userTextColor = _hexToColor(settings['userTextColor']);
      _fontSize = settings['fontSize'] ?? 14.0;
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
    return '#${((color.a * 255).toInt() << 24 | (color.r * 255).toInt() << 16 | (color.g * 255).toInt() << 8 | (color.b * 255).toInt()).toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _settingsDao.saveAllSettings({
        'backgroundOpacity': _backgroundOpacity,
        'bubbleColor': _colorToHex(_bubbleColor),
        'bubbleOpacity': _bubbleOpacity,
        'textColor': _colorToHex(_textColor),
        'userBubbleColor': _colorToHex(_userBubbleColor),
        'userBubbleOpacity': _userBubbleOpacity,
        'userTextColor': _colorToHex(_userTextColor),
        'fontSize': _fontSize,
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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showColorPicker(Color currentColor, Function(Color) onColorChanged) {
    // 确保传入的颜色是不透明的
    final opaqueCurrentColor = currentColor.withAlpha(255);
    debugPrint('[ColorPicker] 传入颜色: $currentColor -> $opaqueCurrentColor');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          title: Text(
            '选择颜色',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: opaqueCurrentColor, // 使用不透明的颜色
              onColorChanged: (color) {
                // 强制设置 alpha 为 255（不透明）
                final opaqueColor = color.withAlpha(255);
                debugPrint('[ColorPicker] 选择颜色: $color -> $opaqueColor');
                onColorChanged(opaqueColor);
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsv,
              labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '确定',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 16.sp,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 600 ? 600.0 : screenWidth;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppTheme.textPrimary,
            size: 20.sp,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '群聊界面设置',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : Icon(
                    Icons.save,
                    color: AppTheme.textPrimary,
                    size: 20.sp,
                  ),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: maxWidth,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            children: [
              _buildSection(
                title: '背景设置',
                icon: Icons.image,
                color: Colors.teal,
                children: [
                  _buildSliderItem(
                    title: '背景透明度',
                    subtitle: '调整背景图片的暗度',
                    value: _backgroundOpacity,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      setState(() => _backgroundOpacity = value);
                    },
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _buildSection(
                title: '对话气泡设置',
                icon: Icons.chat_bubble_outline,
                color: Colors.deepPurple,
                children: [
                  _buildColorPickerItem(
                    title: '接收气泡颜色',
                    subtitle: '设置角色消息气泡的颜色',
                    color: _bubbleColor,
                    onTap: () {
                      _showColorPicker(_bubbleColor, (color) {
                        setState(() => _bubbleColor = color);
                      });
                    },
                  ),
                  _buildSliderItem(
                    title: '接收气泡透明度',
                    subtitle: '调整角色消息气泡的透明度',
                    value: _bubbleOpacity,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      setState(() => _bubbleOpacity = value);
                    },
                  ),
                  _buildColorPickerItem(
                    title: '接收文字颜色',
                    subtitle: '设置角色消息文字的颜色',
                    color: _textColor,
                    onTap: () {
                      _showColorPicker(_textColor, (color) {
                        setState(() => _textColor = color);
                      });
                    },
                  ),
                  Divider(height: 1),
                  _buildColorPickerItem(
                    title: '发送气泡颜色',
                    subtitle: '设置自己消息气泡的颜色',
                    color: _userBubbleColor,
                    onTap: () {
                      _showColorPicker(_userBubbleColor, (color) {
                        setState(() => _userBubbleColor = color);
                      });
                    },
                  ),
                  _buildSliderItem(
                    title: '发送气泡透明度',
                    subtitle: '调整自己消息气泡的透明度',
                    value: _userBubbleOpacity,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      setState(() => _userBubbleOpacity = value);
                    },
                  ),
                  _buildColorPickerItem(
                    title: '发送文字颜色',
                    subtitle: '设置自己消息文字的颜色',
                    color: _userTextColor,
                    onTap: () {
                      _showColorPicker(_userTextColor, (color) {
                        setState(() => _userTextColor = color);
                      });
                    },
                  ),
                  Divider(height: 1),
                  _buildSliderItem(
                    title: '字体大小',
                    subtitle: '调整聊天消息的字体大小',
                    value: _fontSize,
                    min: 8.0,
                    max: 24.0,
                    onChanged: (value) {
                      setState(() => _fontSize = value);
                    },
                    valueDisplay: '${_fontSize.toStringAsFixed(1)}px',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderItem({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    String? valueDisplay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 16.h,
            bottom: 4.h,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                valueDisplay ?? '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            bottom: 8.h,
          ),
          child: Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 16.r),
            valueIndicatorShape: PaddleSliderValueIndicatorShape(),
            valueIndicatorTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
            ),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: 100,
            label: valueDisplay ?? '${(value * 100).toStringAsFixed(0)}%',
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
            inactiveColor: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        SizedBox(height: 8.h),
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
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
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
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
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

