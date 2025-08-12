import 'package:flutter/material.dart';
import 'dart:ui';
import 'base_custom_tag.dart';
import 'chat_list_widget.dart'; // 复用ChatAvatar
import 'utils/resource_mapping_helper.dart';
import '../../../../../dao/chat_settings_dao.dart';

/// 聊天对话标签组件 - 微信对话样式
class ChatConversationWidget extends BaseCustomTag {
  @override
  String get tagName => 'chat-conversation';

  @override
  String get defaultTitle => '对话';

  @override
  bool get defaultExpanded => true;

  @override
  String get titleAlignment => 'center';

  @override
  String get containerType => 'chat-conversation';

  @override
  Widget build(
    BuildContext context,
    String? nameAttribute,
    String content,
    TextStyle baseStyle,
    dynamic formatter,
  ) {
    // 解析属性
    Map<String, String> attributes = _parseChatConversationAttributes(content);
    String title = attributes['title'] ?? '对话';
    
    // 移除属性标签后的纯内容
    String cleanContent = _removeChatConversationAttributes(content);

    // 解析资源映射
    final Map<String, String> nameToUri = ResourceMappingHelper.parseResourceMappings(formatter.resourceMapping);

    return ChatConversationWidgetStateful(
      title: title,
      content: cleanContent,
      baseStyle: baseStyle,
      formatter: formatter,
      nameToUri: nameToUri,
    );
  }

  /// 解析chat-conversation标签的属性
  Map<String, String> _parseChatConversationAttributes(String content) {
    Map<String, String> attributes = {};
    RegExp startTagRegex = RegExp(r'<chat-conversation([^>]*)>', multiLine: true);
    Match? startMatch = startTagRegex.firstMatch(content);
    
    if (startMatch != null) {
      String attributesString = startMatch.group(1) ?? '';
      RegExp attrRegex = RegExp(r'(\w+)="([^"]*)"');
      Iterable<Match> matches = attrRegex.allMatches(attributesString);
      
      for (Match match in matches) {
        attributes[match.group(1)!] = match.group(2)!;
      }
    }
    
    return attributes;
  }

  /// 移除chat-conversation属性标签
  String _removeChatConversationAttributes(String content) {
    return content
        .replaceAll(RegExp(r'<chat-conversation[^>]*>', multiLine: true), '')
        .replaceAll('</chat-conversation>', '')
        .trim();
  }
}

/// 聊天对话组件主体
class ChatConversationWidgetStateful extends StatelessWidget {
  final String title;
  final String content;
  final TextStyle baseStyle;
  final dynamic formatter;
  final Map<String, String> nameToUri;

