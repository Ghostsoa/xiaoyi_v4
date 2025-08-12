import 'package:flutter/material.dart';
import 'base_custom_tag.dart';
import 'status_widget.dart';
import 'archive_widget.dart';
import 'options_widget.dart';
import 'notebook_widget.dart';
import 'role_widget.dart';
import 'message_widget.dart';
import 'topic_widget.dart';
import 'feed_widget.dart';
import 'chat_list_widget.dart';
import 'chat_conversation_widget.dart';

/// 自定义标签解析器
class CustomTagParser {
  // 标签注册表
  static final Map<String, BaseCustomTag> _tagRegistry = {
    'status_on': StatusWidget(expanded: true),
    'status_off': StatusWidget(expanded: false),
    'archive': ArchiveWidget(),
    'options_h': OptionsWidget(horizontal: true),
    'options_v': OptionsWidget(horizontal: false),
    'notebook': NotebookWidget(),
    'role': RoleWidget(),
    'message': MessageWidget(),
    'topic': TopicWidget(),
    'feed': FeedWidget(),
    'chat-list': ChatListWidget(),
    'chat-conversation': ChatConversationWidget(),
  };

  /// 解析文本中的自定义标签
  static List<Widget> parseCustomTags(
    BuildContext context,
    String text,
    TextStyle baseStyle,
    dynamic formatter, // MarkdownFormatter 实例
  ) {
    List<Widget> widgets = [];

    // 创建正则表达式匹配所有支持的自定义标签，支持多个属性
    String tagPattern = _tagRegistry.keys.join('|');
    RegExp customTagRegex = RegExp(
      r'<(' + tagPattern + r')([^>]*?)>(.*?)</\1>',
      multiLine: true,
      dotAll: true,
    );

    int lastEnd = 0;
    Iterable<Match> matches = customTagRegex.allMatches(text);

    for (Match match in matches) {
      // 添加标签前的普通文本
      if (match.start > lastEnd) {
        String beforeText = text.substring(lastEnd, match.start).trim();
        if (beforeText.isNotEmpty) {
          widgets.add(_formatMarkdownOnly(context, beforeText, baseStyle, formatter));
        }
      }

      String tagName = match.group(1)!;
      String attributesString = match.group(2) ?? '';
      String content = match.group(3) ?? '';

      // 解析属性
      Map<String, String> attributes = _parseTagAttributes(attributesString);
      String? nameAttribute = attributes['name'];

      // 构建自定义标签组件
      BaseCustomTag? tagHandler = _tagRegistry[tagName];
      if (tagHandler != null) {
        Widget customWidget;

        // 特殊处理message、topic、feed、chat-list和chat-conversation标签
        if (tagName == 'message') {
          customWidget = (tagHandler as MessageWidget).buildWithAttributes(
            context,
            attributes,
            content,
            baseStyle,
            formatter,
          );
        } else if (tagName == 'topic' || tagName == 'feed' || tagName == 'chat-list' || tagName == 'chat-conversation') {
          // 这些标签需要特殊处理，因为它们的属性在开始标签中
          customWidget = tagHandler.build(
            context,
            nameAttribute,
            '${match.group(0)}', // 传递完整的匹配内容，包含属性
            baseStyle,
            formatter,
          );
        } else {
          customWidget = tagHandler.build(
            context,
            nameAttribute,
            content,
            baseStyle,
            formatter,
          );
        }
        widgets.add(customWidget);
      }

      lastEnd = match.end;
    }

    // 添加最后剩余的文本
    if (lastEnd < text.length) {
      String remainingText = text.substring(lastEnd).trim();
      if (remainingText.isNotEmpty) {
        widgets.add(_formatMarkdownOnly(context, remainingText, baseStyle, formatter));
      }
    }

    return widgets;
  }

  /// 格式化纯markdown内容（不包含自定义标签）
  static Widget _formatMarkdownOnly(
    BuildContext context,
    String text,
    TextStyle baseStyle,
    dynamic formatter,
  ) {
    // 调用formatter的formatMarkdownOnly方法
    return formatter.formatMarkdownOnly(
      context,
      text,
      baseStyle,
      isInCustomTag: false,
    );
  }

  /// 解析标签属性
  static Map<String, String> _parseTagAttributes(String attributesString) {
    Map<String, String> attributes = {};
    RegExp attrRegex = RegExp(r'(\w+)="([^"]*)"');
    Iterable<Match> matches = attrRegex.allMatches(attributesString);

    for (Match match in matches) {
      String key = match.group(1)!;
      String value = match.group(2)!;
      attributes[key] = value;
    }

    return attributes;
  }
}
