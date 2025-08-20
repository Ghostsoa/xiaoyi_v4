/// 资源映射数据模型
class ResourceMapping {
  final String name;
  final String uri;

  ResourceMapping({
    required this.name,
    required this.uri,
  });

  @override
  String toString() => '<name="$name"|uri="$uri">';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceMapping &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          uri == other.uri;

  @override
  int get hashCode => name.hashCode ^ uri.hashCode;
}

/// 资源映射解析工具类
/// 处理 <name="资源名称"|uri="资源URI"> 格式的标签
class ResourceMappingParser {
  /// 解析资源映射字符串为资源列表
  /// [mappingText] 包含多个资源标签的文本
  /// 返回解析后的资源列表
  static List<ResourceMapping> parseResourceMappings(String mappingText) {
    if (mappingText.trim().isEmpty) {
      return [];
    }

    final List<ResourceMapping> resources = [];
    
    // 使用正则表达式匹配 <name="..."|uri="..."> 格式
    final RegExp regex = RegExp(r'<name="([^"]+)"\|uri="([^"]+)">');
    final Iterable<RegExpMatch> matches = regex.allMatches(mappingText);

    for (final match in matches) {
      final String? name = match.group(1);
      final String? uri = match.group(2);
      
      if (name != null && uri != null && name.isNotEmpty && uri.isNotEmpty) {
        resources.add(ResourceMapping(name: name, uri: uri));
      }
    }

    return resources;
  }

  /// 将资源列表转换为资源映射字符串
  /// [resources] 资源列表
  /// 返回格式化的资源映射字符串
  static String generateResourceMappingText(List<ResourceMapping> resources) {
    if (resources.isEmpty) {
      return '';
    }

    return resources.map((resource) => resource.toString()).join('\n');
  }

  /// 添加资源到现有的资源映射文本中
  /// [currentText] 当前的资源映射文本
  /// [name] 新资源名称
  /// [uri] 新资源URI
  /// 返回更新后的资源映射文本
  static String addResource(String currentText, String name, String uri) {
    final List<ResourceMapping> resources = parseResourceMappings(currentText);
    
    // 检查是否已存在相同的资源
    final newResource = ResourceMapping(name: name, uri: uri);
    if (!resources.contains(newResource)) {
      resources.add(newResource);
    }
    
    return generateResourceMappingText(resources);
  }

  /// 从资源映射文本中移除指定资源
  /// [currentText] 当前的资源映射文本
  /// [resourceToRemove] 要移除的资源
  /// 返回更新后的资源映射文本
  static String removeResource(String currentText, ResourceMapping resourceToRemove) {
    final List<ResourceMapping> resources = parseResourceMappings(currentText);
    resources.remove(resourceToRemove);
    return generateResourceMappingText(resources);
  }

  /// 验证资源名称是否有效
  /// [name] 资源名称
  /// 返回是否有效
  static bool isValidResourceName(String name) {
    return name.trim().isNotEmpty && 
           name.isNotEmpty && 
           name.length <= 50 &&
           !name.contains('"') && 
           !name.contains('|') && 
           !name.contains('<') && 
           !name.contains('>');
  }

  /// 验证资源URI是否有效
  /// [uri] 资源URI
  /// 返回是否有效
  static bool isValidResourceUri(String uri) {
    return uri.trim().isNotEmpty && 
           !uri.contains('"') && 
           !uri.contains('|') && 
           !uri.contains('<') && 
           !uri.contains('>');
  }
}
