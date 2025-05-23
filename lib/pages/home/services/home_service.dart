import '../../../net/http_client.dart';

class HomeService {
  final HttpClient _httpClient = HttpClient();

  /// 获取热门列表
  Future<Map<String, dynamic>> getHotItems({
    String period = 'daily',
    int page = 1,
    int? pageSize,
  }) async {
    try {
      final response = await _httpClient.get(
        '/hall/items/hot',
        queryParameters: {
          'period': period,
          'page': page,
          'pageSize': pageSize ?? (page == 1 && period == 'daily' ? 5 : 10),
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('获取热门列表失败: $e');
    }
  }

  /// 获取推荐列表
  Future<Map<String, dynamic>> getRecommendItems({
    int page = 1,
    int? pageSize,
  }) async {
    try {
      final response = await _httpClient.get(
        '/hall/items/recommend',
        queryParameters: {
          'page': page,
          'pageSize': pageSize ?? (page == 1 ? 5 : 10),
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('获取推荐列表失败: $e');
    }
  }

  /// 获取热门标签
  Future<Map<String, dynamic>> getHotTags() async {
    try {
      final response = await _httpClient.get('/hall/tags/hot');
      return response.data;
    } catch (e) {
      throw Exception('获取热门标签失败: $e');
    }
  }

  /// 点赞
  Future<void> likeItem(String id) async {
    try {
      final response = await _httpClient.post('/hall/items/$id/like');
      if (response.data['code'] != 0) {
        throw Exception(response.data['msg'] ?? '点赞失败');
      }
    } catch (e) {
      throw Exception('点赞失败: $e');
    }
  }

  /// 取消点赞
  Future<void> unlikeItem(String id) async {
    try {
      final response = await _httpClient.delete('/hall/items/$id/like');
      if (response.data['code'] != 0) {
        throw Exception(response.data['msg'] ?? '取消点赞失败');
      }
    } catch (e) {
      throw Exception('取消点赞失败: $e');
    }
  }

  /// 激励卡片
  Future<Map<String, dynamic>> rewardItem(String id, double amount) async {
    try {
      final response = await _httpClient.post(
        '/hall/items/$id/reward',
        data: {'amount': amount},
      );
      return response.data;
    } catch (e) {
      throw Exception('激励失败: $e');
    }
  }

  /// 获取全部列表
  Future<Map<String, dynamic>> getAllItems({
    int page = 1,
    int pageSize = 20,
    String? keyword,
    String? category,
    String sortBy = 'new',
    List<String>? types,
    List<String>? tags,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
      };

      if (keyword != null && keyword.isNotEmpty) {
        params['keyword'] = keyword;
      }
      if (category != null) {
        params['category'] = category;
      }
      if (types != null && types.isNotEmpty) {
        params['types[]'] = types;
      }
      if (tags != null && tags.isNotEmpty) {
        params['tags[]'] = tags;
      }

      final response =
          await _httpClient.get('/hall/items', queryParameters: params);
      return response.data;
    } catch (e) {
      throw Exception('获取列表失败: $e');
    }
  }
}
