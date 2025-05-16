import 'package:flutter/material.dart';
import 'dart:ui';
import 'base_formatter.dart';

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
    return FutureBuilder<List<InlineSpan>>(
      future: Future.value(_processFormats(text, baseStyle)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(text, style: baseStyle);
        }
        return RichText(
          text: TextSpan(children: snapshot.data!),
        );
      },
    );
  }

  List<InlineSpan> _processFormats(String text, TextStyle baseStyle) {
    List<InlineSpan> spans = [];
    int currentIndex = 0;

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

      // Default emoji if not provided in tag
      String currentEmoji = emoji;

      Widget tagWidget;

      switch (tag) {
        case 's': // 对话内容
          tagWidget = _buildTagContainer(
            emoji: currentEmoji,
            content: content,
            baseStyle: baseStyle,
            textColor: dynamicColor,
            backgroundColor: lightDynamicColor,
            borderColor: borderDynamicColor,
            fontWeight: FontWeight.w600,
            borderRadius: BorderRadius.circular(8),
          );
          break;

        case 'action': // 动作描述
          tagWidget = _buildTagContainer(
            emoji: currentEmoji,
            content: content,
            baseStyle: baseStyle,
            textColor: dynamicColor,
            backgroundColor: lightDynamicColor,
            borderColor: borderDynamicColor,
            fontStyle: FontStyle.italic,
            borderRadius: BorderRadius.circular(20),
          );
          break;

        case 'thought': // 内心想法
          tagWidget = _buildTagContainer(
              emoji: currentEmoji,
              content: content,
              baseStyle: baseStyle,
              textColor: dynamicColor
                  .withOpacity(0.85), // Slightly lighter for thoughts
              backgroundColor: dynamicColor.withOpacity(0.05),
              borderColor:
                  Colors.transparent, // No main border, use left border below
              fontStyle: FontStyle.italic,
              borderRadius: BorderRadius.circular(8),
              customDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    dynamicColor.withOpacity(0.05),
                    dynamicColor.withOpacity(0.02)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                    left: BorderSide(
                        color: dynamicColor.withOpacity(0.35), width: 2.5)),
              ));
          break;

        case 'narration': // 叙述内容
          tagWidget = _buildTagContainer(
              emoji: currentEmoji,
              content: content,
              baseStyle: baseStyle,
              textColor: dynamicColor,
              backgroundColor: Colors.transparent, // Clean look for narration
              borderColor: Colors.transparent,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.2,
              borderRadius: BorderRadius.circular(4),
              customDecoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: dynamicColor.withOpacity(0.3), width: 1)),
              ));
          break;

        case 'emotion': // 情绪表达
          tagWidget = _buildTagContainer(
            emoji: currentEmoji,
            content: content,
            baseStyle: baseStyle,
            textColor: dynamicColor,
            backgroundColor: lightDynamicColor,
            borderColor: borderDynamicColor,
            fontWeight: FontWeight.w600,
            borderRadius: BorderRadius.circular(16),
          );
          break;

        case 'environment': // 环境描写
          tagWidget = _buildTagContainer(
              emoji: currentEmoji,
              content: content,
              baseStyle: baseStyle,
              textColor: dynamicColor,
              backgroundColor: lightDynamicColor,
              borderColor: borderDynamicColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              padding: const EdgeInsets.all(8),
              customDecoration: BoxDecoration(
                // Keep gradient for environment
                gradient: LinearGradient(
                  colors: [
                    dynamicColor.withOpacity(0.1),
                    dynamicColor.withOpacity(0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: borderDynamicColor.withOpacity(0.15), width: 0.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 3,
                      offset: const Offset(0, 1))
                ],
              ));
          break;

        case 'system': // 系统消息
          tagWidget = _buildTagContainer(
            emoji: currentEmoji,
            content: content,
            baseStyle: baseStyle,
            textColor: dynamicColor,
            backgroundColor: lightDynamicColor,
            borderColor: borderDynamicColor,
            fontFamily: 'monospace',
            fontSizeMultiplier: 0.95,
            borderRadius: BorderRadius.circular(6),
          );
          break;

        case 'emphasis': // 重点内容
          tagWidget = _buildTagContainer(
            emoji: currentEmoji,
            content: content,
            baseStyle: baseStyle,
            textColor: dynamicColor,
            backgroundColor: lightDynamicColor,
            borderColor: borderDynamicColor,
            fontWeight: FontWeight.bold,
            borderRadius: BorderRadius.circular(4),
          );
          break;

        default: // Fallback for unknown tags
          tagWidget =
              Text(content, style: baseStyle.copyWith(color: dynamicColor));
          break;
      }

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: tagWidget,
      ));
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

  Widget _buildTagContainer({
    required String emoji,
    required String content,
    required TextStyle baseStyle,
    required Color textColor,
    required Color backgroundColor,
    required Color borderColor,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    String? fontFamily,
    double? fontSizeMultiplier,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    BoxDecoration? customDecoration,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
          vertical: 3, horizontal: 1), // Added horizontal margin
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: customDecoration ??
          BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius ?? BorderRadius.circular(4),
            border: Border.all(
              color: borderColor,
              width: 0.5,
            ),
          ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.center, // Align emoji and text vertically
        children: [
          if (emoji.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                  right: 4.0), // Space between emoji and text
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: baseStyle.fontSize! * (fontSizeMultiplier ?? 1.0),
                  color: textColor, // Emoji color matches text color
                ),
              ),
            ),
          Flexible(
            child: Text(
              content,
              style: baseStyle.copyWith(
                color: textColor,
                fontWeight: fontWeight,
                fontStyle: fontStyle,
                letterSpacing: letterSpacing,
                fontFamily: fontFamily,
                fontSize: baseStyle.fontSize! * (fontSizeMultiplier ?? 1.0),
                height: 1.35, // Consistent line height
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  TextStyle getStyle(TextStyle baseStyle) {
    return baseStyle;
  }
}
