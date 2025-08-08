import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:typed_data';
import 'base_formatter.dart';
import '../../../../services/file_service.dart';
import '../../../../utils/resource_mapping_parser.dart';

class MarkdownFormatter extends BaseFormatter {
  // 选项选中状态回调
  final Function(String groupId, String title, List<String> selectedOptions)? onOptionsChanged;
  // 资源映射字符串（预留给 role 标签解析使用）
  final String? resourceMapping;

  MarkdownFormatter({this.onOptionsChanged, this.resourceMapping});

  // 自定义标签配置
  static const Map<String, Map<String, dynamic>> _customTagConfigs = {
    'status_on': {
      'defaultTitle': '状态栏',
      'defaultExpanded': true,
      'titleAlignment': 'left',
      'containerType': 'status',
    },
    'status_off': {
      'defaultTitle': '状态栏',
      'defaultExpanded': false,
      'titleAlignment': 'left',
      'containerType': 'status',
    },
    'archive': {
      'defaultTitle': '档案',
      'defaultExpanded': false,
      'titleAlignment': 'center',
      'containerType': 'archive',
    },
    'options_h': {
      'defaultTitle': '选项',
      'defaultExpanded': false,
      'titleAlignment': 'center',
      'containerType': 'options_horizontal',
    },
    'options_v': {
      'defaultTitle': '选项',
      'defaultExpanded': false,
      'titleAlignment': 'center',
      'containerType': 'options_vertical',
    },
    'notebook': {
      'defaultTitle': '记事本',
      'defaultExpanded': false,
      'titleAlignment': 'left',
      'containerType': 'notebook',
    },
    'role': {
      'defaultTitle': '角色',
      'defaultExpanded': true,
      'titleAlignment': 'left',
      'containerType': 'role',
    },
  };

  @override
  Widget format(BuildContext context, String text, TextStyle baseStyle) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    // 首先检查是否包含自定义标签
    List<Widget> customTagWidgets = _parseCustomTags(context, text, baseStyle);
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

  // 解析自定义标签
  List<Widget> _parseCustomTags(BuildContext context, String text, TextStyle baseStyle) {
    List<Widget> widgets = [];

    // 创建正则表达式匹配所有支持的自定义标签
    String tagPattern = _customTagConfigs.keys.join('|');
    RegExp customTagRegex = RegExp(
      r'<(' + tagPattern + r')(?:\s+name="([^"]*)")?\s*>(.*?)</\1>',
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
          widgets.add(_formatMarkdownOnly(context, beforeText, baseStyle, isInCustomTag: false));
        }
      }

      String tagName = match.group(1)!;
      String? nameAttribute = match.group(2);
      String content = match.group(3) ?? '';

      // 构建自定义标签组件
      Widget customWidget = _buildCustomTagWidget(
        context,
        tagName,
        nameAttribute,
        content,
        baseStyle,
      );
      widgets.add(customWidget);

