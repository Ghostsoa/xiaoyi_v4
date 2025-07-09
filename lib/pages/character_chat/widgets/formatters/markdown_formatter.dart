import 'package:flutter/material.dart';
import 'dart:ui';
import 'base_formatter.dart';
import 'dart:math' as math;

class MarkdownFormatter extends BaseFormatter {
  // 正则表达式匹配常见的 Emoji Unicode 范围
  static final RegExp _emojiRegex = RegExp(
    r'^([\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{FE0F}\u{200D}\u{1F900}-\u{1F9FF}]+)?\s*(.*)$',
    unicode: true,
  );

  // 辅助函数：提取Emoji和标签
  // 规则:
  // 1. "emoji标签" -> emoji:"emoji", label:"标签" (emoji和标签之间无空格)
  // 2. "emoji" -> emoji:"emoji", label:""
  // 3. "标签" -> emoji:"", label:"标签"
  // 4. "emoji 标签" -> emoji:"", label:"emoji 标签" (emoji和标签之间有空格，视为一个整体标签)
  Map<String, String> _extractEmojiAndLabel(String text) {
    String trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return {'emoji': '', 'label': ''};
    }

    final match = _emojiRegex.firstMatch(trimmedText);

    if (match != null) {
      String potentialEmoji = match.group(1) ?? '';
      String potentialLabel = match.group(2) ?? '';

      if (potentialEmoji.isNotEmpty) {
        // If an emoji is found, check if there's a space immediately after it in the original trimmed text.
        // We need to see what was captured by \s* between the emoji and the label.
        // A robust way is to check the character in trimmedText right after potentialEmoji.
        if (trimmedText.length > potentialEmoji.length &&
            trimmedText[potentialEmoji.length] == ' ') {
          // There is a space immediately after the emoji, so it's not a valid emoji+label combo by the new rule.
          // Treat the whole thing as a label.
          return {'emoji': '', 'label': trimmedText};
        } else {
          // No space immediately after emoji, or it's just emoji (potentialLabel would be empty or not start with space here)
          return {'emoji': potentialEmoji, 'label': potentialLabel.trim()};
        }
      } else {
        // No emoji was matched by group(1).
        // Check if the potentialLabel (which is effectively trimmedText here if group(1) is empty)
        // is itself a pure emoji.
        if (potentialLabel.isNotEmpty && _isPurelyEmoji(potentialLabel)) {
          return {'emoji': potentialLabel, 'label': ''};
        }
        // Otherwise, the whole thing is a label.
        return {'emoji': '', 'label': potentialLabel.trim()};
      }
    } else {
      // Should not happen with the current regex (due to (.*)), but as a fallback:
      return {'emoji': '', 'label': trimmedText};
    }
  }

  // 辅助函数，判断字符串是否完全由定义的Emoji字符组成
  bool _isPurelyEmoji(String text) {
    if (text.isEmpty) return false;
    // 这个正则只匹配Emoji字符，且从头到尾都是Emoji
    final RegExp emojiOnlyRegex = RegExp(
      r'^([\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{FE0F}\u{200D}\u{1F900}-\u{1F9FF}]+)$',
      unicode: true,
    );
    return emojiOnlyRegex.hasMatch(text);
  }

  // 新增辅助函数：判断单元格文本是否像App图标组件
  bool _isAppLikeCell(String cellText) {
    if (cellText.isEmpty) return false;

    final extracted = _extractEmojiAndLabel(cellText);
    String emoji = extracted['emoji']!;
    String label = extracted['label']!;

    if (emoji.isNotEmpty) {
      if (label.isNotEmpty) {
        // Emoji 存在，如果标签也存在，标签长度不宜过长
        return label.runes.length <= 12;
      }
      return true; // 只有 Emoji 也可以
    } else {
      // 没有 Emoji，则标签必须存在且短
      if (label.isNotEmpty) {
        // 允许的标签最大长度（无emoji时）
        // 并且标签本身不应包含多个连续空格 (单个空格允许，如 "App Name")
        return label.runes.length <= 10 && !label.contains('  ');
      }
    }
    return false;
  }

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

        // 检查是否是手机UI表格的特殊标记
        if (lines[i].trim().contains('| MOCK_PHONE_UI |')) {
          List<String> phoneLines = [];
          int currentPhoneLine = i;
          while (currentPhoneLine < lines.length &&
              lines[currentPhoneLine].trim().startsWith('|')) {
            phoneLines.add(lines[currentPhoneLine].trim());
            currentPhoneLine++;
          }

          if (phoneLines.isNotEmpty) {
            widgets.add(_buildPhoneUi(context, phoneLines, baseStyle));
            i = currentPhoneLine - 1;
            continue;
          }
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

  // 新增方法：构建手机UI界面
  Widget _buildPhoneUi(
      BuildContext context, List<String> lines, TextStyle baseStyle) {
    if (lines.isEmpty) return const SizedBox.shrink();

    // 提取状态栏、内容和导航栏的行
    List<String> firstLineCells = lines.first.split('|');
    String statusBarText =
        (firstLineCells.length > 2) ? firstLineCells[2].trim() : ' ';

    List<String> lastLineCells = lines.last.split('|');
    String bottomNavBarText =
        (lastLineCells.length > 1) ? lastLineCells[1].trim() : ' ';

    List<String> contentLines = lines.sublist(1, lines.length - 1);
    // 过滤掉分隔符行
    contentLines
        .removeWhere((line) => line.contains('---') || line.contains('==='));

    // --- 开始修改 appGridData 生成逻辑 ---
    const int maxSingleSpaceGridItems = 5; // 单空格分隔时，一行中App图标的最大数量
    List<List<String>> appGridData = []; // 使用 appGridData 作为最终变量名

    for (String line in contentLines) {
      if (line.startsWith('|') && line.endsWith('|')) {
        String innerContent = line.substring(1, line.length - 1).trim();
        if (innerContent.isEmpty) continue;

        List<String> cellsForThisRow;

        // 1. 尝试按2个或更多空格分割
        List<String> multiSpaceCells = innerContent
            .split(RegExp(r'\s{2,}'))
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList();

        if (multiSpaceCells.length > 1) {
          cellsForThisRow = multiSpaceCells;
        } else {
          // 2. 未被双空格成功分割，检查是否为显式列表项
          if (innerContent.startsWith('- ') ||
              innerContent.startsWith('* ') ||
              RegExp(r'^\d+\.\s+').hasMatch(innerContent)) {
            cellsForThisRow = [innerContent]; // 视为单个列表项
          } else {
            // 3. 非显式列表项，尝试按单个空格分割，并检查是否像App图标组
            List<String> singleSpaceCells = innerContent
                .split(RegExp(r'\s+'))
                .map((c) => c.trim())
                .where((c) => c.isNotEmpty)
                .toList();

            if (singleSpaceCells.length > 1 &&
                singleSpaceCells.length <= maxSingleSpaceGridItems) {
              bool allCellsAppLike = true;
              for (String cellCandidate in singleSpaceCells) {
                if (!_isAppLikeCell(cellCandidate)) {
                  allCellsAppLike = false;
                  break;
                }
              }
              if (allCellsAppLike) {
                cellsForThisRow = singleSpaceCells; // 视为App图标网格行
              } else {
                cellsForThisRow = [innerContent]; // 不像App图标组，视为单个列表项
              }
            } else {
              // 单空格分割后仍为单个单元格，或单元格过多
              cellsForThisRow = [innerContent]; // 视为单个列表项
            }
          }
        }
        if (cellsForThisRow.isNotEmpty) {
          appGridData.add(cellsForThisRow);
        }
      }
    }
    // --- 结束修改 appGridData 生成逻辑 ---

    // 获取屏幕宽度，用于计算手机容器宽度
    double screenWidth = MediaQuery.of(context).size.width;
    // 计算合适的手机容器宽度，设置为屏幕宽度的75%，或最小280像素
    double phoneWidth = math.max(screenWidth * 0.75, 280.0);
    // 计算手机容器高度，保持合理的长宽比，比如16:9或18:9
    double phoneHeight = phoneWidth * 2.0; // 更高的手机，大约2倍宽度

    return Semantics(
      label: '手机界面模拟',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        padding: const EdgeInsets.all(4.0),
        width: phoneWidth, // 设置更宽的手机容器宽度
        height: phoneHeight, // 设置更高的手机容器高度
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(30.0),
          border: Border.all(color: Colors.grey[800]!, width: 8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.0),
          child: Container(
            color: Colors.grey[900], // 手机屏幕背景色
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 状态栏
                _buildPhoneStatusBar(statusBarText, baseStyle),
                // 内容区域 - 使用Expanded让内容区域填充剩余空间
                Expanded(
                  child:
                      _buildPhoneContentArea(context, appGridData, baseStyle),
                ),
                // 底部导航栏
                _buildPhoneBottomNavBar(bottomNavBarText, baseStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStatusBar(String text, TextStyle baseStyle) {
    List<String> parts = text
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList(); // 按一个或多个空格分割

    Widget statusBarContent;

    if (parts.length >= 3) {
      // 如果有3个或更多部分，取第一个、中间所有、最后一个
      String leftPart = parts.first;
      String rightPart = parts.last;
      String centerPart = parts.sublist(1, parts.length - 1).join(' ');
      statusBarContent = Row(
        children: [
          Text(leftPart,
              style: _statusTextStyle(baseStyle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const Spacer(),
          if (centerPart.isNotEmpty)
            Text(centerPart,
                style: _statusTextStyle(baseStyle),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(rightPart,
              style: _statusTextStyle(baseStyle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      );
    } else if (parts.length == 2) {
      // 如果有2个部分，左边一个，右边一个
      statusBarContent = Row(
        children: [
          Text(parts.first,
              style: _statusTextStyle(baseStyle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(parts.last,
              style: _statusTextStyle(baseStyle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      );
    } else {
      // 如果只有1个或0个部分，则居中显示原始文本
      statusBarContent = Text(
        text,
        style: _statusTextStyle(baseStyle),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      color: Colors.transparent,
      child: statusBarContent,
    );
  }

  // 辅助方法获取状态栏文本样式
  TextStyle _statusTextStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      color: Colors.white.withOpacity(0.8),
      fontSize: baseStyle.fontSize! * 0.8,
    );
  }

  // 新增方法：决定渲染 Grid 还是 List
  Widget _buildPhoneContentArea(BuildContext context,
      List<List<String>> contentData, TextStyle baseStyle) {
    if (contentData.isEmpty) {
      // 如果没有有效的appGridData内容行，可以默认使用空的AppGrid或特定提示
      // 或者根据场景决定是更像空列表还是空网格
      return _buildPhoneAppGrid(context, [], baseStyle);
    }

    bool preferListView = true; // 默认列表视图
    for (var row in contentData) {
      if (row.length > 1) {
        preferListView = false; // 一旦发现有多单元格的行，就切换到网格视图
        break;
      }
    }
    // 特殊处理：如果只有一行，且这一行也只有一个单元格，但内容非常短，可能还是Grid更好看？
    // 例如 |  अकेला | (Hindi for alone/single) -> Grid (single large icon)
    // 但为了处理 | 📱💬💌 | 后跟列表的情况，优先List。
    // 只有当 preferListView 仍然是 false (即检测到多cell行)时，才用Grid

    if (preferListView) {
      return _buildPhoneContentList(context, contentData, baseStyle);
    } else {
      return _buildPhoneAppGrid(context, contentData, baseStyle);
    }
  }

  // 新增方法：构建手机UI的列表内容
  Widget _buildPhoneContentList(
      BuildContext context, List<List<String>> listData, TextStyle baseStyle) {
    List<Widget> listItems = [];
    // 定义列表项的基础文本样式，移除isTitleLike相关的特定样式
    final TextStyle listItemStyle = baseStyle.copyWith(
        color: Colors.white.withOpacity(0.85), // 统一颜色透明度
        fontWeight: FontWeight.normal, // 统一字重
        fontSize: baseStyle.fontSize! * 0.85 // 统一字体大小
        );

    for (int i = 0; i < listData.length; i++) {
      var rowCells = listData[i];
      if (rowCells.isEmpty || rowCells.first.isEmpty) continue;

      String textContent = rowCells.first; // 每行只有一个单元格，取其内容

      listItems.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: RichText(
          // 使用 RichText 替换 Text 以支持内联Markdown格式
          text: TextSpan(
            children: _processInlineFormats(textContent, listItemStyle),
            style: listItemStyle,
          ),
          textAlign: TextAlign.left, // 确保文本左对齐
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
      ));
      if (i < listData.length - 1) {
        listItems.add(Divider(
            color: Colors.grey[800],
            height: 0.5,
            thickness: 0.5,
            indent: 16,
            endIndent: 16)); // 调整分隔线颜色和缩进
      }
    }

    if (listItems.isEmpty) {
      return Center(
        child: Text(
          '列表为空',
          style: baseStyle.copyWith(color: Colors.grey[600]),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, // 确保内容左对齐
        children: listItems,
      ),
    );
  }

  Widget _buildPhoneAppGrid(
      BuildContext context, List<List<String>> gridData, TextStyle baseStyle) {
    if (gridData.isEmpty) {
      return Center(
        child: Text(
          '无应用内容',
          style: baseStyle.copyWith(color: Colors.grey[600]),
        ),
      );
    }
    // 固定为3列
    const int crossAxisCount = 3;

    List<Widget> appIcons = [];
    for (var row in gridData) {
      for (var cell in row) {
        if (cell.isNotEmpty) {
          final extracted = _extractEmojiAndLabel(cell);
          String emoji = extracted['emoji']!;
          String label = extracted['label']!;

          appIcons.add(Semantics(
            label: '应用图标: $label',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style:
                      TextStyle(fontSize: baseStyle.fontSize! * 1.8), // 放大emoji
                ),
                const SizedBox(height: 4.0),
                Text(
                  label,
                  style: baseStyle.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: baseStyle.fontSize! * 0.75,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ));
        } else {
          // 如果单元格为空，则添加一个占位符，以保持网格对齐
          appIcons.add(const SizedBox.shrink());
        }
      }
    }
    // 如果appIcons为空，则显示提示
    if (appIcons.isEmpty) {
      return Center(
        child: Text(
          '无应用内容',
          style: baseStyle.copyWith(color: Colors.grey[600]),
        ),
      );
    }

    // 创建网格布局，使用GridView确保一行显示3个应用图标
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: GridView.count(
        crossAxisCount: crossAxisCount, // 固定3列
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 20.0,
        childAspectRatio: 0.85, // 控制图标的长宽比
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // 禁用滚动
        children: appIcons,
      ),
    );
  }

  Widget _buildPhoneBottomNavBar(String text, TextStyle baseStyle) {
    // 将文本按空格分割，每个部分作为一个图标/标签
    // 注意：这里的分割逻辑需要调整，因为一个导航项可能包含空格，如 "信息 (未读)"
    // 我们应该先按 Markdown 表格的 | 分割，这里传入的 text 已经是单个导航区域的完整文本
    // 例如："通话记录 📱信息(未读) 🌐浏览器 📸相机"
    // 我们需要根据视觉上的分隔（可能是多个空格）或固定数量来拆分导航项
    // 为了简化，我们假设导航项之间用至少一个空格分隔
    List<String> navItemStrings =
        text.split(RegExp(r'\s+')).where((item) => item.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          top: BorderSide(color: Colors.grey[700]!, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: navItemStrings.map((itemString) {
          // 使用新的辅助函数提取 emoji 和 label
          final extracted = _extractEmojiAndLabel(itemString);
          String emoji = extracted['emoji']!;
          String label = extracted['label']!;

          return Flexible(
            child: Semantics(
              label: '导航项: $label',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emoji.isNotEmpty)
                    Text(
                      emoji,
                      style: TextStyle(
                          fontSize: baseStyle.fontSize! * 1.5,
                          color: Colors.white.withOpacity(0.8)),
                    ),
                  if (emoji.isNotEmpty && label.isNotEmpty)
                    const SizedBox(height: 2.0),
                  if (label.isNotEmpty)
                    Text(
                      label,
                      style: baseStyle.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: baseStyle.fontSize! * 0.7,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
