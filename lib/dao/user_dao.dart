import 'package:shared_preferences/shared_preferences.dart';

/// 用户数据访问对象
/// 负责存储和获取用户信息
class UserDao {
  static final UserDao _instance = UserDao._internal();

  factory UserDao() => _instance;

  UserDao._internal();

  // 保存用户信息
  Future<void> saveUserInfo(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    // 保存用户基本信息
    await prefs.setInt('userId', userData['id']);
    await prefs.setString('username', userData['username']);
    await prefs.setString('userEmail', userData['email']);
    await prefs.setInt('userRole', userData['role']);
    await prefs.setInt('userStatus', userData['status']);
    await prefs.setString('token', userData['token']);

    // 保存头像URI，如果有的话
    if (userData['avatar'] != null) {
      await prefs.setString('avatar', userData['avatar']);
      print('保存用户头像: ${userData['avatar']}'); // 添加日志便于调试
    }

    // 记录登录状态
    await prefs.setBool('isLoggedIn', true);
  }

  // 清除用户信息
  Future<void> clearUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('userId');
    await prefs.remove('username');
    await prefs.remove('userEmail');
    await prefs.remove('userRole');
    await prefs.remove('userStatus');
    await prefs.remove('token');
    await prefs.remove('avatar');

    await prefs.setBool('isLoggedIn', false);
  }

  // 获取登录状态
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // 获取用户ID
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  // 获取用户名
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // 获取用户邮箱
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  // 获取用户角色
  Future<int?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userRole');
  }

  // 获取用户状态
  Future<int?> getUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userStatus');
  }

  // 获取用户Token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 获取用户角色描述
  Future<String> getUserRoleDescription() async {
    final role = await getUserRole();
    switch (role) {
      case 0:
        return '普通用户';
      case 1:
        return '运营';
      case 2:
        return '管理员';
      default:
        return '未知';
    }
  }

  // 获取用户状态描述
  Future<String> getUserStatusDescription() async {
    final status = await getUserStatus();
    switch (status) {
      case 0:
        return '正常';
      case 1:
        return '禁用';
      default:
        return '未知';
    }
  }

  // 判断是否是管理员
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 2;
  }

  // 判断是否是运营
  Future<bool> isOperator() async {
    final role = await getUserRole();
    return role == 1;
  }

  // 判断账户是否正常
  Future<bool> isAccountActive() async {
    final status = await getUserStatus();
    return status == 0;
  }

  // 保存用户名
  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  // 保存用户头像
  Future<void> saveAvatar(String avatar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar', avatar);
  }

  // 获取用户头像
  Future<String?> getAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('avatar');
  }
}
