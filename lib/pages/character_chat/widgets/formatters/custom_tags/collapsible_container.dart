import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../../dao/chat_settings_dao.dart';

/// 可折叠容器组件（状态栏和档案共用）
class CollapsibleContainer extends StatefulWidget {
  final String title;
  final String content;
  final bool defaultExpanded;
  final String titleAlignment;
  final String containerType;
  final TextStyle baseStyle;
  final dynamic formatter; // MarkdownFormatter 实例

  const CollapsibleContainer({
    super.key,
    required this.title,
    required this.content,
    required this.defaultExpanded,
    required this.titleAlignment,
    required this.containerType,
    required this.baseStyle,
    required this.formatter,
  });

  @override
  State<CollapsibleContainer> createState() => _CollapsibleContainerState();
}

class _CollapsibleContainerState extends State<CollapsibleContainer>
    with SingleTickerProviderStateMixin {
  late bool isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.defaultExpanded;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 380),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _iconRotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(_expandAnimation);

    if (isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isStatusCollapsed =
        (widget.containerType == 'status_on' || widget.containerType == 'status_off') && !isExpanded;

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: ChatSettingsDao().getCustomTagStyles(),
      builder: (context, snapshot) {
        final customStyles = snapshot.data ?? {};
        final statusStyle = customStyles[widget.containerType];

        Color backgroundColor;
        double opacity;
        Color textColor;

        if (statusStyle != null) {
          backgroundColor = Color(int.parse(statusStyle['backgroundColor'].toString().replaceAll('0x', ''), radix: 16));
          opacity = (statusStyle['opacity'] as num).toDouble();
          textColor = Color(int.parse(statusStyle['textColor'].toString().replaceAll('0x', ''), radix: 16));
        } else {
          backgroundColor = widget.baseStyle.color ?? Colors.grey;
          opacity = 0.1;
          textColor = widget.baseStyle.color ?? Colors.black;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 1.0),
          // 根据展开状态和容器类型决定宽度
          width: ((widget.containerType == 'status_on' || widget.containerType == 'status_off') && !isExpanded) ? null : double.infinity,
          child: (isStatusCollapsed)
              ? _buildCollapsedStatusBar(backgroundColor, opacity, textColor)
              : _buildExpandedContainer(backgroundColor, opacity, textColor),
        );
      },
    );
  }

  /// 构建折叠状态的状态栏
  Widget _buildCollapsedStatusBar(Color backgroundColor, double opacity, Color textColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IntrinsicWidth(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: _buildContainerDecoration(backgroundColor, opacity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTitleBar(backgroundColor, textColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建展开状态的容器
  Widget _buildExpandedContainer(Color backgroundColor, double opacity, Color textColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: _buildContainerDecoration(backgroundColor, opacity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTitleBar(backgroundColor, textColor),
              _buildContentArea(textColor),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建容器装饰
  BoxDecoration _buildContainerDecoration(Color backgroundColor, double opacity) {
    return BoxDecoration(
      color: backgroundColor.withOpacity((opacity * 0.3).clamp(0.0, 1.0)),
      borderRadius: BorderRadius.circular(12.0),
      border: Border.all(
        color: backgroundColor.withOpacity((opacity * 1.2).clamp(0.0, 1.0)),
        width: 0.8,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  /// 构建标题栏
  Widget _buildTitleBar(Color backgroundColor, Color textColor) {
    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: BorderRadius.circular(12.0),
      splashColor: backgroundColor.withOpacity(0.1),
      highlightColor: backgroundColor.withOpacity(0.05),
      child: Container(
        width: (widget.containerType == 'status' && !isExpanded) ? null : double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: widget.titleAlignment == 'center' && (isExpanded || widget.containerType != 'status')
            ? _buildCenterAlignedTitle(backgroundColor, textColor)
            : _buildLeftAlignedTitle(backgroundColor, textColor),
      ),
    );
  }

  /// 构建居中对齐的标题（档案类型）
  Widget _buildCenterAlignedTitle(Color backgroundColor, Color textColor) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: widget.baseStyle.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: widget.baseStyle.fontSize! * 0.85,
              color: backgroundColor,
            ),
          ),
          const SizedBox(width: 4.0),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: const Offset(0, 2),
                child: Icon(
                  Icons.keyboard_arrow_up,
                  size: 12,
                  color: backgroundColor,
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -2),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 12,
                  color: backgroundColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建左对齐的标题（状态栏类型）
  Widget _buildLeftAlignedTitle(Color backgroundColor, Color textColor) {
    bool shouldExpand = isExpanded || widget.containerType != 'status';

    if (shouldExpand) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          AnimatedBuilder(
            animation: _iconRotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _iconRotationAnimation.value * 3.14159,
                child: Icon(
                  Icons.keyboard_arrow_right,
                  size: 16,
                  color: backgroundColor,
                ),
              );
            },
          ),
          const SizedBox(width: 4.0),
          Text(
            widget.title,
            style: widget.baseStyle.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: widget.baseStyle.fontSize! * 0.85,
              color: backgroundColor,
            ),
          ),
          const Spacer(),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _iconRotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _iconRotationAnimation.value * 3.14159,
                child: Icon(
                  Icons.keyboard_arrow_right,
                  size: 16,
                  color: backgroundColor,
                ),
              );
            },
          ),
          const SizedBox(width: 4.0),
          Text(
            widget.title,
            style: widget.baseStyle.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: widget.baseStyle.fontSize! * 0.85,
              color: backgroundColor,
            ),
          ),
        ],
      );
    }
  }

  /// 构建内容区域
  Widget _buildContentArea(Color textColor) {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Container(
          width: ((widget.containerType == 'status_on' || widget.containerType == 'status_off') && !isExpanded) ? null : double.infinity,
          padding: const EdgeInsets.fromLTRB(8.0, 6.0, 8.0, 8.0),
          child: widget.formatter.formatMarkdownOnly(context, widget.content, widget.baseStyle.copyWith(color: textColor), isInCustomTag: true, allowNestedTags: true),
        ),
      ),
    );
  }
}
