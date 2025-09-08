import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../pages/novel_detail_page.dart';

class NovelSettingsSheet extends StatefulWidget {
  // 会话ID
  final String sessionId;

  // 字体尺寸设置
  final double contentFontSize;
  final double titleFontSize;
  final Function(double) onContentFontSizeChanged;
  final Function(double) onTitleFontSizeChanged;

  // 背景颜色设置
  final Color backgroundColor;
  final Function(Color) onBackgroundColorChanged;

  // 字体颜色设置
  final Color textColor;
  final Function(Color) onTextColorChanged;

  const NovelSettingsSheet({
    super.key,
    required this.sessionId,
    required this.contentFontSize,
    required this.titleFontSize,
    required this.onContentFontSizeChanged,
    required this.onTitleFontSizeChanged,
    required this.backgroundColor,
    required this.onBackgroundColorChanged,
    required this.textColor,
    required this.onTextColorChanged,
  });

  @override
  State<NovelSettingsSheet> createState() => _NovelSettingsSheetState();
}

class _NovelSettingsSheetState extends State<NovelSettingsSheet> {
  late double _contentFontSize;
  late double _titleFontSize;
  late Color _backgroundColor;
  late Color _textColor;

  // 预定义的背景颜色选项
  final List<Color> _backgroundColors = [
    const Color(0xFF121212), // 暗黑色
    const Color(0xFF1E1E1E), // 深灰色
    const Color(0xFF2D2D2D), // 中灰色
    const Color(0xFF323232), // 稍浅灰色
    const Color(0xFF222222), // 近黑色
    const Color(0xFF2B2118), // 咖啡黑
    const Color(0xFF20232A), // 夜空蓝黑
    const Color(0xFF0F2027), // 深海蓝黑
    const Color(0xFF292929), // 深灰色
    const Color(0xFF24222A), // 深蓝紫黑色
    const Color(0xFFEDE7D9), // 米色纸张
    const Color(0xFFF8F3E3), // 象牙白
    const Color(0xFFF5F5DC), // 米黄色
  ];

  // 预定义的文本颜色选项
  final List<Color> _textColors = [
    Colors.white,
    Colors.grey[200]!,
    Colors.grey[300]!,
    Colors.grey[400]!,
    Colors.amber[100]!,
    Colors.amber[50]!,
    const Color(0xFFCCCCBA), // 暖灰色
    const Color(0xFFD3D3D3), // 浅灰色
    const Color(0xFF93A8AC), // 灰蓝色
    Colors.black,
    Colors.grey[850]!,
    Colors.grey[800]!,
    Colors.grey[700]!,
  ];

  @override
  void initState() {
    super.initState();
    _contentFontSize = widget.contentFontSize;
    _titleFontSize = widget.titleFontSize;
    _backgroundColor = widget.backgroundColor;
    _textColor = widget.textColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHeader(context),
          SizedBox(height: 16.h),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFontSizeSettings(),
                  SizedBox(height: 24.h),
                  _buildBackgroundColorSettings(),
                  SizedBox(height: 24.h),
                  _buildTextColorSettings(),
                  SizedBox(height: 24.h),
                  _buildNovelConfigSettings(),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '小说设置',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildFontSizeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('字体大小'),
        SizedBox(height: 16.h),

        // 内容字体大小设置
        _buildFontSizeSetting(
          label: '内容字体',
          value: _contentFontSize,
          minValue: 12.0,
          maxValue: 22.0,
          onChanged: (value) {
            setState(() {
              _contentFontSize = value;
              widget.onContentFontSizeChanged(value);
            });
          },
          sampleText: '这是正文内容文字示例...',
        ),
        SizedBox(height: 16.h),

        // 标题字体大小设置
        _buildFontSizeSetting(
          label: '标题字体',
          value: _titleFontSize,
          minValue: 14.0,
          maxValue: 26.0,
          onChanged: (value) {
            setState(() {
              _titleFontSize = value;
              widget.onTitleFontSizeChanged(value);
            });
          },
          sampleText: '第一章 故事的开始',
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildFontSizeSetting({
    required String label,
    required double value,
    required double minValue,
    required double maxValue,
    required Function(double) onChanged,
    required String sampleText,
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: Colors.grey[700],
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.2),
            trackHeight: 4.h,
          ),
          child: Slider(
            value: value.clamp(minValue, maxValue),
            min: minValue,
            max: maxValue,
            divisions: ((maxValue - minValue) * 2).toInt(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey[800]!, width: 1),
          ),
          child: Text(
            sampleText,
            style: TextStyle(
              color: _textColor,
              fontSize: value.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundColorSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('背景颜色'),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: _backgroundColors.map((color) {
            final bool isSelected = _backgroundColor == color;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _backgroundColor = color;
                  widget.onBackgroundColorChanged(color);
                });
              },
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color:
                        isSelected ? AppTheme.primaryColor : Colors.grey[600]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: AppTheme.primaryColor,
                        size: 18.sp,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextColorSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('文字颜色'),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: _textColors.map((color) {
            final bool isSelected = _textColor == color;
            final bool isDarkText = color.computeLuminance() < 0.5;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _textColor = color;
                  widget.onTextColorChanged(color);
                });
              },
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (isDarkText ? Colors.grey[400]! : Colors.grey[700]!),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: isDarkText ? Colors.white : Colors.black,
                        size: 18.sp,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNovelConfigSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('小说配置'),
        SizedBox(height: 12.h),
        _buildSettingButton(
          icon: Icons.auto_stories,
          label: '小说详情设置',
          onTap: () {
            // 关闭当前设置面板
            Navigator.of(context).pop();

            // 打开小说详情页面
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => NovelDetailPage(
                  sessionId: widget.sessionId,
                  textColor: _textColor,
                  backgroundColor: _backgroundColor,
                ),
              ),
            );
          },
        ),
        SizedBox(height: 8.h),
        _buildSettingButton(
          icon: Icons.book_outlined,
          label: '封装成册',
          onTap: () {
            // 暂不实现功能
          },
        ),
      ],
    );
  }

  Widget _buildSettingButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white70,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
