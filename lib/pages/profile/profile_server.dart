import '../../net/http_client.dart';

class ProfileServer {
  final HttpClient _httpClient = HttpClient();

  // 获取用户资产信息
  Future<Map<String, dynamic>> getUserAssets() async {
    try {
      final response = await _httpClient.get('/assets');

      // 无论HTTP状态码如何，只要响应中有data字段，就尝试从中获取错误信息
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        // 优先从响应体中获取code和msg
        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'] ?? {},
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '获取成功' : '获取失败'),
            'code': responseData['code']
          };
        }
      }

      // 如果无法从响应体中获取错误信息，则使用HTTP状态码
      if (response.statusCode == 200) {
        return {'success': true, 'data': {}, 'msg': '获取成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': {},
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': {}, 'msg': e.toString(), 'code': -1};
    }
  }

  // 获取资产变动记录
  Future<Map<String, dynamic>> getAssetRecords(
      {String? assetType, int page = 1, int pageSize = 10}) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'page_size': pageSize,
      };

      if (assetType != null) {
        queryParams['asset_type'] = assetType;
      }

      final response = await _httpClient.get(
        '/assets/records',
        queryParameters: queryParams,
      );

      // 无论HTTP状态码如何，只要响应中有data字段，就尝试从中获取错误信息
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        // 优先从响应体中获取code和msg
        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'] ?? {},
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '获取成功' : '获取失败'),
            'code': responseData['code']
          };
        }
      }

      // 如果无法从响应体中获取错误信息，则使用HTTP状态码
      if (response.statusCode == 200) {
        return {'success': true, 'data': {}, 'msg': '获取成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': {},
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': {}, 'msg': e.toString(), 'code': -1};
    }
  }

  // 更新用户信息
  Future<Map<String, dynamic>> updateUserInfo({
    required String username,
    String? avatar,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'username': username,
      };

      // 如果有头像 URI，添加到请求数据中
      if (avatar != null) {
        data['avatar'] = avatar;
      }

      final response = await _httpClient.put(
        '/user',
        data: data,
      );

      // 无论HTTP状态码如何，只要响应中有data字段，就尝试从中获取错误信息
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        // 优先从响应体中获取code和msg
        if (responseData.containsKey('code') &&
            responseData.containsKey('msg')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'] ?? {},
            'msg': responseData['msg'],
            'code': responseData['code']
          };
        }
      }

      // 如果无法从响应体中获取错误信息，则使用HTTP状态码
      if (response.statusCode == 200) {
        return {'success': true, 'data': {}, 'msg': '操作成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': {},
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': {}, 'msg': e.toString(), 'code': -1};
    }
  }

  // 兑换卡密
  Future<Map<String, dynamic>> redeemCard({
    required String cardSecret,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'card_secret': cardSecret,
      };

      final response = await _httpClient.post(
        '/cards/redeem',
        data: data,
      );

      // 无论HTTP状态码如何，只要响应中有data字段，就尝试从中获取错误信息
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        // 优先从响应体中获取code和msg
        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'] ?? {},
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '兑换成功' : '兑换失败'),
            'code': responseData['code']
          };
        }
      }

      // 如果无法从响应体中获取错误信息，则使用HTTP状态码
      if (response.statusCode == 200) {
        return {'success': true, 'data': {}, 'msg': '兑换成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': {},
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': {}, 'msg': e.toString(), 'code': -1};
    }
  }

  // 兑换小懿币为畅玩时长
  Future<Map<String, dynamic>> exchangePlayTime({
    required double coin,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'coin': coin,
      };

      if (description != null && description.isNotEmpty) {
        data['description'] = description;
      }

      final response = await _httpClient.post(
        '/assets/exchange/play-time',
        data: data,
      );

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'] ?? {},
            'msg': responseData['message'] ??
                (responseData['code'] == 0 ? '兑换成功' : '兑换失败'),
            'code': responseData['code']
          };
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': {}, 'msg': '兑换成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': {},
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': {}, 'msg': e.toString(), 'code': -1};
    }
  }

  // 同步旧资产数据
  Future<Map<String, dynamic>> syncOldAssets() async {
    try {
      final response = await _httpClient.post('/assets/sync-old');

      // 无论HTTP状态码如何，只要响应中有data字段，就尝试从中获取错误信息
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        // 优先从响应体中获取code和msg
        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'] ?? {},
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '同步成功' : '同步失败'),
            'code': responseData['code']
          };
        }
      }

      // 如果无法从响应体中获取错误信息，则使用HTTP状态码
      if (response.statusCode == 200) {
        return {'success': true, 'data': {}, 'msg': '同步成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': {},
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': {}, 'msg': e.toString(), 'code': -1};
    }
  }

  // 获取所有API密钥
  Future<Map<String, dynamic>> getApiKeys() async {
    try {
      final response = await _httpClient.get('/api-keys');

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'] ?? [],
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '获取成功' : '获取失败'),
            'code': responseData['code']
          };
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': [], 'msg': '获取成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': [],
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': [], 'msg': e.toString(), 'code': -1};
    }
  }

  // 获取单个API密钥详情
  Future<Map<String, dynamic>> getApiKeyDetail(int id) async {
    try {
      final response = await _httpClient.get('/api-keys/$id');

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'] ?? {},
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '获取成功' : '获取失败'),
            'code': responseData['code']
          };
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': {}, 'msg': '获取成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': {},
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': {}, 'msg': e.toString(), 'code': -1};
    }
  }

  // 添加API密钥
  Future<Map<String, dynamic>> addApiKey({
    required String apiKey,
    required String endpoint,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'apiKey': apiKey,
        'endpoint': endpoint,
      };

      final response = await _httpClient.post(
        '/api-keys',
        data: data,
      );

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'] ?? {},
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '添加成功' : '添加失败'),
            'code': responseData['code']
          };
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': {}, 'msg': '添加成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': {},
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': {}, 'msg': e.toString(), 'code': -1};
    }
  }

  // 更新API密钥
  Future<Map<String, dynamic>> updateApiKey({
    required int id,
    required String apiKey,
    required String endpoint,
    int? status,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'apiKey': apiKey,
        'endpoint': endpoint,
      };

      if (status != null) {
        data['status'] = status;
      }

      final response = await _httpClient.put(
        '/api-keys/$id',
        data: data,
      );

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'] ?? {},
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '更新成功' : '更新失败'),
            'code': responseData['code']
          };
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': {}, 'msg': '更新成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': {},
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': {}, 'msg': e.toString(), 'code': -1};
    }
  }

  // 删除API密钥
  Future<Map<String, dynamic>> deleteApiKey(int id) async {
    try {
      final response = await _httpClient.delete('/api-keys/$id');

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': {},
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '删除成功' : '删除失败'),
            'code': responseData['code']
          };
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': {}, 'msg': '删除成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': {},
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': {}, 'msg': e.toString(), 'code': -1};
    }
  }

  // 更新API密钥状态
  Future<Map<String, dynamic>> updateApiKeyStatus({
    required int id,
    required int status,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'status': status,
      };

      final response = await _httpClient.put(
        '/api-keys/$id/status',
        data: data,
      );

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'] ?? {},
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '状态更新成功' : '状态更新失败'),
            'code': responseData['code']
          };
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': {}, 'msg': '状态更新成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': {},
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': {}, 'msg': e.toString(), 'code': -1};
    }
  }

  // 批量添加API密钥
  Future<Map<String, dynamic>> batchAddApiKeys({
    required List<String> apiKeys,
    required String endpoint,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'apiKeys': apiKeys,
        'endpoint': endpoint,
      };

      final response = await _httpClient.post(
        '/api-keys/batch',
        data: data,
      );

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'] ?? [],
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '批量添加成功' : '批量添加失败'),
            'code': responseData['code']
          };
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': [], 'msg': '批量添加成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': [],
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': [], 'msg': e.toString(), 'code': -1};
    }
  }

  // 批量删除API密钥
  Future<Map<String, dynamic>> batchDeleteApiKeys({
    required List<int> ids,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'ids': ids,
      };

      final response = await _httpClient.delete(
        '/api-keys/batch',
        data: data,
      );

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': {},
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '批量删除成功' : '批量删除失败'),
            'code': responseData['code']
          };
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': {}, 'msg': '批量删除成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': {},
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': {}, 'msg': e.toString(), 'code': -1};
    }
  }

  // 获取可用的官方模型配额
  Future<Map<String, dynamic>> getAvailableOfficialModels() async {
    try {
      final response = await _httpClient.get('/official-available-models');

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'] ?? [],
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '获取模型配额信息成功' : '获取模型配额信息失败'),
            'code': responseData['code']
          };
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': [], 'msg': '获取模型配额信息成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': [],
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': [], 'msg': e.toString(), 'code': -1};
    }
  }

  // 切换官方密钥使用状态
  Future<Map<String, dynamic>> toggleOfficialKey() async {
    try {
      final response = await _httpClient.post('/official-key/toggle');

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'] ?? {},
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '官方密钥状态切换成功' : '官方密钥状态切换失败'),
            'code': responseData['code']
          };
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': {}, 'msg': '官方密钥状态切换成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': {},
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': {}, 'msg': e.toString(), 'code': -1};
    }
  }

  // 批量更新API密钥状态
  Future<Map<String, dynamic>> batchUpdateApiKeyStatus({
    required List<int> ids,
    required int status,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'ids': ids,
        'status': status,
      };

      final response = await _httpClient.put(
        '/api-keys/batch/status',
        data: data,
      );

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'],
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '批量更新API密钥状态成功' : '批量更新API密钥状态失败'),
            'code': responseData['code']
          };
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': null, 'msg': '批量更新API密钥状态成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': null,
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': null, 'msg': e.toString(), 'code': -1};
    }
  }

  // 一键更新所有API密钥状态
  Future<Map<String, dynamic>> updateAllApiKeyStatus({
    required int status,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'status': status,
      };

      final response = await _httpClient.put(
        '/api-keys/all/status',
        data: data,
      );

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'],
            'msg': responseData['msg'] ??
                (responseData['code'] == 0 ? '一键更新所有API密钥状态成功' : '一键更新所有API密钥状态失败'),
            'code': responseData['code']
          };
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': null, 'msg': '一键更新所有API密钥状态成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': null,
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': null, 'msg': e.toString(), 'code': -1};
    }
  }

  // 一键删除所有封禁的API密钥
  Future<Map<String, dynamic>> deleteAllBannedApiKeys() async {
    try {
      final response = await _httpClient.delete('/api-keys/banned/all');

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData.containsKey('code')) {
          return {
            'success': responseData['code'] == 0,
            'data': responseData['data'],
            'msg': responseData['message'] ?? responseData['msg'] ??
                (responseData['code'] == 0 ? '一键删除所有封禁API密钥成功' : '一键删除所有封禁API密钥失败'),
            'code': responseData['code']
          };
        }
      }

      if (response.statusCode == 200) {
        return {'success': true, 'data': null, 'msg': '一键删除所有封禁API密钥成功', 'code': 0};
      } else {
        return {
          'success': false,
          'data': null,
          'msg': '${response.statusCode}',
          'code': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'data': null, 'msg': e.toString(), 'code': -1};
    }
  }
}
