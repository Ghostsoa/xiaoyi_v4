import 'package:flutter/material.dart';
import 'base_custom_tag.dart';
import 'collapsible_container.dart';
import '../../../../../dao/chat_settings_dao.dart';

/// 状态栏标签组件
class StatusWidget extends BaseCustomTag {
  final bool expanded;

  StatusWidget({required this.expanded});

  @override
  String get tagName => expanded ? 'status_on' : 'status_off';

  @override
  String get defaultTitle => '状态栏';

  @override
  bool get defaultExpanded => expanded;

  @override
  String get titleAlignment => 'left';

  @override
  String get containerType => expanded ? 'status_on' : 'status_off';

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

    return CollapsibleContainer(
      title: title,
      content: content,
      defaultExpanded: defaultExpanded,
      titleAlignment: titleAlignment,
      containerType: containerType,
      baseStyle: baseStyle,
      formatter: formatter,
    );
  }
}
