import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';

class GroupChatInputArea extends StatefulWidget {
  final TextEditingController messageController;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSendTap;
  final VoidCallback onStopGenerationTap;
  final VoidCallback onOpenGroupPanel;
  final VoidCallback onOpenSettings;
  final Future<void> Function() onResetSession;

  const GroupChatInputArea({
    super.key,
    required this.messageController,
    required this.focusNode,
    required this.isSending,
    required this.onSendTap,
    required this.onStopGenerationTap,
    required this.onOpenGroupPanel,
    required this.onOpenSettings,
    required this.onResetSession,
  });

  @override
  State<GroupChatInputArea> createState() => _GroupChatInputAreaState();
}

class _GroupChatInputAreaState extends State<GroupChatInputArea>
    with TickerProviderStateMixin {
  
  // 输入框状态
  bool _isInputFocused = false;
  bool _isMenuExpanded = false;
  
  // 动画控制器
  late AnimationController _bubbleAnimationController;
  late AnimationController _menuAnimationController;
  late Animation<double> _bubbleOpacityAnimation;
  late Animation<double> _menuHeightAnimation;

  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _bubbleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _bubbleOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bubbleAnimationController, curve: Curves.easeOut),
    );
    _menuHeightAnimation = Tween<double>(begin: 0, end: 80).animate(
      CurvedAnimation(parent: _menuAnimationController, curve: Curves.easeInOut),
    );
    
    // 添加焦点监听
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _bubbleAnimationController.dispose();
    _menuAnimationController.dispose();
    super.dispose();
  }
  
  void _onFocusChange() {
    setState(() {
      _isInputFocused = widget.focusNode.hasFocus;
      if (_isInputFocused) {
        _bubbleAnimationController.forward();
      } else {
        _bubbleAnimationController.reverse();
      }
    });
  }
  
  void _insertBrackets() {
    final controller = widget.messageController;
    final selection = controller.selection;
    final text = controller.text;
    const insert = '()';
    
    if (selection.isValid) {
      final newText = text.replaceRange(selection.start, selection.end, insert);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: selection.start + 1);
    } else {
      controller.text = text + insert;
      controller.selection = TextSelection.collapsed(offset: controller.text.length - 1);
    }
  }
  
  void _insertQuotes() {
    final controller = widget.messageController;
    final selection = controller.selection;
    final text = controller.text;
    const insert = '""';
    
    if (selection.isValid) {
      final newText = text.replaceRange(selection.start, selection.end, insert);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: selection.start + 1);
    } else {
      controller.text = text + insert;
      controller.selection = TextSelection.collapsed(offset: controller.text.length - 1);
    }
  }
  
  void _clearInput() {
    widget.messageController.clear();
  }

  Widget _buildFunctionBubble({
    Widget? icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Material(
      color: isHighlighted ? AppTheme.primaryColor : Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon,
                SizedBox(width: 4.w),
              ],
              Text(
                label,
                style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedFunctionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                color: isLoading ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              alignment: Alignment.center,
              child: isLoading
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 22.sp),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(color: isLoading ? Colors.white.withOpacity(0.6) : Colors.white, fontSize: 11.sp),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.messageController.text.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 功能气泡栏 (当输入框聚焦时显示)
        if (_isInputFocused)
          FadeTransition(
            opacity: _bubbleOpacityAnimation,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFunctionBubble(icon: null, label: '()', onTap: _insertBrackets),
                  _buildFunctionBubble(icon: null, label: '""', onTap: _insertQuotes),
                  _buildFunctionBubble(
                    icon: Icon(Icons.backspace_outlined, color: Colors.white, size: 14.sp),
                    label: '清空输入框',
                    onTap: _clearInput,
                  ),
                ],
              ),
            ),
          ),

        // 输入框行
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              // 菜单按钮
              Container(
                width: 36.w,
                height: 36.w,
                margin: EdgeInsets.only(right: 8.w),
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMenuExpanded = !_isMenuExpanded;
                      if (_isMenuExpanded) {
                        _menuAnimationController.forward();
                      } else {
                        _menuAnimationController.reverse();
                      }
                    });
                  },
                  child: AnimatedIcon(
                    icon: AnimatedIcons.menu_close,
                    progress: _menuAnimationController,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
              ),
              // 输入框
              Expanded(
                child: Container(
                  constraints: BoxConstraints(minHeight: 36.h, maxHeight: 120.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Focus(
                    canRequestFocus: true,
                    child: TextField(
                      controller: widget.messageController,
                      focusNode: widget.focusNode,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 14.sp),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: '发送消息...',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ),
              // 发送按钮
              Container(
                width: 36.w,
                height: 36.w,
                margin: EdgeInsets.only(left: 8.w),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.isSending
                        ? widget.onStopGenerationTap
                        : hasText
                            ? widget.onSendTap
                            : null,
                    borderRadius: BorderRadius.circular(18.r),
                    child: Icon(
                      widget.isSending
                          ? Icons.stop_rounded
                          : Icons.send,
                      color: widget.isSending
                          ? Colors.red.withOpacity(0.8)
                          : hasText
                              ? AppTheme.primaryColor
                              : Colors.white.withOpacity(0.5),
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 扩展菜单网格
        if (_isMenuExpanded)
          AnimatedBuilder(
            animation: _menuAnimationController,
            builder: (context, child) {
              return SizedBox(height: _menuHeightAnimation.value, child: child);
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                ),
              ),
              child: GridView.count(
                crossAxisCount: 4,
                padding: EdgeInsets.symmetric(vertical: 4.h),
                mainAxisSpacing: 2.h,
                crossAxisSpacing: 2.w,
                childAspectRatio: 0.9,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildExpandedFunctionButton(
                    icon: Icons.group,
                    label: '群聊',
                    onTap: widget.onOpenGroupPanel,
                  ),
                  _buildExpandedFunctionButton(
                    icon: Icons.palette_outlined,
                    label: '设置',
                    onTap: widget.onOpenSettings,
                  ),
                  _buildExpandedFunctionButton(
                    icon: Icons.restart_alt,
                    label: '重置',
                    onTap: () async {
                      await widget.onResetSession();
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
