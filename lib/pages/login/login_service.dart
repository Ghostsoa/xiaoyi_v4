import '../../net/http_client.dart';
import '../../dao/user_dao.dart';

class LoginService {
  final HttpClient _httpClient = HttpClient();
  final UserDao _userDao = UserDao();

  // 登录请求
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _httpClient.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      // 返回响应数据
      return response.data;
    } catch (e) {
      // 网络错误或其他异常
      throw Exception('登录失败: 网络连接错误');
    }
  }

  // 保存用户信息和token
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    // 使用UserDao保存用户信息
    await _userDao.saveUserInfo(userData);

    // 设置网络请求的token
    final token = userData['token'];
    _httpClient.setToken(token);
  }

  // 退出登录
  Future<void> logout() async {
    await _userDao.clearUserInfo();
    _httpClient.clearToken();
  }
}
