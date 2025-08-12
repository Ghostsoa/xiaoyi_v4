import 'package:flutter/material.dart';
import 'dart:ui';
import 'base_custom_tag.dart';
import '../../../../../dao/chat_settings_dao.dart';

/// 记事本标签组件
class NotebookWidget extends BaseCustomTag {
  @override
  String get tagName => 'notebook';

  @override
  String get defaultTitle => '记事本';

  @override
  bool get defaultExpanded => false;

  @override
  String get titleAlignment => 'left';

  @override
  String get containerType => 'notebook';

  @override
  Widget build(
    BuildContext context,
    String? nameAttribute,
    String content,
    TextStyle baseStyle,
    dynamic formatter,
  ) {
    String title = nameAttribute?.isNotEmpty == true
        ? nameAttribute!
        : defaultTitle;

    return NotebookWidgetStateful(
      title: title,
      content: content,
      baseStyle: baseStyle,
      formatter: formatter,
    );
  }
}

/// 独立的记事本组件，记事本风格设计，可折叠
class NotebookWidgetStateful extends StatefulWidget {
  final String title;
  final String content;
  final TextStyle baseStyle;
  final dynamic formatter;

  const NotebookWidgetStateful({
    super.key,
    required this.title,
    required this.content,
    required this.baseStyle,
    required this.formatter,
  });

  @override
  State<NotebookWidgetStateful> createState() => _NotebookWidgetStatefulState();
}

class _NotebookWidgetStatefulState extends State<NotebookWidgetStateful>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false; // 默认折叠
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _iconRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
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
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: ChatSettingsDao().getCustomTagStyles(),
      builder: (context, snapshot) {
        final customStyles = snapshot.data ?? {};
        final notebookStyle = customStyles['notebook'];

        Color backgroundColor;
        double opacity;
        Color textColor;

        if (notebookStyle != null) {
          backgroundColor = Color(int.parse(notebookStyle['backgroundColor'].toString().replaceAll('0x', ''), radix: 16));
          opacity = (notebookStyle['opacity'] as num).toDouble();
          textColor = Color(int.parse(notebookStyle['textColor'].toString().replaceAll('0x', ''), radix: 16));
        } else {
          backgroundColor = widget.baseStyle.color ?? Colors.grey;
          opacity = 0.1;
          textColor = widget.baseStyle.color ?? Colors.black;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      backgroundColor.withOpacity((opacity * 0.8).clamp(0.0, 1.0)),
                      backgroundColor.withOpacity((opacity * 0.4).clamp(0.0, 1.0)),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: backgroundColor.withOpacity((opacity * 1.5).clamp(0.0, 1.0)),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleBar(backgroundColor, textColor),
                _buildContentArea(),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  /// 构建标题栏
  Widget _buildTitleBar(Color backgroundColor, Color textColor) {
    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12.0),
        topRight: Radius.circular(12.0),
      ),
      splashColor: backgroundColor.withOpacity(0.06),
      highlightColor: backgroundColor.withOpacity(0.03),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          border: Border(
            bottom: BorderSide(
              color: backgroundColor.withOpacity(0.15),
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          children: [
            // 折叠箭头（带旋转动画）
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
            // 记事本图标
            Icon(
              Icons.note_alt_outlined,
              size: 16,
              color: backgroundColor,
            ),
            const SizedBox(width: 6.0),
            // 动态标题
            Text(
              widget.title,
              style: widget.baseStyle
                  .copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: widget.baseStyle.fontSize! * 0.95,
                    color: backgroundColor,
                    letterSpacing: 0.4,
                  )
                  .merge(const TextStyle(overflow: TextOverflow.ellipsis)),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContentArea() {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8.0, 6.0, 8.0, 10.0),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12.0),
              bottomRight: Radius.circular(12.0),
            ),
          ),
          child: _buildNotebookContent(),
        ),
      ),
    );
  }

  /// 构建记事本内容，每行都有横线
  Widget _buildNotebookContent() {
    const double lineHeight = 24.0;

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: ChatSettingsDao().getCustomTagStyles(),
      builder: (context, snapshot) {
        final customStyles = snapshot.data ?? {};
        final notebookStyle = customStyles['notebook'];

        Color textColor;
        Color lineColor;

        if (notebookStyle != null) {
          textColor = Color(int.parse(notebookStyle['textColor'].toString().replaceAll('0x', ''), radix: 16));
          final bgColor = Color(int.parse(notebookStyle['backgroundColor'].toString().replaceAll('0x', ''), radix: 16));
          lineColor = bgColor.withOpacity(0.12);
        } else {
          textColor = widget.baseStyle.color ?? Colors.black;
          lineColor = (widget.baseStyle.color ?? Colors.grey).withOpacity(0.12);
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: lineHeight * 3),
          child: CustomPaint(
            painter: NotebookLinesPainter(
              lineCount: 0,
              lineHeight: lineHeight,
              lineColor: lineColor,
              lineWidth: 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: widget.formatter.formatMarkdownOnly(
                context,
                widget.content,
                widget.baseStyle.copyWith(
                  color: textColor,
                  fontSize: widget.baseStyle.fontSize! * 0.95,
                  height: lineHeight / (widget.baseStyle.fontSize! * 0.95),
                ),
                isInCustomTag: true,
                allowNestedTags: true,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 记事本横线的自定义绘制器
class NotebookLinesPainter extends CustomPainter {
  final int lineCount;
  final double lineHeight;
  final Color lineColor;
  final double lineWidth;

  NotebookLinesPainter({
    required this.lineCount,
    required this.lineHeight,
    required this.lineColor,
    required this.lineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth;

    double y = lineHeight;
    while (y < size.height + 0.5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += lineHeight;
    }
  }

  @override
  bool shouldRepaint(covariant NotebookLinesPainter oldDelegate) {
    return oldDelegate.lineCount != lineCount ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.lineWidth != lineWidth;
  }
}
