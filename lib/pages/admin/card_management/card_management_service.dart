import '../../../net/http_client.dart';

class CardManagementService {
  final HttpClient _httpClient = HttpClient();

  // 获取卡密列表
  Future<Map<String, dynamic>> getCardList({
    String? cardSecret,
    String? cardType,
    int? status,
    String? batchNo,
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
    if (batchNo != null && batchNo.isNotEmpty) {
      queryParams['batch_no'] = batchNo;
    }

    try {
      final response = await _httpClient.get(
        '/admin/cards',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '获取卡密列表失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 创建单个卡密
  Future<Map<String, dynamic>> createCard({
    required String cardType,
    required int amount,
    String? batchNo,
    String? remark,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'card_type': cardType,
        'amount': amount,
      };

      if (batchNo != null && batchNo.isNotEmpty) data['batch_no'] = batchNo;
      if (remark != null && remark.isNotEmpty) data['remark'] = remark;

      final response = await _httpClient.post(
        '/admin/cards',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '创建卡密失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 批量创建卡密
  Future<Map<String, dynamic>> batchCreateCards({
    required String cardType,
    required int amount,
    required int count,
    String? batchNo,
    String? remark,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'card_type': cardType,
        'amount': amount,
        'count': count,
      };

      if (batchNo != null && batchNo.isNotEmpty) data['batch_no'] = batchNo;
      if (remark != null && remark.isNotEmpty) data['remark'] = remark;

      final response = await _httpClient.post(
        '/admin/cards/batch',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '批量创建卡密失败');
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
        throw Exception(response.data['msg'] ?? '获取卡密详情失败');
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
        throw Exception(response.data['msg'] ?? '禁用卡密失败');
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
        throw Exception(response.data['msg'] ?? '启用卡密失败');
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
        throw Exception(response.data['msg'] ?? '批量禁用卡密失败');
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
        throw Exception(response.data['msg'] ?? '批量启用卡密失败');
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
        throw Exception(response.data['msg'] ?? '删除卡密失败');
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
        throw Exception(response.data['msg'] ?? '批量删除卡密失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 导出未使用的卡密
  Future<Map<String, dynamic>> exportUnusedCards({
    String? cardType,
    String? batchNo,
  }) async {
    Map<String, dynamic> queryParams = {};

    if (cardType != null) queryParams['card_type'] = cardType;
    if (batchNo != null && batchNo.isNotEmpty) {
      queryParams['batch_no'] = batchNo;
    }

    try {
      final response = await _httpClient.get(
        '/admin/cards/export',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '导出未使用卡密失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
