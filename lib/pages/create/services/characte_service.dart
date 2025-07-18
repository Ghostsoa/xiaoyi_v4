import '../../../net/http_client.dart';

class CharacterService {
  final _httpClient = HttpClient();

  Future<Map<String, dynamic>> createCharacter(
      Map<String, dynamic> data) async {
    try {
      final response = await _httpClient.post('/characters', data: data);
      return response.data;
    } catch (e) {
      return {
        'code': -1,
        'msg': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getCharacterList({
    int page = 1,
    int pageSize = 10,
    String? keyword,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'pageSize': pageSize,
      };

      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response =
          await _httpClient.get('/characters', queryParameters: queryParams);
      return response.data;
    } catch (e) {
      return {
        'code': -1,
        'msg': e.toString(),
        'data': {
          'items': [],
          'total': 0,
        },
      };
    }
  }

  Future<Map<String, dynamic>> updateCharacter(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _httpClient.put('/characters/$id', data: data);
      return response.data;
    } catch (e) {
      return {
        'code': -1,
        'msg': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updateCharacterStatus(
      String id, String status) async {
    try {
      final response = await _httpClient.put('/characters/$id/status', data: {
        'status': status,
      });
      return response.data;
    } catch (e) {
      return {
        'code': -1,
        'msg': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> deleteCharacter(String id) async {
    try {
      final response = await _httpClient.delete('/characters/$id');
      return response.data;
    } catch (e) {
      return {
        'code': -1,
        'msg': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> formatMarkdown(String text) async {
    try {
      final response = await _httpClient.post('/format-markdown', data: {
        'text': text,
      });
      return response.data;
    } catch (e) {
      return {
        'code': -1,
        'msg': e.toString(),
        'data': null,
      };
    }
  }
}
