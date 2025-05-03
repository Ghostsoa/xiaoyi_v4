import '../../../net/http_client.dart';

class MaterialService {
  final HttpClient _client = HttpClient();

  Future<Map<String, dynamic>> getMaterials({
    int page = 1,
    int pageSize = 10,
    String? type,
    String? keyword,
  }) async {
    final response = await _client.get(
      '/materials',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (type != null) 'type': type,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      },
    );

    if (response.data['code'] == 0) {
      return response.data['data'];
    } else {
      throw response.data['message'] ?? '获取素材失败';
    }
  }

  Future<Map<String, dynamic>> createMaterial(Map<String, dynamic> data) async {
    final response = await _client.post(
      '/materials',
      data: data,
    );

    if (response.data['code'] == 0) {
      return response.data['data'];
    } else {
      throw response.data['message'] ?? '创建素材失败';
    }
  }

  Future<void> updateMaterial(int id, Map<String, dynamic> data) async {
    final response = await _client.put(
      '/materials/$id',
      data: data,
    );

    if (response.data['code'] != 0) {
      throw response.data['message'] ?? '更新素材失败';
    }
  }

  /// 删除素材
  Future<void> deleteMaterial(String id) async {
    try {
      final response = await _client.delete(
        '/materials/$id',
      );

      if (response.data['code'] != 0) {
        throw Exception(response.data['msg'] ?? '删除失败');
      }
    } catch (e) {
      throw Exception('删除失败: $e');
    }
  }

  /// 切换素材状态（公开/私有）
  Future<void> toggleMaterialStatus(String id) async {
    try {
      final response = await _client.post(
        '/materials/$id/toggle',
      );

      if (response.data['code'] != 0) {
        throw Exception(response.data['msg'] ?? '状态切换失败');
      }
    } catch (e) {
      throw Exception('状态切换失败: $e');
    }
  }

  /// 获取公共素材
  Future<Map<String, dynamic>> getPublicMaterials({
    int page = 1,
    int pageSize = 10,
    String? type,
    String? keyword,
  }) async {
    final response = await _client.get(
      '/materials/all',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (type != null) 'type': type,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      },
    );

    if (response.data['code'] == 0) {
      return response.data['data'];
    } else {
      throw response.data['message'] ?? '获取素材失败';
    }
  }
}
