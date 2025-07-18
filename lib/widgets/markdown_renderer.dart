import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

class MarkdownRenderer extends StatelessWidget {
  final String markdownText;
  final TextStyle? defaultStyle;
  final Color? linkColor;
  final TextAlign textAlign;
  final Function(String)? onLinkTap;

  const MarkdownRenderer({
    super.key,
    required this.markdownText,
    this.defaultStyle,
    this.linkColor,
    this.textAlign = TextAlign.left,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = defaultStyle ??
        TextStyle(
          fontSize: 14.sp,
          color: AppTheme.textPrimary,
          height: 1.5,
        );

    // 解析Markdown文本
    final List<Widget> widgets = _parseMarkdown(
      context,
      markdownText,
      baseStyle,
      linkColor ?? AppTheme.primaryColor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  List<Widget> _parseMarkdown(
    BuildContext context,
    String text,
    TextStyle baseStyle,
    Color linkColor,
  ) {
    // 按行分割文本
    final List<String> lines = text.split('\n');
    final List<Widget> widgets = [];
    List<String> currentListItems = [];
    bool inCodeBlock = false;
    List<String> codeBlockLines = [];
    String codeLanguage = '';

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      final String trimmed = line.trim();

      // 处理空行
      if (trimmed.isEmpty) {
        if (currentListItems.isNotEmpty) {
          widgets.add(_buildList(currentListItems, baseStyle));
          currentListItems = [];
        }
        continue;
      }

      // 处理代码块
      if (trimmed.startsWith('```')) {
        if (inCodeBlock) {
          // 结束代码块
          widgets.add(_buildCodeBlock(
              codeBlockLines.join('\n'), codeLanguage, context, baseStyle));
          codeBlockLines = [];
          inCodeBlock = false;
          codeLanguage = '';
        } else {
          // 开始代码块
          inCodeBlock = true;
          codeLanguage = trimmed.length > 3 ? trimmed.substring(3).trim() : '';
          if (currentListItems.isNotEmpty) {
            widgets.add(_buildList(currentListItems, baseStyle));
            currentListItems = [];
          }
        }
        continue;
      }

      if (inCodeBlock) {
        codeBlockLines.add(line);
        continue;
      }

      // 处理标题 (# 标题)
      if (trimmed.startsWith('#')) {
        if (currentListItems.isNotEmpty) {
          widgets.add(_buildList(currentListItems, baseStyle));
          currentListItems = [];
        }

        int level = 1;
        String title = trimmed.substring(1).trim();

        // 判断标题级别 (### 对应 h3)
        while (level < 6 && title.startsWith('#')) {
          level++;
          title = title.substring(1).trim();
        }

        widgets.add(_buildHeading(title, level, baseStyle));
        continue;
      }

      // 处理引用块
      if (trimmed.startsWith('> ')) {
        if (currentListItems.isNotEmpty) {
          widgets.add(_buildList(currentListItems, baseStyle));
          currentListItems = [];
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

        widgets.add(_buildQuoteBlock(quoteContent.toString(), baseStyle));
        i = currentLine - 1;
        continue;
      }

      // 处理分割线
      if (RegExp(r'^\s*---+\s*$').hasMatch(trimmed)) {
        if (currentListItems.isNotEmpty) {
          widgets.add(_buildList(currentListItems, baseStyle));
          currentListItems = [];
        }
        widgets.add(_buildDivider(baseStyle));
        continue;
      }

      // 处理表格
      if (trimmed.startsWith('|') &&
          i + 1 < lines.length &&
          lines[i + 1].trim().startsWith('|')) {
        if (currentListItems.isNotEmpty) {
          widgets.add(_buildList(currentListItems, baseStyle));
          currentListItems = [];
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
          widgets.add(_buildTable(tableData, baseStyle));
          i = currentLine - 1;
          continue;
        }
      }

      // 处理无序列表
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        currentListItems.add(trimmed.substring(2).trim());
        continue;
      }

      // 处理有序列表项 (1. 列表项)
      final orderedListRegex = RegExp(r'^\d+\.\s');
      if (orderedListRegex.hasMatch(trimmed)) {
        final listItemContent =
            trimmed.replaceFirst(orderedListRegex, '').trim();
        currentListItems.add(listItemContent);
        continue;
      }

      // 处理普通段落
      if (currentListItems.isNotEmpty) {
        widgets.add(_buildList(currentListItems, baseStyle));
        currentListItems = [];
      }

      widgets.add(_buildParagraph(line, baseStyle, linkColor));
    }

    // 处理最后的列表项
    if (currentListItems.isNotEmpty) {
      widgets.add(_buildList(currentListItems, baseStyle));
    }

    // 处理最后的代码块
    if (inCodeBlock && codeBlockLines.isNotEmpty) {
      widgets.add(_buildCodeBlock(
          codeBlockLines.join('\n'), codeLanguage, context, baseStyle));
    }

    return widgets;
  }

  Widget _buildHeading(String text, int level, TextStyle baseStyle) {
    // 基于标题级别设置文字大小
    double fontSize;
    FontWeight weight = FontWeight.bold;

    switch (level) {
      case 1:
        fontSize = 24.sp;
        break;
      case 2:
        fontSize = 20.sp;
        break;
      case 3:
        fontSize = 18.sp;
        break;
      case 4:
        fontSize = 16.sp;
        break;
      case 5:
        fontSize = 14.sp;
        break;
      case 6:
        fontSize = 12.sp;
        break;
      default:
        fontSize = 14.sp;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Text.rich(
        _buildTextSpans(
            text,
            baseStyle.copyWith(
              fontSize: fontSize,
              fontWeight: weight,
            ),
            baseStyle.color!.withOpacity(0.7)),
        textAlign: textAlign,
      ),
    );
  }

  Widget _buildParagraph(String text, TextStyle baseStyle, Color linkColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Text.rich(
        _buildTextSpans(text, baseStyle, linkColor),
        textAlign: textAlign,
      ),
    );
  }

  Widget _buildList(List<String> items, TextStyle baseStyle) {
    List<Widget> listItems = [];

    for (int i = 0; i < items.length; i++) {
      listItems.add(
        Padding(
          padding: EdgeInsets.only(left: 16.w, bottom: 6.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 6.h, right: 8.w),
                child: Container(
                  width: 4.w,
                  height: 4.w,
                  decoration: BoxDecoration(
                    color: baseStyle.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text.rich(
                  _buildTextSpans(items[i], baseStyle, AppTheme.primaryColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: listItems,
    );
  }

  Widget _buildDivider(TextStyle baseStyle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Container(
        height: 1,
        color: baseStyle.color?.withOpacity(0.2),
      ),
    );
  }

  Widget _buildQuoteBlock(String text, TextStyle baseStyle) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseStyle.color?.withOpacity(0.08) ?? Colors.grey.withOpacity(0.08),
            baseStyle.color?.withOpacity(0.04) ?? Colors.grey.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color:
              baseStyle.color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
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
              width: 3.w,
              margin: EdgeInsets.only(right: 12.w),
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
                borderRadius: BorderRadius.circular(1.5.r),
              ),
            ),
            Expanded(
              child: Text.rich(
                _buildTextSpans(
                  text,
                  baseStyle.copyWith(
                    fontStyle: FontStyle.italic,
                    color: baseStyle.color?.withOpacity(0.85),
                    height: 1.6,
                    letterSpacing: 0.3,
                  ),
                  AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeBlock(
      String code, String language, BuildContext context, TextStyle baseStyle) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseStyle.color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
            baseStyle.color?.withOpacity(0.05) ?? Colors.grey.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: baseStyle.color?.withOpacity(0.1) ??
                    Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (language.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
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
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: SelectableText(
                      code,
                      style: baseStyle.copyWith(
                        height: 1.5,
                        letterSpacing: 0.5,
                        fontFamily: 'monospace',
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

  Widget _buildTable(List<List<String>> tableData, TextStyle baseStyle) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color:
            baseStyle.color?.withOpacity(0.05) ?? Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color:
              baseStyle.color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 6.h),
                          child: Text(
                            cell,
                            style:
                                baseStyle.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ))
                    .toList(),
              ),
            // 数据行
            ...tableData.skip(1).map((row) => TableRow(
                  children: row
                      .map((cell) => Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 6.h),
                            child: Text(cell, style: baseStyle),
                          ))
                      .toList(),
                )),
          ],
        ),
      ),
    );
  }

