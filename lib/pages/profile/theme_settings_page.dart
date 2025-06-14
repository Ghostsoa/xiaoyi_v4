import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_config.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/custom_toast.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  late ThemeConfig _themeConfig;
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadThemeConfig();
  }

  Future<void> _loadThemeConfig() async {
    try {
      final config = await ThemeConfig.load();
      setState(() {
        _themeConfig = config;
        _isLoading = false;
        _hasUnsavedChanges = false;
      });
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '加载主题配置失败',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    try {
      await _themeConfig.save();
      setState(() {
        _hasUnsavedChanges = false;
      });
      if (mounted) {
        CustomToast.show(
          context,
          message: '主题配置已保存',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '保存主题配置失败',
          type: ToastType.error,
        );
      }
    }
  }

  void _applyChanges() {
    _themeConfig.apply();
    ThemeController().updateSystemUI();
    setState(() {});
    if (mounted) {
      CustomToast.show(
        context,
        message: '主题已更新',
        type: ToastType.success,
      );
    }
  }

  // 应用预设主题
  void _applyPresetTheme(String themeName) {
    _themeConfig.applyPresetTheme(themeName);
    setState(() {
      _hasUnsavedChanges = true;
    });
    _applyChanges();
  }

  void _showColorPicker(String colorKey) {
    final currentColor = _themeConfig.getColor(colorKey);
    Color pickedColor = currentColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            '选择${ThemeConfig.getColorName(colorKey)}',
            style: AppTheme.titleStyle,
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (color) {
                pickedColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              labelTypes: const [],
              pickerAreaBorderRadius:
                  BorderRadius.circular(AppTheme.radiusMedium),
              hexInputBar: true,
              portraitOnly: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '取消',
                style: AppTheme.buttonTextStyle.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _themeConfig.updateColor(colorKey, pickedColor);
                setState(() {
                  _hasUnsavedChanges = true;
                });
                Navigator.of(context).pop();
              },
              child: Text(
                '确定',
                style: AppTheme.buttonTextStyle.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showGradientPicker(String gradientKey) {
    final currentGradient = _themeConfig.getGradient(gradientKey);
    List<Color> pickedColors = List.from(currentGradient);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              title: Text(
                '编辑${ThemeConfig.getGradientName(gradientKey)}',
                style: AppTheme.titleStyle,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 60.h,
                      margin: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: pickedColors,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    ...List.generate(pickedColors.length, (index) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                '颜色 ${index + 1}',
                                style: AppTheme.bodyStyle,
                              ),
                              Spacer(),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.error,
                                  size: 20.sp,
                                ),
                                onPressed: pickedColors.length <= 2
                                    ? null
                                    : () {
                                        setState(() {
                                          pickedColors.removeAt(index);
                                        });
                                      },
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  Color selectedColor = pickedColors[index];
                                  return AlertDialog(
                                    backgroundColor: AppTheme.cardBackground,
                                    title: Text(
                                      '选择颜色 ${index + 1}',
                                      style: AppTheme.titleStyle,
                                    ),
                                    content: SingleChildScrollView(
                                      child: ColorPicker(
                                        pickerColor: selectedColor,
                                        onColorChanged: (color) {
                                          selectedColor = color;
                                        },
                                        pickerAreaHeightPercent: 0.8,
                                        enableAlpha: false,
                                        displayThumbColor: true,
                                        paletteType: PaletteType.hsvWithHue,
                                        labelTypes: const [],
                                        pickerAreaBorderRadius:
                                            BorderRadius.circular(
                                                AppTheme.radiusMedium),
                                        hexInputBar: true,
                                        portraitOnly: true,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: Text(
                                          '取消',
                                          style:
                                              AppTheme.buttonTextStyle.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            pickedColors[index] = selectedColor;
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          '确定',
                                          style:
                                              AppTheme.buttonTextStyle.copyWith(
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              height: 40.h,
                              decoration: BoxDecoration(
                                color: pickedColors[index],
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSmall),
                                border: Border.all(
                                  color: AppTheme.border.withOpacity(0.1),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                        ],
                      );
                    }),
                    if (pickedColors.length < 5)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            pickedColors.add(Colors.white);
                          });
                        },
                        icon: Icon(
                          Icons.add_circle_outline,
                          size: 20.sp,
                          color: AppTheme.primaryColor,
                        ),
                        label: Text(
                          '添加颜色',
                          style: AppTheme.buttonTextStyle.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    '取消',
                    style: AppTheme.buttonTextStyle.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _themeConfig.updateGradient(gradientKey, pickedColors);
                    setState(() {
                      _hasUnsavedChanges = true;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    '确定',
                    style: AppTheme.buttonTextStyle.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _resetToDefault() async {
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            title: Text(
              '重置主题',
              style: AppTheme.titleStyle,
            ),
            content: Text(
              '确定要将主题恢复为默认设置吗？',
              style: AppTheme.bodyStyle,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  '取消',
                  style: AppTheme.buttonTextStyle.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  '确定',
                  style: AppTheme.buttonTextStyle.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      setState(() {
        _themeConfig.resetToDefault();
        _hasUnsavedChanges = true;
      });
    }
  }

  // 构建预设主题项
  Widget _buildThemePresetItem(String themeName, String displayName) {
    Map<String, Color> colors;
    List<Color> buttonGradient;
    bool isLightTheme = themeName == 'light';

    // 获取对应的预设颜色
    switch (themeName) {
      case 'pink':
        colors = ThemeConfig.pinkGradientColors;
        buttonGradient = ThemeConfig.pinkGradientGradients['button']!;
        break;
      case 'blue':
        colors = ThemeConfig.blueGradientColors;
        buttonGradient = ThemeConfig.blueGradientGradients['button']!;
        break;
      case 'lime':
        colors = ThemeConfig.limeGradientColors;
        buttonGradient = ThemeConfig.limeGradientGradients['button']!;
        break;
      case 'orange':
        colors = ThemeConfig.orangeGradientColors;
        buttonGradient = ThemeConfig.orangeGradientGradients['button']!;
        break;
      case 'light':
        colors = ThemeConfig.lightThemeColors;
        buttonGradient = ThemeConfig.lightThemeGradients['button']!;
        break;
      case 'default':
      default:
        colors = ThemeConfig.defaultColors;
        buttonGradient = ThemeConfig.defaultGradients['button']!;
        break;
    }

    return GestureDetector(
      onTap: () => _applyPresetTheme(themeName),
      child: Container(
        margin: EdgeInsets.only(right: 12.w),
        width: 80.w,
        child: Column(
          children: [
            Container(
              height: 80.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: buttonGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: buttonGradient.first.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isLightTheme
                  ? Center(
                      child: Icon(
                        Icons.light_mode,
                        color: Colors.white,
                        size: 30.sp,
                      ),
                    )
                  : null,
            ),
            SizedBox(height: 8.h),
            Text(
              displayName,
              style: isLightTheme
                  ? AppTheme.secondaryStyle.copyWith(
                      color: AppTheme.primaryLight, fontWeight: FontWeight.w600)
                  : AppTheme.secondaryStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorItem(String colorKey) {
    final color = _themeConfig.getColor(colorKey);
    return InkWell(
      onTap: () => _showColorPicker(colorKey),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: AppTheme.border.withOpacity(0.1),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                ThemeConfig.getColorName(colorKey),
                style: AppTheme.bodyStyle,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientItem(String gradientKey) {
    final gradient = _themeConfig.getGradient(gradientKey);
    return InkWell(
      onTap: () => _showGradientPicker(gradientKey),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ThemeConfig.getGradientName(gradientKey),
                    style: AppTheme.bodyStyle,
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    height: 24.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: AppTheme.border.withOpacity(0.1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: Text(
          '主题设置',
          style: AppTheme.titleStyle,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textPrimary,
            size: 20.sp,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: Text(
              '保存',
              style: AppTheme.buttonTextStyle.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          TextButton(
            onPressed: _resetToDefault,
            child: Text(
              '重置',
              style: AppTheme.buttonTextStyle.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 预设主题选择区域
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: AppTheme.border.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '预设主题',
                              style: AppTheme.titleStyle,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              '点击下方预设快速应用主题',
                              style: AppTheme.secondaryStyle,
                            ),
                            SizedBox(height: 16.h),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildThemePresetItem('default',
                                      ThemeConfig.themeNames['default']!),
                                  _buildThemePresetItem(
                                      'pink', ThemeConfig.themeNames['pink']!),
                                  _buildThemePresetItem(
                                      'blue', ThemeConfig.themeNames['blue']!),
                                  _buildThemePresetItem(
                                      'lime', ThemeConfig.themeNames['lime']!),
                                  _buildThemePresetItem('orange',
                                      ThemeConfig.themeNames['orange']!),
                                  _buildThemePresetItem('light',
                                      ThemeConfig.themeNames['light']!),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: AppTheme.border.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '主色系',
                              style: AppTheme.titleStyle,
                            ),
                            SizedBox(height: 16.h),
                            _buildColorItem('primary'),
                            Divider(
                              color: AppTheme.border.withOpacity(0.1),
                              height: 1.h,
                            ),
                            _buildColorItem('primaryLight'),
                            Divider(
                              color: AppTheme.border.withOpacity(0.1),
                              height: 1.h,
                            ),
                            _buildColorItem('primaryDark'),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: AppTheme.border.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '基础渐变',
                              style: AppTheme.titleStyle,
                            ),
                            SizedBox(height: 16.h),
                            _buildGradientItem('primary'),
                            Divider(
                              color: AppTheme.border.withOpacity(0.1),
                              height: 1.h,
                            ),
                            _buildGradientItem('accent'),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: AppTheme.border.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '界面渐变',
                              style: AppTheme.titleStyle,
                            ),
                            SizedBox(height: 16.h),
                            _buildGradientItem('button'),
                            Divider(
                              color: AppTheme.border.withOpacity(0.1),
                              height: 1.h,
                            ),
                            _buildGradientItem('text'),
                            Divider(
                              color: AppTheme.border.withOpacity(0.1),
                              height: 1.h,
                            ),
                            _buildGradientItem('border'),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: AppTheme.border.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '状态渐变',
                              style: AppTheme.titleStyle,
                            ),
                            SizedBox(height: 16.h),
                            _buildGradientItem('success'),
                            Divider(
                              color: AppTheme.border.withOpacity(0.1),
                              height: 1.h,
                            ),
                            _buildGradientItem('warning'),
                            Divider(
                              color: AppTheme.border.withOpacity(0.1),
                              height: 1.h,
                            ),
                            _buildGradientItem('error'),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: AppTheme.border.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '主题说明',
                              style: AppTheme.titleStyle,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              '• 可以使用预设主题快速切换颜色方案\n'
                              '• 点击渐变条可以编辑对应的渐变颜色\n'
                              '• 每个渐变支持2-5个颜色节点\n'
                              '• 基础渐变：用于主要和强调色\n'
                              '• 界面渐变：用于按钮、文本和边框等界面元素\n'
                              '• 状态渐变：用于成功、警告、错误等状态\n'
                              '• 修改后点击预览查看效果\n'
                              '• 确认后点击保存应用设置',
                              style: AppTheme.secondaryStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasUnsavedChanges)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '预览仅显示部分效果，完整效果需要重启应用',
                            style: AppTheme.secondaryStyle,
                          ),
                          SizedBox(height: 12.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _applyChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                              ),
                              child: Text('预览效果'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
