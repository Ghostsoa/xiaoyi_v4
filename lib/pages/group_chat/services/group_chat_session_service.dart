import 'package:flutter/foundation.dart';
import '../../../net/http_client.dart';

class GroupChatSessionService {
  final HttpClient _httpClient = HttpClient();

  // 单例模式
  static final GroupChatSessionService _instance = GroupChatSessionService._internal();
  factory GroupChatSessionService() => _instance;
  GroupChatSessionService._internal();


  Future<Map<String, dynamic>> createGroupChatSession(
    int groupChatId, {
    bool isDebug = false,
  }) async {
    try {
      final response = await _httpClient.post(
        '/sessions/groupchat',
        data: {
          'groupchatId': groupChatId,
          'isDebug': isDebug,
        },
      );

      if (response.data['code'] == 0) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '创建群聊会话失败');
      }
    } catch (e) {
      // 如果已经是Exception，直接重新抛出，避免重复包装
      if (e is Exception) {
        rethrow;
      }
      // 只对非Exception错误进行包装
      throw Exception('创建群聊会话失败: $e');
    }
  }

  /// 更新群聊会话
  /// 路由: PUT /sessions/groupchat/:id
  /// 参数: 全量更新会话信息
  Future<Map<String, dynamic>> updateSession(int sessionId, Map<String, dynamic> data) async {
    try {
      debugPrint('[GroupChatSessionService] 更新会话 $sessionId, 数据: $data');
      
      final response = await _httpClient.put(
        '/sessions/groupchat/$sessionId',
        data: data,
      );

      debugPrint('[GroupChatSessionService] 更新响应: ${response.data}');

      if (response.data is! Map) {
        throw Exception('API返回格式错误: ${response.data}');
      }

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['code'] == 0) {
        // 服务器可能不返回 data 字段，需要处理
        final data = responseData['data'];
        return {
          'success': true,
          'data': data != null ? Map<String, dynamic>.from(data as Map) : <String, dynamic>{},
          'msg': responseData['msg'] ?? '更新成功',
        };
      } else {
        throw Exception(responseData['msg'] ?? '更新会话失败');
      }
    } catch (e) {
      debugPrint('[GroupChatSessionService] 更新失败: $e');
      throw Exception('更新会话失败: $e');
    }
  }

  /// 获取群聊会话详情
  /// 路由: GET /sessions/groupchat/{id}
  Future<Map<String, dynamic>> getGroupChatSessionDetail(int sessionId) async {
    try {
      final response = await _httpClient.get('/sessions/groupchat/$sessionId');

      final int code = response.data['code'] ?? -1;
      final String msg = response.data['msg'] ?? '';

      if (code == 0) {
        return {
          'success': true,
          'data': response.data['data'] ?? {},
        };
      }

      if (code == 1001) {
        return {
          'success': false,
          'msg': msg.isNotEmpty ? msg : '未找到用户信息',
          'unauthorized': true,
        };
      }

      return {
        'success': false,
        'msg': msg.isNotEmpty ? msg : '获取群聊详情失败',
      };
    } catch (e) {
      throw Exception('获取群聊详情失败: $e');
    }
  }

  /// 获取群聊会话消息列表
  /// 路由: GET /sessions/groupchat/:id/messages
  /// 参数:
  /// - sessionId: 会话ID
  /// - page: 页码（默认1）
  /// - pageSize: 每页数量（默认20）
  /// - cursor: 游标（可选，用于游标分页）
  Future<Map<String, dynamic>> getMessages(
    int sessionId, {
    int page = 1,
    int pageSize = 20,
    String? cursor,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      
      if (cursor != null && cursor.isNotEmpty) {
        queryParameters['cursor'] = cursor;
      }

      final response = await _httpClient.get(
        '/sessions/groupchat/$sessionId/messages',
        queryParameters: queryParameters,
      );

      if (response.data['code'] == 0) {
        return response.data['data'];
      } else {
        throw Exception(response.data['msg'] ?? '获取消息历史失败');
      }
    } catch (e) {
      throw Exception('获取消息历史失败: $e');
    }
  }

  /// 重置群聊会话
  /// 路由: POST /sessions/groupchat/:id/reset
  Future<void> resetSession(int sessionId) async {
    try {
      final response = await _httpClient.post('/sessions/groupchat/$sessionId/reset');

      if (response.data is! Map) {
        throw Exception('API返回格式错误: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      if (data['code'] != 0) {
        throw Exception(data['msg'] ?? '重置会话失败');
      }
    } catch (e) {
      throw Exception('重置会话失败: $e');
    }
  }

  /// 更新消息内容
  /// 路由: PUT /sessions/groupchat/:id/messages/:messageId
  Future<void> updateMessage(int sessionId, String messageId, String content) async {
    try {
      final response = await _httpClient.put(
        '/sessions/groupchat/$sessionId/messages/$messageId',
        data: {'content': content},
      );

      if (response.data is! Map) {
        throw Exception('API返回格式错误: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      if (data['code'] != 0) {
        throw Exception(data['msg'] ?? '更新消息失败');
      }
    } catch (e) {
      throw Exception('更新消息失败: $e');
    }
  }

  /// 删除单条消息
  /// 路由: DELETE /sessions/groupchat/:id/messages/:messageId
  Future<void> deleteMessage(int sessionId, String messageId) async {
    try {
      final response = await _httpClient.delete(
        '/sessions/groupchat/$sessionId/messages/$messageId',
      );

      if (response.data is! Map) {
        throw Exception('API返回格式错误: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      if (data['code'] != 0) {
        throw Exception(data['msg'] ?? '删除消息失败');
      }
    } catch (e) {
      throw Exception('删除消息失败: $e');
    }
  }

  /// 撤回最后一轮的用户消息和所有AI角色的回复
  /// 路由: POST /sessions/groupchat/:id/messages/revoke
  Future<void> revokeLastRound(int sessionId) async {
    try {
      final response = await _httpClient.post(
        '/sessions/groupchat/$sessionId/messages/revoke',
      );

      if (response.data is! Map) {
        throw Exception('API返回格式错误: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      if (data['code'] != 0) {
        throw Exception(data['msg'] ?? '撤回消息失败');
      }
    } catch (e) {
      throw Exception('撤回消息失败: $e');
    }
  }

  /// 删除指定消息ID及其之后的所有消息
  /// 路由: POST /sessions/groupchat/:id/messages/:messageId/revoke-after
  Future<void> revokeMessageAndAfter(int sessionId, String messageId) async {
    try {
      final url = '/sessions/groupchat/$sessionId/messages/$messageId/revoke-after';
      debugPrint('[GroupChatSessionService] 调用撤销API: $url');
      debugPrint('[GroupChatSessionService] sessionId类型: ${sessionId.runtimeType}, messageId类型: ${messageId.runtimeType}');
      
      final response = await _httpClient.post(url);

      debugPrint('[GroupChatSessionService] API响应类型: ${response.data.runtimeType}');
      debugPrint('[GroupChatSessionService] API响应内容: ${response.data}');
      
      // 检查响应是否是 Map
      if (response.data is! Map) {
        throw Exception('API返回格式错误: ${response.data}');
      }
      
      final data = response.data as Map<String, dynamic>;
      if (data['code'] != 0) {
        throw Exception(data['msg'] ?? '撤销消息失败');
      }
    } catch (e) {
      debugPrint('[GroupChatSessionService] 撤销失败: $e');
      throw Exception('撤销消息失败: $e');
    }
  }

  /// 同步调试设置
  /// 路由: POST /sessions/groupchat/:id/sync-debug
  Future<void> syncDebugSettings(int sessionId) async {
    try {
      final response = await _httpClient.post(
        '/sessions/groupchat/$sessionId/sync-debug',
      );

      if (response.data['code'] != 0) {
        throw Exception(response.data['msg'] ?? '同步调试设置失败');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('同步调试设置失败: $e');
    }
  }
}
