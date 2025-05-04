import 'package:flutter/material.dart';
import 'dart:ui';
import 'base_formatter.dart';

class MarkdownFormatter extends BaseFormatter {
  @override
  Widget format(BuildContext context, String text, TextStyle baseStyle) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    List<Widget> widgets = [];
    List<String> lines = text.split('\n');
    List<TextSpan> currentLineSpans = [];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      // 检测是否是引用块开始
      if (line.startsWith('> ')) {
        if (currentLineSpans.isNotEmpty) {
          widgets.add(RichText(
            text: TextSpan(children: currentLineSpans),
          ));
          currentLineSpans = [];
        }

        // 收集连续的引用行
        StringBuffer quoteContent = StringBuffer();
        int currentLine = i;

        while (currentLine < lines.length) {
          String quoteLine = lines[currentLine].trim();
          if (!quoteLine.startsWith('> ')) break;

          // 处理引用内容
          String content = quoteLine.length > 1 ? quoteLine.substring(2) : '';

          // 如果不是第一行，添加换行符
          if (quoteContent.isNotEmpty) {
            quoteContent.write('\n');
          }

          // 即使是空行也保留，以保持段落格式
          quoteContent.write(content);
          currentLine++;
        }

        // 创建引用块
        widgets.add(Semantics(
          label: '引用块',
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseStyle.color?.withOpacity(0.08) ??
                      Colors.grey.withOpacity(0.08),
                  baseStyle.color?.withOpacity(0.04) ??
                      Colors.grey.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: baseStyle.color?.withOpacity(0.1) ??
                    Colors.grey.withOpacity(0.1),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 3,
                    margin: const EdgeInsets.only(right: 12.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          baseStyle.color?.withOpacity(0.3) ??
                              Colors.grey.withOpacity(0.3),
                          baseStyle.color?.withOpacity(0.1) ??
                              Colors.grey.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: _processInlineFormats(
                          quoteContent.toString(),
                          baseStyle.copyWith(
                            fontStyle: FontStyle.italic,
                            color: baseStyle.color?.withOpacity(0.85),
                            height: 1.6,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));

        i = currentLine - 1;
        continue;
      }

      // 检测是否是表格开始
      if (line.startsWith('|') &&
          i + 1 < lines.length &&
          lines[i + 1].trim().startsWith('|')) {
        if (currentLineSpans.isNotEmpty) {
          widgets.add(RichText(
            text: TextSpan(children: currentLineSpans),
          ));
          currentLineSpans = [];
        }

        List<List<String>> tableData = [];
        int currentLine = i;

        while (currentLine < lines.length &&
            lines[currentLine].trim().startsWith('|')) {
          String tableLine = lines[currentLine].trim();

          // 跳过分隔行
          if (tableLine.contains('-')) {
            currentLine++;
            continue;
          }

          // 简单的分割处理
          List<String> cells = tableLine
              .split('|')
              .where((cell) => cell.trim().isNotEmpty)
              .map((cell) => cell.trim())
              .toList();

          if (cells.isNotEmpty) {
            tableData.add(cells);
          }

          currentLine++;
        }

        if (tableData.isNotEmpty) {
          widgets.add(Container(
            margin: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: BoxDecoration(
              color: baseStyle.color?.withOpacity(0.05) ??
                  Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: baseStyle.color?.withOpacity(0.1) ??
                    Colors.grey.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: baseStyle.color?.withOpacity(0.1) ??
                        Colors.grey.withOpacity(0.1),
                    width: 0.5,
                  ),
                  verticalInside: BorderSide(
                    color: baseStyle.color?.withOpacity(0.1) ??
                        Colors.grey.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                children: [
                  // 表头
                  if (tableData.isNotEmpty)
                    TableRow(
                      decoration: BoxDecoration(
                        color: baseStyle.color?.withOpacity(0.1) ??
                            Colors.grey.withOpacity(0.1),
                      ),
                      children: tableData[0]
                          .map((cell) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 6.0),
                                child: Text(
                                  cell,
                                  style: baseStyle.copyWith(
                                      fontWeight: FontWeight.w600),
                                ),
                              ))
                          .toList(),
                    ),
                  // 数据行
                  ...tableData.skip(1).map((row) => TableRow(
                        children: row
                            .map((cell) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 6.0),
                                  child: Text(cell, style: baseStyle),
                                ))
                            .toList(),
                      )),
                ],
              ),
            ),
          ));

