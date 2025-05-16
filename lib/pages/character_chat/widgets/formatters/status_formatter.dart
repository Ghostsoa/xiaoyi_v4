import 'package:flutter/material.dart';
import 'dart:ui';
import 'base_formatter.dart';
import 'dart:collection';

// 标签解析结果
class TagParseResult {
  final String tag;
  final String emoji;
  final String? color;
  final int endPos;

  TagParseResult({
    required this.tag,
    required this.emoji,
    this.color,
    required this.endPos,
  });
}

class StatusFormatter extends BaseFormatter {
  // Helper function to map color names to Material Colors (dark shades)
  Color _getColorFromName(String? colorName,
      {Color defaultColor = Colors.black}) {
    if (colorName == null) return defaultColor;
    switch (colorName.toLowerCase()) {
      case "red":
        return Colors.red[700]!;
      case "blue":
        return Colors.blue[700]!;
      case "green":
        return Colors.green[700]!;
      case "yellow":
        return Colors.yellow[800]!;
      case "purple":
        return Colors.purple[700]!;
      case "orange":
        return Colors.orange[800]!;
      case "pink":
        return Colors.pink[700]!;
      case "black":
        return Colors.black;
      case "white": // White is tricky for text, ensure good contrast or use for borders
        return Colors
            .grey[800]!; // Defaulting to dark grey if white is for text
      case "gray":
        return Colors.grey[700]!;
      case "brown":
        return Colors.brown[700]!;
      case "cyan":
        return Colors.cyan[700]!;
      case "magenta": // Magenta is not a direct Material Color, using deepPurpleAccent
        return Colors.deepPurpleAccent[400]!;
      case "gold":
        return Colors.amber[700]!;
      case "silver":
        return Colors.grey[600]!;
      case "olive":
        return Colors.green[900]!;
      case "teal":
        return Colors.teal[700]!;
      case "navy":
        return Colors.blue[900]!;
      case "maroon":
        return Colors.red[900]!;
      case "lime":
        return Colors.lime[800]!;
      default:
        return defaultColor;
    }
  }

  @override
  Widget format(BuildContext context, String text, TextStyle baseStyle) {
    try {
      // 解析文本中的标签和内容
      final result = _processFormats(text, baseStyle);

      return RichText(
        text: TextSpan(children: result),
      );
    } catch (e) {
      // 如果解析出错，显示原始文本
      debugPrint('标签解析错误: $e');
      return Text(text, style: baseStyle);
    }
  }

