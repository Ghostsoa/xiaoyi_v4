import 'package:flutter/material.dart';
import 'topic_comment_widget.dart';
import '../../../../../dao/chat_settings_dao.dart';

/// 话题评论区组件
class TopicCommentsWidget extends StatefulWidget {
  final String commentsContent;
  final TextStyle baseStyle;
  final dynamic formatter;
  final Map<String, String> nameToUri;

  const TopicCommentsWidget({
    super.key,
    required this.commentsContent,
    required this.baseStyle,
    required this.formatter,
    required this.nameToUri,
  });

  @override
  State<TopicCommentsWidget> createState() => _TopicCommentsWidgetState();
}

class _TopicCommentsWidgetState extends State<TopicCommentsWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> comments = _parseComments(widget.commentsContent);

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: ChatSettingsDao().getCustomTagStyles(),
      builder: (context, snapshot) {
        final customStyles = snapshot.data ?? {};
        final topicStyle = customStyles['topic'];

        Color backgroundColor;
        Color textColor;

        if (topicStyle != null) {
          backgroundColor = Color(int.parse(topicStyle['backgroundColor'].toString().replaceAll('0x', ''), radix: 16));
          textColor = Color(int.parse(topicStyle['textColor'].toString().replaceAll('0x', ''), radix: 16));
        } else {
          backgroundColor = widget.baseStyle.color ?? Colors.grey;
          textColor = widget.baseStyle.color ?? Colors.black;
        }

        return Column(
          children: [
            // 分隔线
            Container(
              height: 0.5,
              color: backgroundColor.withOpacity(0.1),
            ),
            // 评论区头部
            InkWell(
              onTap: _toggleExpanded,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: backgroundColor,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      '评论 ${comments.length}',
                      style: widget.baseStyle.copyWith(
                        fontSize: widget.baseStyle.fontSize! * 0.8,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: backgroundColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 评论列表
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 8.0),
                child: Column(
                  children: comments.map((comment) => TopicCommentWidget(
                    author: comment['author'] ?? '匿名',
                    time: comment['time'] ?? '刚刚',
                    content: comment['content'] ?? '',
                    likes: comment['likes'] ?? '0',
                    baseStyle: widget.baseStyle,
                    formatter: widget.formatter,
                    nameToUri: widget.nameToUri,
                    backgroundColor: backgroundColor,
                    textColor: textColor,
                  )).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 解析评论内容
  List<Map<String, String>> _parseComments(String commentsContent) {
    List<Map<String, String>> comments = [];

    RegExp commentRegex = RegExp(
      r'<comment([^>]*?)>(.*?)</comment>',
      multiLine: true,
      dotAll: true,
    );

    Iterable<Match> matches = commentRegex.allMatches(commentsContent);

    for (Match match in matches) {
      String attributesString = match.group(1) ?? '';
      String content = match.group(2) ?? '';

      // 解析属性
      Map<String, String> attributes = {};
      RegExp attrRegex = RegExp(r'(\w+)="([^"]*)"');
      Iterable<Match> attrMatches = attrRegex.allMatches(attributesString);

      for (Match attrMatch in attrMatches) {
        attributes[attrMatch.group(1)!] = attrMatch.group(2)!;
      }

      comments.add({
        'author': attributes['author'] ?? '匿名',
        'time': attributes['time'] ?? '刚刚',
        'likes': attributes['likes'] ?? '0',
        'content': content,
      });
    }

    return comments;
  }
}
