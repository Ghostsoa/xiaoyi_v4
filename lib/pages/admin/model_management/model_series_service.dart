import 'package:dio/dio.dart';
import '../../../net/http_client.dart';

class ModelSeriesService {
  final HttpClient _httpClient = HttpClient();

  /// 批量添加官方API密钥
  Future<Response> batchAddOfficialApiKeys({
    required List<String> apiKeys,
    String? endpoint,
    required List<Map<String, dynamic>> modelQuotas,
  }) async {
    final Map<String, dynamic> data = {
      'apiKeys': apiKeys,
      'modelQuotas': modelQuotas,
    };
    if (endpoint != null && endpoint.isNotEmpty) {
      data['endpoint'] = endpoint;
    }
    return await _httpClient.post(
      '/admin/official-apikeys',
      data: data,
    );
  }

  /// 获取所有官方API密钥列表
  Future<Response> getOfficialApiKeys({int page = 1, int pageSize = 10}) async {
    return await _httpClient.get(
      '/admin/official-apikeys',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  /// 获取单个官方API密钥详情
  Future<Response> getOfficialApiKey(int id) async {
    return await _httpClient.get('/admin/official-apikeys/$id');
  }

  /// 获取密钥配额信息
  Future<Response> getOfficialApiKeyQuotas(int id) async {
    return await _httpClient.get('/admin/official-apikeys/$id/quotas');
  }

  /// 更新官方API密钥状态
  Future<Response> updateOfficialApiKeysStatus({
    required List<int> ids,
    required int status,
  }) async {
    return await _httpClient.put(
      '/admin/official-apikeys/status',
      data: {
        'ids': ids,
        'status': status,
      },
    );
  }

  /// 批量删除官方API密钥
  Future<Response> batchDeleteOfficialApiKeys(List<int> ids) async {
    return await _httpClient.delete(
      '/admin/official-apikeys',
      data: ids,
    );
  }
}