          i = currentLine - 1;
          continue;
        }
      }

      // 处理分割线
      if (RegExp(r'^\s*---+\s*$').hasMatch(line)) {
        if (currentLineSpans.isNotEmpty) {
          widgets.add(RichText(
            text: TextSpan(children: currentLineSpans),
          ));
          currentLineSpans = [];
        }
        widgets.add(Semantics(
          label: '分割线',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              height: 1,
              color: baseStyle.color?.withOpacity(0.2),
            ),
          ),
        ));
        continue;
      }

      // 处理无序列表
      if (line.startsWith('- ') || line.startsWith('* ')) {
        if (currentLineSpans.isNotEmpty) {
          widgets.add(RichText(
            text: TextSpan(children: currentLineSpans),
          ));
          currentLineSpans = [];
        }

        String listItemContent =
            line.substring(line.indexOf(line[0]) + 1).trim();
        List<TextSpan> listItemSpans =
            _processInlineFormats(listItemContent, baseStyle);

        widgets.add(Semantics(
          label: '列表项: $listItemContent',
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6.0, right: 8.0),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: baseStyle.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(children: listItemSpans),
                  ),
                ),
              ],
            ),
          ),
        ));
        continue;
      }

      // 处理代码块
      if (line.startsWith('```')) {
        if (currentLineSpans.isNotEmpty) {
          widgets.add(RichText(
            text: TextSpan(children: currentLineSpans),
          ));
          currentLineSpans = [];
        }

        int endIndex = -1;
        StringBuffer codeContent = StringBuffer();
        String language = line.substring(3).trim();

        for (int j = i + 1; j < lines.length; j++) {
          if (lines[j].trim() == '```') {
            endIndex = j;
            break;
          }
          if (codeContent.isNotEmpty) codeContent.write('\n');
          codeContent.write(lines[j]);
        }

        if (endIndex != -1) {
          widgets.add(Semantics(
            label: '代码块${language.isNotEmpty ? ': $language' : ''}',
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
                        if (language.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                            child: Text(
                              language.toUpperCase(),
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
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.8,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              child: Text(
                                codeContent.toString(),
                                style: baseStyle.copyWith(
                                  height: 1.5,
                                  letterSpacing: 0.5,
                                ),
                              ),
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
          i = endIndex;
          continue;
        }
      }

      // 处理普通行内格式
      currentLineSpans.addAll(_processInlineFormats(line, baseStyle));
      if (i < lines.length - 1) {
        currentLineSpans.add(TextSpan(text: '\n'));
      }
    }

    // 添加剩余的spans
    if (currentLineSpans.isNotEmpty) {
      widgets.add(RichText(
        text: TextSpan(children: currentLineSpans),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  List<TextSpan> _processInlineFormats(String text, TextStyle baseStyle) {
    List<TextSpan> spans = [];
    int lastEnd = 0;

    // 按优先级处理不同的格式组合
    RegExp inlinePattern = RegExp(
      r'(\*\*\*.*?\*\*\*)|' // 加粗斜体 ***text***
      r'(\*\*.*?\*\*)|' // 加粗 **text**
      r'(\*.*?\*)|' // 斜体 *text*
      r'(~~.*?~~)|' // 删除线 ~~text~~
      r'(`.*?`)', // 行内代码 `text`
      multiLine: true,
    );

    Iterable<Match> matches = inlinePattern.allMatches(text);

    for (Match match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      String matchedText = match.group(0) ?? '';
      if (matchedText.length >= 2) {
        if (matchedText.startsWith('***') &&
            matchedText.endsWith('***') &&
            matchedText.length > 6) {
          // 加粗斜体
          spans.add(TextSpan(
            text: matchedText.substring(3, matchedText.length - 3),
            style: baseStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ));
        } else if (matchedText.startsWith('**') &&
            matchedText.endsWith('**') &&
            matchedText.length > 4) {
          // 加粗
          spans.add(TextSpan(
            text: matchedText.substring(2, matchedText.length - 2),
            style: baseStyle.copyWith(fontWeight: FontWeight.bold),
          ));
        } else if (matchedText.startsWith('*') &&
            matchedText.endsWith('*') &&
            matchedText.length > 2) {
          // 斜体
          spans.add(TextSpan(
            text: matchedText.substring(1, matchedText.length - 1),
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ));
        } else if (matchedText.startsWith('~~') &&
            matchedText.endsWith('~~') &&
            matchedText.length > 4) {
          // 删除线
          spans.add(TextSpan(
            text: matchedText.substring(2, matchedText.length - 2),
            style: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
          ));
        } else if (matchedText.startsWith('`') &&
            matchedText.endsWith('`') &&
            matchedText.length > 2) {
          // 行内代码
          spans.add(TextSpan(
            text: ' ${matchedText.substring(1, matchedText.length - 1)} ',
            style: baseStyle.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 0.3,
              height: 1.2,
              backgroundColor: baseStyle.color?.withOpacity(0.08) ??
                  Colors.grey.withOpacity(0.08),
              color: baseStyle.color?.withOpacity(0.9) ??
                  Colors.grey.withOpacity(0.9),
            ),
          ));
        } else {
          spans.add(TextSpan(
            text: matchedText,
            style: baseStyle,
          ));
        }
      } else {
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle,
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
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
