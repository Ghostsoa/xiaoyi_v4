import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
import 'dart:ui';
import '../../../theme/app_theme.dart';
import '../../../dao/chat_settings_dao.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../widgets/custom_toast.dart';

class FormatOption {
  bool isEnabled;
  bool isBold;
  bool isItalic;
  Color color;

  FormatOption({
    this.isEnabled = false,
    this.isBold = false,
    this.isItalic = false,
    this.color = Colors.black,
  });
}

class UiSettingsPage extends StatefulWidget {
  final VoidCallback? onSettingsChanged;
  final Uint8List? backgroundImage;
  final double backgroundOpacity;

  const UiSettingsPage({
    super.key,
    this.onSettingsChanged,
    this.backgroundImage,
    this.backgroundOpacity = 0.5,
  });

  @override
  State<UiSettingsPage> createState() => _UiSettingsPageState();
}

class _UiSettingsPageState extends State<UiSettingsPage> {
  final ChatSettingsDao _settingsDao = ChatSettingsDao();
  String _selectedMode = 'old';
  bool _isSaving = false;

  // 格式化选项
  final Map<String, FormatOption> _formatOptions = {
    'parentheses': FormatOption(), // ()格式化
    'brackets': FormatOption(), // []格式化
    'quotes': FormatOption(), // ""格式化
  };
  bool _codeBlockFormat = false; // ```格式化

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // 加载UI模式
    final mode = await _settingsDao.getUiMode();
    // 加载格式化选项
    final formatOptions = await _settingsDao.getFormatOptions();
    // 加载代码块格式
    final codeBlockFormat = await _settingsDao.getCodeBlockFormat();

