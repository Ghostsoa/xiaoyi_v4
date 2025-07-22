import '../../../net/http_client.dart';

class AuthorService {
  final HttpClient _httpClient = HttpClient();

  Future<Map<String, num>> getAuthorStats() async {
    try {
      final response = await _httpClient.get('/hall/authors/stats');
      if (response.statusCode == 200 && response.data['code'] == 0) {
        final data = response.data['data'] as Map<String, dynamic>;
        return {
          'character_count': data['character_count'] ?? 0,
          'novel_count': data['novel_count'] ?? 0,
          'world_count': data['world_count'] ?? 0,
          'template_count': data['template_count'] ?? 0,
          'entry_count': data['entry_count'] ?? 0,
          'like_count': data['like_count'] ?? 0,
          'dialog_count': data['dialog_count'] ?? 0,
          'unclaimed_duration': (data['unclaimed_duration'] is num)
              ? data['unclaimed_duration']
              : 0,
          'follower_count': data['follower_count'] ?? 0,
        };
      }
      throw Exception(response.data['msg'] ?? '获取统计信息失败');
    } catch (e) {
      throw Exception('获取统计信息失败: $e');
    }
  }

  /// 领取时长奖励
  ///
  /// [hours] 要领取的小时数，-1表示领取全部，null也表示领取全部
  Future<Map<String, dynamic>> claimDuration({double? hours}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (hours != null) {
        queryParams['hours'] = hours;
      }

      final response = await _httpClient.post(
        '/hall/authors/claim-duration',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        return response.data['data'];
      }

      throw Exception(response.data['msg'] ?? '领取时长失败');
    } catch (e) {
      throw Exception('领取时长失败: $e');
    }
  }

  /// 获取我发布的更新记录
  Future<Map<String, dynamic>> getMyUpdates({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _httpClient.get(
        '/authors/my-updates',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        return response.data;
      }

      throw Exception(response.data['msg'] ?? '获取更新记录失败');
    } catch (e) {
      throw Exception('获取更新记录失败: $e');
    }
  }

  /// 创建作者更新记录
  Future<Map<String, dynamic>> createUpdate({
    required int authorId,
    required int itemId,
    required String itemType,
    required String title,
    required String description,
    required String updateType,
  }) async {
    try {
      final response = await _httpClient.post(
        '/authors/updates',
        data: {
          'author_id': authorId,
          'item_id': itemId,
          'item_type': itemType,
          'title': title,
          'description': description,
          'update_type': updateType,
        },
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        return response.data;
      }

      throw Exception(response.data['msg'] ?? '创建更新记录失败');
    } catch (e) {
      throw Exception('创建更新记录失败: $e');
    }
  }

  /// 更新作者更新记录
  Future<void> updateUpdate({
    required int updateId,
    String? title,
    String? description,
    String? updateType,
  }) async {
    try {
      // 构建非空参数
      final Map<String, dynamic> data = {};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (updateType != null) data['update_type'] = updateType;

      final response = await _httpClient.put(
        '/authors/updates/$updateId',
        data: data,
      );

      if (response.statusCode != 200 || response.data['code'] != 0) {
        throw Exception(response.data['msg'] ?? '更新记录失败');
      }
    } catch (e) {
      throw Exception('更新记录失败: $e');
    }
  }

  /// 删除作者更新记录
  Future<void> deleteUpdate(int updateId) async {
    try {
      final response = await _httpClient.delete(
        '/authors/updates/$updateId',
      );

      if (response.statusCode != 200 || response.data['code'] != 0) {
        throw Exception(response.data['msg'] ?? '删除更新记录失败');
      }
    } catch (e) {
      throw Exception('删除更新记录失败: $e');
    }
  }
}
