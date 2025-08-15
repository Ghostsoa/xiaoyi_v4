import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'base_formatter.dart';
import 'custom_tags/custom_tag_parser.dart';

class MarkdownFormatter extends BaseFormatter {
  // 选项选中状态回调
  final Function(String groupId, String title, List<String> selectedOptions)? onOptionsChanged;
  // 资源映射字符串（预留给 role 标签解析使用）
  final String? resourceMapping;

  MarkdownFormatter({this.onOptionsChanged, this.resourceMapping});



  @override
  Widget format(BuildContext context, String text, TextStyle baseStyle) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    // 首先检查是否包含自定义标签
    List<Widget> customTagWidgets = CustomTagParser.parseCustomTags(context, text, baseStyle, this);
    if (customTagWidgets.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: customTagWidgets,
      );
    }

    List<Widget> widgets = [];
    List<String> lines = text.split('\n');
    List<TextSpan> currentLineSpans = [];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      // 处理标题 (# 标题)
      if (line.startsWith('#')) {
        if (currentLineSpans.isNotEmpty) {
          widgets.add(RichText(
            text: TextSpan(children: currentLineSpans),
          ));
          currentLineSpans = [];
        }

        int level = 1;
        String title = line.substring(1).trim();

        // 判断标题级别 (### 对应 h3)
        while (level < 6 && title.startsWith('#')) {
          level++;
          title = title.substring(1).trim();
        }

        widgets.add(_buildHeading(title, level, baseStyle));
        continue;
      }

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
            margin: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (baseStyle.color ?? Colors.black).withOpacity(0.08),
                  (baseStyle.color ?? Colors.black).withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: (baseStyle.color ?? Colors.black).withOpacity(0.12),
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: (baseStyle.color ?? Colors.black).withOpacity(0.12),
                      width: 0.5,
                    ),
                    verticalInside: BorderSide(
                      color: (baseStyle.color ?? Colors.black).withOpacity(0.12),
                      width: 0.5,
                    ),
                  ),
                  children: [
                    // 表头
                    if (tableData.isNotEmpty)
                      TableRow(
                        decoration: BoxDecoration(
                          color: (baseStyle.color ?? Colors.black)
                              .withOpacity(0.06),
                        ),
                        children: tableData[0]
                          .map((cell) => Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 8.h),
                                child: Text(
                                  cell,
                                  style: baseStyle.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  // 数据行
                  ...tableData.skip(1).map((row) => TableRow(
                        children: row
                            .map((cell) => Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 8.h),
                                  child: Text(
                                    cell,
                                    style: baseStyle,
                                  ),
                                ))
                            .toList(),
                      )),
                ],
              ), // Table 结束
            ), // SingleChildScrollView 结束
          ), // ClipRRect 结束
        )); // Container 结束
        
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
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text('•', style: baseStyle),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(children: listItemSpans),
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
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
                            child: Text(
                              codeContent.toString(),
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



  // 处理markdown格式，支持可控的自定义标签嵌套
  Widget _formatMarkdownOnly(BuildContext context, String text, TextStyle baseStyle, {bool isInCustomTag = false, bool allowNestedTags = false, int nestingDepth = 0}) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    // 如果允许嵌套标签且嵌套深度未超限，先尝试解析自定义标签
    if (allowNestedTags && nestingDepth < 3) {
      List<Widget> nestedTagWidgets = CustomTagParser.parseCustomTags(context, text, baseStyle, this);
      if (nestedTagWidgets.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: nestedTagWidgets,
        );
      }
    }

    List<Widget> widgets = [];
    List<String> lines = text.split('\n');
    List<TextSpan> currentLineSpans = [];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      // 处理标题 (# 标题)
      if (line.startsWith('#')) {
        if (currentLineSpans.isNotEmpty) {
          widgets.add(RichText(
            text: TextSpan(children: currentLineSpans),
          ));
          currentLineSpans = [];
        }

        int level = 1;
        String title = line.substring(1).trim();

        // 判断标题级别 (### 对应 h3)
        while (level < 6 && title.startsWith('#')) {
          level++;
          title = title.substring(1).trim();
        }

        widgets.add(_buildHeading(title, level, baseStyle));
        continue;
      }

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
            margin: EdgeInsets.symmetric(vertical: isInCustomTag ? 4.0 : 12.0),
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
            margin: EdgeInsets.symmetric(vertical: isInCustomTag ? 4.h : 12.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (baseStyle.color ?? Colors.black).withOpacity(0.08),
                  (baseStyle.color ?? Colors.black).withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: (baseStyle.color ?? Colors.black).withOpacity(0.12),
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: (baseStyle.color ?? Colors.black).withOpacity(0.12),
                      width: 0.5,
                    ),
                    verticalInside: BorderSide(
                      color: (baseStyle.color ?? Colors.black).withOpacity(0.12),
                      width: 0.5,
                    ),
                  ),
                  children: [
                    // 表头
                    if (tableData.isNotEmpty)
                      TableRow(
                        decoration: BoxDecoration(
                          color: (baseStyle.color ?? Colors.black)
                              .withOpacity(0.06),
                        ),
                        children: tableData[0]
                          .map((cell) => Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 8.h),
                                child: Text(
                                  cell,
                                  style: baseStyle.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  // 数据行
                  ...tableData.skip(1).map((row) => TableRow(
                        children: row
                            .map((cell) => Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 8.h),
                                  child: Text(
                                    cell,
                                    style: baseStyle,
                                  ),
                                ))
                            .toList(),
                      )),
                ],
              ), // Table 结束
            ), // SingleChildScrollView 结束
          ), // ClipRRect 结束
        )); // Container 结束

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
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text('•', style: baseStyle),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(children: listItemSpans),
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
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
              margin: EdgeInsets.symmetric(vertical: isInCustomTag ? 4.0 : 12.0),
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
                            child: Text(
                              codeContent.toString(),
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

  // 为新组件提供的公共方法：处理markdown格式，支持可控的自定义标签嵌套
  Widget formatMarkdownOnly(BuildContext context, String text, TextStyle baseStyle, {bool isInCustomTag = false, bool allowNestedTags = false, int nestingDepth = 0}) {
    return _formatMarkdownOnly(context, text, baseStyle, isInCustomTag: isInCustomTag, allowNestedTags: allowNestedTags, nestingDepth: nestingDepth);
  }

  // 为新组件提供的公共方法：处理内联格式
  List<TextSpan> processInlineFormats(String text, TextStyle baseStyle) {
    return _processInlineFormats(text, baseStyle);
  }

  // 为选项组件提供构建选项内容的方法
  Widget buildOptionsContent(BuildContext context, String content, String containerType, TextStyle baseStyle) {
    return formatMarkdownOnly(context, content, baseStyle, isInCustomTag: true, allowNestedTags: true);
  }

  /// 构建标题组件
  Widget _buildHeading(String title, int level, TextStyle baseStyle) {
    double fontSize;
    FontWeight fontWeight;

    switch (level) {
      case 1:
        fontSize = baseStyle.fontSize! * 1.8;
        fontWeight = FontWeight.w700;
        break;
      case 2:
        fontSize = baseStyle.fontSize! * 1.5;
        fontWeight = FontWeight.w600;
        break;
      case 3:
        fontSize = baseStyle.fontSize! * 1.3;
        fontWeight = FontWeight.w600;
        break;
      case 4:
        fontSize = baseStyle.fontSize! * 1.1;
        fontWeight = FontWeight.w500;
        break;
      case 5:
        fontSize = baseStyle.fontSize! * 1.0;
        fontWeight = FontWeight.w500;
        break;
      default:
        fontSize = baseStyle.fontSize! * 0.9;
        fontWeight = FontWeight.w400;
        break;
    }

    return Semantics(
      label: '标题 $level: $title',
      child: Padding(
        padding: EdgeInsets.only(
          top: level <= 2 ? 16.0 : 12.0,
          bottom: level <= 2 ? 8.0 : 6.0,
        ),
        child: Text(
          title,
          style: baseStyle.copyWith(
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