    if (mounted) {
      setState(() {
        _selectedMode = mode;
        _codeBlockFormat = codeBlockFormat;

        // 恢复格式化选项
        formatOptions.forEach((key, value) {
          if (_formatOptions.containsKey(key)) {
            _formatOptions[key]!.isEnabled = value['isEnabled'] ?? false;
            _formatOptions[key]!.isBold = value['isBold'] ?? false;
            _formatOptions[key]!.isItalic = value['isItalic'] ?? false;
            _formatOptions[key]!.color =
                Color(value['color'] ?? Colors.black.value);
          }
        });
      });
    }
  }

  Future<void> _saveSettings(String mode) async {
    setState(() => _isSaving = true);

    try {
      // 保存UI模式
      await _settingsDao.saveUiMode(mode);

      setState(() {
        _selectedMode = mode;
      });

      // 通知设置变更
      widget.onSettingsChanged?.call();

      CustomToast.show(
        context,
        message: '设置已保存',
        type: ToastType.success,
      );
    } catch (e) {
      CustomToast.show(
        context,
        message: '保存失败: $e',
        type: ToastType.error,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // 保存格式化选项
  Future<void> _saveFormatOptions() async {
    setState(() => _isSaving = true);

    try {
      final options = _formatOptions.map((key, option) => MapEntry(key, {
            'isEnabled': option.isEnabled,
            'isBold': option.isBold,
            'isItalic': option.isItalic,
            'color': option.color.value,
          }));
      await _settingsDao.saveFormatOptions(options);

      // 通知设置变更
      widget.onSettingsChanged?.call();
    } catch (e) {
      CustomToast.show(
        context,
        message: '保存失败: $e',
        type: ToastType.error,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // 保存代码块格式
  Future<void> _saveCodeBlockFormat() async {
    setState(() => _isSaving = true);

    try {
      await _settingsDao.saveCodeBlockFormat(_codeBlockFormat);

      // 通知设置变更
      widget.onSettingsChanged?.call();
    } catch (e) {
      CustomToast.show(
        context,
        message: '保存失败: $e',
        type: ToastType.error,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showColorPicker(FormatOption option) {
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
              pickerColor: option.color,
              onColorChanged: (Color color) {
                setState(() => option.color = color);
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

  Widget _buildFormatOptionItem({
    required String title,
    required String key,
    required String example,
    bool isCodeBlock = false,
  }) {
    if (isCodeBlock) {
      return Container(
        margin: EdgeInsets.only(bottom: 8.h),
        child: Row(
          children: [
            Checkbox(
              value: _codeBlockFormat,
              onChanged: (value) {
                setState(() => _codeBlockFormat = value ?? false);
                _saveCodeBlockFormat(); // 自动保存
              },
              activeColor: AppTheme.primaryColor,
              checkColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                '$title $example',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 检查key是否存在
    if (!_formatOptions.containsKey(key)) {
      return const SizedBox(); // 如果key不存在，返回空组件
    }

    final option = _formatOptions[key]!;

    // 根据key获取对应的格式符号
    String formatSymbol = '';
    switch (key) {
      case 'parentheses':
        formatSymbol = '( )';
        break;
      case 'brackets':
        formatSymbol = '[ ]';
        break;
      case 'quotes':
        formatSymbol = '" "';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Checkbox(
            value: option.isEnabled,
            onChanged: (value) {
              setState(() {
                option.isEnabled = value ?? false;
              });
              _saveFormatOptions(); // 自动保存
            },
            activeColor: AppTheme.primaryColor,
            checkColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              option.isEnabled ? '$formatSymbol示例文本' : formatSymbol,
              style: TextStyle(
                color: option.isEnabled
                    ? option.color
                    : Colors.white.withOpacity(0.7),
                fontSize: 14.sp,
                fontWeight: option.isBold ? FontWeight.bold : FontWeight.normal,
                fontStyle:
                    option.isItalic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          if (option.isEnabled) ...[
            // 加粗按钮
            IconButton(
              onPressed: () {
                setState(() {
                  option.isBold = !option.isBold;
                });
                _saveFormatOptions(); // 自动保存
              },
              icon: Icon(
                Icons.format_bold,
                color: option.isBold
                    ? AppTheme.primaryColor
                    : Colors.white.withOpacity(0.7),
                size: 20.sp,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: 32.w,
                minHeight: 32.w,
              ),
            ),
            // 斜体按钮
            IconButton(
              onPressed: () {
                setState(() {
                  option.isItalic = !option.isItalic;
                });
                _saveFormatOptions(); // 自动保存
              },
              icon: Icon(
                Icons.format_italic,
                color: option.isItalic
                    ? AppTheme.primaryColor
                    : Colors.white.withOpacity(0.7),
                size: 20.sp,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: 32.w,
                minHeight: 32.w,
              ),
            ),
            // 颜色选择
            GestureDetector(
              onTap: () {
                _showColorPicker(option);
                _saveFormatOptions(); // 自动保存
              },
              child: Container(
                width: 28.w,
                height: 28.w,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  color: option.color,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomOptions() {
    if (_selectedMode != 'custom') return const SizedBox();

    return Container(
      margin: EdgeInsets.only(top: 16.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            // 背景模糊层
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(color: Colors.transparent),
              ),
            ),
            // 内容层
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.withOpacity(0.15),
                    Colors.purple.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_paint,
                        color: Colors.purple,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '格式化选项',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildFormatOptionItem(
                    title: '小括号格式化',
                    key: 'parentheses',
                    example: '(示例文本)',
                  ),
                  _buildFormatOptionItem(
                    title: '中括号格式化',
                    key: 'brackets',
                    example: '[示例文本]',
                  ),
                  _buildFormatOptionItem(
                    title: '引号格式化',
                    key: 'quotes',
                    example: '"示例文本"',
                  ),
                  _buildFormatOptionItem(
                    title: '代码块格式化',
                    key: 'codeBlock',
                    example: '```示例文本```',
                    isCodeBlock: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String mode,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    String? characterCardValue,
  }) {
    final bool isSelected = _selectedMode == mode;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            // 背景模糊层
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(color: Colors.transparent),
              ),
            ),
            // 内容层
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _saveSettings(mode),
                splashColor: color.withOpacity(0.1),
                highlightColor: color.withOpacity(0.05),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isSelected
                            ? color.withOpacity(0.2)
                            : Colors.white.withOpacity(0.1),
                        isSelected
                            ? color.withOpacity(0.1)
                            : Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected
                          ? color.withOpacity(0.5)
                          : Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.8)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12.sp,
                              ),
                            ),
                            if (characterCardValue != null) ...[
                              SizedBox(height: 4.h),
                              Text(
                                '角色卡设置: $characterCardValue',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Radio(
                        value: mode,
                        groupValue: _selectedMode,
                        onChanged: (value) => _saveSettings(value as String),
                        activeColor: color,
                        fillColor:
                            MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.selected)) {
                            return color;
                          }
                          return Colors.white.withOpacity(0.7);
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
                            '消息渲染设置',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          // 占位，保持对称
                          SizedBox(width: 36.w),
                        ],
                      ),
                    ),

                    // 设置列表
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        children: [
                          // 提示信息
                          Container(
                            margin: EdgeInsets.only(bottom: 24.h),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Stack(
                                children: [
                                  // 背景模糊层
                                  Positioned.fill(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 8.0, sigmaY: 8.0),
                                      child:
                                          Container(color: Colors.transparent),
                                    ),
                                  ),
                                  // 内容层
                                  Container(
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.amber.withOpacity(0.15),
                                          Colors.amber.withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: Colors.amber.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.amber,
                                          size: 20.sp,
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Text(
                                            '注意：当角色卡指定UI类型时，指定的UI类型将优先于此处设置',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.sp,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 模式选择卡片
                          _buildModeCard(
                            mode: 'none',
                            title: '不启用',
                            description: '不使用任何格式化，纯文本显示',
                            icon: Icons.format_clear,
                            color: Colors.grey,
                            characterCardValue: 'disabled',
                          ),
                          _buildModeCard(
                            mode: 'old',
                            title: '新版UI样式',
                            description: '使用新版的UI样式，支持状态栏显示',
                            icon: Icons.restore,
                            color: Colors.blue,
                            characterCardValue: 'legacy_bar',
                          ),
                          _buildModeCard(
                            mode: 'markdown',
                            title: 'Markdown格式',
                            description: '支持Markdown格式的消息显示，适合复杂内容',
                            icon: Icons.text_format,
                            color: Colors.green,
                            characterCardValue: 'markdown',
                          ),
                          _buildModeCard(
                            mode: 'custom',
                            title: '自定义',
                            description: '自定义UI显示样式，可设置特殊文本格式',
                            icon: Icons.palette,
                            color: Colors.purple,
                          ),

                          // 自定义选项
                          _buildCustomOptions(),

                          // 底部间距
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 加载指示器
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '保存中...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
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
}
