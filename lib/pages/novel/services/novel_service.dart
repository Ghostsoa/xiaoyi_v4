import '../../../net/http_client.dart';

class NovelService {
  final HttpClient _httpClient = HttpClient();

  /// 创建小说会话
  Future<Map<String, dynamic>> createNovelSession(int novelId) async {
    try {
      final response = await _httpClient.post(
        '/sessions/novel/create/$novelId',
      );

      return response.data;
    } catch (e) {
      throw '创建小说会话失败: $e';
    }
  }

  /// 发送小说对话请求
  /// [sessionId] 小说会话ID
  /// [input] 用户输入内容，为空则由AI自动创作
  /// [timeout] 超时时间，默认为90秒
  Future<Map<String, dynamic>> sendNovelChat(
    String sessionId, {
    String? input,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (input != null && input.isNotEmpty) {
        data['input'] = input;
      }

      final response = await _httpClient.post(
        '/sessions/novel/$sessionId/chat',
        data: data,
        timeout: timeout,
      );

      return response.data;
    } catch (e) {
      throw '对话失败: $e';
    }
  }

  /// 获取小说历史消息
  /// [sessionId] 小说会话ID
  /// [page] 页码，默认为1
  /// [pageSize] 每页记录数，默认为10
  Future<Map<String, dynamic>> getNovelMessages(
    String sessionId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      // 确保页码和每页数量为正数
      final validPage = page < 1 ? 1 : page;
      final validPageSize = pageSize < 1 ? 10 : pageSize;

      final response = await _httpClient.get(
        '/sessions/novel/$sessionId/messages',
        queryParameters: {
          'page': validPage,
          'pageSize': validPageSize,
        },
      );

      return response.data;
    } catch (e) {
      throw '获取历史消息失败: $e';
    }
  }

  /// 重置小说会话，清空所有内容
  /// [sessionId] 小说会话ID
  Future<Map<String, dynamic>> resetNovelSession(String sessionId) async {
    try {
      final response = await _httpClient.post(
        '/sessions/novel/$sessionId/reset',
      );

      return response.data;
    } catch (e) {
      throw '重置会话失败: $e';
    }
  }

  /// 撤销指定章节及其后的内容
  /// [sessionId] 小说会话ID
  /// [chapterTitle] 要撤销的章节标题
  Future<Map<String, dynamic>> undoNovelChapter(
      String sessionId, String chapterTitle) async {
    try {
      final response = await _httpClient.post(
        '/sessions/novel/$sessionId/messages/revoke-chapter',
        data: {
          'chapter_title': chapterTitle,
        },
      );

      return response.data;
    } catch (e) {
      throw '撤销章节失败: $e';
    }
  }

  /// 更新指定消息的内容
  /// [sessionId] 小说会话ID
  /// [msgId] 消息ID
  /// [content] 修改后的内容
  Future<Map<String, dynamic>> updateMessageContent(
    String sessionId,
    String msgId,
    String content,
  ) async {
    try {
      final response = await _httpClient.put(
        '/sessions/novel/$sessionId/messages/$msgId',
        data: {
          'content': content,
        },
      );

      return response.data;
    } catch (e) {
      throw '更新消息内容失败: $e';
    }
  }

  /// 获取小说会话详情
  /// [sessionId] 小说会话ID
  Future<Map<String, dynamic>> getNovelSession(String sessionId) async {
    try {
      final response = await _httpClient.get(
        '/sessions/novel/$sessionId',
      );

      return response.data;
    } catch (e) {
      throw '获取小说会话详情失败: $e';
    }
  }

  /// 更新小说会话
  /// [sessionId] 小说会话ID
  /// [updateData] 需要更新的字段和值
  Future<Map<String, dynamic>> updateNovelSession(
    String sessionId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _httpClient.put(
        '/sessions/novel/$sessionId',
        data: updateData,
      );

      return response.data;
    } catch (e) {
      throw '更新小说会话失败: $e';
    }
  }
}
