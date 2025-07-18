import '../../../net/http_client.dart';

class AuthorService {
  final HttpClient _httpClient = HttpClient();

  Future<Map<String, num>> getAuthorStats() async {
    try {
      final response = await _httpClient.get('/hall/authors/stats');
      if (response.statusCode == 200 && response.data['code'] == 0) {
        final data = response.data['data'] as Map<String, dynamic>;
        return {
          '角色': data['character_count'] ?? 0,
          '小说': data['novel_count'] ?? 0,
          '世界书': data['world_count'] ?? 0,
          '模板': data['template_count'] ?? 0,
          '词条': data['entry_count'] ?? 0,
          '获赞': data['like_count'] ?? 0,
          '对话': data['dialog_count'] ?? 0,
          '待领时长': (data['unclaimed_duration'] is num)
              ? data['unclaimed_duration']
              : 0,
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
}
