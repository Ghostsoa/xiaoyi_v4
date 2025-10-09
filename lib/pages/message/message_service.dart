import '../../../net/http_client.dart';
import '../../services/session_data_service.dart';
import '../../models/session_model.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class MessageService {
  final HttpClient _httpClient = HttpClient();
  final SessionDataService _sessionDataService = SessionDataService();

  /// 获取角色会话列表（从本地数据库）
  Future<Map<String, dynamic>> getCharacterSessions({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _sessionDataService.getLocalCharacterSessions(
        page: page,
        pageSize: pageSize,
      );

      // 转换为原有的API格式，保持兼容性
      return {
        'list': response.sessions.map((session) => session.toApiJson()).toList(),
        'total': response.total,
        'page': response.page,
        'pageSize': response.pageSize,
      };
    } catch (e) {
      debugPrint('[MessageService] 获取本地角色会话失败: $e');
      throw '获取会话列表失败: $e';
    }
  }

  /// 从API获取角色会话并同步到本地
  Future<Map<String, dynamic>> syncCharacterSessionsFromApi({
    int page = 1,
    int pageSize = 10,
    bool syncToLocal = true, // 🔥 是否同步到本地数据库
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
        final apiData = response.data['data'];

        // 添加调试信息，忽略list字段内容
        final debugData = Map<String, dynamic>.from(apiData);
        if (debugData['list'] is List) {
          debugData['list'] = '[${(debugData['list'] as List).length} items]';
        }
        debugPrint('[MessageService] API响应数据: $debugData');

        // 🔥 只有第一页才同步到本地数据库
        if (syncToLocal) {
          // 转换API数据为SessionModel
          final apiResponse = SessionListResponse.fromApiJson(apiData, false);

          debugPrint('[MessageService] 解析后会话数量: ${apiResponse.sessions.length}, 总数: ${apiResponse.total}');

          // 基于页的"修正式"对齐本地缓存
          await _sessionDataService.reconcileCharacterPageWithApi(
            apiResponse.sessions,
            page,
            pageSize,
          );
        } else {
          debugPrint('[MessageService] 跳过本地同步（page=$page）');
        }

        return apiData;
      } else {
        throw response.data['msg'] ?? '获取会话列表失败';
      }
    } catch (e) {
      debugPrint('[MessageService] 同步角色会话失败: $e');
      throw '同步会话列表失败: $e';
    }
  }

  /// 获取小说会话列表（从本地数据库）
  Future<Map<String, dynamic>> getNovelSessions({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _sessionDataService.getLocalNovelSessions(
        page: page,
        pageSize: pageSize,
      );

      // 转换为原有的API格式，保持兼容性
      return {
        'sessions': response.sessions.map((session) => session.toApiJson()).toList(),
        'total': response.total,
        'page': response.page,
        'pageSize': response.pageSize,
      };
    } catch (e) {
      debugPrint('[MessageService] 获取本地小说会话失败: $e');
      throw '获取小说会话列表失败: $e';
    }
  }

  /// 从API获取小说会话并同步到本地
  Future<Map<String, dynamic>> syncNovelSessionsFromApi({
    int page = 1,
    int pageSize = 10,
    bool syncToLocal = true, // 🔥 是否同步到本地数据库
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
        final apiData = response.data['data'];

        // 添加调试信息，忽略sessions字段内容
        final debugData = Map<String, dynamic>.from(apiData);
        if (debugData['sessions'] is List) {
          debugData['sessions'] = '[${(debugData['sessions'] as List).length} items]';
        }
        debugPrint('[MessageService] 小说API响应数据: $debugData');

        // 🔥 只有第一页才同步到本地数据库
        if (syncToLocal) {
          // 转换API数据为SessionModel
          final apiResponse = SessionListResponse.fromApiJson(apiData, true);

          debugPrint('[MessageService] 解析后小说会话数量: ${apiResponse.sessions.length}, 总数: ${apiResponse.total}');

          // 基于页的"修正式"对齐本地缓存
          await _sessionDataService.reconcileNovelPageWithApi(
            apiResponse.sessions,
            page,
            pageSize,
          );
        } else {
          debugPrint('[MessageService] 跳过本地同步（page=$page）');
        }

        return apiData;
      } else {
        throw response.data['message'] ?? '获取小说会话列表失败';
      }
    } catch (e) {
      debugPrint('[MessageService] 同步小说会话失败: $e');
      throw '同步小说会话列表失败: $e';
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
        // API删除成功后，同步删除本地数据
        for (final sessionId in sessionIds) {
          try {
            await _sessionDataService.deleteCharacterSession(sessionId);
          } catch (e) {
            debugPrint('[MessageService] 删除本地角色会话失败 $sessionId: $e');
          }
        }

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
        // API删除成功后，同步删除本地数据
        for (final sessionId in sessionIds) {
          try {
            await _sessionDataService.deleteNovelSession(sessionId);
          } catch (e) {
            debugPrint('[MessageService] 删除本地小说会话失败 $sessionId: $e');
          }
        }

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
        // API重命名成功后，更新本地数据
        try {
          final localResponse = await _sessionDataService.getLocalCharacterSessions(page: 1, pageSize: 1000);
          final existingSession = localResponse.sessions.firstWhere(
            (session) => session.id == sessionId,
            orElse: () => throw '会话不存在',
          );

          final updatedSession = existingSession.copyWith(
            name: newName,
            lastSyncTime: DateTime.now(),
          );

          await _sessionDataService.updateCharacterSession(updatedSession);
        } catch (e) {
          debugPrint('[MessageService] 更新本地角色会话名称失败: $e');
        }

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
        // API重命名成功后，更新本地数据
        try {
          final localResponse = await _sessionDataService.getLocalNovelSessions(page: 1, pageSize: 1000);
          final existingSession = localResponse.sessions.firstWhere(
            (session) => session.id == sessionId,
            orElse: () => throw '会话不存在',
          );

          final updatedSession = existingSession.copyWith(
            name: newName,
            title: newName, // 小说会话的title也需要更新
            lastSyncTime: DateTime.now(),
          );

          await _sessionDataService.updateNovelSession(updatedSession);
        } catch (e) {
          debugPrint('[MessageService] 更新本地小说会话名称失败: $e');
        }

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

  /// 🔥 置顶角色会话
  Future<void> pinCharacterSession(int sessionId) async {
    try {
      await _sessionDataService.pinCharacterSession(sessionId);
    } catch (e) {
      debugPrint('[MessageService] 置顶角色会话失败: $e');
      throw '置顶会话失败: $e';
    }
  }

  /// 🔥 取消置顶角色会话
  Future<void> unpinCharacterSession(int sessionId) async {
    try {
      await _sessionDataService.unpinCharacterSession(sessionId);
    } catch (e) {
      debugPrint('[MessageService] 取消置顶角色会话失败: $e');
      throw '取消置顶失败: $e';
    }
  }

  /// 🔥 置顶小说会话
  Future<void> pinNovelSession(int sessionId) async {
    try {
      await _sessionDataService.pinNovelSession(sessionId);
    } catch (e) {
      debugPrint('[MessageService] 置顶小说会话失败: $e');
      throw '置顶会话失败: $e';
    }
  }

  /// 🔥 取消置顶小说会话
  Future<void> unpinNovelSession(int sessionId) async {
    try {
      await _sessionDataService.unpinNovelSession(sessionId);
    } catch (e) {
      debugPrint('[MessageService] 取消置顶小说会话失败: $e');
      throw '取消置顶失败: $e';
    }
  }

  /// 获取群聊会话列表（从本地数据库）
  Future<Map<String, dynamic>> getGroupChatSessionsFromLocal({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _sessionDataService.getLocalGroupChatSessions(
        page: page,
        pageSize: pageSize,
      );

      // 转换为原有的API格式，保持兼容性
      return {
        'list': response.sessions.map((session) => session.toApiJson()).toList(),
        'total': response.total,
        'page': response.page,
        'pageSize': response.pageSize,
      };
    } catch (e) {
      debugPrint('[MessageService] 获取本地群聊会话失败: $e');
      throw '获取会话列表失败: $e';
    }
  }

  /// 从API获取群聊会话并同步到本地
  Future<Map<String, dynamic>> syncGroupChatSessionsFromApi({
    int page = 1,
    int pageSize = 10,
    bool syncToLocal = true, // 🔥 是否同步到本地数据库
  }) async {
    try {
      final response = await _httpClient.get(
        '/sessions/groupchat',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      if (response.data['code'] == 0) {
        final apiData = response.data['data'];
        final List<dynamic> items = apiData['items'] ?? [];
        final int total = apiData['total'] ?? 0;

        // 🔥 只有第一页才同步到本地数据库
        if (syncToLocal) {
          // 将API数据转换为SessionModel
          final apiSessions = items.map((item) {
            return SessionModel.fromApiJson(item as Map<String, dynamic>);
          }).toList();

          // 同步到本地数据库（增量更新）
          await _sessionDataService.insertOrUpdateGroupChatSessions(apiSessions);
        } else {
          debugPrint('[MessageService] 跳过本地同步（page=$page）');
        }

        return {
          'total': total,
          'page': page,
          'pageSize': pageSize,
          'items': items, // 🔥 返回原始items数据
        };
      } else {
        throw '同步失败: ${response.data['msg'] ?? '未知错误'}';
      }
    } catch (e) {
      debugPrint('[MessageService] 同步群聊会话失败: $e');
      throw '同步会话列表失败: $e';
    }
  }

  /// 🔥 置顶群聊会话
  Future<void> pinGroupChatSession(int sessionId) async {
    try {
      await _sessionDataService.pinGroupChatSession(sessionId);
    } catch (e) {
      debugPrint('[MessageService] 置顶群聊会话失败: $e');
      throw '置顶会话失败: $e';
    }
  }

  /// 🔥 取消置顶群聊会话
  Future<void> unpinGroupChatSession(int sessionId) async {
    try {
      await _sessionDataService.unpinGroupChatSession(sessionId);
    } catch (e) {
      debugPrint('[MessageService] 取消置顶群聊会话失败: $e');
      throw '取消置顶失败: $e';
    }
  }

  /// 客服单轮对话（无上下文）
  Future<Map<String, dynamic>> customerChat(String message) async {
    try {
      final response = await _httpClient.post(
        '/customer/chat',
        data: {
          'message': message,
        },
        options: _httpClient.getNoCacheOptions(),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        return {
          'success': false,
          'msg': '服务无响应',
        };
      }

      final code = data['code'] as int?;
      final msg = data['msg']?.toString() ?? '';

      if (code == 0) {
        final reply = (data['data'] as Map<String, dynamic>?)?['reply']?.toString() ?? '';
        return {
          'success': true,
          'reply': reply,
          'msg': msg.isNotEmpty ? msg : '对话成功',
        };
      }

      // 未认证
      if (code == 1006) {
        return {
          'success': false,
          'msg': msg.isNotEmpty ? msg : '未找到用户信息',
          'unauthorized': true,
        };
      }

      // 服务器错误
      if (code == 5000) {
        return {
          'success': false,
          'msg': msg.isNotEmpty ? msg : 'AI服务暂时不可用',
        };
      }

      // 其他错误
      return {
        'success': false,
        'msg': msg.isNotEmpty ? msg : '请求失败',
      };
    } catch (e) {
      return {
        'success': false,
        'msg': '请求失败: $e',
      };
    }
  }

  /// 切换官方密钥（无需参数，用户ID由认证中间件获取）
  Future<Map<String, dynamic>> customerToggleKey() async {
    try {
      final response = await _httpClient.post(
        '/customer/toggle-key',
        data: const {},
        options: _httpClient.getNoCacheOptions(),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        return {
          'success': false,
          'msg': '服务无响应',
        };
      }

      final code = data['code'] as int?;
      final msg = data['msg']?.toString() ?? '';

      if (code == 0) {
        final Map<String, dynamic> payload = (data['data'] as Map<String, dynamic>?) ?? {};
        return {
          'success': true,
          'status': payload['status']?.toString(),
          'message': payload['message']?.toString() ?? msg,
          'msg': msg.isNotEmpty ? msg : '操作成功',
        };
      }

      if (code == 1006) {
        return {
          'success': false,
          'msg': msg.isNotEmpty ? msg : '未找到用户信息',
          'unauthorized': true,
        };
      }

      if (code == 5000) {
        return {
          'success': false,
          'msg': msg.isNotEmpty ? msg : '操作失败，请稍后再试',
        };
      }

      return {
        'success': false,
        'msg': msg.isNotEmpty ? msg : '请求失败',
      };
    } catch (e) {
      return {
        'success': false,
        'msg': '请求失败: $e',
      };
    }
  }

  /// 获取群聊会话列表
  /// 路由: GET /sessions/groupchat
  /// 参数: page=1&pageSize=10
  Future<Map<String, dynamic>> getGroupChatSessions({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _httpClient.get(
        '/sessions/groupchat',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

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

      if (code == 5000) {
        return {
          'success': false,
          'msg': msg.isNotEmpty ? msg : '操作失败，请稍后再试',
        };
      }

      return {
        'success': false,
        'msg': msg.isNotEmpty ? msg : '请求失败',
      };
    } catch (e) {
      return {
        'success': false,
        'msg': '请求失败: $e',
      };
    }
  }

  /// 删除群聊会话
  Future<Map<String, dynamic>> deleteGroupChatSession(int sessionId) async {
    try {
      final response = await _httpClient.delete('/sessions/groupchat/$sessionId');

      final int code = response.data['code'] ?? -1;
      final String msg = response.data['msg'] ?? '';

      if (code == 0) {
        return {
          'success': true,
          'msg': msg.isNotEmpty ? msg : '删除成功',
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
        'msg': msg.isNotEmpty ? msg : '删除失败',
      };
    } catch (e) {
      return {
        'success': false,
        'msg': '删除失败: $e',
      };
    }
  }

  /// 重命名群聊会话
  Future<Map<String, dynamic>> renameGroupChatSession(int sessionId, String newName) async {
    try {
      final response = await _httpClient.put(
        '/sessions/groupchat/$sessionId/rename',
        data: {'name': newName},
      );

      final int code = response.data['code'] ?? -1;
      final String msg = response.data['msg'] ?? '';

      if (code == 0) {
        return {
          'success': true,
          'msg': msg.isNotEmpty ? msg : '重命名成功',
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
        'msg': msg.isNotEmpty ? msg : '重命名失败',
      };
    } catch (e) {
      return {
        'success': false,
        'msg': '重命名失败: $e',
      };
    }
  }

  /// 批量删除群聊会话
  Future<Map<String, dynamic>> batchDeleteGroupChatSessions(List<int> sessionIds) async {
    try {
      final response = await _httpClient.delete(
        '/sessions/groupchat/batch',
        data: {'sessionIds': sessionIds},
      );

      final int code = response.data['code'] ?? -1;
      final String msg = response.data['msg'] ?? '';

      if (code == 0) {
        return {
          'success': true,
          'msg': msg.isNotEmpty ? msg : '删除成功',
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
        'msg': msg.isNotEmpty ? msg : '批量删除失败',
      };
    } catch (e) {
      return {
        'success': false,
        'msg': '批量删除失败: $e',
      };
    }
  }
}
