import 'package:flutter/material.dart';
import 'base_custom_tag.dart';

/// 状态标签组件 - 处理各种状态标签的渲染
class StatusTagWidget extends BaseCustomTag {
  final String statusTagType;

  StatusTagWidget({required this.statusTagType});

  @override
  String get tagName => statusTagType;

  @override
  String get defaultTitle => _getDefaultTitle(statusTagType);

  @override
  bool get defaultExpanded => true;

  @override
  String get titleAlignment => 'left';

  @override
  String get containerType => statusTagType;

  String _getDefaultTitle(String tagType) {
    switch (tagType) {
      case 's':
        return '对话内容';
      case 'action':
        return '动作描述';
      case 'thought':
        return '内心想法';
      case 'narration':
        return '叙述内容';
      case 'emotion':
        return '情绪表达';
      case 'environment':
        return '环境描写';
      case 'system':
        return '系统消息';
      case 'emphasis':
        return '重点内容';
      default:
        return '状态标签';
    }
  }

  @override
  Widget build(
    BuildContext context,
    String? nameAttribute,
    String content,
    TextStyle baseStyle,
    dynamic formatter,
  ) {
    // 解析属性
    Map<String, String> attributes = _parseAttributes(nameAttribute);
    String emoji = attributes['emjoy'] ?? _getDefaultEmoji(statusTagType);
    String? colorName = attributes['color'];

    // 创建状态标签渲染器
    return _createStatusTagWidget(
      statusTagType,
      emoji,
      colorName,
      content,
      baseStyle,
      formatter,
      context,
    );
  }

  /// 解析属性字符串
  Map<String, String> _parseAttributes(String? attributeString) {
    Map<String, String> attributes = {};
    if (attributeString == null || attributeString.isEmpty) {
      return attributes;
    }

    // 简单的属性解析，支持 emjoy="..." color="..." 格式
    RegExp attrRegex = RegExp(r'(\w+)="([^"]*)"');
    Iterable<Match> matches = attrRegex.allMatches(attributeString);

    for (Match match in matches) {
      String key = match.group(1)!;
      String value = match.group(2)!;
      attributes[key] = value;
    }

    return attributes;
  }

  /// 获取默认表情符号
  String _getDefaultEmoji(String tagType) {
    switch (tagType) {
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
        return "⚙️";
      case 'emphasis':
        return "❗";
      default:
        return "";
    }
  }

  /// 获取颜色
  Color _getColorFromName(String? colorName, {Color defaultColor = Colors.black}) {
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
      case "white":
        return Colors.grey[800]!;
      case "gray":
        return Colors.grey[700]!;
      case "brown":
        return Colors.brown[700]!;
      case "cyan":
        return Colors.cyan[700]!;
      case "magenta":
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

  /// 创建状态标签组件
  Widget _createStatusTagWidget(
    String tag,
    String emoji,
    String? colorName,
    String content,
    TextStyle baseStyle,
    dynamic formatter,
    BuildContext context,
  ) {
    Color dynamicColor = _getColorFromName(colorName, defaultColor: baseStyle.color ?? Colors.black);
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
    bool isNestedContainer = true;

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
            left: BorderSide(color: dynamicColor.withOpacity(0.35), width: 2)
          ),
        );
        break;

      case 'narration': // 叙述内容
        fontStyle = FontStyle.italic;
        letterSpacing = 0.2;
        isNestedContainer = false;
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
            color: borderDynamicColor.withOpacity(0.15), 
            width: 0.5
          ),
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
        isNestedContainer = false;
        break;

      default: // 未知标签
        return Text(content, style: baseStyle);
    }

    // 处理内容 - 使用 formatter 来处理可能的 markdown 格式
    Widget contentWidget;
    if (formatter != null && formatter.formatMarkdownOnly != null) {
      contentWidget = formatter.formatMarkdownOnly(
        context,
        content,
        baseStyle.copyWith(
          color: dynamicColor,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          letterSpacing: letterSpacing,
          fontFamily: fontFamily,
          fontSize: baseStyle.fontSize! * (fontSizeMultiplier ?? 1.0),
          height: 1.35,
        ),
        isInCustomTag: true,
      );
    } else {
      contentWidget = Text(
        content,
        style: baseStyle.copyWith(
          color: dynamicColor,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          letterSpacing: letterSpacing,
          fontFamily: fontFamily,
          fontSize: baseStyle.fontSize! * (fontSizeMultiplier ?? 1.0),
          height: 1.35,
        ),
      );
    }

    // 对于不需要容器包装的标签，直接返回样式化的文本
    if (!isNestedContainer) {
      if (emoji.isNotEmpty) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$emoji ',
              style: baseStyle.copyWith(
                color: dynamicColor,
                fontSize: baseStyle.fontSize! * (fontSizeMultiplier ?? 1.0),
              ),
            ),
            Expanded(child: contentWidget),
          ],
        );
      } else {
        return contentWidget;
      }
    }

    // 创建带容器的标签部件
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
                  fontSize: baseStyle.fontSize! * (fontSizeMultiplier ?? 1.0) * 0.9,
                  color: dynamicColor,
                ),
              ),
            ),
          Flexible(child: contentWidget),
        ],
      ),
    );
  }
}
