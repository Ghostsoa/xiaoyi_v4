import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_theme.dart';
import 'formatters/base_formatter.dart';
import 'formatters/status_formatter.dart';
import 'formatters/markdown_formatter.dart';
import 'formatters/custom_formatter.dart';

class ChatBubble extends StatefulWidget {
  final String message;
  final bool isUser;
  final bool isLoading;
  final bool isError;
  final String? status;
  final Color bubbleColor;
  final double bubbleOpacity;
  final Color textColor;
  final String? msgId;
  final Function(String msgId, String newContent)? onEdit;
  final String formatMode;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.isLoading = false,
    this.isError = false,
    this.status,
    required this.bubbleColor,
    required this.bubbleOpacity,
    required this.textColor,
    this.msgId,
    this.onEdit,
    this.formatMode = 'none',
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _isEditing = false;
  late TextEditingController _editController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message);
  }

  @override
  void dispose() {
    _editController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (widget.msgId == null || widget.onEdit == null) return;
    setState(() {
      _isEditing = true;
      _editController.text = widget.message;
    });
    _focusNode.requestFocus();
  }

  void _finishEditing() {
    if (_isEditing) {
      final newContent = _editController.text.trim();
      if (newContent.isNotEmpty && newContent != widget.message) {
        widget.onEdit!(widget.msgId!, newContent);
      }
      setState(() => _isEditing = false);
    }
  }

  Widget _buildStatusText() {
    if (widget.isLoading || (widget.status != null && !widget.isUser)) {
      final text = widget.isLoading
          ? '正在思考...'
          : widget.status == 'error'
              ? '发送失败'
              : widget.status == 'streaming'
                  ? '正在生成...'
                  : widget.status == 'done'
                      ? '生成完成'
                      : '';

      if (widget.isLoading || widget.status == 'streaming') {
        return Shimmer.fromColors(
          baseColor: widget.textColor.withOpacity(0.5),
          highlightColor: Colors.white,
          period: const Duration(milliseconds: 1200),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4.w,
                height: 4.w,
                decoration: BoxDecoration(
                  color: widget.textColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                text,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      } else {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4.w,
              height: 4.w,
              decoration: BoxDecoration(
                color: widget.status == 'done'
                    ? Colors.green
                    : widget.status == 'error'
                        ? Colors.red
                        : widget.textColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              text,
              style: TextStyle(
                color: widget.status == 'error'
                    ? AppTheme.error
                    : widget.status == 'done'
                        ? Colors.green
                        : widget.textColor.withOpacity(0.8),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildContent() {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: Colors.transparent,
            child: TextField(
              controller: _editController,
              focusNode: _focusNode,
              maxLines: null,
              style: TextStyle(
                color: widget.textColor,
                fontSize: 14.sp,
                height: 1.5,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
                hintText: '编辑消息...',
                hintStyle: TextStyle(
                  color: widget.textColor.withOpacity(0.5),
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _editController.text = widget.message;
                  });
                },
                style: TextButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '取消',
                  style: TextStyle(
                    color: widget.textColor.withOpacity(0.8),
                    fontSize: 14.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              TextButton(
                onPressed: _finishEditing,
                style: TextButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                ),
                child: Text(
                  '确定',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (widget.isError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              widget.message,
              style: TextStyle(
                color: Colors.red,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      );
    }

    final baseStyle = TextStyle(
      color: widget.textColor,
      fontSize: 14.sp,
      height: 1.5,
    );

    if (widget.message.isEmpty &&
        (widget.isLoading || widget.status == 'streaming')) {
      return const SizedBox.shrink();
    }

    if (widget.message.isEmpty) {
      return const SizedBox.shrink();
    }

    BaseFormatter formatter;
    switch (widget.formatMode) {
      case 'old':
        formatter = StatusFormatter();
        break;
      case 'markdown':
        formatter = MarkdownFormatter();
        break;
      case 'custom':
        formatter = CustomFormatter();
        break;
      default:
        if (widget.formatMode == 'none') {
          return Text(
            widget.message,
            style: baseStyle,
          );
        }
        formatter = StatusFormatter();
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: formatter.format(context, widget.message, baseStyle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 4.h,
      ),
      child: Align(
        alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onLongPress: widget.isLoading || widget.isError || widget.isUser
                ? null
                : () {
                    print('长按消息调试信息:');
                    print('- 消息ID: ${widget.msgId}');
                    print('- 是否用户消息: ${widget.isUser}');
                    print('- 是否加载中: ${widget.isLoading}');
                    print('- 是否错误: ${widget.isError}');
                    print('- 是否有编辑回调: ${widget.onEdit != null}');
                    _startEditing();
                  },
            borderRadius: BorderRadius.circular(12.r),
            child: Ink(
              decoration: BoxDecoration(
                color: widget.bubbleColor.withOpacity(
                  _isEditing
                      ? widget.bubbleOpacity * 0.8
                      : widget.bubbleOpacity,
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(12.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildContent(),
                    if (!widget.isUser &&
                        !_isEditing &&
                        (widget.isLoading || widget.status != null)) ...[
                      SizedBox(height: widget.message.isEmpty ? 0 : 6.h),
                      _buildStatusText(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