  const ChatConversationWidgetStateful({
    super.key,
    required this.title,
    required this.content,
    required this.baseStyle,
    required this.formatter,
    required this.nameToUri,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> messages = _parseMessages(content);

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: ChatSettingsDao().getCustomTagStyles(),
      builder: (context, snapshot) {
        final customStyles = snapshot.data ?? {};
        final conversationStyle = customStyles['chat-conversation'];

        Color backgroundColor;
        double opacity;
        Color textColor;

        if (conversationStyle != null) {
          backgroundColor = Color(int.parse(conversationStyle['backgroundColor'].toString().replaceAll('0x', ''), radix: 16));
          opacity = (conversationStyle['opacity'] as num).toDouble();
          textColor = Color(int.parse(conversationStyle['textColor'].toString().replaceAll('0x', ''), radix: 16));
        } else {
          backgroundColor = baseStyle.color ?? Colors.grey;
          opacity = 0.1;
          textColor = baseStyle.color ?? Colors.black;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      backgroundColor.withOpacity((opacity * 0.3).clamp(0.0, 1.0)),
                      backgroundColor.withOpacity((opacity * 0.1).clamp(0.0, 1.0)),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: backgroundColor.withOpacity((opacity * 1.2).clamp(0.0, 1.0)),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
            child: Column(
              children: [
                // 对话头部
                _buildChatHeader(context, backgroundColor, opacity, textColor),
                // 消息列表
                Container(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: messages.map((msg) => _buildChatMessage(context, msg, backgroundColor, opacity, textColor)).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  /// 构建对话头部
  Widget _buildChatHeader(BuildContext context, Color backgroundColor, double opacity, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor.withOpacity((opacity * 0.8).clamp(0.0, 1.0)),
            backgroundColor.withOpacity((opacity * 0.5).clamp(0.0, 1.0)),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: backgroundColor.withOpacity((opacity * 1.5).clamp(0.0, 1.0)),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 返回按钮
          Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: backgroundColor,
          ),
          const SizedBox(width: 8.0),
          // 对话标题
          Expanded(
            child: Text(
              title,
              style: baseStyle.copyWith(
                fontSize: baseStyle.fontSize! * 1.0,
                fontWeight: FontWeight.w600,
                color: backgroundColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // 更多按钮
          Icon(
            Icons.more_horiz,
            size: 20,
            color: backgroundColor,
          ),
        ],
      ),
    );
  }

  /// 构建单条聊天消息
  Widget _buildChatMessage(BuildContext context, Map<String, String> msg, Color backgroundColor, double opacity, Color textColor) {
    String sender = msg['sender'] ?? '未知';
    String time = msg['time'] ?? '';
    String side = msg['side'] ?? 'left';
    String content = msg['content'] ?? '';
    
    bool isLeft = side == 'left';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLeft) ...[
            // 左侧：头像
            ChatAvatar(
              nameToUri: nameToUri,
              name: sender,
              baseStyle: baseStyle,
              size: 36.0,
              isGroup: false,
            ),
            const SizedBox(width: 8.0),
          ],
          // 消息气泡
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 250.0),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: isLeft
                    ? backgroundColor.withOpacity((opacity * 0.5).clamp(0.0, 1.0))
                    : backgroundColor.withOpacity((opacity * 1.5).clamp(0.0, 1.0)),
                borderRadius: BorderRadius.circular(8.0), // 统一圆角，不要凸出
                border: Border.all(
                  color: isLeft
                      ? backgroundColor.withOpacity((opacity * 1.5).clamp(0.0, 1.0))
                      : backgroundColor.withOpacity((opacity * 3.0).clamp(0.0, 1.0)),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: formatter.formatMarkdownOnly(
                context,
                content,
                baseStyle.copyWith(
                  fontSize: baseStyle.fontSize! * 0.85,
                  color: textColor,
                ),
                isInCustomTag: true,
                allowNestedTags: false,
              ),
            ),
          ),
          if (!isLeft) ...[
            const SizedBox(width: 8.0),
            // 右侧：头像
            ChatAvatar(
              nameToUri: nameToUri,
              name: sender,
              baseStyle: baseStyle,
              size: 36.0,
              isGroup: false,
            ),
          ],
        ],
      ),
    );
  }

  /// 解析聊天消息
  List<Map<String, String>> _parseMessages(String content) {
    List<Map<String, String>> messages = [];
    
    RegExp msgRegex = RegExp(
      r'<chat-msg([^>]*?)>(.*?)</chat-msg>',
      multiLine: true,
      dotAll: true,
    );
    
    Iterable<Match> matches = msgRegex.allMatches(content);
    
    for (Match match in matches) {
      String attributesString = match.group(1) ?? '';
      String msgContent = match.group(2) ?? '';
      
      // 解析属性
      Map<String, String> attributes = {};
      RegExp attrRegex = RegExp(r'(\w+)="([^"]*)"');
      Iterable<Match> attrMatches = attrRegex.allMatches(attributesString);
      
      for (Match attrMatch in attrMatches) {
        attributes[attrMatch.group(1)!] = attrMatch.group(2)!;
      }
      
      attributes['content'] = msgContent.trim();
      messages.add(attributes);
    }
    
    return messages;
  }
}
