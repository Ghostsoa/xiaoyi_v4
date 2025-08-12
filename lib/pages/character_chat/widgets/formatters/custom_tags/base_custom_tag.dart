import 'package:flutter/material.dart';

/// 自定义标签的基础抽象类
abstract class BaseCustomTag {
  /// 标签名称
  String get tagName;
  
  /// 默认标题
  String get defaultTitle;
  
  /// 默认展开状态
  bool get defaultExpanded;
  
  /// 标题对齐方式
  String get titleAlignment;
  
  /// 容器类型
  String get containerType;
  
  /// 构建标签组件
  Widget build(
    BuildContext context,
    String? nameAttribute,
    String content,
    TextStyle baseStyle,
    dynamic formatter, // MarkdownFormatter 实例
  );
}

/// 标签配置信息
class TagConfig {
  final String defaultTitle;
  final bool defaultExpanded;
  final String titleAlignment;
  final String containerType;

  const TagConfig({
    required this.defaultTitle,
    required this.defaultExpanded,
    required this.titleAlignment,
    required this.containerType,
  });
}
