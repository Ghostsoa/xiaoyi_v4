import '../../../net/http_client.dart';

class CharacterService {
  final HttpClient _httpClient = HttpClient();

  /// 创建角色卡会话
  Future<Map<String, dynamic>> createCharacterSession(
    int characterId,
    Map<String, String> initFields,
  ) async {
    try {
      final response = await _httpClient.post(
        '/sessions/character',
        data: {
          'characterId': characterId,
          'initFields': initFields,
        },
      );

      if (response.data['code'] == 0) {
        return response.data;
      } else {
        throw response.data['msg'] ?? '创建会话失败';
      }
    } catch (e) {
      throw '创建会话失败: $e';
    }
  }

  /// 获取会话详情
  Future<Map<String, dynamic>> getCharacterSession(int sessionId) async {
    try {
      final response = await _httpClient.get('/sessions/character/$sessionId');

      if (response.data['code'] == 0) {
        return response.data['data'];
      } else {
        throw response.data['msg'] ?? '获取会话详情失败';
      }
    } catch (e) {
      throw '获取会话详情失败: $e';
    }
  }

  /// 更新会话设置
  Future<void> updateCharacterSession(
    int sessionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _httpClient.put(
        '/sessions/character/$sessionId',
        data: updates,
      );

      if (response.data['code'] != 0) {
        throw response.data['msg'] ?? '更新会话失败';
      }
    } catch (e) {
      throw '更新会话失败: $e';
    }
  }

  /// 获取会话消息历史
  Future<Map<String, dynamic>> getSessionMessages(
    int sessionId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _httpClient.get(
        '/sessions/character/$sessionId/messages',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      if (response.data['code'] == 0) {
        return response.data['data'];
      } else {
        throw response.data['msg'] ?? '获取消息历史失败';
      }
    } catch (e) {
      throw '获取消息历史失败: $e';
    }
  }

  /// 删除单条消息
  Future<void> deleteMessage(int sessionId, String messageId) async {
    try {
      final response = await _httpClient.delete(
        '/sessions/character/$sessionId/messages/$messageId',
      );

      if (response.data['code'] != 0) {
        throw response.data['msg'] ?? '删除消息失败';
      }
    } catch (e) {
      throw '删除消息失败: $e';
    }
  }

  /// 撤销指定消息及其后的所有消息
  Future<void> revokeMessageAndAfter(int sessionId, String messageId) async {
    try {
      final response = await _httpClient.post(
        '/sessions/character/$sessionId/messages/$messageId/revoke-after',
      );

      if (response.data['code'] != 0) {
        throw response.data['msg'] ?? '撤销消息失败';
      }
    } catch (e) {
      throw '撤销消息失败: $e';
    }
  }

  /// 更新消息内容
  Future<void> updateMessage(
    int sessionId,
    String messageId,
    String content,
  ) async {
    try {
      final response = await _httpClient.put(
        '/sessions/character/$sessionId/messages/$messageId',
        data: {
          'content': content,
        },
      );

      if (response.data['code'] != 0) {
        throw response.data['msg'] ?? '更新消息失败';
      }
    } catch (e) {
      throw '更新消息失败: $e';
    }
  }

  /// 重置会话
  Future<void> resetSession(int sessionId) async {
    try {
      final response = await _httpClient.post(
        '/sessions/character/$sessionId/reset',
      );

      if (response.data['code'] != 0) {
        throw response.data['msg'] ?? '重置会话失败';
      }
    } catch (e) {
      throw '重置会话失败: $e';
    }
  }

  /// 检查会话版本
  Future<Map<String, dynamic>> checkSessionVersion(int sessionId) async {
    try {
      final response = await _httpClient.get(
        '/sessions/character/$sessionId/version',
      );

      if (response.data['code'] == 0) {
        return response.data['data'];
      } else {
        throw response.data['msg'] ?? '检查会话版本失败';
      }
    } catch (e) {
      throw '检查会话版本失败: $e';
    }
  }

  /// 更新会话到最新版本
  Future<void> updateSessionVersion(int sessionId) async {
    try {
      final response = await _httpClient.post(
        '/sessions/character/$sessionId/version/update',
      );

      if (response.data['code'] != 0) {
        throw response.data['msg'] ?? '更新会话版本失败';
      }
    } catch (e) {
      throw '更新会话版本失败: $e';
    }
  }
}
