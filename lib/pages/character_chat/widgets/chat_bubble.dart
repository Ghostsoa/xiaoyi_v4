import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../theme/app_theme.dart';
import 'formatters/base_formatter.dart';
import 'formatters/status_formatter.dart';
import 'formatters/markdown_formatter.dart';
import 'formatters/custom_formatter.dart';
import 'status_bar.dart';
import 'package:flutter/services.dart';
import '../../../widgets/custom_toast.dart';
import '../services/character_service.dart';

class ChatBubble extends StatefulWidget {
  final String message;
  final bool isUser;
  final bool isLoading;
  final String? status;
  final Color bubbleColor;
  final double bubbleOpacity;
  final Color textColor;
  final String? msgId;
  final Function(String msgId, String newContent)? onEdit;
  final String formatMode;
  final Map<String, dynamic>? statusBar;
  final bool? enhance;
  final double fontSize;
  final int? sessionId;
  final Function()? onMessageDeleted;
  final Function()? onMessageRevoked;
  final Function(String msgId)? onMessageRegenerate;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.isLoading = false,
    this.status,
    required this.bubbleColor,
    required this.bubbleOpacity,
    required this.textColor,
    this.msgId,
    this.onEdit,
    this.formatMode = 'none',
    this.statusBar,
    this.enhance,
    this.fontSize = 14.0,
    this.sessionId,
    this.onMessageDeleted,
    this.onMessageRevoked,
    this.onMessageRegenerate,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with TickerProviderStateMixin {
  bool _isEditing = false;
  bool _isButtonsExpanded = false;
  bool _isProcessing = false;
  late TextEditingController _editController;
  final FocusNode _focusNode = FocusNode();
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonAnimation;
  final CharacterService _characterService = CharacterService();

  // 添加炫彩动画控制器
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message);

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _buttonAnimation = CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    );

    // 初始化炫彩动画控制器，使用更长的动画周期以产生更平滑的效果
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _editController.dispose();
    _focusNode.dispose();
    _buttonAnimationController.dispose();
    _shimmerController.dispose(); // 释放炫彩动画控制器
    super.dispose();
  }

  void _startEditing() {
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
        if (widget.msgId != null && widget.onEdit != null) {
          widget.onEdit!(widget.msgId!, newContent);
        }
      }
      setState(() => _isEditing = false);
    }
  }

  void _toggleButtons() {
    setState(() {
      _isButtonsExpanded = !_isButtonsExpanded;
    });

    if (_isButtonsExpanded) {
      _buttonAnimationController.forward();
    } else {
      _buttonAnimationController.reverse();
    }
  }

  Future<void> _deleteMessage() async {
    if (widget.msgId == null || widget.sessionId == null || _isProcessing)
      return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await _characterService.deleteMessage(
        widget.sessionId!,
        widget.msgId!,
      );

      if (widget.onMessageDeleted != null) {
        widget.onMessageDeleted!();
      }

      if (mounted) {
        CustomToast.show(
          context,
          message: '消息已删除',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: e.toString(),
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _revokeMessage() async {
    debugPrint(
        '尝试撤销消息: msgId=${widget.msgId}, sessionId=${widget.sessionId}, isProcessing=${_isProcessing}');

    if (widget.msgId == null || widget.sessionId == null || _isProcessing) {
      debugPrint(
          '无法撤销消息: ${widget.msgId == null ? "消息ID为空" : widget.sessionId == null ? "会话ID为空" : "正在处理中"}');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认撤销'),
        content: const Text('确定要撤销此消息及其后的所有消息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('撤销', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      debugPrint(
          '开始调用撤销API: sessionId=${widget.sessionId}, msgId=${widget.msgId}');
      await _characterService.revokeMessageAndAfter(
        widget.sessionId!,
        widget.msgId!,
      );
      debugPrint('API调用成功');

      if (widget.onMessageRevoked != null) {
        widget.onMessageRevoked!();
        debugPrint('已触发onMessageRevoked回调');
      } else {
        debugPrint('警告: onMessageRevoked回调为空');
      }

      if (mounted) {
        CustomToast.show(
          context,
          message: '消息已撤销',
          type: ToastType.success,
        );
      }
    } catch (e) {
      debugPrint('撤销消息失败: $e');
      if (mounted) {
        CustomToast.show(
          context,
          message: e.toString(),
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _copyTextToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      CustomToast.show(
        context,
        message: '已复制到剪贴板',
        type: ToastType.success,
      );

      HapticFeedback.lightImpact();
    });
  }

  Widget _buildActionButton(
      IconData icon, VoidCallback? onTap, String tooltip, String label) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: widget.bubbleColor.withOpacity(widget.bubbleOpacity * 0.8),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14.sp,
                color: widget.textColor,
              ),
              SizedBox(width: 3.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.sp,
                  color: widget.textColor,
                ),
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildExpandButton() {
    return InkWell(
      onTap: _toggleButtons,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: widget.bubbleColor.withOpacity(widget.bubbleOpacity * 0.8),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isButtonsExpanded
                  ? (widget.isUser
                      ? Icons.keyboard_arrow_right
                      : Icons.keyboard_arrow_left)
                  : (widget.isUser
                      ? Icons.keyboard_arrow_left
                      : Icons.keyboard_arrow_right),
              size: 14.sp,
              color: widget.textColor,
            ),
            SizedBox(width: 3.w),
            Text(
              _isButtonsExpanded ? '收起' : '操作',
              style: TextStyle(
                fontSize: 9.sp,
                color: widget.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIButtonRow() {
    if (widget.isLoading || widget.status == 'streaming') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 4.h, left: 12.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildExpandButton(),
          ClipRect(
            child: SizeTransition(
              sizeFactor: _buttonAnimation,
              axis: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 4.w),
                  _buildActionButton(
                      Icons.refresh,
                      _isProcessing || widget.onMessageRegenerate == null
                          ? null
                          : () {
                              if (widget.msgId != null &&
                                  widget.onMessageRegenerate != null) {
                                widget.onMessageRegenerate!(widget.msgId!);
                              }
                            },
                      '重新生成',
                      '重新生成'),
                  SizedBox(width: 4.w),
                  _buildActionButton(Icons.delete_outline,
                      _isProcessing ? null : _deleteMessage, '删除', '删除'),
                  SizedBox(width: 4.w),
                  _buildActionButton(Icons.copy_outlined,
                      () => _copyTextToClipboard(widget.message), '复制内容', '复制'),
                  SizedBox(width: 4.w),
                  _buildActionButton(
                      Icons.edit_outlined, _startEditing, '编辑', '编辑'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserButtonRow() {
    return Padding(
      padding: EdgeInsets.only(top: 4.h, right: 12.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRect(
            child: SizeTransition(
              sizeFactor: _buttonAnimation,
              axis: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(Icons.undo,
                      _isProcessing ? null : _revokeMessage, '撤销', '撤销'),
                  SizedBox(width: 4.w),
                  _buildActionButton(Icons.delete_outline,
                      _isProcessing ? null : _deleteMessage, '删除', '删除'),
                  SizedBox(width: 4.w),
                  _buildActionButton(
                      Icons.edit_outlined, _startEditing, '编辑', '编辑'),
                  SizedBox(width: 4.w),
                  _buildActionButton(Icons.copy_outlined,
                      () => _copyTextToClipboard(widget.message), '复制内容', '复制'),
                  SizedBox(width: 4.w),
                ],
              ),
            ),
          ),
          _buildExpandButton(),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    if (widget.isLoading || (widget.status != null && !widget.isUser)) {
      final text =
          widget.isLoading || widget.status == 'streaming' ? '正在生成...' : '';

      if (widget.isLoading || widget.status == 'streaming') {
        // 恢复"正在生成..."的Shimmer流光效果
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
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildEnhanceTagContent() {
    if (widget.enhance == null || widget.isUser) {
      return const SizedBox.shrink();
    }

    if (widget.enhance!) {
      // 烫金效果 - 只有文字有Shimmer闪光
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          // 黑金渐变背景
          gradient: LinearGradient(
            colors: [
              Colors.black,
              Color(0xFF1A1A1A),
              Color(0xFF0D0D0D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(3.r),
          // 金色边框
          border: Border.all(
            color: Color(0xFFD4AF37), // 金色
            width: 0.5,
          ),
          // 轻微阴影增加立体感
          boxShadow: [
            BoxShadow(
              color: Color(0xFFD4AF37).withOpacity(0.2),
              blurRadius: 2,
              spreadRadius: 0,
            ),
          ],
        ),
        // 只有文字有Shimmer效果
        child: Shimmer.fromColors(
          baseColor: Color(0xFFD4AF37), // 金色
          highlightColor: Color(0xFFF5F5DC), // 浅米色
          period: const Duration(milliseconds: 2500),
            child: Text(
              "增强回复",
              style: TextStyle(
              color: Color(0xFFD4AF37), // 烫金色文字
              fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(0.5, 0.5),
                  blurRadius: 1,
                ),
              ],
              ),
            ),
        ),
      );
    } else {
      // 标准回复保持简单样式
      return Text(
        "标准回复",
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 11.sp,
          fontWeight: FontWeight.w400,
        ),
      );
    }
  }

  Widget _buildCombinedStatusRow() {
    if (widget.isUser) {
      return const SizedBox.shrink();
    }

    if ((widget.status == null && !widget.isLoading) &&
        widget.enhance == null) {
      return const SizedBox.shrink();
    }

    if (widget.isLoading || widget.status == 'streaming') {
      return _buildStatusText();
    }

    return _buildEnhanceTagContent();
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
                fontSize: widget.fontSize.sp,
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
                  fontSize: widget.fontSize.sp,
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

    final baseStyle = TextStyle(
      color: widget.textColor,
      fontSize: widget.fontSize.sp,
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

  Widget _buildStatusBar() {
    if (widget.statusBar == null || widget.isUser) {
      return const SizedBox.shrink();
    }

    return StatusBar(
      statusData: widget.statusBar!,
      textColor: widget.textColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 4.h,
      ),
      child: Column(
        crossAxisAlignment:
            widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.90,
            ),
            decoration: BoxDecoration(
              color: widget.bubbleColor.withOpacity(
                _isEditing ? widget.bubbleOpacity * 0.8 : widget.bubbleOpacity,
              ),
              borderRadius: BorderRadius.all(Radius.circular(10.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 8.h,
            ),
            margin: EdgeInsets.only(
              left: widget.isUser ? 0 : 4.w,
              right: widget.isUser ? 4.w : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildContent(),
                if (!widget.isUser && widget.statusBar != null)
                  _buildStatusBar(),
                if (!widget.isUser && !_isEditing) ...[
                  SizedBox(height: widget.message.isEmpty ? 0 : 6.h),
                  _buildCombinedStatusRow(),
                ],
              ],
            ),
          ),
          widget.isUser ? _buildUserButtonRow() : _buildAIButtonRow(),
        ],
      ),
    );
  }
}
