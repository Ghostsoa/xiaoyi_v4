import 'package:flutter/material.dart';
import 'topic_widget.dart'; // 复用TopicAvatar

/// 单条话题评论组件
class TopicCommentWidget extends StatelessWidget {
  final String author;
  final String time;
  final String content;
  final String likes; // 评论点赞数
  final TextStyle baseStyle;
  final dynamic formatter;
  final Map<String, String> nameToUri;
  final Color backgroundColor;
  final Color textColor;

  const TopicCommentWidget({
    super.key,
    required this.author,
    required this.time,
    required this.content,
    required this.likes,
    required this.baseStyle,
    required this.formatter,
    required this.nameToUri,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: backgroundColor.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 评论者头像（小尺寸）
          TopicAvatar(
            nameToUri: nameToUri,
            authorName: author,
            baseStyle: baseStyle,
            size: 24.0,
          ),
          const SizedBox(width: 8.0),
          // 评论内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 评论者信息
                Row(
                  children: [
                    Text(
                      author,
                      style: baseStyle.copyWith(
                        fontSize: baseStyle.fontSize! * 0.8,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      time,
                      style: baseStyle.copyWith(
                        fontSize: baseStyle.fontSize! * 0.7,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                // 评论内容
                formatter.formatMarkdownOnly(
                  context,
                  content,
                  baseStyle.copyWith(
                    fontSize: baseStyle.fontSize! * 0.85,
                    color: textColor,
                  ),
                  isInCustomTag: true,
                  allowNestedTags: false, // 评论不支持嵌套标签
                ),
                const SizedBox(height: 4.0),
                // 评论互动按钮
                Row(
                  children: [
                    _buildCommentAction(Icons.thumb_up_outlined, likes, backgroundColor, textColor),
                    const SizedBox(width: 12.0),
                    _buildCommentAction(Icons.reply_outlined, '回复', backgroundColor, textColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建评论互动按钮
  Widget _buildCommentAction(IconData icon, String label, Color backgroundColor, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: backgroundColor,
        ),
        const SizedBox(width: 3.0),
        Text(
          label,
          style: baseStyle.copyWith(
            fontSize: baseStyle.fontSize! * 0.65,
            color: textColor.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
