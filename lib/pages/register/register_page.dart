import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_toast.dart';
import '../login/login_page.dart';
import 'terms_page.dart';
import 'privacy_policy_page.dart';
import 'register_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _inviterIdController = TextEditingController();
  final _registerService = RegisterService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isGettingCode = false;
  bool _isRegistering = false;
  int _countdownSeconds = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    _inviterIdController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  // 获取验证码
  void _getVerificationCode() async {
    // 验证邮箱格式
    if (_emailController.text.isEmpty ||
        !RegExp(r'^[\w-\.]+@qq\.com$').hasMatch(_emailController.text)) {
      CustomToast.show(
        context,
        message: '请输入有效的QQ邮箱地址',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isGettingCode = true;
    });

    try {
      // 调用发送验证码接口
      final response =
          await _registerService.sendVerificationCode(_emailController.text);

      if (response['code'] == 0) {
        // 成功发送验证码
        CustomToast.show(
          context,
          message: response['msg'] ?? '验证码已发送',
          type: ToastType.success,
        );

        // 开始倒计时
        setState(() {
          _countdownSeconds = 60;
        });
        _startCountdown();
      } else {
        // 发送验证码失败
        CustomToast.show(
          context,
          message: response['msg'] ?? '发送验证码失败',
          type: ToastType.error,
        );
        setState(() {
          _isGettingCode = false;
        });
      }
    } catch (e) {
      // 处理异常
      CustomToast.show(
        context,
        message: e.toString(),
        type: ToastType.error,
      );
      setState(() {
        _isGettingCode = false;
      });
    }
  }

  void _startCountdown() {
    if (_countdownSeconds > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _countdownSeconds--;
          });
          _startCountdown();
        }
      });
    } else {
      setState(() {
        _isGettingCode = false;
      });
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      // 验证验证码
      if (_verificationCodeController.text.isEmpty) {
        CustomToast.show(
          context,
          message: '请输入验证码',
          type: ToastType.warning,
        );
        return;
      }

      // 显示加载指示器
      setState(() {
        _isRegistering = true;
      });

      try {
        // 调用注册接口
        final response = await _registerService.register(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          code: _verificationCodeController.text,
          inviterId: _inviterIdController.text.isEmpty
              ? null
              : int.parse(_inviterIdController.text),
        );

        if (response['code'] == 0) {
          // 注册成功
          CustomToast.show(
            context,
            message: response['msg'] ?? '注册成功',
            type: ToastType.success,
          );

          // 保存登录凭据，用于自动填充登录表单
          await _registerService.saveLoginCredentials(
              _emailController.text, _passwordController.text);

          // 导航到登录页面
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false, // 清除所有路由历史
          );
        } else {
          // 注册失败
          CustomToast.show(
            context,
            message: response['msg'] ?? '注册失败',
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
            _isRegistering = false;
          });
        }
      }
    } else if (!_agreeToTerms) {
      CustomToast.show(
        context,
        message: '请同意服务条款和隐私政策',
        type: ToastType.warning,
      );
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
                  SizedBox(height: 16.h),
                  // 顶部操作区域
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // 返回按钮
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42.w,
                          height: 42.w,
                          decoration: AppTheme.backButtonDecoration,
                          child: Center(
                            child: Icon(
                              Icons.arrow_back,
                              size: 22.w,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  // 标题
                  Text(
                    '创建账户',
                    style: AppTheme.headingStyle,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '填写以下信息注册新账户',
                    style: AppTheme.secondaryStyle,
                  ),
                  SizedBox(height: 32.h),

                  // 用户名输入框
                  CustomTextField(
                    hintText: '用户名',
                    controller: _usernameController,
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppTheme.textHint,
                      size: 22.w,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入用户名';
                      }
                      if (value.length < 2 || value.length > 20) {
                        return '用户名长度必须在2-20位之间';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

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

                  // 邀请人ID输入框
                  CustomTextField(
                    hintText: '邀请人ID（选填）',
                    controller: _inviterIdController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icon(
                      Icons.person_add_outlined,
                      color: AppTheme.textHint,
                      size: 22.w,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // 验证码输入框
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CustomTextField(
                          hintText: '验证码',
                          controller: _verificationCodeController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icon(
                            Icons.security_outlined,
                            color: AppTheme.textHint,
                            size: 22.w,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入验证码';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 56.h,
                          decoration: AppTheme.buttonDecoration,
                          child: ElevatedButton(
                            onPressed:
                                _isGettingCode ? null : _getVerificationCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isGettingCode
                                  ? Colors.grey[800]
                                  : AppTheme.primaryColor,
                              foregroundColor: _isGettingCode
                                  ? AppTheme.textSecondary
                                  : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              _isGettingCode
                                  ? '${_countdownSeconds}s'
                                  : '获取验证码',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                      if (value.length < 6 || value.length > 16) {
                        return '密码长度必须在6-16位之间';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // 确认密码输入框
                  CustomTextField(
                    hintText: '确认密码',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppTheme.textHint,
                      size: 22.w,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.textHint,
                        size: 22.w,
                      ),
                      onPressed: _toggleConfirmPasswordVisibility,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请确认密码';
                      }
                      if (value != _passwordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24.h),

                  // 同意条款
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: Checkbox(
                          value: _agreeToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreeToTerms = value ?? false;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusXSmall),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Wrap(
                          children: [
                            Text(
                              '我已阅读并同意',
                              style: AppTheme.secondaryStyle,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TermsPage(),
                                  ),
                                );
                              },
                              child: Text(
                                '服务条款',
                                style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: AppTheme.bodySize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '和',
                              style: AppTheme.secondaryStyle,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PrivacyPolicyPage(),
                                  ),
                                );
                              },
                              child: Text(
                                '隐私政策',
                                style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: AppTheme.bodySize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  _isRegistering
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : CustomButton(
                          onPressed: _register,
                          child: Text('注册'),
                        ),
                  SizedBox(height: 24.h),

                  // 登录链接
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '已有账号？',
                        style: AppTheme.secondaryStyle,
                      ),
                      CustomTextButton(
                        text: '立即登录',
                        onPressed: () {
                          Navigator.pop(context);
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
