import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_toast.dart';
import 'message_service.dart';

class CustomerServicePage extends StatefulWidget {
  const CustomerServicePage({super.key});

  @override
  State<CustomerServicePage> createState() => _CustomerServicePageState();
}

class _TempMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final bool isLoading;

  const _TempMessage({
    required this.role,
    required this.content,
    this.isLoading = false,
  });

  _TempMessage copyWith({String? role, String? content, bool? isLoading}) {
    return _TempMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class _CustomerServicePageState extends State<CustomerServicePage> {
  static const String _toggleKeyTag = '<toggle_key>';
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessageService _messageService = MessageService();

  final List<_TempMessage> _messages = <_TempMessage>[];
  bool _isSending = false;
  bool _isToggling = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _appendMessage(_TempMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final String text = _inputController.text.trim();
    if (text.isEmpty || _isSending) {
      if (text.isEmpty) {
        CustomToast.show(context, message: '请输入消息', type: ToastType.warning);
      }
      return;
    }

    // 追加用户消息
    _appendMessage(_TempMessage(role: 'user', content: text));

    // 清空输入框并设置发送中
    setState(() {
      _isSending = true;
      _inputController.clear();
    });

    // 追加占位的客服消息（loading）
    _appendMessage(const _TempMessage(role: 'assistant', content: '...', isLoading: true));

    try {
      final result = await _messageService.customerChat(text);
      if (!mounted) return;

      final int assistantIndex = _messages.lastIndexWhere((m) => m.role == 'assistant' && m.isLoading);
      if (assistantIndex != -1) {
        if (result['success'] == true) {
          final String reply = result['reply']?.toString() ?? '';
          setState(() {
            _messages[assistantIndex] = _messages[assistantIndex]
                .copyWith(content: reply.isNotEmpty ? reply : '（无回复）', isLoading: false);
          });
        } else {
          final String msg = result['msg']?.toString() ?? '请求失败';
          setState(() {
            _messages[assistantIndex] = _messages[assistantIndex]
                .copyWith(content: msg, isLoading: false);
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  Widget _buildBubble(_TempMessage message) {
    final bool isUser = message.role == 'user';
    final Color bubbleColor = isUser
        ? AppTheme.primaryColor
        : AppTheme.cardBackground;
    final Color textColor = isUser ? Colors.white : AppTheme.textPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 6.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.r),
              topRight: Radius.circular(12.r),
              bottomLeft: Radius.circular(isUser ? 12.r : 2.r),
              bottomRight: Radius.circular(isUser ? 2.r : 12.r),
            ),
            border: isUser ? null : Border.all(color: AppTheme.border),
          ),
          child: message.isLoading
              ? SizedBox(
                  height: 16.h,
                  width: 16.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : (!isUser && message.content.contains(_toggleKeyTag))
                  ? _buildAssistantRichContent(message, textColor)
                  : Text(
                      message.content,
                      style: AppTheme.bodyStyle.copyWith(color: textColor),
                    ),
        ),
      ),
    );
  }

  Widget _buildAssistantRichContent(_TempMessage message, Color textColor) {
    // 将 <toggle_key> 替换为按钮
    final parts = message.content.split(_toggleKeyTag);
    final List<Widget> children = [];
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isNotEmpty) {
        children.add(Text(
          part,
          style: AppTheme.bodyStyle.copyWith(color: textColor),
        ));
      }
      if (i < parts.length - 1) {
        children.add(SizedBox(width: 6.w));
        children.add(_buildToggleKeyButton(message));
        children.add(SizedBox(width: 6.w));
      }
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  Widget _buildToggleKeyButton(_TempMessage message) {
    return GestureDetector(
      onTap: _isToggling
          ? null
          : () async {
              final int messageIndex = _messages.indexOf(message);
              if (messageIndex == -1) return;
              setState(() => _isToggling = true);
              try {
                final result = await _messageService.customerToggleKey();
                if (!mounted) return;
                if (result['success'] == true) {
                  final String info = (result['message']?.toString() ?? result['msg']?.toString() ?? '操作成功');
                  CustomToast.show(context, message: info, type: ToastType.success);
                  setState(() {
                    final updated = _messages[messageIndex]
                        .copyWith(content: _messages[messageIndex].content.replaceFirst(_toggleKeyTag, info));
                    _messages[messageIndex] = updated;
                  });
                } else {
                  final String err = result['msg']?.toString() ?? '操作失败';
                  CustomToast.show(context, message: err, type: ToastType.error);
                }
              } finally {
                if (mounted) setState(() => _isToggling = false);
              }
            },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          gradient: _isToggling
              ? null
              : LinearGradient(
                  colors: AppTheme.buttonGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: const GradientRotation(0.4),
                ),
          color: _isToggling ? AppTheme.cardBackground : null,
          borderRadius: BorderRadius.circular(14.r),
          border: _isToggling ? Border.all(color: AppTheme.border) : null,
          boxShadow: _isToggling
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.buttonGradient.first.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: _isToggling
            ? SizedBox(
                width: 14.w,
                height: 14.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.toggle_on, color: Colors.white, size: 16.sp),
                  SizedBox(width: 4.w),
                  Text(
                    '切换官方密钥',
                    style: AppTheme.buttonTextStyle.copyWith(fontSize: 12.sp),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12.w,
          right: 12.w,
          bottom: 8.h,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.border),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: TextField(
                  controller: _inputController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: '请输入您的问题…',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: _isSending ? null : _send,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: _isSending
                      ? null
                      : LinearGradient(
                          colors: AppTheme.buttonGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          transform: const GradientRotation(0.4),
                        ),
                  color: _isSending ? AppTheme.cardBackground : null,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border:
                      _isSending ? Border.all(color: AppTheme.border) : null,
                  boxShadow: _isSending
                      ? []
                      : [
                          BoxShadow(
                            color: AppTheme.buttonGradient.first
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: _isSending
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        children: [
                          Icon(Icons.send, color: Colors.white, size: 16.sp),
                          SizedBox(width: 4.w),
                          Text('发送', style: AppTheme.buttonTextStyle),
                        ],
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        title: Text('客服', style: AppTheme.titleStyle),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 80.h),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildBubble(_messages[index]);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }
}


