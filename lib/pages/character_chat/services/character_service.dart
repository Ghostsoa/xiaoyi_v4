import '../../../net/http_client.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class CharacterService {
  final HttpClient _httpClient = HttpClient();

  /// 创建角色卡会话
  Future<Map<String, dynamic>> createCharacterSession(
    int characterId,
    Map<String, String> initFields, {
    bool isDebug = false,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'characterId': characterId,
        'initFields': initFields,
      };

      if (isDebug) {
        data['debug'] = 'debug';
      }

      final response = await _httpClient.post(
        '/sessions/character',
        data: data,
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

  /// 获取角色卡详情
  Future<Map<String, dynamic>> getCharacterDetail(int characterId) async {
    try {
      final response = await _httpClient.get(
        '/hall/items/$characterId/detail',
        queryParameters: {
          'type': 'character_card',
        },
      );

      if (response.data['code'] == 0) {
        return response.data['data'];
      } else {
        throw response.data['msg'] ?? '获取角色卡详情失败';
      }
    } catch (e) {
      throw '获取角色卡详情失败: $e';
    }
  }

  /// 获取角色卡会话的所有存档
  Future<List<Map<String, dynamic>>> getSessionSaveSlots(int sessionId) async {
    try {
      final response = await _httpClient.get(
        '/sessions/character/$sessionId/save-slots',
      );

      if (response.data['code'] == 0) {
        return List<Map<String, dynamic>>.from(
            response.data['data']['list'] ?? []);
      } else {
        throw response.data['msg'] ?? '获取存档列表失败';
      }
    } catch (e) {
      throw '获取存档列表失败: $e';
    }
  }

  /// 创建新存档
  Future<Map<String, dynamic>> createSaveSlot(
      int sessionId, String saveName) async {
    try {
      final response = await _httpClient.post(
        '/sessions/character/$sessionId/save-slots',
        data: {
          'save_name': saveName,
        },
      );

      if (response.data['code'] == 0) {
        return response.data['data'];
      } else {
        throw response.data['msg'] ?? '创建存档失败';
      }
    } catch (e) {
      throw '创建存档失败: $e';
    }
  }

  /// 激活指定存档
  Future<void> activateSaveSlot(int sessionId, String saveSlotId) async {
    try {
      final response = await _httpClient.put(
        '/sessions/character/$sessionId/save-slots/$saveSlotId/activate',
      );

      if (response.data['code'] != 0) {
        throw response.data['msg'] ?? '激活存档失败';
      }
    } catch (e) {
      throw '激活存档失败: $e';
    }
  }

  /// 重命名存档
  Future<void> renameSaveSlot(
      int sessionId, String saveSlotId, String newName) async {
    try {
      final response = await _httpClient.put(
        '/sessions/character/$sessionId/save-slots/$saveSlotId',
        data: {
          'save_name': newName,
        },
      );

      if (response.data['code'] != 0) {
        throw response.data['msg'] ?? '重命名存档失败';
      }
    } catch (e) {
      throw '重命名存档失败: $e';
    }
  }

  /// 删除存档
  Future<void> deleteSaveSlot(int sessionId, String saveSlotId) async {
    try {
      final response = await _httpClient.delete(
        '/sessions/character/$sessionId/save-slots/$saveSlotId',
      );

      if (response.data['code'] != 0) {
        throw response.data['msg'] ?? '删除存档失败';
      }
    } catch (e) {
      throw '删除存档失败: $e';
    }
  }

  /// 复制当前存档（创建快照）
  Future<Map<String, dynamic>> duplicateSaveSlot(
      int sessionId, String saveName) async {
    try {
      final response = await _httpClient.post(
        '/sessions/character/$sessionId/save-slots/duplicate',
        data: {
          'save_name': saveName,
        },
      );

      if (response.data['code'] == 0) {
        return response.data['data'];
      } else {
        throw response.data['msg'] ?? '创建存档快照失败';
      }
    } catch (e) {
      throw '创建存档快照失败: $e';
    }
  }

  /// 上报对话持续时间
  Future<void> reportDialogDuration(int itemId, int authorId) async {
    try {
      await _httpClient.post(
        '/dialog-duration/report',
        data: {
          'item_id': itemId,
          'author_id': authorId,
        },
      );
      // 忽略响应结果
    } catch (e) {
      // 忽略错误，不影响用户体验
      debugPrint('上报对话持续时间失败: $e');
    }
  }

  /// 获取对话灵感建议
  Future<Map<String, dynamic>> getInspirationSuggestions(int sessionId) async {
    try {
      final response = await _httpClient.get(
        '/sessions/character/$sessionId/inspiration',
        options: Options(
          receiveTimeout: const Duration(minutes: 2),
          sendTimeout: const Duration(minutes: 2),
        ),
      );

      if (response.data['code'] == 0) {
        return response.data['data'];
      } else {
        throw response.data['msg'] ?? '获取灵感建议失败';
      }
    } catch (e) {
      throw '获取灵感建议失败: $e';
    }
  }
}