  TextSpan _buildTextSpans(String text, TextStyle style, Color linkColor) {
    // 处理文本中的内联样式，如粗体、斜体、链接等

    // 加粗斜体: ***text*** 或 ___text___
    final boldItalicRegex = RegExp(r'\*\*\*(.*?)\*\*\*|___(.*?)___');

    // 粗体: **text** 或 __text__
    final boldRegex = RegExp(r'\*\*(.*?)\*\*|__(.*?)__');

    // 斜体: *text* 或 _text_
    final italicRegex = RegExp(r'\*(.*?)\*|_(.*?)_');

    // 删除线: ~~text~~
    final strikethroughRegex = RegExp(r'~~(.*?)~~');

    // 链接: [text](url)
    final linkRegex = RegExp(r'\[(.*?)\]\((.*?)\)');

    // 行内代码: `code`
    final codeRegex = RegExp(r'`(.*?)`');

    List<TextSpan> spans = [];
    String remaining = text;

    while (remaining.isNotEmpty) {
      // 查找最近的匹配
      int? boldItalicIndex = _findFirstMatch(boldItalicRegex, remaining);
      int? boldIndex = _findFirstMatch(boldRegex, remaining);
      int? italicIndex = _findFirstMatch(italicRegex, remaining);
      int? strikethroughIndex = _findFirstMatch(strikethroughRegex, remaining);
      int? linkIndex = _findFirstMatch(linkRegex, remaining);
      int? codeIndex = _findFirstMatch(codeRegex, remaining);

      int? firstIndex = _minNonNullIndex([
        boldItalicIndex,
        boldIndex,
        italicIndex,
        strikethroughIndex,
        linkIndex,
        codeIndex
      ]);

      if (firstIndex == null || firstIndex == -1) {
        // 没有找到任何特殊格式
        spans.add(TextSpan(text: remaining, style: style));
        break;
      }

      if (firstIndex > 0) {
        // 添加格式之前的纯文本
        spans.add(
            TextSpan(text: remaining.substring(0, firstIndex), style: style));
      }

      if (firstIndex == boldItalicIndex) {
        // 处理加粗斜体
        final match = boldItalicRegex.firstMatch(remaining)!;
        final content = match.group(1) ?? match.group(2) ?? '';
        spans.add(TextSpan(
          text: content,
          style: style.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ));
        remaining = remaining.substring(match.end);
      } else if (firstIndex == boldIndex) {
        // 处理粗体
        final match = boldRegex.firstMatch(remaining)!;
        final content = match.group(1) ?? match.group(2) ?? '';
        spans.add(TextSpan(
          text: content,
          style: style.copyWith(fontWeight: FontWeight.bold),
        ));
        remaining = remaining.substring(match.end);
      } else if (firstIndex == italicIndex) {
        // 处理斜体
        final match = italicRegex.firstMatch(remaining)!;
        final content = match.group(1) ?? match.group(2) ?? '';
        spans.add(TextSpan(
          text: content,
          style: style.copyWith(fontStyle: FontStyle.italic),
        ));
        remaining = remaining.substring(match.end);
      } else if (firstIndex == strikethroughIndex) {
        // 处理删除线
        final match = strikethroughRegex.firstMatch(remaining)!;
        final content = match.group(1) ?? '';
        spans.add(TextSpan(
          text: content,
          style: style.copyWith(decoration: TextDecoration.lineThrough),
        ));
        remaining = remaining.substring(match.end);
      } else if (firstIndex == linkIndex) {
        // 处理链接
        final match = linkRegex.firstMatch(remaining)!;
        final text = match.group(1) ?? '';
        final url = match.group(2) ?? '';
        spans.add(TextSpan(
          text: text,
          style: style.copyWith(
            color: linkColor,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (onLinkTap != null) {
                onLinkTap!(url);
              }
            },
        ));
        remaining = remaining.substring(match.end);
      } else if (firstIndex == codeIndex) {
        // 处理行内代码
        final match = codeRegex.firstMatch(remaining)!;
        final code = match.group(1) ?? '';
        spans.add(TextSpan(
          text: code,
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor:
                style.color?.withOpacity(0.08) ?? Colors.grey.withOpacity(0.08),
            letterSpacing: 0.3,
            height: 1.2,
            fontSize: style.fontSize,
            color:
                style.color?.withOpacity(0.9) ?? Colors.grey.withOpacity(0.9),
          ),
        ));
        remaining = remaining.substring(match.end);
      }
    }

    return TextSpan(children: spans);
  }

  int? _findFirstMatch(RegExp regex, String text) {
    final match = regex.firstMatch(text);
    return match?.start;
  }

  int? _minNonNullIndex(List<int?> indices) {
    final validIndices = indices.where((i) => i != null).cast<int>();
    return validIndices.isEmpty
        ? null
        : validIndices.reduce((a, b) => a < b ? a : b);
  }
}
