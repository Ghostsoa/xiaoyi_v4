import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_toast.dart';
import '../register/register_page.dart';
import '../main/main_page.dart';
import 'login_service.dart';
import '../forgot_password/forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginService = LoginService();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // 加载保存的登录凭据
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final isNewRegistered = prefs.getBool('isNewRegistered') ?? false;

    if (isNewRegistered) {
      // 如果是新注册用户，直接加载邮箱和密码，不勾选记住我
      final savedEmail = prefs.getString('email');
      final savedPassword = prefs.getString('password');

      if (savedEmail != null && savedPassword != null) {
        setState(() {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          _rememberMe = false;
        });
      }

      // 清除新注册标志，避免下次启动时再次加载
      await prefs.setBool('isNewRegistered', false);
    } else {
      // 普通情况，仅当启用了记住我功能时加载凭据
      final savedEmail = prefs.getString('email');
      final savedPassword = prefs.getString('password');
      final savedRememberMe = prefs.getBool('rememberMe');

      if (savedEmail != null &&
          savedPassword != null &&
          savedRememberMe == true) {
        setState(() {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          _rememberMe = true;
        });
      }
    }
  }

  // 保存登录凭据
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    if (_rememberMe) {
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setBool('rememberMe', true);
    } else {
      // 如果不勾选记住我，则清除保存的凭据
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 调用登录服务
        final response = await _loginService.login(
            _emailController.text, _passwordController.text);

        // 检查登录状态码
        if (response['code'] == 0) {
          // 保存登录凭据（如果选择记住我）
          await _saveCredentials();

          // 保存用户数据
          final userData = response['data'];
          await _loginService.saveUserData(userData);

          // 登录成功提示
          CustomToast.show(
            context,
            message: response['msg'] ?? '登录成功',
            type: ToastType.success,
          );

          // 导航到主页面
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainPage()),
            );
          }
        } else {
          // 显示错误消息
          CustomToast.show(
            context,
            message: response['msg'] ?? '登录失败',
            type: ToastType.error,
          );
        }
      } catch (e) {
        // 处理异常
        CustomToast.show(
          context,
          message: e.toString(),
          type: ToastType.error,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 60.h),
                  // 标题
                  Text(
                    '欢迎回来',
                    style: AppTheme.headingStyle,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '请登录您的账户',
                    style: AppTheme.secondaryStyle,
                  ),
                  SizedBox(height: 40.h),

                  // 邮箱输入框
                  CustomTextField(
                    hintText: '邮箱',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppTheme.textHint,
                      size: 22.w,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入邮箱';
                      }
                      if (!RegExp(r'^[\w-\.]+@qq\.com$').hasMatch(value)) {
                        return '请输入有效的QQ邮箱地址';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // 密码输入框
                  CustomTextField(
                    hintText: '密码',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppTheme.textHint,
                      size: 22.w,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.textHint,
                        size: 22.w,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      if (value.length < 6) {
                        return '密码长度不能少于6位';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // 记住我和忘记密码
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXSmall),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            child: Text(
                              '记住我',
                              style: AppTheme.secondaryStyle,
                            ),
                          ),
                        ],
                      ),
                      CustomTextButton(
                        text: '忘记密码？',
                        onPressed: () {
                          // 跳转到忘记密码页面
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  // 登录按钮
                  _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : CustomButton(
                          onPressed: _login,
                          child: Text('登录'),
                        ),
                  SizedBox(height: 24.h),

                  // 注册链接
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '还没有账号？',
                        style: AppTheme.secondaryStyle,
                      ),
                      CustomTextButton(
                        text: '立即注册',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
