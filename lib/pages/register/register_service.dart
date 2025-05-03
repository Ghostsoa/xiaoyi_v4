import '../../net/http_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterService {
  final HttpClient _httpClient = HttpClient();

  // 发送注册验证码
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    try {
      final response = await _httpClient.post(
        '/register/code',
        data: {
          'email': email,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('发送验证码失败: 网络连接错误');
    }
  }

  // 注册新用户
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String code,
    int? inviterId,
  }) async {
    try {
      final response = await _httpClient.post(
        '/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'code': code,
          'inviter_id': inviterId,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('注册失败: 网络连接错误');
    }
  }

  // 保存登录凭据，注册成功后自动填充登录表单
  Future<void> saveLoginCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    // 保存邮箱和密码，但不启用记住我功能
    await prefs.setString('email', email);
    await prefs.setString('password', password);

    // 设置标志，表示是新注册用户
    await prefs.setBool('isNewRegistered', true);
  }
}
