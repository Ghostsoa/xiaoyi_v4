import 'package:flutter/material.dart';
import 'dart:ui';
import 'base_custom_tag.dart';
import 'topic_widget.dart';
import 'utils/resource_mapping_helper.dart';
import '../../../../../dao/chat_settings_dao.dart';

/// 信息流标签组件 - 话题列表
class FeedWidget extends BaseCustomTag {
  @override
  String get tagName => 'feed';

  @override
  String get defaultTitle => '信息流';

  @override
  bool get defaultExpanded => true;

  @override
  String get titleAlignment => 'left';

  @override
  String get containerType => 'feed';

  @override
  Widget build(
    BuildContext context,
    String? nameAttribute,
    String content,
    TextStyle baseStyle,
    dynamic formatter,
  ) {
    // 解析feed标签属性
    Map<String, String> attributes = _parseFeedAttributes(content);
    
    String feedTitle = attributes['title'] ?? '信息流';
    String feedType = attributes['type'] ?? 'hot'; // hot, new, following
    
    // 移除属性标签后的纯内容
    String cleanContent = _removeFeedAttributes(content);

    return FeedWidgetStateful(
      feedTitle: feedTitle,
      feedType: feedType,
      content: cleanContent,
      baseStyle: baseStyle,
      formatter: formatter,
    );
  }

  /// 解析feed标签的属性
  Map<String, String> _parseFeedAttributes(String content) {
    Map<String, String> attributes = {};
    
    // 匹配开始标签中的属性
    RegExp startTagRegex = RegExp(r'<feed([^>]*)>', multiLine: true);
    Match? startMatch = startTagRegex.firstMatch(content);
    
    if (startMatch != null) {
      String attributesString = startMatch.group(1) ?? '';
      RegExp attrRegex = RegExp(r'(\w+)="([^"]*)"');
      Iterable<Match> matches = attrRegex.allMatches(attributesString);
      
      for (Match match in matches) {
        String key = match.group(1)!;
        String value = match.group(2)!;
        attributes[key] = value;
      }
    }
    
    return attributes;
  }

  /// 移除feed属性标签
  String _removeFeedAttributes(String content) {
    // 移除开始和结束标签，保留中间内容
    return content
        .replaceAll(RegExp(r'<feed[^>]*>', multiLine: true), '')
        .replaceAll('</feed>', '')
        .trim();
  }
}

/// 信息流组件主体
class FeedWidgetStateful extends StatefulWidget {
  final String feedTitle;
  final String feedType;
  final String content;
  final TextStyle baseStyle;
  final dynamic formatter;

  const FeedWidgetStateful({
    super.key,
    required this.feedTitle,
    required this.feedType,
    required this.content,
    required this.baseStyle,
    required this.formatter,
  });

  @override
  State<FeedWidgetStateful> createState() => _FeedWidgetStatefulState();
}

