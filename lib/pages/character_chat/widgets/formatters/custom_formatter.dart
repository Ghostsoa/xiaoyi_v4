import 'package:flutter/material.dart';
import 'dart:ui';
import 'base_formatter.dart';
import '../../../../dao/chat_settings_dao.dart';

class CustomFormatter extends BaseFormatter {
  final ChatSettingsDao _settingsDao = ChatSettingsDao();

  @override
  Widget format(BuildContext context, String text, TextStyle baseStyle) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadFormatSettings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(text, style: baseStyle);
        }

        final formatOptions =
            snapshot.data!['formatOptions'] as Map<String, dynamic>;
        final codeBlockFormat = snapshot.data!['codeBlockFormat'] as bool;

        // 如果没有启用任何格式，直接返回原文本
        if (!codeBlockFormat && formatOptions.isEmpty) {
          return Text(text, style: baseStyle);
        }

        return RichText(
          text: TextSpan(
            children: _processFormats(
              text,
              baseStyle,
              formatOptions,
              codeBlockFormat,
            ),
          ),
        );
      },
    );
  }

  List<InlineSpan> _processFormats(
    String text,
    TextStyle baseStyle,
    Map<String, dynamic> formatOptions,
    bool codeBlockFormat,
  ) {
    List<InlineSpan> spans = [];
    StringBuffer currentText = StringBuffer();

    // 记录所有可能的开始标记和对应的格式
    Map<String, Map<String, dynamic>> startTags = {};

    // 只添加启用的预定义格式
    formatOptions.forEach((key, value) {
      if (value['isEnabled'] == true) {
        String prefix, suffix;
        switch (key) {
          case 'parentheses':
            prefix = '(';
            suffix = ')';
            break;
          case 'brackets':
            prefix = '[';
            suffix = ']';
            break;
          case 'quotes':
            prefix = '“';
            suffix = '”';
            break;
          default:
            return;
        }
        startTags[prefix] = {
          'suffix': suffix,
          'style': TextStyle(
            fontWeight: value['isBold'] == true ? FontWeight.bold : null,
            fontStyle: value['isItalic'] == true ? FontStyle.italic : null,
            color: Color((value['color'] ?? Colors.black.value).toInt()),
          ),
        };
      }
    });

    // 只在启用时添加代码块格式
    if (codeBlockFormat) {
      startTags['```'] = {
        'suffix': '```',
        'style': const TextStyle(
          fontFamily: 'monospace',
          height: 1.5,
          letterSpacing: 0.5,
        ),
        'isCodeBlock': true,
      };
    }

    // 如果没有启用任何格式，直接返回原文本
    if (startTags.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    int i = 0;
    while (i < text.length) {
      bool foundStart = false;

      // 检查是否是开始标记
      for (var startTag in startTags.entries) {
        if (i + startTag.key.length <= text.length &&
            text.substring(i, i + startTag.key.length) == startTag.key) {
          // 如果当前有文本，先添加到spans
          if (currentText.isNotEmpty) {
            spans.add(TextSpan(
              text: currentText.toString(),
              style: baseStyle,
            ));
            currentText.clear();
          }

          // 寻找结束标记
          final suffix = startTag.value['suffix'];
          final endIndex = text.indexOf(suffix, i + startTag.key.length);

          if (endIndex != -1) {
            // 提取内容
            final content = text.substring(i + startTag.key.length, endIndex);

            // 如果是代码块，使用特殊的容器
            if (startTag.value['isCodeBlock'] == true) {
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
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              content,
                              style: baseStyle.merge(startTag.value['style']),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ));
            } else {
              // 其他格式直接应用样式
              spans.add(TextSpan(
                text: content,
                style: baseStyle.merge(startTag.value['style']),
              ));
            }

            // 更新索引到结束标记之后
            i = (endIndex + suffix.length).toInt();
            foundStart = true;
            break;
          }
        }
      }

      if (!foundStart) {
        currentText.write(text[i]);
        i++;
      }
    }

    // 处理剩余的文本
    if (currentText.isNotEmpty) {
      spans.add(TextSpan(
        text: currentText.toString(),
        style: baseStyle,
      ));
    }

    return spans;
  }

  Future<Map<String, dynamic>> _loadFormatSettings() async {
    final formatOptions = await _settingsDao.getFormatOptions();
    final codeBlockFormat = await _settingsDao.getCodeBlockFormat();

    return {
      'formatOptions': formatOptions,
      'codeBlockFormat': codeBlockFormat,
    };
  }

  @override
  TextStyle getStyle(TextStyle baseStyle) {
    return baseStyle;
  }
}
