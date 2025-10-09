import '../../../net/http_client.dart';

class GroupChatService {
  final HttpClient _httpClient = HttpClient();

  // 单例模式
  static final GroupChatService _instance = GroupChatService._internal();
  factory GroupChatService() => _instance;
  GroupChatService._internal();

  /// 创建群聊
  /// 请求路由: POST /groupchats
  /// 返回格式：
  /// {
  ///   "code": 0,
  ///   "msg": "创建成功",
  ///   "data": {
  ///     "id": 123
  ///   }
  /// }
  Future<Map<String, dynamic>> createGroupChat(Map<String, dynamic> groupChatData) async {
    try {
      final response = await _httpClient.post('/groupchats', data: groupChatData);

      if (response.data['code'] == 0) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '创建群聊失败');
      }
    } catch (e) {
      throw Exception('创建群聊失败: $e');
    }
  }

  /// 获取个人群聊列表
  /// 请求路由: GET /groupchats
  /// 查询参数:
  /// - page: 页码（默认1）
  /// - pageSize: 每页数量（默认10）
  /// - keyword: 搜索关键词
  /// - status: 状态筛选（draft, published, private）
  /// 返回格式：
  /// {
  ///   "code": 0,
  ///   "msg": "获取成功",
  ///   "data": {
  ///     "items": [...],
  ///     "total": 25
  ///   }
  /// }
  Future<Map<String, dynamic>> getGroupChatList({
    int page = 1,
    int pageSize = 10,
    String? keyword,
    String? status,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };

      if (keyword != null && keyword.isNotEmpty) {
        queryParameters['keyword'] = keyword;
      }

      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      final response = await _httpClient.get(
        '/groupchats',
        queryParameters: queryParameters,
      );

      if (response.data['code'] == 0) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '获取群聊列表失败');
      }
    } catch (e) {
      throw Exception('获取群聊列表失败: $e');
    }
  }

  /// 更新群聊
  /// 请求路由: PUT /groupchats/{id}
  /// 路径参数: id - 群聊ID
  /// 返回格式：
  /// {
  ///   "code": 0,
  ///   "msg": "更新成功",
  ///   "data": null
  /// }
  Future<Map<String, dynamic>> updateGroupChat(int id, Map<String, dynamic> groupChatData) async {
    try {
      final response = await _httpClient.put('/groupchats/$id', data: groupChatData);

      if (response.data['code'] == 0) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '更新群聊失败');
      }
    } catch (e) {
      throw Exception('更新群聊失败: $e');
    }
  }

  /// 删除群聊
  /// 请求路由: DELETE /groupchats/{id}
  /// 路径参数: id - 群聊ID
  /// 返回格式：
  /// {
  ///   "code": 200,
  ///   "msg": "删除成功",
  ///   "data": null
  /// }
  Future<Map<String, dynamic>> deleteGroupChat(int id) async {
    try {
      final response = await _httpClient.delete('/groupchats/$id');

      if (response.data['code'] == 200 || response.data['code'] == 0) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '删除群聊失败');
      }
    } catch (e) {
      throw Exception('删除群聊失败: $e');
    }
  }

  /// 更新群聊状态
  /// 请求路由: PUT /groupchats/{id}/status
  /// 路径参数: id - 群聊ID
  /// 请求体: {"status": "published"} // draft, published, private
  /// 返回格式：
  /// {
  ///   "code": 0,
  ///   "msg": "更新成功",
  ///   "data": null
  /// }
  Future<Map<String, dynamic>> updateGroupChatStatus(int id, String status) async {
    try {
      final response = await _httpClient.put('/groupchats/$id/status', data: {
        'status': status,
      });

      if (response.data['code'] == 0) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '更新群聊状态失败');
      }
    } catch (e) {
      throw Exception('更新群聊状态失败: $e');
    }
  }

  /// 获取单个群聊详情
  /// 请求路由: GET /groupchats/{id}
  /// 路径参数: id - 群聊ID
  /// 返回格式：
  /// {
  ///   "code": 0,
  ///   "msg": "获取成功",
  ///   "data": {群聊详细信息}
  /// }
  Future<Map<String, dynamic>> getGroupChatById(int id) async {
    try {
      final response = await _httpClient.get('/groupchats/$id');

      if (response.data['code'] == 0) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '获取群聊详情失败');
      }
    } catch (e) {
      throw Exception('获取群聊详情失败: $e');
    }
  }

}
