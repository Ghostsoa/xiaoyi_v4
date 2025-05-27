import '../../../net/http_client.dart';

class NovelService {
  final _httpClient = HttpClient();

  // 统一处理响应，将msg转为message
  Map<String, dynamic> _processResponse(Map<String, dynamic> response) {
    // 如果有msg字段但没有message字段，将msg复制到message
    if (response.containsKey('msg') && !response.containsKey('message')) {
      response['message'] = response['msg'];
    }
    return response;
  }

  // 创建小说
  Future<Map<String, dynamic>> createNovel(Map<String, dynamic> data) async {
    try {
      final response = await _httpClient.post('/novels', data: data);
      return _processResponse(response.data);
    } catch (e) {
      return {
        'code': -1,
        'message': e.toString(),
        'data': null,
      };
    }
  }

  // 获取用户小说列表
  Future<Map<String, dynamic>> getUserNovels({
    int page = 1,
    int pageSize = 10,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'page_size': pageSize,
      };

      // 添加状态过滤
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response =
          await _httpClient.get('/novels', queryParameters: queryParams);
      return _processResponse(response.data);
    } catch (e) {
      return {
        'code': -1,
        'message': e.toString(),
        'data': {
          'novels': [],
          'total': 0,
          'page': page,
          'size': pageSize,
        },
      };
    }
  }

  // 获取小说详情
  Future<Map<String, dynamic>> getNovelDetail(String id) async {
    try {
      final response = await _httpClient.get('/novels/$id');
      return _processResponse(response.data);
    } catch (e) {
      return {
        'code': -1,
        'message': e.toString(),
        'data': null,
      };
    }
  }

  // 更新小说
  Future<Map<String, dynamic>> updateNovel(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _httpClient.put('/novels/$id', data: data);
      return _processResponse(response.data);
    } catch (e) {
      return {
        'code': -1,
        'message': e.toString(),
        'data': null,
      };
    }
  }

  // 删除小说
  Future<Map<String, dynamic>> deleteNovel(String id) async {
    try {
      final response = await _httpClient.delete('/novels/$id');
      return _processResponse(response.data);
    } catch (e) {
      return {
        'code': -1,
        'message': e.toString(),
        'data': null,
      };
    }
  }
}
