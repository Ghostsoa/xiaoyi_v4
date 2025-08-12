import 'package:flutter/material.dart';
import 'dart:ui';
import 'base_custom_tag.dart';
import '../../../../../dao/chat_settings_dao.dart';

/// 选项标签组件
class OptionsWidget extends BaseCustomTag {
  final bool horizontal;

  OptionsWidget({required this.horizontal});

  @override
  String get tagName => horizontal ? 'options_h' : 'options_v';

  @override
  String get defaultTitle => '选项';

  @override
  bool get defaultExpanded => false;

  @override
  String get titleAlignment => 'center';

  @override
  String get containerType => horizontal ? 'options_horizontal' : 'options_vertical';

  @override
  Widget build(
    BuildContext context,
    String? nameAttribute,
    String content,
    TextStyle baseStyle,
    dynamic formatter,
  ) {
    String title = nameAttribute?.isNotEmpty == true
        ? nameAttribute!
        : defaultTitle;

    List<String> options = _parseOptions(content);
    String groupId = '${title}_$containerType';

    return OptionsWidgetStateful(
      groupId: groupId,
      title: title,
      options: options,
      containerType: containerType,
      baseStyle: baseStyle,
      onOptionsChanged: formatter.onOptionsChanged,
      formatter: formatter,
    );
  }

  /// 解析选项标签
  List<String> _parseOptions(String content) {
    RegExp optionRegex = RegExp(r'<option>(.*?)</option>', multiLine: true, dotAll: true);
    Iterable<Match> matches = optionRegex.allMatches(content);
    return matches.map((match) => match.group(1)?.trim() ?? '').where((option) => option.isNotEmpty).toList();
  }
}

/// 独立的选项组件，管理选中状态
class OptionsWidgetStateful extends StatefulWidget {
  final String groupId;
  final String title;
  final List<String> options;
  final String containerType;
  final TextStyle baseStyle;
  final Function(String groupId, String title, List<String> selectedOptions)? onOptionsChanged;
  final dynamic formatter;

  const OptionsWidgetStateful({
    super.key,
    required this.groupId,
    required this.title,
    required this.options,
    required this.containerType,
    required this.baseStyle,
    this.onOptionsChanged,
    required this.formatter,
  });

  @override
  State<OptionsWidgetStateful> createState() => _OptionsWidgetStatefulState();
}

class _OptionsWidgetStatefulState extends State<OptionsWidgetStateful> {
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
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: ChatSettingsDao().getCustomTagStyles(),
      builder: (context, snapshot) {
        final customStyles = snapshot.data ?? {};
        final optionsStyle = customStyles[widget.containerType == 'options_horizontal' ? 'options_h' : 'options_v'];

        Color backgroundColor;
        double opacity;
        Color textColor;

        if (optionsStyle != null) {
          backgroundColor = Color(int.parse(optionsStyle['backgroundColor'].toString().replaceAll('0x', ''), radix: 16));
          opacity = (optionsStyle['opacity'] as num).toDouble();
          textColor = Color(int.parse(optionsStyle['textColor'].toString().replaceAll('0x', ''), radix: 16));
        } else {
          backgroundColor = widget.baseStyle.color ?? Colors.grey;
          opacity = 0.1;
          textColor = widget.baseStyle.color ?? Colors.black;
        }

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
                    color: backgroundColor,
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
                      color: textColor.withOpacity(0.6),
                      fontSize: widget.baseStyle.fontSize! * 0.9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                widget.containerType == 'options_horizontal'
                    ? _buildHorizontalOptions(backgroundColor, opacity, textColor)
                    : _buildVerticalOptions(backgroundColor, opacity, textColor),
            ],
          ),
        );
      },
    );
  }

  /// 构建水平滚动选项
  Widget _buildHorizontalOptions(Color backgroundColor, double opacity, Color textColor) {
    return SizedBox(
      height: 40.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: widget.options.length,
        itemBuilder: (context, index) {
          String option = widget.options[index];
          bool isSelected = selectedOptions.contains(option);
          return Container(
            margin: EdgeInsets.only(right: index < widget.options.length - 1 ? 8.0 : 0),
            child: _buildOptionButton(option, isSelected, true, backgroundColor, opacity, textColor),
          );
        },
      ),
    );
  }

  /// 构建垂直滚动选项
  Widget _buildVerticalOptions(Color backgroundColor, double opacity, Color textColor) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200.0),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: widget.options.length,
        itemBuilder: (context, index) {
          String option = widget.options[index];
          bool isSelected = selectedOptions.contains(option);
          return Container(
            margin: EdgeInsets.only(bottom: index < widget.options.length - 1 ? 6.0 : 0),
            child: _buildOptionButton(option, isSelected, false, backgroundColor, opacity, textColor),
          );
        },
      ),
    );
  }
  /// 构建选项按钮
  Widget _buildOptionButton(String option, bool isSelected, bool isHorizontal, Color backgroundColor, double opacity, Color textColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleOption(option),
          borderRadius: BorderRadius.circular(12.0),
          splashColor: backgroundColor.withOpacity(0.1),
          highlightColor: backgroundColor.withOpacity(0.05),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: isSelected ? 8 : 6,
                sigmaY: isSelected ? 8 : 6
              ),
              child: Container(
                padding: isHorizontal
                    ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0)
                    : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSelected
                        ? [
                            backgroundColor.withOpacity((opacity * 3.0).clamp(0.0, 1.0)),
                            backgroundColor.withOpacity((opacity * 2.0).clamp(0.0, 1.0)),
                            backgroundColor.withOpacity((opacity * 1.0).clamp(0.0, 1.0)),
                          ]
                        : [
                            backgroundColor.withOpacity((opacity * 1.0).clamp(0.0, 1.0)),
                            backgroundColor.withOpacity((opacity * 0.6).clamp(0.0, 1.0)),
                            backgroundColor.withOpacity((opacity * 0.3).clamp(0.0, 1.0)),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isSelected
                        ? backgroundColor.withOpacity((opacity * 6.0).clamp(0.0, 1.0))
                        : backgroundColor.withOpacity((opacity * 2.5).clamp(0.0, 1.0)),
                    width: isSelected ? 1.5 : 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? backgroundColor.withOpacity((opacity * 1.5).clamp(0.0, 1.0))
                          : Colors.black.withOpacity(0.05),
                      blurRadius: isSelected ? 10 : 6,
                      offset: Offset(0, isSelected ? 4 : 2),
                      spreadRadius: isSelected ? 1 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: RichText(
                    textAlign: isHorizontal ? TextAlign.center : TextAlign.left,
                    text: TextSpan(
                      children: widget.formatter.processInlineFormats(
                        option,
                        widget.baseStyle.copyWith(
                          fontSize: widget.baseStyle.fontSize! * (isSelected ? 0.95 : 0.9),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? textColor
                              : textColor.withOpacity(0.85),
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
    );
  }
}
