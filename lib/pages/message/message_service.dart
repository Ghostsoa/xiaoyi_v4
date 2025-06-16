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

  /// 获取小说会话列表
  Future<Map<String, dynamic>> getNovelSessions({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _httpClient.get(
        '/sessions/novel',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.data['code'] == 0) {
        return response.data['data'];
      } else {
        throw response.data['message'] ?? '获取小说会话列表失败';
      }
    } catch (e) {
      throw '获取小说会话列表失败: $e';
    }
  }

  /// 批量删除角色会话
  Future<Map<String, dynamic>> batchDeleteCharacterSessions(List<int> sessionIds) async {
    try {
      final response = await _httpClient.post(
        '/sessions/character/batch-delete',
        data: {'sessionIds': sessionIds},
      );

      if (response.data['code'] == 0) {
        return {
          'success': true,
          'msg': response.data['msg'] ?? '批量删除成功',
        };
      } else {
        return {
          'success': false,
          'msg': response.data['msg'] ?? '批量删除失败',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'msg': '批量删除失败: $e',
      };
    }
  }

  /// 批量删除小说会话
  Future<Map<String, dynamic>> batchDeleteNovelSessions(List<int> sessionIds) async {
    try {
      final response = await _httpClient.post(
        '/sessions/novel/batch-delete',
        data: {'sessionIds': sessionIds},
      );

      if (response.data['code'] == 0) {
        return {
          'success': true,
          'msg': response.data['msg'] ?? '批量删除成功',
        };
      } else {
        return {
          'success': false,
          'msg': response.data['msg'] ?? '批量删除失败',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'msg': '批量删除失败: $e',
      };
    }
  }

  // 重命名角色会话
  Future<Map<String, dynamic>> renameSession(
      int sessionId, String newName) async {
    try {
      final response = await _httpClient.post(
        '/sessions/character/$sessionId/rename',
        data: {'name': newName},
      );

      if (response.data['code'] == 0) {
        return {
          'success': true,
          'data': response.data['data'],
          'msg': response.data['msg'] ?? '重命名成功',
        };
      } else {
        return {
          'success': false,
          'msg': response.data['msg'] ?? '重命名失败',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'msg': '重命名失败: $e',
      };
    }
  }

  // 重命名小说会话
  Future<Map<String, dynamic>> renameNovelSession(
      int sessionId, String newName) async {
    try {
      final response = await _httpClient.post(
        '/sessions/novel/$sessionId/rename',
        data: {'name': newName},
      );

      if (response.data['code'] == 0) {
        return {
          'success': true,
          'data': response.data['data'],
          'msg': response.data['msg'] ?? '重命名成功',
        };
      } else {
        return {
          'success': false,
          'msg': response.data['msg'] ?? '重命名失败',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'msg': '重命名失败: $e',
      };
    }
  }
}
