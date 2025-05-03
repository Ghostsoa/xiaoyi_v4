import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_toast.dart';
import 'forgot_password_service.dart';
import '../login/login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _forgotPasswordService = ForgotPasswordService();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isGettingCode = false;
  bool _isResetting = false;
  int _countdownSeconds = 0;

  // 步骤: 1=输入邮箱, 2=验证并重置密码
  int _step = 1;

  @override
  void dispose() {
    _emailController.dispose();
    _verificationCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _obscureNewPassword = !_obscureNewPassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  // 获取验证码
  void _getVerificationCode() async {
    // 验证邮箱
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
      final response = await _forgotPasswordService
          .sendVerificationCode(_emailController.text);

      if (response['code'] == 0) {
        // 验证码发送成功
        CustomToast.show(
          context,
          message: response['msg'] ?? '验证码已发送至您的邮箱',
          type: ToastType.success,
        );

        // 开始倒计时
        setState(() {
          _countdownSeconds = 60;
          _step = 2; // 进入下一步
        });
        _startCountdown();
      } else {
        // 验证码发送失败
        CustomToast.show(
          context,
          message: response['msg'] ?? '验证码发送失败',
          type: ToastType.error,
        );
        setState(() {
          _isGettingCode = false;
        });
      }
    } catch (e) {
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

  // 重置密码
  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isResetting = true;
      });

      try {
        // 调用重置密码接口
        final response = await _forgotPasswordService.resetPassword(
          email: _emailController.text,
          code: _verificationCodeController.text,
          newPassword: _newPasswordController.text,
        );

        if (response['code'] == 0) {
          // 密码重置成功
          CustomToast.show(
            context,
            message: response['msg'] ?? '密码重置成功',
            type: ToastType.success,
          );

          // 返回登录页面
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
        } else {
          // 密码重置失败
          CustomToast.show(
            context,
            message: response['msg'] ?? '密码重置失败',
            type: ToastType.error,
          );
        }
      } catch (e) {
        CustomToast.show(
          context,
          message: e.toString(),
          type: ToastType.error,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isResetting = false;
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
                    '找回密码',
                    style: AppTheme.headingStyle,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '我们将向您的邮箱发送验证码',
                    style: AppTheme.secondaryStyle,
                  ),
                  SizedBox(height: 32.h),

                  // 步骤1: 输入邮箱
                  if (_step == 1)
                    Column(
                      children: [
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
                            if (!RegExp(r'^[\w-\.]+@qq\.com$')
                                .hasMatch(value)) {
                              return '请输入有效的QQ邮箱地址';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),

                        // 下一步按钮
                        _isGettingCode
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : CustomButton(
                                onPressed: _getVerificationCode,
                                child: Text('获取验证码'),
                              ),
                      ],
                    ),

                  // 步骤2: 验证并重置密码
                  if (_step == 2)
                    Column(
                      children: [
                        // 邮箱显示
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                color: AppTheme.textSecondary,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  _emailController.text,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _step = 1;
                                    _isGettingCode = false;
                                  });
                                },
                                child: Text(
                                  '更改',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
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
                                  onPressed: _isGettingCode
                                      ? null
                                      : _getVerificationCode,
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
                                        : '重新获取',
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

                        // 新密码输入框
                        CustomTextField(
                          hintText: '新密码',
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: AppTheme.textHint,
                            size: 22.w,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.textHint,
                              size: 22.w,
                            ),
                            onPressed: _toggleNewPasswordVisibility,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入新密码';
                            }
                            if (value.length < 6) {
                              return '密码长度不能少于6位';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),

                        // 确认新密码输入框
                        CustomTextField(
                          hintText: '确认新密码',
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
                              return '请确认新密码';
                            }
                            if (value != _newPasswordController.text) {
                              return '两次输入的密码不一致';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),

                        // 重置密码按钮
                        _isResetting
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : CustomButton(
                                onPressed: _resetPassword,
                                child: Text('重置密码'),
                              ),
                      ],
                    ),

                  SizedBox(height: 24.h),

                  // 返回登录页
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
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
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
