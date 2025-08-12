import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:typed_data';
import 'base_custom_tag.dart';
import 'topic_comments_widget.dart';
import '../../../../../services/file_service.dart';
import '../../../../../dao/chat_settings_dao.dart';
import 'utils/resource_mapping_helper.dart';

/// 话题标签组件 - 微博样式
class TopicWidget extends BaseCustomTag {
  @override
  String get tagName => 'topic';

  @override
  String get defaultTitle => '话题';

  @override
  bool get defaultExpanded => true;

  @override
  String get titleAlignment => 'left';

  @override
  String get containerType => 'topic';

  @override
  Widget build(
    BuildContext context,
    String? nameAttribute,
    String content,
    TextStyle baseStyle,
    dynamic formatter,
  ) {
    // 解析标签属性
    Map<String, String> attributes = _parseTopicAttributes(content);
    
    String title = attributes['title'] ?? '';
    String author = attributes['author'] ?? '匿名用户';
    String time = attributes['time'] ?? '刚刚';
    String tags = attributes['tags'] ?? '';
    String likes = attributes['likes'] ?? '0';
    String shares = attributes['shares'] ?? '0';
    String comments = attributes['comments'] ?? '0';

    // 移除属性标签后的纯内容
    String cleanContent = _removeTopicAttributes(content);

    // 分离主内容和评论区
    Map<String, String> contentParts = _separateContentAndComments(cleanContent);

    // 解析资源映射
    final Map<String, String> nameToUri = ResourceMappingHelper.parseResourceMappings(formatter.resourceMapping);

    return TopicWidgetStateful(
      title: title,
      author: author,
      time: time,
      tags: tags,
      likes: likes,
      shares: shares,
      comments: comments,
      content: contentParts['content'] ?? '',
      commentsContent: contentParts['comments'] ?? '',
      baseStyle: baseStyle,
      formatter: formatter,
      nameToUri: nameToUri,
    );
  }

  /// 解析topic标签的属性
  Map<String, String> _parseTopicAttributes(String content) {
    Map<String, String> attributes = {};
    
    // 匹配开始标签中的属性
    RegExp startTagRegex = RegExp(r'<topic([^>]*)>', multiLine: true);
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

  /// 移除topic属性标签
  String _removeTopicAttributes(String content) {
    // 移除开始和结束标签，保留中间内容
    return content
        .replaceAll(RegExp(r'<topic[^>]*>', multiLine: true), '')
        .replaceAll('</topic>', '')
        .trim();
  }

  /// 分离主内容和评论区
  Map<String, String> _separateContentAndComments(String content) {
    RegExp commentsRegex = RegExp(r'<comments>(.*?)</comments>', multiLine: true, dotAll: true);
    Match? commentsMatch = commentsRegex.firstMatch(content);
    
    if (commentsMatch != null) {
      String mainContent = content.substring(0, commentsMatch.start).trim();
      String commentsContent = commentsMatch.group(1)?.trim() ?? '';
      
      return {
        'content': mainContent,
        'comments': commentsContent,
      };
    }
    
    return {
      'content': content,
      'comments': '',
    };
  }
}

/// 话题组件主体
class TopicWidgetStateful extends StatelessWidget {
  final String title;
  final String author;
  final String time;
  final String tags;
  final String likes;
  final String shares;
  final String comments;
  final String content;
  final String commentsContent;
  final TextStyle baseStyle;
  final dynamic formatter;
  final Map<String, String> nameToUri;

