import '../../../net/http_client.dart';

class NotificationService {
  final HttpClient _httpClient = HttpClient();

  // 获取所有通知列表
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _httpClient.get(
        '/admin/notifications',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '获取通知列表失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 创建通知
  Future<Map<String, dynamic>> createNotification({
    required String title,
    required String content,
    required String type,
    required bool isBroadcast,
    int level = 0,
    List<int>? targetUsers,
    String? link,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'title': title,
        'content': content,
        'type': type,
        'level': level,
        'is_broadcast': isBroadcast,
      };

      if (link != null && link.isNotEmpty) {
        data['link'] = link;
      }

      if (!isBroadcast && targetUsers != null && targetUsers.isNotEmpty) {
        data['target_users'] = targetUsers;
      }

      final response = await _httpClient.post(
        '/admin/notifications',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '创建通知失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 删除通知
  Future<void> deleteNotification(int notificationId) async {
    try {
      final response = await _httpClient.delete(
        '/admin/notifications/$notificationId',
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['msg'] ?? '删除通知失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
