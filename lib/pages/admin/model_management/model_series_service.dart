import 'package:dio/dio.dart';
import '../../../net/http_client.dart';

class ModelSeriesService {
  final HttpClient _httpClient = HttpClient();

  /// 获取模型系列列表
  Future<Response> getModelSeriesList({
    int page = 1,
    int pageSize = 10,
  }) async {
    return await _httpClient.get(
      '/admin/models/series',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  /// 创建模型系列
  Future<Response> createModelSeries({
    required String name,
    required String displayName,
    required String endpoint,
    required int status,
  }) async {
    return await _httpClient.post(
      '/admin/models/series',
      data: {
        'name': name,
        'displayName': displayName,
        'endpoint': endpoint,
        'status': status,
      },
    );
  }

  /// 更新模型系列
  Future<Response> updateModelSeries({
    required int id,
    String? displayName,
    String? endpoint,
    int? status,
  }) async {
    final Map<String, dynamic> data = {};
    if (displayName != null) data['displayName'] = displayName;
    if (endpoint != null) data['endpoint'] = endpoint;
    if (status != null) data['status'] = status;

    return await _httpClient.put(
      '/admin/models/series/$id',
      data: data,
    );
  }

  /// 删除模型系列
  Future<Response> deleteModelSeries(int id) async {
    return await _httpClient.delete('/admin/models/series/$id');
  }

  /// 获取模型列表
  Future<Response> getModelList({
    required int seriesId,
    int page = 1,
    int pageSize = 10,
  }) async {
    return await _httpClient.get(
      '/admin/models',
      queryParameters: {
        'seriesId': seriesId,
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  /// 创建模型
  Future<Response> createModel({
    required int seriesId,
    required String name,
    required String displayName,
    required double inputPrice,
    required double outputPrice,
    required int status,
  }) async {
    return await _httpClient.post(
      '/admin/models',
      data: {
        'seriesId': seriesId,
        'name': name,
        'displayName': displayName,
        'inputPrice': inputPrice,
        'outputPrice': outputPrice,
        'status': status,
      },
    );
  }

  /// 删除模型
  Future<Response> deleteModel(int id) async {
    return await _httpClient.delete('/admin/models/$id');
  }

  /// 获取API密钥列表
  Future<Response> getApiKeys(String seriesName) async {
    return await _httpClient.get(
      '/admin/models/api-keys',
      queryParameters: {
        'seriesName': seriesName,
      },
    );
  }

  /// 添加API密钥
  Future<Response> addApiKey({
    required String seriesName,
    required String key,
  }) async {
    return await _httpClient.post(
      '/admin/models/api-keys',
      data: {
        'seriesName': seriesName,
        'key': key,
      },
    );
  }

  /// 删除API密钥
  Future<Response> deleteApiKey({
    required String seriesName,
    required String key,
  }) async {
    return await _httpClient.delete(
      '/admin/models/api-keys',
      data: {
        'seriesName': seriesName,
        'key': key,
      },
    );
  }
}
