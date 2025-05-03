import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../dao/user_dao.dart';
import '../../../services/file_service.dart';
import 'dart:typed_data';

class UserInfoWidget extends StatefulWidget {
  final String username;
  final int userId;
  final int userRole;
  final String roleDescription;
  final int level;
  final String levelName;
  final VoidCallback onEditPressed;

  const UserInfoWidget({
    super.key,
    required this.username,
    required this.userId,
    required this.userRole,
    required this.roleDescription,
    required this.level,
    required this.levelName,
    required this.onEditPressed,
  });

  @override
  State<UserInfoWidget> createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends State<UserInfoWidget> {
  final UserDao _userDao = UserDao();
  final FileService _fileService = FileService();
  String? _avatarUri;
  Uint8List? _avatarBytes;
  bool _isLoadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      final avatarUri = await _userDao.getAvatar();
      setState(() {
        _avatarUri = avatarUri;
      });

      if (avatarUri != null) {
        setState(() {
          _isLoadingAvatar = true;
        });

        final response = await _fileService.getFile(avatarUri);
        if (response.statusCode == 200) {
          setState(() {
            _avatarBytes = response.data;
            _isLoadingAvatar = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingAvatar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // 头像部分
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _avatarBytes == null
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
                : _avatarBytes != null
                    ? ClipOval(
                        child: Image.memory(
                          _avatarBytes!,
                          fit: BoxFit.cover,
                          width: 80.w,
                          height: 80.w,
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.username.isEmpty
                              ? '?'
                              : widget.username.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
          ),
          SizedBox(width: 16.w),
          // 用户信息部分
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.username,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        widget.roleDescription,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  'ID: ${widget.userId}',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.8),
                            AppTheme.primaryColor,
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        'LV.${widget.level}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      widget.levelName,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 编辑按钮
          IconButton(
            onPressed: widget.onEditPressed,
            icon: Icon(
              Icons.edit_outlined,
              color: AppTheme.textSecondary,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }
}