      lastEnd = match.end;
    }

    // 添加最后剩余的文本
    if (lastEnd < text.length) {
      String remainingText = text.substring(lastEnd).trim();
      if (remainingText.isNotEmpty) {
        widgets.add(_formatMarkdownOnly(context, remainingText, baseStyle, isInCustomTag: false));
      }
    }

    return widgets;
  }

  // 解析嵌套的自定义标签（支持有限深度）
  List<Widget> _parseCustomTagsNested(BuildContext context, String text, TextStyle baseStyle, int nestingDepth) {
    List<Widget> widgets = [];

    // 创建正则表达式匹配所有支持的自定义标签
    String tagPattern = _customTagConfigs.keys.join('|');
    RegExp customTagRegex = RegExp(
      r'<(' + tagPattern + r')(?:\s+name="([^"]*)")?\s*>(.*?)</\1>',
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
          widgets.add(_formatMarkdownOnly(context, beforeText, baseStyle, isInCustomTag: true, allowNestedTags: false));
        }
      }

      String tagName = match.group(1)!;
      String? nameAttribute = match.group(2);
      String content = match.group(3) ?? '';

      // 构建嵌套的自定义标签组件
      Widget customWidget = _buildCustomTagWidgetNested(
        context,
        tagName,
        nameAttribute,
        content,
        baseStyle,
        nestingDepth,
      );
      widgets.add(customWidget);

      lastEnd = match.end;
    }

    // 添加最后剩余的文本
    if (lastEnd < text.length) {
      String remainingText = text.substring(lastEnd).trim();
      if (remainingText.isNotEmpty) {
        widgets.add(_formatMarkdownOnly(context, remainingText, baseStyle, isInCustomTag: true, allowNestedTags: false));
      }
    }

    return widgets;
  }

  // 处理markdown格式，支持可控的自定义标签嵌套
  Widget _formatMarkdownOnly(BuildContext context, String text, TextStyle baseStyle, {bool isInCustomTag = false, bool allowNestedTags = false, int nestingDepth = 0}) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    // 如果允许嵌套标签且嵌套深度未超限，先尝试解析自定义标签
    if (allowNestedTags && nestingDepth < 3) {
      List<Widget> nestedTagWidgets = _parseCustomTagsNested(context, text, baseStyle, nestingDepth + 1);
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
            margin: EdgeInsets.symmetric(vertical: isInCustomTag ? 4.0 : 12.0),
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

  // 构建嵌套的自定义标签组件
  Widget _buildCustomTagWidgetNested(
    BuildContext context,
    String tagName,
    String? nameAttribute,
    String content,
    TextStyle baseStyle,
    int nestingDepth,
  ) {
    Map<String, dynamic> config = _customTagConfigs[tagName]!;
    String containerType = config['containerType'];

    // 选项标签使用独立设计
    if (containerType.startsWith('options_')) {
      String title = nameAttribute?.isNotEmpty == true
          ? nameAttribute!
          : config['defaultTitle'];
      return _buildOptionsWidget(context, title, content, containerType, baseStyle);
    }

    // 记事本标签使用独立设计
    if (containerType == 'notebook') {
      String title = nameAttribute?.isNotEmpty == true
          ? nameAttribute!
          : config['defaultTitle'];
      return _buildNotebookWidget(context, title, content, baseStyle);
    }

    // 角色标签使用独立设计
    if (containerType == 'role') {
      String roleName = nameAttribute?.isNotEmpty == true
          ? nameAttribute!
          : '未知角色';
      return _buildRoleWidget(context, roleName, content, baseStyle);
    }

    // 其他标签使用可折叠容器（支持嵌套）
    String title = nameAttribute?.isNotEmpty == true
        ? nameAttribute!
        : config['defaultTitle'];
    bool defaultExpanded = config['defaultExpanded'];
    String titleAlignment = config['titleAlignment'];

    return _buildCollapsibleContainer(
      context,
      title,
      content,
      defaultExpanded,
      titleAlignment,
      containerType,
      baseStyle,
    );
  }

  // 构建自定义标签组件
  Widget _buildCustomTagWidget(
    BuildContext context,
    String tagName,
    String? nameAttribute,
    String content,
    TextStyle baseStyle,
  ) {
    Map<String, dynamic> config = _customTagConfigs[tagName]!;
    String containerType = config['containerType'];

    // 选项标签使用独立设计
    if (containerType.startsWith('options_')) {
      String title = nameAttribute?.isNotEmpty == true
          ? nameAttribute!
          : config['defaultTitle'];
      return _buildOptionsWidget(context, title, content, containerType, baseStyle);
    }

    // 记事本标签使用独立设计
    if (containerType == 'notebook') {
      String title = nameAttribute?.isNotEmpty == true
          ? nameAttribute!
          : config['defaultTitle'];
      return _buildNotebookWidget(context, title, content, baseStyle);
    }

    // 角色标签使用独立设计
    if (containerType == 'role') {
      String roleName = nameAttribute?.isNotEmpty == true
          ? nameAttribute!
          : '未知角色';
      return _buildRoleWidget(context, roleName, content, baseStyle);
    }

    // 其他标签使用可折叠容器
    String title = nameAttribute?.isNotEmpty == true
        ? nameAttribute!
        : config['defaultTitle'];
    bool defaultExpanded = config['defaultExpanded'];
    String titleAlignment = config['titleAlignment'];

    return _buildCollapsibleContainer(
      context,
      title,
      content,
      defaultExpanded,
      titleAlignment,
      containerType,
      baseStyle,
    );
  }

  // 构建可折叠容器 - 毛玻璃版本
  Widget _buildCollapsibleContainer(
    BuildContext context,
    String title,
    String content,
    bool defaultExpanded,
    String titleAlignment,
    String containerType,
    TextStyle baseStyle,
  ) {
    return _CollapsibleContainer(
      title: title,
      content: content,
      defaultExpanded: defaultExpanded,
      titleAlignment: titleAlignment,
      containerType: containerType,
      baseStyle: baseStyle,
      formatter: this,
    );
  }

  // 构建独立的选项组件（优雅设计）
  Widget _buildOptionsWidget(BuildContext context, String title, String content, String containerType, TextStyle baseStyle) {
    List<String> options = _parseOptions(content);
    // 使用标题和容器类型作为唯一标识，避免重复创建
    String groupId = '${title}_${containerType}';

    return _OptionsWidget(
      groupId: groupId,
      title: title,
      options: options,
      containerType: containerType,
      baseStyle: baseStyle,
      onOptionsChanged: onOptionsChanged,
      formatter: this,
    );
  }

  // 构建选项内容
  Widget _buildOptionsContent(BuildContext context, String content, String containerType, TextStyle baseStyle) {
    // 解析选项内容，提取 <option> 标签
    List<String> options = _parseOptions(content);

    if (options.isEmpty) {
      return Text(
        '暂无选项',
        style: baseStyle.copyWith(
          color: baseStyle.color?.withOpacity(0.6),
          fontSize: baseStyle.fontSize! * 0.9,
        ),
      );
    }

    if (containerType == 'options_horizontal') {
      return _buildHorizontalOptions(options, baseStyle);
    } else {
      return _buildVerticalOptions(options, baseStyle);
    }
  }

  // 解析选项标签
  List<String> _parseOptions(String content) {
    RegExp optionRegex = RegExp(r'<option>(.*?)</option>', multiLine: true, dotAll: true);
    Iterable<Match> matches = optionRegex.allMatches(content);
    return matches.map((match) => match.group(1)?.trim() ?? '').where((option) => option.isNotEmpty).toList();
  }

  // 构建水平滚动选项
  Widget _buildHorizontalOptions(List<String> options, TextStyle baseStyle) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.asMap().entries.map((entry) {
          int index = entry.key;
          String option = entry.value;
          return Container(
            margin: EdgeInsets.only(right: index < options.length - 1 ? 8.0 : 0),
            child: _buildOptionButton(option, baseStyle),
          );
        }).toList(),
      ),
    );
  }

  // 构建垂直列表选项
  Widget _buildVerticalOptions(List<String> options, TextStyle baseStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options.asMap().entries.map((entry) {
        int index = entry.key;
        String option = entry.value;
        return Container(
          margin: EdgeInsets.only(bottom: index < options.length - 1 ? 6.0 : 0),
          child: _buildOptionButton(option, baseStyle),
        );
      }).toList(),
    );
  }

  // 构建优雅的选项按钮
  Widget _buildOptionButton(String option, TextStyle baseStyle) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // 这里可以添加选项点击逻辑
          debugPrint('选项被点击: $option');
        },
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseStyle.color?.withOpacity(0.06) ?? Colors.grey.withOpacity(0.06),
                baseStyle.color?.withOpacity(0.03) ?? Colors.grey.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: baseStyle.color?.withOpacity(0.15) ?? Colors.grey.withOpacity(0.15),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: _processInlineFormats(
                option,
                baseStyle.copyWith(
                  fontSize: baseStyle.fontSize! * 0.95,
                  fontWeight: FontWeight.w500,
                  color: baseStyle.color?.withOpacity(0.85),
                  letterSpacing: 0.2,
                ),
              ),
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
        ),
      ),
    );
  }

  // 构建记事本组件（独立设计，记事本风格）
  Widget _buildNotebookWidget(BuildContext context, String title, String content, TextStyle baseStyle) {
    return _NotebookWidget(
      title: title,
      content: content,
      baseStyle: baseStyle,
      formatter: this,
    );
  }

  // 构建角色组件（独立设计，角色对话风格）
  Widget _buildRoleWidget(BuildContext context, String roleName, String content, TextStyle baseStyle) {
    // 解析资源映射为 Map<Name, Uri>
    final Map<String, String> nameToUri = {};
    if ((resourceMapping ?? '').trim().isNotEmpty) {
      for (final r in ResourceMappingParser.parseResourceMappings(resourceMapping!)) {
        nameToUri[r.name] = r.uri;
      }
    }

    return _RoleWidget(
      roleName: roleName,
      content: content,
      baseStyle: baseStyle,
      formatter: this,
      nameToUri: nameToUri,
    );
  }

  // 处理角色内容，识别心理活动标签
  Widget _formatRoleContent(BuildContext context, String content, TextStyle baseStyle) {
    // 查找心理活动标签 <thought>...</thought>
    RegExp thoughtRegex = RegExp(r'<thought>(.*?)</thought>', multiLine: true, dotAll: true);

    List<Widget> widgets = [];
    int lastEnd = 0;

    Iterable<Match> matches = thoughtRegex.allMatches(content);

    for (Match match in matches) {
      // 添加心理活动前的普通内容
      if (match.start > lastEnd) {
        String beforeText = content.substring(lastEnd, match.start).trim();
        if (beforeText.isNotEmpty) {
          widgets.add(_formatMarkdownOnly(context, beforeText, baseStyle, isInCustomTag: true, allowNestedTags: true));
        }
      }

      // 添加心理活动内容（特殊样式，无容器）
      String thoughtContent = match.group(1)?.trim() ?? '';
      if (thoughtContent.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _formatMarkdownOnly(
            context,
            thoughtContent,
            baseStyle.copyWith(
              color: baseStyle.color?.withOpacity(0.6), // 基于配置颜色的浅色版本
              fontStyle: FontStyle.italic, // 斜体显示
              fontSize: baseStyle.fontSize! * 0.9, // 稍小字体
              decoration: TextDecoration.underline, // 下划线，表示特殊
              decorationColor: baseStyle.color?.withOpacity(0.3), // 基于配置颜色的更浅版本
              decorationStyle: TextDecorationStyle.dotted, // 点状下划线
            ),
            isInCustomTag: true,
            allowNestedTags: true
          ),
        ));
      }

      lastEnd = match.end;
    }

    // 添加最后剩余的内容
    if (lastEnd < content.length) {
      String remainingText = content.substring(lastEnd).trim();
      if (remainingText.isNotEmpty) {
        widgets.add(_formatMarkdownOnly(context, remainingText, baseStyle, isInCustomTag: true, allowNestedTags: true));
      }
    }

    // 如果没有找到心理活动标签，直接返回格式化的内容
    if (widgets.isEmpty) {
      return _formatMarkdownOnly(context, content, baseStyle, isInCustomTag: true, allowNestedTags: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

// 独立的选项组件，管理选中状态
class _OptionsWidget extends StatefulWidget {
  final String groupId;
  final String title;
  final List<String> options;
  final String containerType;
  final TextStyle baseStyle;
  final Function(String groupId, String title, List<String> selectedOptions)? onOptionsChanged;
  final MarkdownFormatter formatter;

  const _OptionsWidget({
    required this.groupId,
    required this.title,
    required this.options,
    required this.containerType,
    required this.baseStyle,
    this.onOptionsChanged,
    required this.formatter,
  });

  @override
  State<_OptionsWidget> createState() => _OptionsWidgetState();
}

class _OptionsWidgetState extends State<_OptionsWidget> {
  Set<String> selectedOptions = <String>{};

  void _toggleOption(String option) {
    setState(() {
      if (selectedOptions.contains(option)) {
        selectedOptions.remove(option);
      } else {
        selectedOptions.add(option);
      }
    });

    // 通知父组件选项变化
    widget.onOptionsChanged?.call(
      widget.groupId,
      widget.title,
      selectedOptions.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 优雅的标题
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.title,
              style: widget.baseStyle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: widget.baseStyle.fontSize! * 1.1,
                color: widget.baseStyle.color?.withOpacity(0.9),
              ),
            ),
          ),
          // 选项内容
          if (widget.options.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '暂无选项',
                style: widget.baseStyle.copyWith(
                  color: widget.baseStyle.color?.withOpacity(0.6),
                  fontSize: widget.baseStyle.fontSize! * 0.9,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            widget.containerType == 'options_horizontal'
                ? _buildHorizontalOptions()
                : _buildVerticalOptions(),
        ],
      ),
    );
  }

  // 构建水平滚动选项
  Widget _buildHorizontalOptions() {
    return SizedBox(
      height: 40.0, // 减小固定高度，让按钮有更好的比例
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero, // 移除默认内边距
        itemCount: widget.options.length,
        itemBuilder: (context, index) {
          String option = widget.options[index];
          bool isSelected = selectedOptions.contains(option);
          return Container(
            margin: EdgeInsets.only(right: index < widget.options.length - 1 ? 8.0 : 0),
            child: _buildOptionButton(option, isSelected),
          );
        },
      ),
    );
  }

  // 构建垂直滚动选项
  Widget _buildVerticalOptions() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200.0),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero, // 移除默认内边距
        itemCount: widget.options.length,
        itemBuilder: (context, index) {
          String option = widget.options[index];
          bool isSelected = selectedOptions.contains(option);
          return Container(
            margin: EdgeInsets.only(bottom: index < widget.options.length - 1 ? 6.0 : 0),
            child: _buildOptionButton(option, isSelected),
          );
        },
      ),
    );
  }

  // 构建选项按钮（支持选中状态）- 优化版本
  Widget _buildOptionButton(String option, bool isSelected) {
    // 根据容器类型决定样式
    bool isHorizontal = widget.containerType == 'options_horizontal';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleOption(option),
          borderRadius: BorderRadius.circular(12.0),
          splashColor: widget.baseStyle.color?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
          highlightColor: widget.baseStyle.color?.withOpacity(0.05) ?? Colors.blue.withOpacity(0.05),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: isSelected ? 8 : 6,
                  sigmaY: isSelected ? 8 : 6
                ),
                child: Container(
                  padding: isHorizontal
                      ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0)   // 水平选项：增加内边距
                      : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // 垂直选项：更舒适的内边距
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isSelected
                          ? [
                              widget.baseStyle.color?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
                              widget.baseStyle.color?.withOpacity(0.2) ?? Colors.blue.withOpacity(0.2),
                              widget.baseStyle.color?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                            ]
                          : [
                              widget.baseStyle.color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                              widget.baseStyle.color?.withOpacity(0.06) ?? Colors.grey.withOpacity(0.06),
                              widget.baseStyle.color?.withOpacity(0.03) ?? Colors.grey.withOpacity(0.03),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isSelected
                          ? widget.baseStyle.color?.withOpacity(0.6) ?? Colors.blue.withOpacity(0.6)
                          : widget.baseStyle.color?.withOpacity(0.25) ?? Colors.grey.withOpacity(0.25),
                      width: isSelected ? 1.5 : 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? widget.baseStyle.color?.withOpacity(0.15) ?? Colors.blue.withOpacity(0.15)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: isSelected ? 10 : 6,
                        offset: Offset(0, isSelected ? 4 : 2),
                        spreadRadius: isSelected ? 1 : 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: widget.baseStyle.copyWith(
                        fontSize: widget.baseStyle.fontSize! * (isSelected ? 0.95 : 0.9),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? widget.baseStyle.color?.withOpacity(0.95)
                            : widget.baseStyle.color?.withOpacity(0.85),
                        letterSpacing: isSelected ? 0.3 : 0.1,
                        height: 1.0,
                      ),
                      child: RichText(
                        textAlign: isHorizontal ? TextAlign.center : TextAlign.left,
                        text: TextSpan(
                          children: widget.formatter._processInlineFormats(
                            option,
                            widget.baseStyle.copyWith(
                              fontSize: widget.baseStyle.fontSize! * (isSelected ? 0.95 : 0.9),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? widget.baseStyle.color?.withOpacity(0.95)
                                  : widget.baseStyle.color?.withOpacity(0.85),
                              letterSpacing: isSelected ? 0.3 : 0.1,
                              height: 1.0,
                            ),
                          ),
                        ),
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}

// 独立的可折叠容器组件
class _CollapsibleContainer extends StatefulWidget {
  final String title;
  final String content;
  final bool defaultExpanded;
  final String titleAlignment;
  final String containerType;
  final TextStyle baseStyle;
  final MarkdownFormatter formatter;

  const _CollapsibleContainer({
    required this.title,
    required this.content,
    required this.defaultExpanded,
    required this.titleAlignment,
    required this.containerType,
    required this.baseStyle,
    required this.formatter,
  });

  @override
  State<_CollapsibleContainer> createState() => _CollapsibleContainerState();
}

class _CollapsibleContainerState extends State<_CollapsibleContainer>
    with SingleTickerProviderStateMixin {
  late bool isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.defaultExpanded;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 380),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _iconRotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(_expandAnimation);

    if (isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool _isStatusCollapsed =
        widget.containerType == 'status' && !isExpanded;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      // 根据展开状态和容器类型决定宽度
      width: (widget.containerType == 'status' && !isExpanded) ? null : double.infinity,
      child: (_isStatusCollapsed)
          ? Align(
              alignment: Alignment.centerLeft,
              child: IntrinsicWidth(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.baseStyle.color?.withOpacity(0.08) ?? Colors.grey.withOpacity(0.08),
                            widget.baseStyle.color?.withOpacity(0.04) ?? Colors.grey.withOpacity(0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: widget.baseStyle.color?.withOpacity(0.15) ?? Colors.grey.withOpacity(0.15),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 小巧的标题栏（带动画）
                          InkWell(
                            onTap: _toggleExpanded,
                            borderRadius: BorderRadius.circular(12.0),
                            splashColor: widget.baseStyle.color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                            highlightColor: widget.baseStyle.color?.withOpacity(0.05) ?? Colors.grey.withOpacity(0.05),
                            child: Container(
                              // 根据容器类型和展开状态决定宽度
                              width: (widget.containerType == 'status' && !isExpanded) ? null : double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              child: Row(
                                mainAxisSize: (widget.containerType == 'status' && !isExpanded)
                                    ? MainAxisSize.min
                                    : MainAxisSize.max,
                                children: [
                                  // 标题文本和箭头的布局
                                  if (widget.titleAlignment == 'center' && (isExpanded || widget.containerType != 'status')) ...[
                                    // 档案类型：居中布局，同时显示上下箭头
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            widget.title,
                                            style: widget.baseStyle.copyWith(
                                              fontWeight: FontWeight.w500,
                                              fontSize: widget.baseStyle.fontSize! * 0.85,
                                              color: widget.baseStyle.color?.withOpacity(0.8),
                                            ),
                                          ),
                                          const SizedBox(width: 4.0),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Transform.translate(
                                                offset: const Offset(0, 2),
                                                child: Icon(
                                                  Icons.keyboard_arrow_up,
                                                  size: 12,
                                                  color: widget.baseStyle.color?.withOpacity(0.6),
                                                ),
                                              ),
                                              Transform.translate(
                                                offset: const Offset(0, -2),
                                                child: Icon(
                                                  Icons.keyboard_arrow_down,
                                                  size: 12,
                                                  color: widget.baseStyle.color?.withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    // 状态栏类型：左对齐布局，箭头在标题前面（带旋转动画）
                                    AnimatedBuilder(
                                      animation: _iconRotationAnimation,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle: _iconRotationAnimation.value * 3.14159, // 90度旋转
                                          child: Icon(
                                            Icons.keyboard_arrow_right,
                                            size: 16,
                                            color: widget.baseStyle.color?.withOpacity(0.6),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      widget.title,
                                      style: widget.baseStyle.copyWith(
                                        fontWeight: FontWeight.w500,
                                        fontSize: widget.baseStyle.fontSize! * 0.85,
                                        color: widget.baseStyle.color?.withOpacity(0.8),
                                      ),
                                    ),
                                    if (isExpanded || widget.containerType != 'status') const Spacer(),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          // 内容区域（带展开动画）
                          SizeTransition(
                            sizeFactor: _expandAnimation,
                            child: FadeTransition(
                              opacity: _expandAnimation,
                              child: Container(
                                width: double.infinity,
                                padding: widget.containerType == 'status'
                                    ? const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0)
                                    : const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
                                child: widget.containerType.startsWith('options_')
                                    ? widget.formatter._buildOptionsContent(context, widget.content, widget.containerType, widget.baseStyle)
                                    : widget.formatter._formatMarkdownOnly(context, widget.content, widget.baseStyle, isInCustomTag: true, allowNestedTags: true),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.baseStyle.color?.withOpacity(0.08) ?? Colors.grey.withOpacity(0.08),
                  widget.baseStyle.color?.withOpacity(0.04) ?? Colors.grey.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: widget.baseStyle.color?.withOpacity(0.15) ?? Colors.grey.withOpacity(0.15),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
          // 小巧的标题栏（带动画）
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(12.0),
            splashColor: widget.baseStyle.color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
            highlightColor: widget.baseStyle.color?.withOpacity(0.05) ?? Colors.grey.withOpacity(0.05),
            child: Container(
              // 根据容器类型和展开状态决定宽度
              width: (widget.containerType == 'status' && !isExpanded) ? null : double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                mainAxisSize: (widget.containerType == 'status' && !isExpanded)
                    ? MainAxisSize.min
                    : MainAxisSize.max,
                children: [
                  // 标题文本和箭头的布局
                  if (widget.titleAlignment == 'center' && (isExpanded || widget.containerType != 'status')) ...[
                    // 档案类型：居中布局，同时显示上下箭头
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: widget.baseStyle.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: widget.baseStyle.fontSize! * 0.85,
                              color: widget.baseStyle.color?.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.translate(
                                offset: const Offset(0, 2),
                                child: Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 12,
                                  color: widget.baseStyle.color?.withOpacity(0.6),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(0, -2),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 12,
                                  color: widget.baseStyle.color?.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // 状态栏类型：左对齐布局，箭头在标题前面（带旋转动画）
                    AnimatedBuilder(
                      animation: _iconRotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _iconRotationAnimation.value * 3.14159, // 90度旋转
                          child: Icon(
                            Icons.keyboard_arrow_right,
                            size: 16,
                            color: widget.baseStyle.color?.withOpacity(0.6),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      widget.title,
                      style: widget.baseStyle.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: widget.baseStyle.fontSize! * 0.85,
                        color: widget.baseStyle.color?.withOpacity(0.8),
                      ),
                    ),
                    if (isExpanded || widget.containerType != 'status') const Spacer(),
                  ],
                ],
              ),
            ),
          ),
          // 内容区域（带展开动画）
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: Container(
                width: double.infinity,
                padding: widget.containerType == 'status'
                    ? const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0)
                    : const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
                child: widget.containerType.startsWith('options_')
                    ? widget.formatter._buildOptionsContent(context, widget.content, widget.containerType, widget.baseStyle)
                    : widget.formatter._formatMarkdownOnly(context, widget.content, widget.baseStyle, isInCustomTag: true, allowNestedTags: true),
              ),
            ),
          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 独立的记事本组件，记事本风格设计，可折叠
class _NotebookWidget extends StatefulWidget {
  final String title;
  final String content;
  final TextStyle baseStyle;
  final MarkdownFormatter formatter;

  const _NotebookWidget({
    required this.title,
    required this.content,
    required this.baseStyle,
    required this.formatter,
  });

  @override
  State<_NotebookWidget> createState() => _NotebookWidgetState();
}

class _NotebookWidgetState extends State<_NotebookWidget>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false; // 默认折叠
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _iconRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            decoration: BoxDecoration(
              // 跟随外层气泡颜色的柔和背景
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (widget.baseStyle.color ?? Colors.grey).withOpacity(0.08),
                  (widget.baseStyle.color ?? Colors.grey).withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: (widget.baseStyle.color ?? Colors.grey).withOpacity(0.15),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // 记事本标题栏（可点击折叠，带动画）
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12.0),
              topRight: Radius.circular(12.0),
            ),
            splashColor: (widget.baseStyle.color ?? Colors.black)
                .withOpacity(0.06),
            highlightColor: (widget.baseStyle.color ?? Colors.black)
                .withOpacity(0.03),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.zero,
                border: Border(
                  bottom: BorderSide(
                    color: (widget.baseStyle.color ?? Colors.grey).withOpacity(0.15),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 折叠箭头（带旋转动画）
                  AnimatedBuilder(
                    animation: _iconRotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _iconRotationAnimation.value * 3.14159, // 90度旋转
                        child: Icon(
                          Icons.keyboard_arrow_right,
                          size: 16,
                          color: (widget.baseStyle.color ?? Colors.black)
                              .withOpacity(0.6),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4.0),
                  // 记事本图标
                  Icon(
                    Icons.note_alt_outlined,
                    size: 16,
                    color: (widget.baseStyle.color ?? Colors.black)
                        .withOpacity(0.6),
                  ),
                  const SizedBox(width: 6.0),
                  // 动态标题（支持name属性）
                  Text(
                    widget.title,
                    style: widget.baseStyle
                        .copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: widget.baseStyle.fontSize! * 0.95,
                          color: (widget.baseStyle.color ?? Colors.black)
                              .withOpacity(0.85),
                          letterSpacing: 0.4,
                        )
                        .merge(const TextStyle(overflow: TextOverflow.ellipsis)),
                  ),
                  const Spacer(),
                  // 右侧保持留白，去除多余装饰
                ],
              ),
            ),
          ),
          // 记事本内容区域（带展开动画）
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 16.0),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12.0),
                    bottomRight: Radius.circular(12.0),
                  ),
                ),
                child: _buildNotebookContent(),
              ),
            ),
          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建记事本内容，每行都有横线
  Widget _buildNotebookContent() {
    // 计算内容的行数
    String content = widget.content.trim();
    List<String> lines = content.split('\n');
    int contentLines = lines.length;

    // 至少显示3行，最多根据内容决定
    int totalLines = contentLines < 3 ? 3 : contentLines + 1; // 多加一行留白

    const double lineHeight = 24.0; // 每行的高度

    return SizedBox(
      height: totalLines * lineHeight,
      child: Stack(
        children: [
          // 背景横线（使用自定义绘制，减少层级）
          _buildNotebookLines(totalLines, lineHeight),
          // 内容文本，与横线对齐
          Positioned(
            top: 0.0, // 从顶部开始
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0), // 微调内边距，让第一行文字坐在第一条横线上
              child: widget.formatter._formatMarkdownOnly(
                context,
                widget.content,
                widget.baseStyle.copyWith(
                  color: (widget.baseStyle.color ?? Colors.black)
                      .withOpacity(0.9),
                  fontSize: widget.baseStyle.fontSize! * 0.95,
                  height: lineHeight / (widget.baseStyle.fontSize! * 0.95), // 精确计算行高，与横线对齐
                ),
                isInCustomTag: true,
                allowNestedTags: true
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建记事本的横线背景
  Widget _buildNotebookLines(int lineCount, double lineHeight) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _NotebookLinesPainter(
          lineCount: lineCount,
          lineHeight: lineHeight,
          lineColor: (widget.baseStyle.color ?? Colors.grey).withOpacity(0.12),
          lineWidth: 0.8,
        ),
      ),
    );
  }
}

// 记事本横线的自定义绘制器
class _NotebookLinesPainter extends CustomPainter {
  final int lineCount;
  final double lineHeight;
  final Color lineColor;
  final double lineWidth;

  _NotebookLinesPainter({
    required this.lineCount,
    required this.lineHeight,
    required this.lineColor,
    required this.lineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth;

    double y = lineHeight;
    // 从第一条横线开始绘制到底部
    while (y < size.height + 0.5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += lineHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _NotebookLinesPainter oldDelegate) {
    return oldDelegate.lineCount != lineCount ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.lineWidth != lineWidth;
  }
}

// 独立的角色组件，整体容器风格设计
class _RoleWidget extends StatelessWidget {
  final String roleName;
  final String content;
  final TextStyle baseStyle;
  final MarkdownFormatter formatter;
  final Map<String, String> nameToUri;

  const _RoleWidget({
    required this.roleName,
    required this.content,
    required this.baseStyle,
    required this.formatter,
    required this.nameToUri,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              // 角色对话毛玻璃背景
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseStyle.color?.withOpacity(0.06) ?? Colors.grey.withOpacity(0.06),
                  baseStyle.color?.withOpacity(0.03) ?? Colors.grey.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: baseStyle.color?.withOpacity(0.12) ?? Colors.grey.withOpacity(0.12),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // 左侧：立绘头像和名字（从资源映射加载图片）
          _RoleAvatar(nameToUri: nameToUri, roleName: roleName, baseStyle: baseStyle),
          const SizedBox(width: 16.0),
          // 右侧：对话内容区域（默认三行高度）
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                minHeight: baseStyle.fontSize! * 1.4 * 3, // 默认三行高度
              ),
              child: formatter._formatRoleContent(
                context,
                content,
                baseStyle.copyWith(
                  // 使用配置的字体颜色，而不是固定颜色
                  color: baseStyle.color, // 跟随ui_settings_page.dart的字体颜色配置
                  fontSize: baseStyle.fontSize! * 0.95,
                  height: 1.4,
                ),
              ),
            ),
          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleAvatar extends StatefulWidget {
  final Map<String, String> nameToUri;
  final String roleName;
  final TextStyle baseStyle;

  const _RoleAvatar({
    required this.nameToUri,
    required this.roleName,
    required this.baseStyle,
  });

  @override
  State<_RoleAvatar> createState() => _RoleAvatarState();
}

class _RoleAvatarState extends State<_RoleAvatar> {
  final FileService _fileService = FileService();
  Uint8List? _imageBytes;
  bool _loading = false;
  String? _currentUri; // 跟踪当前使用的URI，避免无谓重载
  static final Map<String, Uint8List> _memoryCache = <String, Uint8List>{}; // 简单内存缓存

  @override
  void initState() {
    super.initState();
    _currentUri = widget.nameToUri[widget.roleName];
    _maybeLoad();
  }

  @override
  void didUpdateWidget(covariant _RoleAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 仅当角色名变化或对应的URI发生变化时才重新加载
    final String? newUri = widget.nameToUri[widget.roleName];
    if (oldWidget.roleName != widget.roleName || newUri != _currentUri) {
      _currentUri = newUri;
      // 当URI发生变化时，清空旧图像并尝试加载新图像
      setState(() {
        _imageBytes = null;
      });
      _maybeLoad();
    }
  }

  Future<void> _maybeLoad() async {
    final String? uri = _currentUri ?? widget.nameToUri[widget.roleName];
    if (uri == null || uri.isEmpty) return;
    if (_loading) return;

    // 命中内存缓存则直接使用，避免闪烁
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
        // 写入内存缓存
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
        borderRadius: BorderRadius.circular(8.0),
        child: Image.memory(
          _imageBytes!,
          width: 60.0,
          height: 80.0,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
      );
    } else if (noMapping) {
      // 没有找到资源映射时的占位提示
      avatar = Container(
        width: 60.0,
        height: 80.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fallbackStart, fallbackEnd],
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              '无法找到资源映射',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    } else {
      avatar = Container(
        width: 60.0,
        height: 80.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fallbackStart, fallbackEnd],
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Text(
            widget.roleName.isNotEmpty ? widget.roleName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        avatar,
        const SizedBox(height: 6.0),
        Container(
          constraints: const BoxConstraints(maxWidth: 70),
          child: Text(
            widget.roleName,
            style: widget.baseStyle.copyWith(
              fontSize: widget.baseStyle.fontSize! * 0.8,
              color: widget.baseStyle.color?.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
