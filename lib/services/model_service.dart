import '../net/http_client.dart';

class ModelService {
  final HttpClient _httpClient = HttpClient();

  // 单例模式
  static final ModelService _instance = ModelService._internal();
  factory ModelService() => _instance;
  ModelService._internal();

  /// 获取所有可用的模型
  /// 返回格式：
  /// [
  ///   {
  ///     "id": "1",
  ///     "name": "gemini-2.5-flash-preview-05-20",
  ///     "description": "Gemini 2.5 Flash 预览版 (2024年5月20日)",
  ///     "provider": "Google"
  ///   },
  ///   ...
  /// ]
  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    try {
      final response = await _httpClient.get('/available-models');

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