  // 使用正则表达式解析标签
  List<InlineSpan> _processFormats(String text, TextStyle baseStyle) {
    List<InlineSpan> spans = [];
    int currentIndex = 0;

    // 提前检测是否包含标签，如果没有直接返回纯文本
    if (!text.contains('<') || !text.contains('</')) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    // Regex to capture tag, emoji, color, and content
    final pattern = RegExp(
      r'<(\w+)(?:\s+emjoy="(.*?)")?(?:\s+color="(.*?)")?>(.*?)</\1>',
      dotAll: true,
    );

    Iterable<Match> matches = pattern.allMatches(text);

    for (Match match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: baseStyle,
        ));
      }

      final tag = match.group(1);
      final emoji = match.group(2) ?? _getDefaultEmoji(tag);
      final colorName = match.group(3);
      final content = match.group(4) ?? '';

      Color dynamicColor = _getColorFromName(colorName,
          defaultColor: baseStyle.color ?? Colors.black);
      Color lightDynamicColor = dynamicColor.withOpacity(0.08);
      Color borderDynamicColor = dynamicColor.withOpacity(0.2);

      // 使用正则表达式递归处理内容中的标签
      List<InlineSpan> contentSpans;
      if (content.contains('<') && content.contains('</')) {
        contentSpans = _processFormats(content, baseStyle);
      } else {
        contentSpans = [TextSpan(text: content, style: baseStyle)];
      }

      // 根据标签创建合适的控件
      InlineSpan tagSpan = _createTagWidget(
          tag ?? '', emoji ?? '', colorName, contentSpans, baseStyle);
      spans.add(tagSpan);

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: baseStyle,
      ));
    }
    return spans;
  }

  // 创建标签部件
  InlineSpan _createTagWidget(String tag, String emoji, String? colorName,
      List<InlineSpan> innerSpans, TextStyle baseStyle) {
    Color dynamicColor = _getColorFromName(colorName,
        defaultColor: baseStyle.color ?? Colors.black);
    Color lightDynamicColor = dynamicColor.withOpacity(0.08);
    Color borderDynamicColor = dynamicColor.withOpacity(0.2);

    // 根据标签类型，配置样式属性
    FontWeight? fontWeight;
    FontStyle? fontStyle;
    double? letterSpacing;
    String? fontFamily;
    double? fontSizeMultiplier;
    BorderRadius? borderRadius;
    EdgeInsets? padding;
    BoxDecoration? customDecoration;
    bool isNestedContainer = true; // 是否使用容器包装内容（某些样式可能只需要文本样式）

    switch (tag) {
      case 's': // 对话内容
        fontWeight = FontWeight.w600;
        borderRadius = BorderRadius.circular(8);
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
        break;

      case 'action': // 动作描述
        fontStyle = FontStyle.italic;
        borderRadius = BorderRadius.circular(16);
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
        customDecoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [
              dynamicColor.withOpacity(0.08),
              dynamicColor.withOpacity(0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderDynamicColor.withOpacity(0.5),
            width: 0.5,
          ),
        );
        break;

      case 'thought': // 内心想法
        fontStyle = FontStyle.italic;
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 1);
        borderRadius = BorderRadius.circular(6);
        customDecoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border(
              left:
                  BorderSide(color: dynamicColor.withOpacity(0.35), width: 2)),
        );
        break;

      case 'narration': // 叙述内容
        fontStyle = FontStyle.italic;
        letterSpacing = 0.2;
        isNestedContainer = false; // 不使用容器包装，只应用文本样式
        break;

      case 'emotion': // 情绪表达
        fontWeight = FontWeight.w600;
        borderRadius = BorderRadius.circular(12);
        padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 0);
        customDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dynamicColor.withOpacity(0.3),
            width: 0.5,
          ),
          color: dynamicColor.withOpacity(0.05),
        );
        break;

      case 'environment': // 环境描写
        borderRadius = BorderRadius.circular(6);
        padding = const EdgeInsets.all(4);
        customDecoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [
              dynamicColor.withOpacity(0.07),
              dynamicColor.withOpacity(0.03)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: borderDynamicColor.withOpacity(0.15), width: 0.5),
        );
        break;

      case 'system': // 系统消息
        fontFamily = 'monospace';
        fontSizeMultiplier = 0.95;
        borderRadius = BorderRadius.circular(4);
        padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 1);
        customDecoration = BoxDecoration(
          color: dynamicColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: dynamicColor.withOpacity(0.2),
            width: 0.5,
          ),
        );
        break;

      case 'emphasis': // 重点内容
        fontWeight = FontWeight.bold;
        isNestedContainer = false; // 不使用容器包装，只应用文本样式
        break;

      default: // 未知标签
        return TextSpan(children: innerSpans);
    }

    // 为内部的spans应用当前标签的样式
    List<InlineSpan> styledInnerSpans = innerSpans.map((span) {
      if (span is TextSpan) {
        return TextSpan(
          text: span.text,
          style: (span.style ?? baseStyle).copyWith(
            color: dynamicColor,
            fontWeight: fontWeight ?? span.style?.fontWeight,
            fontStyle: fontStyle ?? span.style?.fontStyle,
            letterSpacing: letterSpacing ?? span.style?.letterSpacing,
            fontFamily: fontFamily ?? span.style?.fontFamily,
            fontSize: baseStyle.fontSize! * (fontSizeMultiplier ?? 1.0),
            height: 1.35, // 一致的行高
          ),
        );
      }
      return span;
    }).toList();

    // 对于不需要容器包装的标签，直接返回样式化的文本
    if (!isNestedContainer) {
      if (emoji.isNotEmpty) {
        // 如果有表情符号，添加到文本前面
        return TextSpan(
          children: [
            TextSpan(
              text: '$emoji ',
              style: baseStyle.copyWith(
                color: dynamicColor,
                fontSize: baseStyle.fontSize! * (fontSizeMultiplier ?? 1.0),
              ),
            ),
            ...styledInnerSpans,
          ],
        );
      } else {
        return TextSpan(children: styledInnerSpans);
      }
    }

    // 创建带容器的标签部件
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: customDecoration ??
            BoxDecoration(
              color: lightDynamicColor,
              borderRadius: borderRadius ?? BorderRadius.circular(4),
              border: Border.all(
                color: borderDynamicColor,
                width: 0.5,
              ),
            ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (emoji.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 2.0),
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize:
                        baseStyle.fontSize! * (fontSizeMultiplier ?? 1.0) * 0.9,
                    color: dynamicColor,
                  ),
                ),
              ),
            Flexible(
              child: RichText(
                text: TextSpan(
                  children: styledInnerSpans,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDefaultEmoji(String? tag) {
    switch (tag) {
      case 's':
        return "💬";
      case 'action':
        return "🎬";
      case 'thought':
        return "💭";
      case 'narration':
        return "📖";
      case 'emotion':
        return "🎭";
      case 'environment':
        return "🏞️";
      case 'system':
        return "⚙️"; // Changed from 🔧 to ⚙️ for better visual
      case 'emphasis':
        return "❗"; // Changed from ⚠️ to ❗ for better visual
      default:
        return "";
    }
  }

  @override
  TextStyle getStyle(TextStyle baseStyle) {
    return baseStyle;
  }
}