class _FeedWidgetStatefulState extends State<FeedWidgetStateful> {
  String _currentFilter = 'hot';

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.feedType;
  }

  @override
  Widget build(BuildContext context) {
    List<String> topicContents = _parseTopicList(widget.content);

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: ChatSettingsDao().getCustomTagStyles(),
      builder: (context, snapshot) {
        final customStyles = snapshot.data ?? {};
        final feedStyle = customStyles['feed'];

        Color backgroundColor;
        double opacity;
        Color textColor;

        if (feedStyle != null) {
          backgroundColor = Color(int.parse(feedStyle['backgroundColor'].toString().replaceAll('0x', ''), radix: 16));
          opacity = (feedStyle['opacity'] as num).toDouble();
          textColor = Color(int.parse(feedStyle['textColor'].toString().replaceAll('0x', ''), radix: 16));
        } else {
          backgroundColor = widget.baseStyle.color ?? Colors.grey;
          opacity = 0.1;
          textColor = widget.baseStyle.color ?? Colors.black;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      backgroundColor.withOpacity((opacity * 0.6).clamp(0.0, 1.0)),
                      backgroundColor.withOpacity((opacity * 0.2).clamp(0.0, 1.0)),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: backgroundColor.withOpacity((opacity * 1.2).clamp(0.0, 1.0)),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: backgroundColor.withOpacity((opacity * 0.5).clamp(0.0, 1.0)),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 信息流标题头部
                if (widget.feedTitle.isNotEmpty && widget.feedTitle != '信息流')
                  _buildFeedHeader(context, backgroundColor, textColor),
                // 话题列表
                ...topicContents.asMap().entries.map((entry) {
                  int index = entry.key;
                  String topicContent = entry.value;
                  return Column(
                    children: [
                      if (index > 0) _buildTopicDivider(backgroundColor),
                      _buildTopicItem(context, topicContent, backgroundColor, textColor),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  /// 构建信息流头部
  Widget _buildFeedHeader(BuildContext context, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor.withOpacity(0.08),
            backgroundColor.withOpacity(0.04),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: backgroundColor.withOpacity(0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 信息流图标
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(
              Icons.dynamic_feed,
              size: 20,
              color: backgroundColor,
            ),
          ),
          const SizedBox(width: 12.0),
          // 标题
          Expanded(
            child: Text(
              widget.feedTitle,
              style: widget.baseStyle.copyWith(
                fontSize: widget.baseStyle.fontSize! * 1.1,
                fontWeight: FontWeight.bold,
                color: backgroundColor,
              ),
            ),
          ),

        ],
      ),
    );
  }





  /// 构建单个话题项（列表项样式）
  Widget _buildTopicItem(BuildContext context, String topicContent, Color backgroundColor, Color textColor) {
    // 解析话题信息
    Map<String, String> topicInfo = _parseTopicInfo(topicContent);

    return Container(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：标题
          if ((topicInfo['title'] ?? '').isNotEmpty)
            Text(
              topicInfo['title']!,
              style: widget.baseStyle.copyWith(
                fontSize: widget.baseStyle.fontSize! * 1.0,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if ((topicInfo['title'] ?? '').isNotEmpty) const SizedBox(height: 6.0),

          // 第二行：内容预览
          Text(
            _getContentPreview(topicInfo['content'] ?? ''),
            style: widget.baseStyle.copyWith(
              fontSize: widget.baseStyle.fontSize! * 0.85,
              color: textColor.withOpacity(0.8),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8.0),

          // 第三行：标签
          if ((topicInfo['tags'] ?? '').isNotEmpty) ...[
            _buildCompactTags(topicInfo['tags']!, backgroundColor, textColor),
            const SizedBox(height: 8.0),
          ],

          // 第四行：作者 + 时间
          Row(
            children: [
              // 小头像
              TopicAvatar(
                nameToUri: _getNameToUri(),
                authorName: topicInfo['author'] ?? '匿名',
                baseStyle: widget.baseStyle,
                size: 20.0, // 很小的头像
              ),
              const SizedBox(width: 6.0),
              Text(
                topicInfo['author'] ?? '匿名',
                style: widget.baseStyle.copyWith(
                  fontSize: widget.baseStyle.fontSize! * 0.8,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                topicInfo['time'] ?? '刚刚',
                style: widget.baseStyle.copyWith(
                  fontSize: widget.baseStyle.fontSize! * 0.75,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              // 简化的互动数据
              _buildCompactInteraction(topicInfo, backgroundColor, textColor),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建话题分隔线
  Widget _buildTopicDivider(Color backgroundColor) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      color: backgroundColor.withOpacity(0.1),
    );
  }

  /// 解析话题信息
  Map<String, String> _parseTopicInfo(String topicContent) {
    Map<String, String> info = {};

    // 解析属性
    RegExp attrRegex = RegExp(r'(\w+)="([^"]*)"');
    Iterable<Match> attrMatches = attrRegex.allMatches(topicContent);
    for (Match match in attrMatches) {
      info[match.group(1)!] = match.group(2)!;
    }

    // 解析内容
    RegExp contentRegex = RegExp(r'<topic[^>]*>(.*?)</topic>', multiLine: true, dotAll: true);
    Match? contentMatch = contentRegex.firstMatch(topicContent);
    if (contentMatch != null) {
      String content = contentMatch.group(1) ?? '';
      // 移除comments部分
      content = content.replaceAll(RegExp(r'<comments>.*?</comments>', multiLine: true, dotAll: true), '').trim();
      info['content'] = content;
    }

    return info;
  }

  /// 获取内容预览（去除markdown格式）
  String _getContentPreview(String content) {
    // 简单地移除markdown标记，获取纯文本预览
    String preview = content
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // 移除加粗
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1') // 移除斜体
        .replaceAll(RegExp(r'`(.*?)`'), r'$1') // 移除代码
        .replaceAll(RegExp(r'#+ '), '') // 移除标题标记
        .replaceAll(RegExp(r'\n+'), ' ') // 换行变空格
        .trim();

    return preview.length > 60 ? '${preview.substring(0, 60)}...' : preview;
  }

  /// 构建紧凑标签
  Widget _buildCompactTags(String tags, Color backgroundColor, Color textColor) {
    List<String> tagList = tags.split(',').take(2).map((tag) => tag.trim()).toList(); // 最多显示2个标签

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: tagList.map((tag) => Container(
        margin: const EdgeInsets.only(right: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: backgroundColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          '#$tag',
          style: widget.baseStyle.copyWith(
            fontSize: widget.baseStyle.fontSize! * 0.7,
            color: textColor,
          ),
        ),
      )).toList(),
    );
  }

  /// 构建紧凑互动信息
  Widget _buildCompactInteraction(Map<String, String> topicInfo, Color backgroundColor, Color textColor) {
    String likes = topicInfo['likes'] ?? '0';
    String comments = topicInfo['comments'] ?? '0';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.thumb_up_outlined,
          size: 12,
          color: backgroundColor,
        ),
        const SizedBox(width: 2.0),
        Text(
          likes,
          style: widget.baseStyle.copyWith(
            fontSize: widget.baseStyle.fontSize! * 0.7,
            color: textColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(width: 8.0),
        Icon(
          Icons.chat_bubble_outline,
          size: 12,
          color: backgroundColor,
        ),
        const SizedBox(width: 2.0),
        Text(
          comments,
          style: widget.baseStyle.copyWith(
            fontSize: widget.baseStyle.fontSize! * 0.7,
            color: textColor.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  /// 获取资源映射
  Map<String, String> _getNameToUri() {
    return ResourceMappingHelper.parseResourceMappings(widget.formatter.resourceMapping);
  }


  /// 解析话题列表
  List<String> _parseTopicList(String content) {
    List<String> topics = [];
    
    RegExp topicRegex = RegExp(
      r'<topic[^>]*>.*?</topic>',
      multiLine: true,
      dotAll: true,
    );
    
    Iterable<Match> matches = topicRegex.allMatches(content);
    
    for (Match match in matches) {
      topics.add(match.group(0)!);
    }
    
    return topics;
  }


}
