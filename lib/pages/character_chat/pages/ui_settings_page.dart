import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
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
                  color: AppTheme.textPrimary,
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
                color: option.isEnabled ? option.color : AppTheme.textSecondary,
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
                    : AppTheme.textSecondary,
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
                    : AppTheme.textSecondary,
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
                    color: AppTheme.textSecondary.withOpacity(0.3),
                    width: 2,
                  ),
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.r),
        border:
            Border(left: BorderSide(color: AppTheme.primaryColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.format_paint,
                  color: AppTheme.primaryColor,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                '格式化选项',
                style: TextStyle(
                  color: AppTheme.textPrimary,
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
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18.sp,
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
                    color: AppTheme.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
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
            fillColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return color;
              }
              return AppTheme.textSecondary;
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 600 ? 600.0 : screenWidth;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SizedBox(
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
                              color: AppTheme.textPrimary,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ),

                      // 页面标题
                      Text(
                        '消息渲染设置',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    children: [
                      // 提示信息
                      Container(
                        margin: EdgeInsets.only(bottom: 24.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border(
                              left: BorderSide(
                                  color: AppTheme.warning, width: 3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.warning,
                              size: 20.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                '注意：当角色卡指定UI类型时，指定的UI类型将优先于此处设置',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ],
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
                        title: '兼容模式',
                        description: '兼容旧版格式，使用Markdown渲染器处理状态标签',
                        icon: Icons.restore,
                        color: AppTheme.primaryColor,
                        characterCardValue: 'legacy_bar',
                      ),
                      _buildModeCard(
                        mode: 'markdown',
                        title: 'Markdown格式',
                        description: '支持Markdown格式的消息显示，适合复杂内容',
                        icon: Icons.text_format,
                        color: AppTheme.success,
                        characterCardValue: 'markdown',
                      ),
                      _buildModeCard(
                        mode: 'custom',
                        title: '自定义',
                        description: '自定义UI显示样式，可设置特殊文本格式',
                        icon: Icons.palette,
                        color: AppTheme.accentPink,
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
      floatingActionButton: _isSaving
          ? Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.w,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
