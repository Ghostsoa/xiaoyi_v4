import 'package:flutter/material.dart';
import 'dart:ui';
import 'base_formatter.dart';

class StatusFormatter extends BaseFormatter {
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

    // 改进正则表达式匹配所有标签，使用非贪婪模式匹配内容
    final pattern = RegExp(
      r'<(scene|action|thought|s)>(.*?)</\1>|```状态栏\s*([\s\S]*?)```',
      dotAll: true,
    );

    // 查找所有匹配项
    Iterable<Match> matches = pattern.allMatches(text);

    for (Match match in matches) {
      // 添加标签前的普通文本
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: baseStyle,
        ));
      }

      // 获取标签类型和内容
      final tag = match.group(1);
      final content = match.group(2) ?? match.group(3) ?? '';

      if (tag == null && match.group(0)!.startsWith('```状态栏')) {
        // 处理状态栏格式
        spans.add(WidgetSpan(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseStyle.color?.withOpacity(0.1) ??
                      Colors.grey.withOpacity(0.1),
                  baseStyle.color?.withOpacity(0.05) ??
                      Colors.grey.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: baseStyle.color?.withOpacity(0.1) ??
                          Colors.white.withOpacity(0.1),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Text(
                          '状态',
                          style: baseStyle.copyWith(
                            fontSize: baseStyle.fontSize! * 0.75,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: baseStyle.color?.withOpacity(0.5),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: LayoutBuilder(
                          builder: (context, constraints) => Text(
                            content.trim(),
                            style: baseStyle.copyWith(
                              height: 1.5,
                              letterSpacing: 0.5,
                              fontFamily: 'monospace',
                            ),
                            softWrap: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
      } else {
        // 处理其他标签
        switch (tag) {
          case 'scene':
            spans.add(WidgetSpan(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: baseStyle.color?.withOpacity(0.1) ??
                      Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: baseStyle.color?.withOpacity(0.2) ??
                        Colors.grey.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  content,
                  style: baseStyle,
                ),
              ),
            ));
            break;
          case 'action':
            spans.add(TextSpan(
              text: content,
              style: baseStyle.copyWith(
                color: Colors.yellow[700],
              ),
            ));
            break;
          case 'thought':
            spans.add(TextSpan(
              text: content,
              style: baseStyle.copyWith(
                fontStyle: FontStyle.italic,
                color: baseStyle.color?.withOpacity(0.7),
              ),
            ));
            break;
          case 's':
            spans.add(TextSpan(
              text: content,
              style: baseStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ));
            break;
        }
      }

      currentIndex = match.end;
    }

    // 添加剩余的文本
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }

  @override
  TextStyle getStyle(TextStyle baseStyle) {
    return baseStyle;
  }
}
