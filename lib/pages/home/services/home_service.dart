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
  Future<Map<String, dynamic>> rewardItem(
    String id,
    double amount, {
    String? message,
  }) async {
    try {
      final Map<String, dynamic> data = {'amount': amount};
      
      // 如果有寄语，添加到请求数据中
      if (message != null && message.isNotEmpty) {
        data['message'] = message;
      }
      
      final response = await _httpClient.post(
        '/hall/items/$id/reward',
        data: data,
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
    required List<String> preferredCategories,
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
          'preferred_category': preferredCategories,
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

  /// 更新用户分区偏好
  Future<Map<String, dynamic>> updateHallPreferencesCategory(String category) async {
    try {
      final response = await _httpClient.put(
        '/hall/preferences/category',
        data: {
          'preferred_category': [category],
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('更新分区偏好失败: $e');
    }
  }

  /// 举报内容
  Future<Map<String, dynamic>> reportItem(
    String itemId,
    int reportType,
    String content,
    List<String> evidence,
  ) async {
    try {
      final response = await _httpClient.post(
        '/hall/items/$itemId/report',
        data: {
          'report_type': reportType,
          'content': content,
          'evidence': evidence,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('提交举报失败: $e');
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

  /// 获取未读的作者更新通知
  Future<Map<String, dynamic>> getUnreadAuthorUpdates({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _httpClient.get(
        '/authors/updates/unread',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('获取未读作者更新失败: $e');
    }
  }

  /// 获取未读作者更新数量
  Future<int> getUnreadAuthorUpdatesCount() async {
    try {
      final response = await _httpClient.get('/authors/updates/unread/count');
      if (response.data['code'] == 0) {
        return response.data['data']['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      // 出错时不抛异常，静默返回0
      return 0;
    }
  }

  /// 获取所有关注作者的更新
  Future<Map<String, dynamic>> getAuthorUpdates({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _httpClient.get(
        '/authors/updates',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('获取作者更新失败: $e');
    }
  }

  /// 标记作者更新为已读
  Future<bool> markAuthorUpdatesAsRead(String authorId) async {
    try {
      final response =
          await _httpClient.post('/authors/$authorId/updates/read');
      return response.data['code'] == 0;
    } catch (e) {
      return false;
    }
  }

  /// 检查是否关注了作者
  Future<bool> checkAuthorFollowing(String authorId) async {
    try {
      final response = await _httpClient.get('/authors/$authorId/following');
      if (response.data['code'] == 0) {
        return response.data['data']['following'] ?? false;
      }
      return false;
    } catch (e) {
      // 出错时不抛异常，静默返回false
      return false;
    }
  }

  /// 关注作者
  Future<bool> followAuthor(String authorId) async {
    try {
      final response = await _httpClient.post('/authors/$authorId/follow');
      return response.data['code'] == 0;
    } catch (e) {
      return false;
    }
  }

  /// 取消关注作者
  Future<bool> unfollowAuthor(String authorId) async {
    try {
      final response = await _httpClient.post('/authors/$authorId/unfollow');
      return response.data['code'] == 0;
    } catch (e) {
      return false;
    }
  }

  /// 获取关注的作者列表
  Future<Map<String, dynamic>> getFollowingAuthors({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _httpClient.get(
        '/authors/following',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('获取关注作者列表失败: $e');
    }
  }

  /// 批量获取用户信息
  Future<List<dynamic>> getUsersBatch(List<int> userIds) async {
    try {
      final response = await _httpClient.post(
        '/users/batch',
        data: {
          'user_ids': userIds,
        },
      );

      if (response.data['code'] == 0) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      throw Exception('批量获取用户信息失败: $e');
    }
  }

  /// 获取作者的详细统计信息
  Future<Map<String, dynamic>> getAuthorPublicStats(String authorId) async {
    try {
      final response = await _httpClient.get('/authors/$authorId/public-stats');

      if (response.data['code'] == 0) {
        return response.data;
      } else {
        throw Exception('获取作者信息失败: ${response.data['message']}');
      }
    } catch (e) {
      throw Exception('获取作者信息失败: $e');
    }
  }

  /// 获取作者的粉丝列表
  Future<Map<String, dynamic>> getAuthorFollowers(
    String authorId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _httpClient.get(
        '/authors/$authorId/followers',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.data['code'] == 0) {
        return response.data;
      } else {
        throw Exception('获取粉丝列表失败: ${response.data['message']}');
      }
    } catch (e) {
      throw Exception('获取粉丝列表失败: $e');
    }
  }

  /// 获取作品详情
  Future<Map<String, dynamic>> getItemDetail(String itemId) async {
    try {
      final response = await _httpClient.get('/hall/items/$itemId/detail');

      if (response.data['code'] == 0) {
        return response.data['data'];
      } else {
        throw Exception(response.data['msg'] ?? '获取作品详情失败');
      }
    } catch (e) {
      throw Exception('获取作品详情失败: $e');
    }
  }

  /// 获取我的粉丝列表
  Future<Map<String, dynamic>> getMyFollowers({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _httpClient.get(
        '/authors/followers',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.data['code'] == 0) {
        return response.data;
      } else {
        throw Exception('获取我的粉丝列表失败: ${response.data['msg']}');
      }
    } catch (e) {
      throw Exception('获取我的粉丝列表失败: $e');
    }
  }

  /// 随机抽卡
  Future<Map<String, dynamic>> drawCards() async {
    try {
      final response = await _httpClient.post('/hall/draw-cards');

      if (response.data['code'] == 0) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '抽卡失败');
      }
    } catch (e) {
      throw Exception('抽卡失败: $e');
    }
  }
}
