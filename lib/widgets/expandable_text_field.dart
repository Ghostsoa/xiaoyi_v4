import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import 'text_editor_page.dart';

class ExpandableTextField extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final String hintText;
  final TextSelectType? selectType;
  final int? maxLength;
  final int previewLines;
  final Widget? helpIcon;
  final Widget? description;
  final Widget? extraButton;
  final VoidCallback? onChanged;

  const ExpandableTextField({
    super.key,
    required this.title,
    required this.controller,
    required this.hintText,
    this.selectType,
    this.maxLength,
    this.previewLines = 3,
    this.helpIcon,
    this.description,
    this.extraButton,
    this.onChanged,
  });

  @override
  State<ExpandableTextField> createState() => _ExpandableTextFieldState();
}

class _ExpandableTextFieldState extends State<ExpandableTextField> {

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Row(
          children: [
            Text(widget.title, style: AppTheme.secondaryStyle),
            if (widget.helpIcon != null) ...[
              SizedBox(width: 4.w),
              widget.helpIcon!,
            ],
            const Spacer(),
            if (widget.extraButton != null) widget.extraButton!,
          ],
        ),

        // 描述信息
        if (widget.description != null) ...[
          SizedBox(height: 4.h),
          widget.description!,
        ],

        SizedBox(height: 8.h),

        // 可展开的文本框 - 移除边框，使用更简洁的设计
        GestureDetector(
          onTap: () => _openTextEditor(context),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: 80.h,
            ),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              // 移除边框，使用阴影效果
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowColor.withOpacity(0.05),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 文本预览
                if (widget.controller.text.isNotEmpty)
                  Text(
                    _getPreviewText(),
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15.sp,
                      height: 1.5,
                    ),
                    maxLines: widget.previewLines,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    widget.hintText,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.6),
                      fontSize: 15.sp,
                      height: 1.5,
                    ),
                  ),

                SizedBox(height: 12.h),

                // 底部信息栏
                Row(
                  children: [
                    // 字数统计
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${widget.controller.text.length}${widget.maxLength != null ? '/${widget.maxLength}' : ''} 字',
                        style: TextStyle(
                          color: widget.maxLength != null && widget.controller.text.length > widget.maxLength!
                              ? Colors.red
                              : AppTheme.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 编辑提示
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 14.sp,
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '点击编辑',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getPreviewText() {
    final text = widget.controller.text;
    if (text.isEmpty) return '';

    // 计算预览行数对应的字符数
    final lines = text.split('\n');
    if (lines.length <= widget.previewLines) {
      return text;
    }

    // 取前几行
    final previewText = lines.take(widget.previewLines).join('\n');
    return previewText;
  }

  Future<void> _openTextEditor(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => TextEditorPage(
          title: widget.title,
          initialText: widget.controller.text,
          hintText: widget.hintText,
          selectType: widget.selectType,
          maxLength: widget.maxLength,
        ),
      ),
    );

    if (result != null && result != widget.controller.text) {
      setState(() {
        widget.controller.text = result;
      });
      // 触发回调通知父组件更新
      if (widget.onChanged != null) {
        widget.onChanged!();
      }
    }
  }
}