  const TopicWidgetStateful({
    super.key,
    required this.title,
    required this.author,
    required this.time,
    required this.tags,
    required this.likes,
    required this.shares,
    required this.comments,
    required this.content,
    required this.commentsContent,
    required this.baseStyle,
    required this.formatter,
    required this.nameToUri,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: ChatSettingsDao().getCustomTagStyles(),
      builder: (context, snapshot) {
        final customStyles = snapshot.data ?? {};
        final topicStyle = customStyles['topic'];

        Color backgroundColor;
        double opacity;
        Color textColor;

        if (topicStyle != null) {
          backgroundColor = Color(int.parse(topicStyle['backgroundColor'].toString().replaceAll('0x', ''), radix: 16));
          opacity = (topicStyle['opacity'] as num).toDouble();
          textColor = Color(int.parse(topicStyle['textColor'].toString().replaceAll('0x', ''), radix: 16));
        } else {
          backgroundColor = baseStyle.color ?? Colors.grey;
          opacity = 0.1;
          textColor = baseStyle.color ?? Colors.black;
        }

        final customTextStyle = baseStyle.copyWith(color: textColor);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity((opacity * 0.5).clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: backgroundColor.withOpacity((opacity * 1.0).clamp(0.0, 1.0)),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部：作者信息
                _buildTopicHeader(context, backgroundColor, textColor),
                // 标题（如果有）
                if (title.isNotEmpty) _buildTopicTitle(context, textColor),
                // 主要内容
                _buildTopicContent(context, textColor),
                // 标签（如果有）
                if (tags.isNotEmpty) _buildTopicTags(context, backgroundColor, textColor),
                // 互动按钮
                _buildInteractionButtons(context, backgroundColor, textColor),
                // 评论区（如果有）
                if (commentsContent.isNotEmpty) _buildCommentsSection(context, textColor),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  /// 构建话题头部（作者+时间）
  Widget _buildTopicHeader(BuildContext context, Color backgroundColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // 作者头像
          TopicAvatar(
            nameToUri: nameToUri,
            authorName: author,
            baseStyle: baseStyle,
            size: 36.0,
          ),
          const SizedBox(width: 10.0),
          // 作者信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author,
                  style: baseStyle.copyWith(
                    fontSize: baseStyle.fontSize! * 0.9,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  time,
                  style: baseStyle.copyWith(
                    fontSize: baseStyle.fontSize! * 0.75,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
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

  /// 构建话题标题
  Widget _buildTopicTitle(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 8.0),
      child: Text(
        title,
        style: baseStyle.copyWith(
          fontSize: baseStyle.fontSize! * 1.1,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  /// 构建话题内容
  Widget _buildTopicContent(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 8.0),
      child: formatter.formatMarkdownOnly(
        context,
        content,
        baseStyle.copyWith(
          color: textColor,
        ),
        isInCustomTag: true,
        allowNestedTags: true,
      ),
    );
  }

  /// 构建话题标签
  Widget _buildTopicTags(BuildContext context, Color backgroundColor, Color textColor) {
    List<String> tagList = tags.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 8.0),
      child: Wrap(
        spacing: 6.0,
        runSpacing: 4.0,
        children: tagList.map((tag) => _buildSingleTag(tag, backgroundColor, textColor)).toList(),
      ),
    );
  }

  /// 构建单个标签
  Widget _buildSingleTag(String tag, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: backgroundColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        '#$tag',
        style: baseStyle.copyWith(
          fontSize: baseStyle.fontSize! * 0.8,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建互动按钮
  Widget _buildInteractionButtons(BuildContext context, Color backgroundColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 8.0),
      child: Row(
        children: [
          _buildInteractionButton(Icons.thumb_up_outlined, '点赞', likes, backgroundColor, textColor),
          const SizedBox(width: 20.0),
          _buildInteractionButton(Icons.share_outlined, '转发', shares, backgroundColor, textColor),
          const SizedBox(width: 20.0),
          _buildInteractionButton(Icons.chat_bubble_outline, '评论', comments, backgroundColor, textColor),
        ],
      ),
    );
  }

  /// 构建单个互动按钮
  Widget _buildInteractionButton(IconData icon, String label, String count, Color backgroundColor, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: backgroundColor,
        ),
        const SizedBox(width: 4.0),
        Text(
          count,
          style: baseStyle.copyWith(
            fontSize: baseStyle.fontSize! * 0.75,
            color: textColor.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  /// 构建评论区
  Widget _buildCommentsSection(BuildContext context, Color textColor) {
    return TopicCommentsWidget(
      commentsContent: commentsContent,
      baseStyle: baseStyle,
      formatter: formatter,
      nameToUri: nameToUri,
    );
  }
}

/// 话题头像组件（复用消息头像逻辑）
class TopicAvatar extends StatefulWidget {
  final Map<String, String> nameToUri;
  final String authorName;
  final TextStyle baseStyle;
  final double size;

  const TopicAvatar({
    super.key,
    required this.nameToUri,
    required this.authorName,
    required this.baseStyle,
    required this.size,
  });

  @override
  State<TopicAvatar> createState() => _TopicAvatarState();
}

class _TopicAvatarState extends State<TopicAvatar> {
  final FileService _fileService = FileService();
  Uint8List? _imageBytes;
  bool _loading = false;
  String? _currentUri;
  static final Map<String, Uint8List> _memoryCache = <String, Uint8List>{};

  @override
  void initState() {
    super.initState();
    _currentUri = ResourceMappingHelper.getResourceUri(widget.nameToUri, widget.authorName);
    _maybeLoad();
  }

  @override
  void didUpdateWidget(covariant TopicAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? newUri = ResourceMappingHelper.getResourceUri(widget.nameToUri, widget.authorName);
    if (oldWidget.authorName != widget.authorName || newUri != _currentUri) {
      _currentUri = newUri;
      setState(() {
        _imageBytes = null;
      });
      _maybeLoad();
    }
  }

  Future<void> _maybeLoad() async {
    final String? uri = _currentUri;
    if (uri == null || uri.isEmpty) return;
    if (_loading) return;

    final Uint8List? cached = _memoryCache[uri];
    if (cached != null) {
      if (mounted) {
        setState(() => _imageBytes = cached);
      } else {
        _imageBytes = cached;
      }
      return;
    }
    setState(() => _loading = true);
    try {
      final resp = await _fileService.getFile(uri);
      final data = resp.data;
      if (mounted && (data is Uint8List || data is List<int>)) {
        final Uint8List bytes = Uint8List.fromList(List<int>.from(data));
        _memoryCache[uri] = bytes;
        setState(() => _imageBytes = bytes);
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool noMapping = _currentUri == null || (_currentUri?.isEmpty ?? true);
    final Color fallbackStart = const Color(0xFF7E57C2).withOpacity(0.8);
    final Color fallbackEnd = const Color(0xFF5E35B1).withOpacity(0.6);

    Widget avatar;
    if (_imageBytes != null) {
      avatar = ClipRRect(
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: Image.memory(
          _imageBytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
      );
    } else if (noMapping) {
      avatar = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fallbackStart, fallbackEnd],
          ),
          borderRadius: BorderRadius.circular(widget.size / 2),
        ),
        child: Center(
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: widget.size * 0.5,
          ),
        ),
      );
    } else {
      avatar = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fallbackStart, fallbackEnd],
          ),
          borderRadius: BorderRadius.circular(widget.size / 2),
        ),
        child: Center(
          child: Text(
            widget.authorName.isNotEmpty ? widget.authorName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.size * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return avatar;
  }
}
