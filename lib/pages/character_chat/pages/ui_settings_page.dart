import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../dao/chat_settings_dao.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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

  const UiSettingsPage({
    super.key,
    this.onSettingsChanged,
  });

  @override
  State<UiSettingsPage> createState() => _UiSettingsPageState();
}

class _UiSettingsPageState extends State<UiSettingsPage> {
  final ChatSettingsDao _settingsDao = ChatSettingsDao();
  String _selectedMode = 'old';

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
    // 保存UI模式
    await _settingsDao.saveUiMode(mode);

    setState(() {
      _selectedMode = mode;
    });

    // 通知设置变更
    widget.onSettingsChanged?.call();
  }

  // 保存格式化选项
  Future<void> _saveFormatOptions() async {
    final options = _formatOptions.map((key, option) => MapEntry(key, {
          'isEnabled': option.isEnabled,
          'isBold': option.isBold,
          'isItalic': option.isItalic,
          'color': option.color.value,
        }));
    await _settingsDao.saveFormatOptions(options);

    // 通知设置变更
    widget.onSettingsChanged?.call();
  }

  // 保存代码块格式
  Future<void> _saveCodeBlockFormat() async {
    await _settingsDao.saveCodeBlockFormat(_codeBlockFormat);

    // 通知设置变更
    widget.onSettingsChanged?.call();
  }

  void _showColorPicker(FormatOption option) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '选择颜色',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16.sp,
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
              showLabel: true,
              paletteType: PaletteType.hsv,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '确定',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14.sp,
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
      return CheckboxListTile(
        title: Text(
          '$title $example',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14.sp,
          ),
        ),
        value: _codeBlockFormat,
        onChanged: (value) {
          setState(() => _codeBlockFormat = value ?? false);
          _saveCodeBlockFormat(); // 自动保存
        },
        activeColor: AppTheme.primaryColor,
        contentPadding: EdgeInsets.zero,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
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
                color: option.isBold ? AppTheme.primaryColor : Colors.grey,
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
                color: option.isItalic ? AppTheme.primaryColor : Colors.grey,
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
                width: 24.w,
                height: 24.w,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  color: option.color,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
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
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '格式化选项',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),
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
    String? characterCardValue,
  }) {
    final bool isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: () => _saveSettings(mode),
      child: Container(
        margin: EdgeInsets.only(bottom: mode == 'custom' ? 0 : 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
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
                        color: Colors.green,
                        fontSize: 10.sp,
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
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.background,
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
                Container(
                  height: 56.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(18.r),
                          child: Container(
                            width: 36.w,
                            height: 36.w,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: AppTheme.textPrimary,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'UI设置',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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
          // 内容区域
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '注意：当角色卡指定UI类型时，指定的UI类型将优先于此处设置',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildModeCard(
                  mode: 'none',
                  title: '不启用',
                  description: '不使用任何格式化',
                  icon: Icons.format_clear,
                  characterCardValue: 'disabled',
                ),
                _buildModeCard(
                  mode: 'old',
                  title: '旧版状态栏',
                  description: '使用经典的状态栏样式',
                  icon: Icons.restore,
                  characterCardValue: 'legacy_bar',
                ),
                _buildModeCard(
                  mode: 'markdown',
                  title: 'Markdown格式',
                  description: '支持Markdown格式的消息显示',
                  icon: Icons.text_format,
                  characterCardValue: 'markdown',
                ),
                _buildModeCard(
                  mode: 'custom',
                  title: '自定义',
                  description: '自定义UI显示样式',
                  icon: Icons.palette,
                ),
                _buildCustomOptions(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
