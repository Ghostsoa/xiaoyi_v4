import '../../../net/http_client.dart';

class UserManagementService {
  final HttpClient _httpClient = HttpClient();

  // 获取用户列表
  Future<Map<String, dynamic>> getUserList({
    int page = 1,
    int pageSize = 10,
    String? status,
    String? role,
    String? keyword,
  }) async {
    Map<String, dynamic> queryParams = {
      'page': page,
      'page_size': pageSize,
    };

    if (status != null) queryParams['status'] = status;
    if (role != null) queryParams['role'] = role;
    if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;

    try {
      final response = await _httpClient.get(
        '/admin/users',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '获取用户列表失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 禁用用户
  Future<void> disableUser(int userId) async {
    try {
      final response = await _httpClient.put('/admin/user/$userId/disable');

      if (response.statusCode != 200) {
        throw Exception(response.data['msg'] ?? '禁用用户失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 启用用户
  Future<void> enableUser(int userId) async {
    try {
      final response = await _httpClient.put('/admin/user/$userId/enable');

      if (response.statusCode != 200) {
        throw Exception(response.data['msg'] ?? '启用用户失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 设置用户角色
  Future<void> setUserRole(int userId, int role) async {
    try {
      final response = await _httpClient.put(
        '/admin/user/$userId/role',
        data: {'Role': role.toString()},
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['msg'] ?? '设置用户角色失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 强制用户下线
  Future<void> forceLogout(int userId) async {
    try {
      final response =
          await _httpClient.post('/admin/user/$userId/force-logout');

      if (response.statusCode != 200) {
        throw Exception(response.data['msg'] ?? '强制用户下线失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 增加用户小懿币
  Future<Map<String, dynamic>> addUserCoin(
    int userId, {
    required int amount,
    required String description,
    String? refId,
    String? refType,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'amount': amount,
        'description': description,
      };

      if (refId != null) data['ref_id'] = refId;
      if (refType != null) data['ref_type'] = refType;

      final response = await _httpClient.post(
        '/admin/user/$userId/coin',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '增加小懿币失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 扣除用户小懿币
  Future<Map<String, dynamic>> deductUserCoin(
    int userId, {
    required int amount,
    required String description,
    String? refId,
    String? refType,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'amount': amount,
        'description': description,
      };

      if (refId != null) data['ref_id'] = refId;
      if (refType != null) data['ref_type'] = refType;

      final response = await _httpClient.post(
        '/admin/user/$userId/coin-deduct',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '扣除小懿币失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 增加用户经验值
  Future<Map<String, dynamic>> addUserExperience(
    int userId, {
    required int amount,
    required String description,
    String? refId,
    String? refType,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'amount': amount,
        'description': description,
      };

      if (refId != null) data['ref_id'] = refId;
      if (refType != null) data['ref_type'] = refType;

      final response = await _httpClient.post(
        '/admin/user/$userId/experience',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '增加经验值失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 增加用户畅玩时长
  Future<Map<String, dynamic>> addUserPlayTime(
    int userId, {
    required int hours,
    required String description,
    String? refId,
    String? refType,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'hours': hours,
        'description': description,
      };

      if (refId != null) data['ref_id'] = refId;
      if (refType != null) data['ref_type'] = refType;

      final response = await _httpClient.post(
        '/admin/user/$userId/play-time',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['msg'] ?? '增加畅玩时长失败');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
