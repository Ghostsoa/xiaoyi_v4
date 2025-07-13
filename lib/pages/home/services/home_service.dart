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

  /// 收藏
  Future<void> favoriteItem(String id) async {
    try {
      final response = await _httpClient.post('/hall/items/$id/favorite');
      if (response.data['code'] != 0) {
        throw Exception(response.data['msg'] ?? '收藏失败');
      }
    } catch (e) {
      throw Exception('收藏失败: $e');
    }
  }

  /// 取消收藏
  Future<void> unfavoriteItem(String id) async {
    try {
      final response = await _httpClient.delete('/hall/items/$id/favorite');
      if (response.data['code'] != 0) {
        throw Exception(response.data['msg'] ?? '取消收藏失败');
      }
    } catch (e) {
      throw Exception('取消收藏失败: $e');
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

  /// 获取作者作品列表
  Future<Map<String, dynamic>> getAuthorItems(
    String authorId, {
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

      final response = await _httpClient.get(
        '/hall/authors/$authorId/items',
        queryParameters: params,
      );
      return response.data;
    } catch (e) {
      throw Exception('获取作者作品列表失败: $e');
    }
  }

  /// 获取收藏列表
  Future<Map<String, dynamic>> getFavorites({
    int page = 1,
    int pageSize = 20,
    List<String>? types,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'page': page,
        'pageSize': pageSize,
      };

      if (types != null && types.isNotEmpty) {
        params['types[]'] = types;
      }

      final response = await _httpClient.get(
        '/hall/favorites',
        queryParameters: params,
      );
      return response.data;
    } catch (e) {
      throw Exception('获取收藏列表失败: $e');
    }
  }

  /// 获取用户偏好设置
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final response = await _httpClient.get('/hall/preferences');
      return response.data;
    } catch (e) {
      throw Exception('获取偏好设置失败: $e');
    }
  }

  /// 更新用户偏好设置
  Future<Map<String, dynamic>> updateUserPreferences({
    required List<String> likedTags,
    required List<String> dislikedTags,
    required List<String> likedAuthors,
    required List<String> dislikedAuthors,
    required List<String> likedKeywords,
    required List<String> dislikedKeywords,
    required int preferenceStrength,
    required int applyToHall,
  }) async {
    try {
      final response = await _httpClient.put(
        '/hall/preferences',
        data: {
          'liked_tags': likedTags,
          'disliked_tags': dislikedTags,
          'liked_authors': likedAuthors,
          'disliked_authors': dislikedAuthors,
          'liked_keywords': likedKeywords,
          'disliked_keywords': dislikedKeywords,
          'preference_strength': preferenceStrength,
          'apply_to_hall': applyToHall,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('更新偏好设置失败: $e');
    }
  }

  /// 重置用户偏好设置
  Future<Map<String, dynamic>> resetUserPreferences() async {
    try {
      final response = await _httpClient.delete('/hall/preferences');
      return response.data;
    } catch (e) {
      throw Exception('重置偏好设置失败: $e');
    }
  }

  /// 搜索用户名
  Future<Map<String, dynamic>> searchUsernames(String keyword,
      {int limit = 10}) async {
    try {
      final response = await _httpClient.get(
        '/usernames/search',
        queryParameters: {
          'keyword': keyword,
          'limit': limit,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('搜索用户名失败: $e');
    }
  }
}
