import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import 'novel_action_button.dart';
import 'novel_small_icon_button.dart';
import 'novel_generating_indicator.dart';

class NovelAiInteractionArea extends StatefulWidget {
  final String currentChapterTitle;
  final bool isInitialMode;
  final bool isGenerating;
  final bool isRefreshing;
  final bool showRefreshSuccess;
  final Animation<double>? refreshRotationAnimation;
  final List<Map<String, dynamic>> novelBubbles;

  final Color backgroundColor;
  final Color textColor;

  final VoidCallback onSettings;
  final VoidCallback onRegenerate;
  final VoidCallback onRefreshPage;
  final VoidCallback onResetConversation;
  final VoidCallback onScrollToBottom;
  final VoidCallback onAutoContinue;
  final VoidCallback onTogglePromptInput;
  final VoidCallback onCancelPrompt;
  final Function(String) onSubmitPrompt;

  final bool showPromptInput;
  final TextEditingController promptController;

  const NovelAiInteractionArea({
    super.key,
    required this.currentChapterTitle,
    required this.isInitialMode,
    required this.isGenerating,
    required this.isRefreshing,
    required this.showRefreshSuccess,
    this.refreshRotationAnimation,
    required this.novelBubbles,
    required this.backgroundColor,
    required this.textColor,
    required this.onSettings,
    required this.onRegenerate,
    required this.onRefreshPage,
    required this.onResetConversation,
    required this.onScrollToBottom,
    required this.onAutoContinue,
    required this.onTogglePromptInput,
    required this.onCancelPrompt,
    required this.onSubmitPrompt,
    required this.showPromptInput,
    required this.promptController,
  });

  @override
  State<NovelAiInteractionArea> createState() => _NovelAiInteractionAreaState();
}

class _NovelAiInteractionAreaState extends State<NovelAiInteractionArea> {
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = widget.backgroundColor.computeLuminance() < 0.5;
    final Color textColor = widget.textColor;
    final Color fadedTextColor = textColor.withOpacity(0.7);
    final Color hintTextColor = textColor.withOpacity(0.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 章节标题显示
        Padding(
          padding: EdgeInsets.only(bottom: 4.h),
          child: Text(
            widget.currentChapterTitle,
            style: TextStyle(
              color: fadedTextColor,
              fontSize: 11.sp,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // 操作按钮行
        Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              NovelSmallIconButton(
                icon: Icons.settings_outlined,
                tooltip: '设置',
                onPressed: widget.isGenerating ? null : widget.onSettings,
                rotationAnimation: widget.refreshRotationAnimation,
                color: textColor,
              ),
              NovelSmallIconButton(
                icon: Icons.undo_outlined,
                tooltip: '撤回上一章',
                onPressed: (widget.isGenerating || widget.novelBubbles.isEmpty)
                    ? null
                    : widget.onRegenerate,
                rotationAnimation: widget.refreshRotationAnimation,
                color: textColor,
              ),
              NovelSmallIconButton(
                icon: widget.isRefreshing
                    ? Icons.sync
                    : widget.showRefreshSuccess
                        ? Icons.check_circle
                        : Icons.refresh_outlined,
                tooltip: '刷新列表',
                onPressed: (widget.isGenerating || widget.isRefreshing)
                    ? null
                    : widget.onRefreshPage,
                isRotating: widget.isRefreshing,
                color:
                    widget.showRefreshSuccess ? Colors.green : fadedTextColor,
                rotationAnimation: widget.refreshRotationAnimation,
              ),
              NovelSmallIconButton(
                icon: Icons.delete_sweep_outlined,
                tooltip: '重置对话',
                onPressed:
                    widget.isGenerating ? null : widget.onResetConversation,
                rotationAnimation: widget.refreshRotationAnimation,
                color: textColor,
              ),
              NovelSmallIconButton(
                icon: Icons.keyboard_arrow_down_outlined,
                tooltip: '回到底部',
                onPressed: widget.onScrollToBottom,
                rotationAnimation: widget.refreshRotationAnimation,
                color: textColor,
              ),
            ],
          ),
        ),

        // 分隔线 - 简化分隔线
        if (widget.novelBubbles.isNotEmpty && !widget.isGenerating)
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Divider(
              color: textColor.withOpacity(0.3),
              thickness: 0.5,
              height: 1,
            ),
          ),

        // 提示文本
        if (!widget.isGenerating) ...[
          if (widget.isInitialMode)
            Text(
              '开始您的小说创作之旅',
              style: TextStyle(
                color: fadedTextColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

          SizedBox(height: 4.h),

          // 根据状态显示不同的提示文本
          Text(
            widget.isInitialMode ? '与AI一起创作属于您的专属小说' : '让AI继续为您创作，或者引导下一章的发展方向',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: hintTextColor,
              fontSize: 12.sp,
            ),
          ),

          SizedBox(height: 8.h),

          // 按钮区域
          Row(
            children: [
              // 自动继续按钮
              Expanded(
                child: NovelActionButton(
                  text: '继续自动下一章',
                  icon: Icons.auto_stories,
                  onTap: widget.onAutoContinue,
                  textColor: textColor,
                ),
              ),
              SizedBox(width: 8.w),
              // 提供引导按钮
              Expanded(
                child: NovelActionButton(
                  text: '我有一个想法',
                  icon: Icons.lightbulb_outline,
                  onTap: widget.onTogglePromptInput,
                  textColor: textColor,
                ),
              ),
            ],
          ),
        ] else
          // 生成状态指示器
          NovelGeneratingIndicator(
            message: widget.currentChapterTitle.startsWith("正在") ||
                    widget.currentChapterTitle.startsWith("根据您")
                ? widget.currentChapterTitle
                : '创作灵感涌现中',
            textColor: textColor,
          ),

        // 输入引导内容区域
        if (widget.showPromptInput && !widget.isGenerating) ...[
          SizedBox(height: 8.h),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey[900]!.withOpacity(0.5)
                  : Colors.grey[300]!.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: textColor.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: TextField(
              controller: widget.promptController,
              maxLines: 2,
              style: TextStyle(
                color: textColor,
                fontSize: 13.sp,
              ),
              decoration: InputDecoration(
                hintText: '输入您对下一章节的想法或剧情走向...',
                hintStyle: TextStyle(
                  color: hintTextColor,
                  fontSize: 13.sp,
                ),
                contentPadding: EdgeInsets.all(8.w),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 取消按钮
              TextButton(
                onPressed: widget.onCancelPrompt,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '取消',
                  style: TextStyle(
                    color: hintTextColor,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              // 提交按钮
              ElevatedButton(
                onPressed: () =>
                    widget.onSubmitPrompt(widget.promptController.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.8),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                child: Text(
                  '提交引导',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],

        // 底部安全区域
        SizedBox(height: 4.h),
      ],
    );
  }
}
