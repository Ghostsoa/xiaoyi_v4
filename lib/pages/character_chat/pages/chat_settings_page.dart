import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
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
  Map<String, Map<String, dynamic>> _customTagStyles = {};

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
      _customTagStyles = settings['customTagStyles'] ?? {};
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

  Color _parseColorFromString(String colorString) {
    try {
      debugPrint('[ColorParser] 解析颜色字符串: $colorString');

      // 移除可能的前缀
      String cleanString = colorString;
      if (cleanString.startsWith('0x') || cleanString.startsWith('0X')) {
        cleanString = cleanString.substring(2);
      } else if (cleanString.startsWith('#')) {
        cleanString = cleanString.substring(1);
      }

      // 确保是8位十六进制数（包含alpha通道）
      if (cleanString.length == 6) {
        cleanString = 'FF$cleanString';
      }

      debugPrint('[ColorParser] 清理后的字符串: $cleanString');
      final color = Color(int.parse(cleanString, radix: 16));
      debugPrint('[ColorParser] 解析结果: $color');
      return color;
    } catch (e) {
      debugPrint('[ColorParser] 解析颜色失败: $colorString, 错误: $e');
      return AppTheme.cardBackground; // 返回默认颜色
    }
  }

  Map<String, dynamic> _getDefaultStyleForTag(String tagName) {
    return {
      'backgroundColor': '0xFF9E9E9E', // 统一的灰色背景
      'opacity': 0.15, // 适中的透明度
      'textColor': '0xFF212121', // 统一的深灰色/黑色文字
    };
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
        'customTagStyles': _customTagStyles,
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
          '聊天界面设置',
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
        child: Container(
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
              SizedBox(height: 16.h),
              _buildSectionWithAction(
                title: '自定义标签样式',
                icon: Icons.style,
                color: Colors.orange,
                actionIcon: Icons.refresh,
                actionLabel: '重置',
                onActionPressed: _resetCustomTagStyles,
                children: [
                  _buildCustomTagStylesList(),
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

  Widget _buildSectionWithAction({
    required String title,
    required List<Widget> children,
    required Color color,
    required IconData icon,
    required IconData actionIcon,
    required String actionLabel,
    required VoidCallback onActionPressed,
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
              const Spacer(),
              // 重置按钮
              TextButton.icon(
                onPressed: onActionPressed,
                icon: Icon(actionIcon, size: 16.sp, color: color),
                label: Text(
                  actionLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
            value: value,
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

  /// 构建自定义标签样式列表
  Widget _buildCustomTagStylesList() {
    final supportedTags = ChatSettingsDao.getSupportedTags();

    return Column(
      children: supportedTags.map((tagName) {
        final style = _customTagStyles[tagName] ?? _getDefaultStyleForTag(tagName);

        return _buildCustomTagStyleItem(tagName, style);
      }).toList(),
    );
  }

  /// 构建单个自定义标签样式项
  Widget _buildCustomTagStyleItem(String tagName, Map<String, dynamic> style) {
    final displayName = ChatSettingsDao.getTagDisplayName(tagName);
    final backgroundColor = _parseColorFromString(style['backgroundColor'].toString());
    final opacity = (style['opacity'] as num).toDouble();
    final textColor = _parseColorFromString(style['textColor'].toString());

    return ExpansionTile(
      title: Text(
        displayName,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '背景: ${_colorToHex(backgroundColor)} | 透明度: ${(opacity * 100).toInt()}% | 文字: ${_colorToHex(textColor)}',
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12.sp,
        ),
      ),
      leading: Container(
        width: 24.w,
        height: 24.h,
        decoration: BoxDecoration(
          color: backgroundColor.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(
            color: backgroundColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'T',
            style: TextStyle(
              color: textColor,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            children: [
              // 背景颜色设置
              _buildColorPickerItem(
                title: '背景颜色',
                subtitle: '设置$displayName的背景颜色',
                color: backgroundColor,
                onTap: () {
                  _showColorPicker(backgroundColor, (color) {
                    final colorString = '0x${((color.a * 255).toInt() << 24 | (color.r * 255).toInt() << 16 | (color.g * 255).toInt() << 8 | (color.b * 255).toInt()).toRadixString(16).padLeft(8, '0')}';
                    debugPrint('[ColorPicker] 选择背景颜色: $color -> $colorString');
                    setState(() {
                      _customTagStyles[tagName] = {
                        ...style,
                        'backgroundColor': colorString,
                      };
                    });
                  });
                },
              ),
              // 透明度设置
              _buildSliderItem(
                title: '背景透明度',
                subtitle: '调整$displayName的背景透明度',
                value: opacity,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  setState(() {
                    _customTagStyles[tagName] = {
                      ...style,
                      'opacity': value,
                    };
                  });
                },
              ),
              // 文字颜色设置
              _buildColorPickerItem(
                title: '文字颜色',
                subtitle: '设置$displayName的文字颜色',
                color: textColor,
                onTap: () {
                  _showColorPicker(textColor, (color) {
                    final colorString = '0x${((color.a * 255).toInt() << 24 | (color.r * 255).toInt() << 16 | (color.g * 255).toInt() << 8 | (color.b * 255).toInt()).toRadixString(16).padLeft(8, '0')}';
                    debugPrint('[ColorPicker] 选择文字颜色: $color -> $colorString');
                    setState(() {
                      _customTagStyles[tagName] = {
                        ...style,
                        'textColor': colorString,
                      };
                    });
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 重置所有标签样式为默认值
  Future<void> _resetCustomTagStyles() async {
    // 显示确认对话框
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          title: Text(
            '重置标签样式',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: Text(
            '确定要将所有标签样式重置为默认的简洁配色吗？此操作不可撤销。',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                '取消',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              child: Text(
                '重置',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        // 清空自定义样式，使用默认值
        _customTagStyles.clear();
      });

      // 保存设置
      await _saveSettings();

      if (mounted) {
        CustomToast.show(
          context,
          message: '标签样式已重置为默认配色',
          type: ToastType.success,
        );
      }
    }
  }
}
