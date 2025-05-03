import '../../../net/http_client.dart';

class MessageService {
  final HttpClient _httpClient = HttpClient();

  /// 获取角色会话列表
  Future<Map<String, dynamic>> getCharacterSessions({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _httpClient.get(
        '/sessions/character',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      if (response.data['code'] == 0) {
        return response.data['data'];
      } else {
        throw response.data['msg'] ?? '获取会话列表失败';
      }
    } catch (e) {
      throw '获取会话列表失败: $e';
    }
  }

  /// 删除角色会话
  Future<void> deleteSession(int id) async {
    try {
      final response = await _httpClient.delete('/sessions/character/$id');

      if (response.data['code'] != 0) {
        throw response.data['msg'] ?? '删除会话失败';
      }
    } catch (e) {
      throw '删除会话失败: $e';
    }
  }
}
