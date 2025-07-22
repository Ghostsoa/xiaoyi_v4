import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../theme/app_theme.dart';
import '../../widgets/custom_toast.dart';
import '../../dao/user_dao.dart';
import '../../services/file_service.dart';
import 'profile_server.dart';
import '../login/login_page.dart';

class EditProfilePage extends StatefulWidget {
  final String currentUsername;
  final String? currentAvatar;

  const EditProfilePage({
    super.key,
    required this.currentUsername,
    this.currentAvatar,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _userDao = UserDao();
  final _profileServer = ProfileServer();
  final _fileService = FileService();
  final _imagePicker = ImagePicker();

  bool _isSubmitting = false;
  String? _selectedAvatarPath;
  String? _avatarUri;
  Uint8List? _avatarBytes;
  bool _isLoadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.currentUsername;
    _avatarUri = widget.currentAvatar;
    if (_avatarUri != null) {
      _loadCurrentAvatar();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentAvatar() async {
    try {
      setState(() {
        _isLoadingAvatar = true;
      });

      debugPrint('尝试加载当前头像: $_avatarUri');

      // 确保头像URI有效
      if (_avatarUri == null || _avatarUri!.isEmpty) {
        debugPrint('头像URI为空或无效');
        return;
      }

      // 处理URI格式
      final String processedUri = _avatarUri!.trim();
      debugPrint('处理后的URI: $processedUri');

      final response = await _fileService
          .getFile(processedUri)
          .timeout(const Duration(seconds: 15));

      debugPrint(
          '头像加载结果: ${response.statusCode}, 数据长度: ${response.data?.length ?? 0}');

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data is Uint8List &&
          (response.data as Uint8List).isNotEmpty) {
        if (mounted) {
          setState(() {
            _avatarBytes = response.data;
            debugPrint('成功设置头像数据，长度: ${_avatarBytes!.length}');
          });
        }
      } else {
        debugPrint('头像数据无效: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('加载头像出错: $e');
      // 加载失败时不显示错误，只是不显示头像
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAvatar = false;
        });
      }
    }
  }

  // 选择并上传头像
  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedAvatarPath = image.path;
      });

      // 上传图片
      final uri = await _fileService.uploadFile(
        File(image.path),
        'avatar',
      );

      setState(() {
        _avatarUri = uri;
      });

      if (mounted) {
        CustomToast.show(
          context,
          message: '头像上传成功',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '头像上传失败：$e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 调用更新用户信息API
      final result = await _profileServer.updateUserInfo(
        username: _usernameController.text.trim(),
        avatar: _avatarUri,
      );

      if (mounted) {
        if (result['success'] == true) {
          // 更新成功，可能需要重新登录或其他操作
          if (result['data'] != null) {
            // 更新本地存储的用户信息
            if (result['data']['username'] != null) {
              await _userDao.saveUsername(result['data']['username']);
            }
            if (result['data']['avatar'] != null) {
              await _userDao.saveAvatar(result['data']['avatar']);
            }
          }

          // 显示成功提示
          CustomToast.show(
            context,
            message: result['msg'],
            type: ToastType.success,
          );

          // 检查是否需要重新登录
          if (result['msg'] != null &&
              result['msg'].toString().contains('请重新登录')) {
            debugPrint('个人资料更新成功，需要重新登录');

            // 清除用户信息
            await _userDao.clearUserInfo();

            // 延迟导航到登录页面，让用户先看到成功提示
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                // 导航到登录页面并清除导航栈
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false, // 清除所有路由历史
                );
              }
            });
          } else {
            // 返回上一页
            Navigator.pop(context, true);
          }
        } else {
          // 显示错误消息
          CustomToast.show(
            context,
            message: result['msg'],
            type: ToastType.error,
          );

          // 如果需要重新登录，处理相应逻辑
          if (result['msg'] != null &&
              result['msg'].toString().contains('请重新登录')) {
            await _userDao.clearUserInfo();

            // 延迟导航到登录页面，让用户先看到提示
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: e.toString(),
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: Text(
          '编辑个人资料',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textPrimary,
            size: 20.sp,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _updateProfile,
            child: _isSubmitting
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : Text(
                    '保存',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头像部分
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadAvatar,
                        child: Container(
                          width: 100.w,
                          height: 100.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _selectedAvatarPath == null &&
                                    _avatarBytes == null
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.primaryColor.withOpacity(0.8),
                                      AppTheme.primaryColor,
                                    ],
                                  )
                                : null,
                          ),
                          child: _isLoadingAvatar
                              ? Center(
                                  child: SizedBox(
                                    width: 24.w,
                                    height: 24.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : _selectedAvatarPath != null
                                  ? ClipOval(
                                      child: Image.file(
                                        File(_selectedAvatarPath!),
                                        fit: BoxFit.cover,
                                        width: 100.w,
                                        height: 100.w,
                                      ),
                                    )
                                  : _avatarBytes != null
                                      ? ClipOval(
                                          child: Image.memory(
                                            _avatarBytes!,
                                            fit: BoxFit.cover,
                                            width: 100.w,
                                            height: 100.w,
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            _usernameController.text.isEmpty
                                                ? '?'
                                                : _usernameController.text
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 42.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        '点击修改头像',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                // 用户名输入框
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 6.h,
                  ),
                  child: TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: '用户名',
                      labelStyle: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14.sp,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      errorStyle: TextStyle(
                        color: Colors.red,
                        fontSize: 12.sp,
                      ),
                    ),
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16.sp,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '用户名不能为空';
                      }
                      if (value.length < 3) {
                        return '用户名不能少于3个字符';
                      }
                      if (value.length > 20) {
                        return '用户名不能超过20个字符';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 48.h),
                // 提交按钮
                InkWell(
                  onTap: _isSubmitting ? null : _updateProfile,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    width: double.infinity,
                    height: 50.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.8),
                          AppTheme.primaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isSubmitting
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.w,
                            ),
                          )
                        : Text(
                            '保存修改',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
