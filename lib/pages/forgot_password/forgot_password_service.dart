import '../../net/http_client.dart';

class ForgotPasswordService {
  final HttpClient _httpClient = HttpClient();

  // 发送找回密码验证码
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    try {
      final response = await _httpClient.post(
        '/forgot-password/code',
        data: {
          'email': email,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('发送验证码失败: 网络连接错误');
    }
  }

  // 重置密码
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _httpClient.post(
        '/forgot-password/reset',
        data: {
          'email': email,
          'code': code,
          'new_password': newPassword,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('重置密码失败: 网络连接错误');
    }
  }
}
