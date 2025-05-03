import '../net/http_client.dart';

class ModelService {
  final HttpClient _httpClient = HttpClient();

  // 单例模式
  static final ModelService _instance = ModelService._internal();
  factory ModelService() => _instance;
  ModelService._internal();

  /// 获取所有可用的模型系列和模型
  /// 返回格式：
  /// [
  ///   {
  ///     "id": 1,
  ///     "name": "gemini",
  ///     "displayName": "哈基米",
  ///     "endpoint": "",
  ///     "status": 1,
  ///     "createdAt": "2025-05-02T07:58:18.37259Z",
  ///     "updatedAt": "2025-05-02T07:58:18.37259Z",
  ///     "models": [
  ///       {
  ///         "id": 1,
  ///         "seriesId": 1,
  ///         "name": "gemini-2.0-flash",
  ///         "displayName": "哈基米2.0",
  ///         "inputPrice": 1000,
  ///         "outputPrice": 2000,
  ///         "status": 1,
  ///         "createdAt": "2025-05-02T08:01:23.5214Z",
  ///         "updatedAt": "2025-05-02T08:01:23.5214Z"
  ///       }
  ///     ]
  ///   }
  /// ]
  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    try {
      final response = await _httpClient.get('/models');

      if (response.data['code'] == 0) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        throw Exception(response.data['msg'] ?? '获取模型列表失败');
      }
    } catch (e) {
      throw Exception('获取模型列表失败: $e');
    }
  }

  /// 根据系列名称获取单个系列的所有模型
  Future<Map<String, dynamic>?> getModelsBySeries(String seriesName) async {
    try {
      final allModels = await getAvailableModels();
      return allModels.firstWhere(
        (item) => item['series']['name'] == seriesName,
        orElse: () => throw Exception('未找到指定的模型系列'),
      );
    } catch (e) {
      throw Exception('获取模型系列失败: $e');
    }
  }

  /// 根据系列名称和模型名称获取单个模型
  Future<Map<String, dynamic>?> getModelByName(
    String seriesName,
    String modelName,
  ) async {
    try {
      final series = await getModelsBySeries(seriesName);
      if (series == null) return null;

      final models = List<Map<String, dynamic>>.from(series['models']);
      return models.firstWhere(
        (model) => model['name'] == modelName,
        orElse: () => throw Exception('未找到指定的模型'),
      );
    } catch (e) {
      throw Exception('获取模型失败: $e');
    }
  }
}
