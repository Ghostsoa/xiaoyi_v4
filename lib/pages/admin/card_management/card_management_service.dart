import '../../../net/http_client.dart';

class CardManagementService {
  final HttpClient _httpClient = HttpClient();

  // ==================== 卡密管理接口 ====================

  // 查询卡密列表
  Future<Map<String, dynamic>> getCardList({
    String? cardSecret,
    String? cardType,
    int? status,
    int? batchId,
    int page = 1,
    int pageSize = 10,
  }) async {
    Map<String, dynamic> queryParams = {
      'page': page,
      'page_size': pageSize,
    };

    if (cardSecret != null && cardSecret.isNotEmpty) {
      queryParams['card_secret'] = cardSecret;
    }
    if (cardType != null) queryParams['card_type'] = cardType;
    if (status != null && status >= 0) queryParams['status'] = status;
    if (batchId != null) queryParams['batch_id'] = batchId;

    try {
      final response = await _httpClient.get(
        '/admin/cards',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '获取卡密列表失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 精确搜索卡密
  Future<Map<String, dynamic>> searchCard(String cardSecret) async {
    try {
      final response = await _httpClient.get(
        '/admin/cards/search',
        queryParameters: {'card_secret': cardSecret},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '搜索卡密失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 获取卡密详情
  Future<Map<String, dynamic>> getCardDetail(int cardId) async {
    try {
      final response = await _httpClient.get('/admin/cards/$cardId');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '获取卡密详情失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 禁用卡密
  Future<void> disableCard(int cardId) async {
    try {
      final response = await _httpClient.put('/admin/cards/$cardId/disable');

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? '禁用卡密失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 启用卡密
  Future<void> enableCard(int cardId) async {
    try {
      final response = await _httpClient.put('/admin/cards/$cardId/enable');

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? '启用卡密失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 批量禁用卡密
  Future<Map<String, dynamic>> batchDisableCards(List<int> cardIds) async {
    try {
      final response = await _httpClient.post(
        '/admin/cards/disable-batch',
        data: {'card_ids': cardIds},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '批量禁用卡密失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 批量启用卡密
  Future<Map<String, dynamic>> batchEnableCards(List<int> cardIds) async {
    try {
      final response = await _httpClient.post(
        '/admin/cards/enable-batch',
        data: {'card_ids': cardIds},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '批量启用卡密失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 删除卡密
  Future<void> deleteCard(int cardId) async {
    try {
      final response = await _httpClient.delete('/admin/cards/$cardId');

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? '删除卡密失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 批量删除卡密
  Future<Map<String, dynamic>> batchDeleteCards(List<int> cardIds) async {
    try {
      final response = await _httpClient.post(
        '/admin/cards/delete-batch',
        data: {'card_ids': cardIds},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '批量删除卡密失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ==================== 批次管理接口 ====================

  // 创建卡密批次
  Future<Map<String, dynamic>> createCardBatch({
    required String cardType,
    required int amount,
    required int count,
    String? remark,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'card_type': cardType,
        'amount': amount,
        'count': count,
      };

      if (remark != null && remark.isNotEmpty) data['remark'] = remark;

      final response = await _httpClient.post(
        '/admin/card-batches',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '创建卡密批次失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 查询批次列表
  Future<Map<String, dynamic>> getBatchList({
    String? cardType,
    int? status,
    String? keyword,
    int page = 1,
    int pageSize = 10,
  }) async {
    Map<String, dynamic> queryParams = {
      'page': page,
      'page_size': pageSize,
    };

    if (cardType != null) queryParams['card_type'] = cardType;
    if (status != null) queryParams['status'] = status;
    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }

    try {
      final response = await _httpClient.get(
        '/admin/card-batches',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '获取批次列表失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 获取批次详情
  Future<Map<String, dynamic>> getBatchDetail(int batchId) async {
    try {
      final response = await _httpClient.get('/admin/card-batches/$batchId');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '获取批次详情失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 禁用批次
  Future<Map<String, dynamic>> disableBatch(int batchId) async {
    try {
      final response =
          await _httpClient.put('/admin/card-batches/$batchId/disable');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '禁用批次失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 启用批次
  Future<Map<String, dynamic>> enableBatch(int batchId) async {
    try {
      final response =
          await _httpClient.put('/admin/card-batches/$batchId/enable');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '启用批次失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 删除批次
  Future<Map<String, dynamic>> deleteBatch(int batchId) async {
    try {
      final response = await _httpClient.delete('/admin/card-batches/$batchId');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '删除批次失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 删除空批次
  Future<Map<String, dynamic>> deleteEmptyBatches() async {
    try {
      final response = await _httpClient.delete('/admin/card-batches/empty');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '删除空批次失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 删除批次中未使用的卡密
  Future<Map<String, dynamic>> deleteUnusedCardsInBatch(int batchId) async {
    try {
      final response =
          await _httpClient.delete('/admin/card-batches/$batchId/unused');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '删除未使用卡密失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 导出批次中未使用的卡密
  Future<Map<String, dynamic>> exportUnusedCardsInBatch(int batchId) async {
    try {
      final response =
          await _httpClient.get('/admin/card-batches/$batchId/export');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '导出未使用卡密失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
