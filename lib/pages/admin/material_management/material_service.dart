import 'package:dio/dio.dart';
import '../../../net/http_client.dart';

enum MaterialType {
  template,
  image,
  prefix,
  suffix,
}

enum MaterialStatus {
  private,
  published,
}

class MaterialService {
  final HttpClient _httpClient = HttpClient();

  // 获取素材列表
  Future<Response> getMaterials({
    int page = 1,
    int pageSize = 20,
    MaterialType? type,
    MaterialStatus? status,
    String? keyword,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'page_size': pageSize,
    };

    if (type != null) {
      queryParams['type'] = type.name;
    }

    if (status != null) {
      queryParams['status'] = status.name;
    }

    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }

    return await _httpClient.get(
      '/admin/materials',
      queryParameters: queryParams,
    );
  }

  // 删除素材
  Future<Response> deleteMaterial(int id) async {
    return await _httpClient.delete('/admin/materials/$id');
  }

  // 获取素材类型的显示名称
  static String getMaterialTypeName(MaterialType type) {
    switch (type) {
      case MaterialType.template:
        return '设定模板';
      case MaterialType.image:
        return '图片';
      case MaterialType.prefix:
        return '前缀词';
      case MaterialType.suffix:
        return '后缀词';
    }
  }

  // 获取素材状态的显示名称
  static String getMaterialStatusName(MaterialStatus status) {
    switch (status) {
      case MaterialStatus.private:
        return '私有';
      case MaterialStatus.published:
        return '已发布';
    }
  }

  // 更新素材状态
  Future<Response> updateMaterialStatus(int id, String status) async {
    return await _httpClient.put(
      '/admin/materials/$id',
      data: {'status': status},
    );
  }
}
