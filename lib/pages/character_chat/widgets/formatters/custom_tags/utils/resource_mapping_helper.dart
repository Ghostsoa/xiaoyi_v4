import '../../../../../../utils/resource_mapping_parser.dart';

/// 资源映射助手类
class ResourceMappingHelper {
  static const String DEFAULT_RESOURCE_KEY = '其他';
  
  /// 解析资源映射并构建映射表
  static Map<String, String> parseResourceMappings(String? resourceMapping) {
    final Map<String, String> nameToUri = {};
    
    if ((resourceMapping ?? '').trim().isNotEmpty) {
      for (final r in ResourceMappingParser.parseResourceMappings(resourceMapping!)) {
        nameToUri[r.name] = r.uri;
      }
    }
    
    return nameToUri;
  }
  
  /// 获取资源URI，支持默认资源
  /// 当找不到指定name的资源时，自动使用"其他"作为默认资源
  static String? getResourceUri(Map<String, String> nameToUri, String name) {
    // 首先尝试获取指定name的资源
    String? uri = nameToUri[name];
    
    // 如果找不到，尝试使用默认资源"其他"
    if (uri == null || uri.isEmpty) {
      uri = nameToUri[DEFAULT_RESOURCE_KEY];
    }
    
    return uri;
  }
  
  /// 检查是否有默认资源
  static bool hasDefaultResource(Map<String, String> nameToUri) {
    return nameToUri.containsKey(DEFAULT_RESOURCE_KEY) && 
           (nameToUri[DEFAULT_RESOURCE_KEY]?.isNotEmpty ?? false);
  }
  
  /// 获取所有可用的资源名称
  static List<String> getAvailableResourceNames(Map<String, String> nameToUri) {
    return nameToUri.keys.toList();
  }
  
  /// 检查指定name是否有对应的资源
  static bool hasResource(Map<String, String> nameToUri, String name) {
    return nameToUri.containsKey(name) && (nameToUri[name]?.isNotEmpty ?? false);
  }
  
  /// 获取资源映射的统计信息
  static Map<String, dynamic> getResourceMappingStats(Map<String, String> nameToUri) {
    return {
      'total': nameToUri.length,
      'hasDefault': hasDefaultResource(nameToUri),
      'names': getAvailableResourceNames(nameToUri),
    };
  }
}
