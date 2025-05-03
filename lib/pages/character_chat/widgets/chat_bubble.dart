import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_theme.dart';

class ChatBubble extends StatefulWidget {
  final String message;
  final bool isUser;
  final bool isLoading;
  final bool isError;
  final String? status;
  final Color bubbleColor;
  final double bubbleOpacity;
  final Color textColor;
  final bool enableMarkdown;
  final int? messageId;
  final Function(int messageId, String newContent)? onEdit;

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
    this.enableMarkdown = true,
    this.messageId,
    this.onEdit,
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
    if (widget.messageId == null || widget.onEdit == null) return;
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
        widget.onEdit!(widget.messageId!, newContent);
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
          baseColor: widget.textColor.withOpacity(0.7),
          highlightColor: widget.textColor,
          child: Text(
            text,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      } else {
        return Text(
          text,
          style: TextStyle(
            color: widget.status == 'error'
                ? AppTheme.error
                : widget.textColor.withOpacity(0.8),
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
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

    if (widget.enableMarkdown) {
      return MarkdownBody(
        data: widget.message,
        selectable: false,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: widget.textColor,
            fontSize: 16.sp,
            height: 1.5,
          ),
          code: TextStyle(
            color: widget.textColor,
            fontSize: 16.sp,
            fontFamily: 'monospace',
            backgroundColor: Colors.black.withOpacity(0.1),
          ),
          codeblockDecoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4.r),
          ),
          blockquote: TextStyle(
            color: widget.textColor.withOpacity(0.8),
            fontSize: 16.sp,
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: widget.textColor.withOpacity(0.5),
                width: 4.w,
              ),
            ),
          ),
          h1: TextStyle(
            color: widget.textColor,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
          h2: TextStyle(
            color: widget.textColor,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
          h3: TextStyle(
            color: widget.textColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
          h4: TextStyle(
            color: widget.textColor,
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
          ),
          h5: TextStyle(
            color: widget.textColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
          h6: TextStyle(
            color: widget.textColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
          listBullet: TextStyle(
            color: widget.textColor,
            fontSize: 16.sp,
          ),
          tableBody: TextStyle(
            color: widget.textColor,
            fontSize: 16.sp,
          ),
          tableHead: TextStyle(
            color: widget.textColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
          tableHeadAlign: TextAlign.center,
          tableBorder: TableBorder.all(
            color: widget.textColor.withOpacity(0.3),
            width: 1,
          ),
          tableCellsPadding: EdgeInsets.all(8.w),
          a: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 16.sp,
            decoration: TextDecoration.underline,
          ),
        ),
        onTapLink: (text, href, title) async {
          if (href != null) {
            final url = Uri.parse(href);
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          }
        },
      );
    }

    return Text(
      widget.message,
      style: TextStyle(
        color: widget.textColor,
        fontSize: 14.sp,
        height: 1.5,
      ),
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
                : _startEditing,
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
                    if (!widget.isUser && !_isEditing) ...[
                      SizedBox(height: 6.h),
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
