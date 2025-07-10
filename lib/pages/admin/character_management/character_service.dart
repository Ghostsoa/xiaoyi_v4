import 'package:dio/dio.dart';
import '../../../net/http_client.dart';

enum CharacterStatus {
  private,
  published,
  draft,
}

class CharacterService {
  final HttpClient _httpClient = HttpClient();

  // 获取角色卡列表
  Future<Response> getCharacters({
    int page = 1,
    int pageSize = 20,
    CharacterStatus? status,
    String? keyword,
    String? tags,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (status != null) {
      queryParams['status'] = status.name;
    }

    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }

    if (tags != null && tags.isNotEmpty) {
      queryParams['tags'] = tags;
    }

    return await _httpClient.get(
      '/admin/characters',
      queryParameters: queryParams,
    );
  }

  // 删除角色卡
  Future<Response> deleteCharacter(int id) async {
    return await _httpClient.delete('/admin/characters/$id');
  }

  // 更新角色卡状态
  Future<Response> updateCharacterStatus(int id, String status) async {
    return await _httpClient.put(
      '/admin/characters/$id',
      data: {'status': status},
    );
  }

  // 获取状态显示名称
  static String getStatusName(CharacterStatus status) {
    switch (status) {
      case CharacterStatus.private:
        return '私有';
      case CharacterStatus.published:
        return '已发布';
      case CharacterStatus.draft:
        return '草稿';
    }
  }
}
