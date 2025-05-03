import '../../net/http_client.dart';

class NotificationService {
  final HttpClient _httpClient = HttpClient();

  // 获取未读通知数量，总是从服务器获取最新数据
  Future<int> getUnreadCount() async {
    try {
      final response = await _httpClient.get(
        '/notifications/unread',
        options: _httpClient.getNoCacheOptions(), // 禁用缓存，强制从服务器获取最新数据
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        return response.data['data']['count'] ?? 0;
      } else {
        throw Exception(response.data['msg'] ?? '获取未读通知数量失败');
      }
    } catch (e) {
      // 发生错误时返回0，避免UI显示异常
      return 0;
    }
  }

  // 获取通知列表
  Future<Map<String, dynamic>> getNotifications({
    int? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'page_size': pageSize,
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _httpClient.get(
        '/notifications',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        Map<String, dynamic> data = response.data['data'];

        // 确保notifications字段存在，如果为null则初始化为空列表
        if (!data.containsKey('notifications') ||
            data['notifications'] == null) {
          data['notifications'] = [];
        }

        return data;
      } else {
        throw Exception(response.data['msg'] ?? '获取通知列表失败');
      }
    } catch (e) {
      throw Exception('获取通知列表失败: $e');
    }
  }

  // 标记通知为已读
  Future<void> markAsRead(int notificationId) async {
    try {
      final response =
          await _httpClient.put('/notifications/$notificationId/read');

      if (response.statusCode != 200 || response.data['code'] != 0) {
        throw Exception(response.data['msg'] ?? '标记通知已读失败');
      }
    } catch (e) {
      throw Exception('标记通知已读失败: $e');
    }
  }

  // 标记所有通知为已读
  Future<void> markAllAsRead() async {
    try {
      final response = await _httpClient.put('/notifications/read-all');

      if (response.statusCode != 200 || response.data['code'] != 0) {
        throw Exception(response.data['msg'] ?? '标记所有通知已读失败');
      }
    } catch (e) {
      throw Exception('标记所有通知已读失败: $e');
    }
  }

  // 删除通知
  Future<void> deleteNotification(int notificationId) async {
    try {
      final response =
          await _httpClient.delete('/notifications/$notificationId');

      if (response.statusCode != 200 || response.data['code'] != 0) {
        throw Exception(response.data['msg'] ?? '删除通知失败');
      }
    } catch (e) {
      throw Exception('删除通知失败: $e');
    }
  }
}
