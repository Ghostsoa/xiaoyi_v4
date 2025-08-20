import 'package:flutter/material.dart';
import 'base_custom_tag.dart';
import 'collapsible_container.dart';

/// 档案标签组件
class ArchiveWidget extends BaseCustomTag {
  @override
  String get tagName => 'archive';

  @override
  String get defaultTitle => '档案';

  @override
  bool get defaultExpanded => false;

  @override
  String get titleAlignment => 'center';

  @override
  String get containerType => 'archive';

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
