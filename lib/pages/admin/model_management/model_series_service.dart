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

  /// 获取单个模型系列
  Future<Response> getModelSeries(int id) async {
    return await _httpClient.get('/admin/models/series/$id');
  }

  /// 创建模型系列
  Future<Response> createModelSeries({
    required String name,
    required String displayName,
    required String endpoint,
    String? description,
    required int status,
  }) async {
    return await _httpClient.post(
      '/admin/models/series',
      data: {
        'name': name,
        'displayName': displayName,
        'endpoint': endpoint,
        'description': description,
        'status': status,
      },
    );
  }

  /// 更新模型系列
  Future<Response> updateModelSeries({
    required int id,
    String? name,
    String? displayName,
    String? endpoint,
    String? description,
    int? status,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (displayName != null) data['displayName'] = displayName;
    if (endpoint != null) data['endpoint'] = endpoint;
    if (description != null) data['description'] = description;
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
    int? seriesId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'pageSize': pageSize,
    };

    if (seriesId != null) {
      queryParams['seriesId'] = seriesId;
    }

    return await _httpClient.get(
      '/admin/models',
      queryParameters: queryParams,
    );
  }

  /// 获取单个模型
  Future<Response> getModel(int id) async {
    return await _httpClient.get('/admin/models/$id');
  }

  /// 创建模型
  Future<Response> createModel({
    required int seriesId,
    required String name,
    required String displayName,
    String? description,
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
        'description': description,
        'inputPrice': inputPrice,
        'outputPrice': outputPrice,
        'status': status,
      },
    );
  }

  /// 更新模型
  Future<Response> updateModel({
    required int id,
    String? name,
    String? displayName,
    String? description,
    double? inputPrice,
    double? outputPrice,
    int? status,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (displayName != null) data['displayName'] = displayName;
    if (description != null) data['description'] = description;
    if (inputPrice != null) data['inputPrice'] = inputPrice;
    if (outputPrice != null) data['outputPrice'] = outputPrice;
    if (status != null) data['status'] = status;

    return await _httpClient.put(
      '/admin/models/$id',
      data: data,
    );
  }

  /// 删除模型
  Future<Response> deleteModel(int id) async {
    return await _httpClient.delete('/admin/models/$id');
  }

  /// 获取API密钥列表
  Future<Response> getApiKeys({
    required int seriesId,
    int page = 1,
    int pageSize = 10,
  }) async {
    return await _httpClient.get(
      '/admin/models/api-keys',
      queryParameters: {
        'seriesId': seriesId,
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  /// 添加API密钥
  Future<Response> addApiKey({
    required int seriesId,
    required String key,
  }) async {
    return await _httpClient.post(
      '/admin/models/api-keys',
      data: {
        'seriesId': seriesId,
        'key': key,
      },
    );
  }

  /// 批量添加API密钥
  Future<Response> batchAddApiKeys({
    required int seriesId,
    required List<String> keys,
  }) async {
    return await _httpClient.post(
      '/admin/models/api-keys/batch',
      data: {
        'seriesId': seriesId,
        'keys': keys,
      },
    );
  }

  /// 删除API密钥
  Future<Response> deleteApiKey(int id) async {
    return await _httpClient.delete('/admin/models/api-keys/$id');
  }

  /// 获取API密钥（内部接口）
  Future<Response> getApiKey(String modelName) async {
    return await _httpClient.get(
      '/admin/models/api-keys/get-key',
      queryParameters: {
        'modelName': modelName,
      },
    );
  }

  /// 获取所有系列及其模型
  Future<Response> getAllSeriesWithModels() async {
    return await _httpClient.get('/admin/models/all-series-with-models');
  }
}
