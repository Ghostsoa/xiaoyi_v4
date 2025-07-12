import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
import 'dart:ui';
import '../../../theme/app_theme.dart';
import '../../../dao/chat_settings_dao.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../widgets/custom_toast.dart';

class ChatSettingsPage extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final VoidCallback? onSettingsChanged;
  final Uint8List? backgroundImage;
  final double backgroundOpacity;

  const ChatSettingsPage({
    super.key,
    required this.sessionData,
    this.onSettingsChanged,
    this.backgroundImage,
    this.backgroundOpacity = 0.5,
  });

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  final ChatSettingsDao _settingsDao = ChatSettingsDao();
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
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          title: Text(
            '选择颜色',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: onColorChanged,
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
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 600 ? 600.0 : screenWidth;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 背景层
          if (widget.backgroundImage != null)
            Image.memory(
              widget.backgroundImage!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          Container(color: Colors.black.withOpacity(widget.backgroundOpacity)),

          // 内容层
          SafeArea(
            child: Center(
              child: Container(
                width: maxWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部操作区域
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 返回按钮
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(8.r),
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ),

                          // 页面标题
                          Text(
                            '聊天界面设置',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          // 保存按钮
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isSaving ? null : _saveSettings,
                              borderRadius: BorderRadius.circular(8.r),
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                child: _isSaving
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.w,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Icon(
                                        Icons.save,
                                        color: Colors.white,
                                        size: 20.sp,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 设置列表
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
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
                          SizedBox(height: 20.h),
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
                              Divider(
                                color: Colors.white.withOpacity(0.2),
                                height: 1,
                              ),
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
                              Divider(
                                color: Colors.white.withOpacity(0.2),
                                height: 1,
                              ),
                              _buildSliderItem(
                                title: '字体大小',
                                subtitle: '调整聊天消息的字体大小',
                                value: _fontSize,
                                min: 8.0,
                                max: 24.0,
                                onChanged: (value) {
                                  setState(() => _fontSize = value);
                                },
                                valueDisplay:
                                    '${_fontSize.toStringAsFixed(1)}px',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: children,
              ),
            ),
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
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                valueDisplay ?? '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
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
              color: Colors.white.withOpacity(0.7),
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
            value: value,
            min: min,
            max: max,
            divisions: 100,
            label: valueDisplay ?? '${(value * 100).toStringAsFixed(0)}%',
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
            inactiveColor: Colors.white24,
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
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
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
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
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
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
