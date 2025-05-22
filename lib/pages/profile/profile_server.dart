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
}
