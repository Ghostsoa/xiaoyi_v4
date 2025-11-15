import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
import '../../../theme/app_theme.dart';
import '../../../services/file_service.dart';
import '../../../widgets/custom_toast.dart';

class RolePanel extends StatefulWidget {
  final List<dynamic> roles;

  const RolePanel({
    super.key,
    required this.roles,
  });

  @override
  State<RolePanel> createState() => _RolePanelState();
}

class _RolePanelState extends State<RolePanel> {
  final FileService _fileService = FileService();
  final Map<String, Uint8List> _avatarCache = {};
  int _selectedRoleIndex = 0;

  @override
  void initState() {
    super.initState();
    _preloadAvatars();
  }

  Future<void> _preloadAvatars() async {
    for (int i = 0; i < widget.roles.length; i++) {
      final role = widget.roles[i];
      final avatarUri = role['avatarUri'];
      if (avatarUri != null && avatarUri.isNotEmpty) {
        try {
          final result = await _fileService.getFile(avatarUri);
          if (mounted) {
            setState(() {
              _avatarCache[avatarUri] = result.data as Uint8List;
            });
          }
        } catch (e) {
          debugPrint('加载角色头像失败: $e');
        }
      }
    }
  }


  Widget _buildRoleAvatar(String? avatarUri, String? roleName, {bool isSelected = false}) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.r),
        child: _buildAvatarImage(avatarUri, roleName),
      ),
    );
  }

  Widget _buildAvatarImage(String? avatarUri, String? roleName) {
    // 如果已经缓存了，直接显示
    if (avatarUri != null && _avatarCache.containsKey(avatarUri)) {
      return Image.memory(
        _avatarCache[avatarUri]!,
        fit: BoxFit.cover,
        width: 50.w,
        height: 50.w,
      );
    }
    
    // 如果有URI但还没加载，显示占位符并在后台加载
    if (avatarUri != null && avatarUri.isNotEmpty) {
      // 异步加载头像，但不使用FutureBuilder避免闪烁
      _loadAvatarToCache(avatarUri);
      return _buildAvatarPlaceholder(roleName, 50.w);
    }
    
    // 没有URI，显示占位符
    return _buildAvatarPlaceholder(roleName, 50.w);
  }

  Future<void> _loadAvatarToCache(String uri) async {
    // 如果正在加载或已经缓存，直接返回
    if (_avatarCache.containsKey(uri)) return;
    
    try {
      final result = await _fileService.getFile(uri);
      if (mounted && !_avatarCache.containsKey(uri)) {
        setState(() {
          _avatarCache[uri] = result.data as Uint8List;
        });
      }
    } catch (e) {
      debugPrint('加载头像失败: $e');
    }
  }

  Widget _buildAvatarPlaceholder(String? roleName, double size) {
    final firstLetter = (roleName?.isNotEmpty == true) ? roleName![0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = widget.roles[_selectedRoleIndex];
    
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              // 拖拽指示条
              Container(
                margin: EdgeInsets.symmetric(vertical: 12.h),
                width: 60.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // 标题
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '群聊角色',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // 角色头像水平列表
              Container(
                height: 80.h,
                margin: EdgeInsets.symmetric(vertical: 16.h),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  itemCount: widget.roles.length,
                  itemBuilder: (context, index) {
                    final role = widget.roles[index];
                    final isSelected = index == _selectedRoleIndex;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRoleIndex = index;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 16.w),
                        child: Column(
                          children: [
                            _buildRoleAvatar(
                              role['avatarUri'], 
                              role['name'], 
                              isSelected: isSelected,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              role['name'] ?? '未命名',
                              style: TextStyle(
                                color: isSelected 
                                    ? AppTheme.primaryColor 
                                    : AppTheme.textSecondary,
                                fontSize: 12.sp,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 角色详细信息
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 角色介绍标题和发言按钮
                      if (currentRole['description'] != null && currentRole['description'].isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '角色介绍',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                             Material(
                               color: AppTheme.primaryColor,
                               borderRadius: BorderRadius.circular(12.r),
                               child: InkWell(
                                 onTap: () {
                                   // TODO: 实现发言功能
                                   CustomToast.show(
                                     context,
                                     message: '发言功能待实现',
                                     type: ToastType.info,
                                   );
                                 },
                                 borderRadius: BorderRadius.circular(12.r),
                                 child: Container(
                                   padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                   child: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       Icon(
                                         Icons.chat_bubble_outline,
                                         color: Colors.white,
                                         size: 14.sp,
                                       ),
                                       SizedBox(width: 4.w),
                                       Text(
                                         '发言',
                                         style: TextStyle(
                                           color: Colors.white,
                                           fontSize: 12.sp,
                                           fontWeight: FontWeight.w500,
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                               ),
                             ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppTheme.textSecondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppTheme.textSecondary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            currentRole['description'],
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14.sp,
                              height: 1.5,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ] else ...[
                        // 如果没有角色介绍，只显示发言按钮
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                             Material(
                               color: AppTheme.primaryColor,
                               borderRadius: BorderRadius.circular(12.r),
                               child: InkWell(
                                 onTap: () {
                                   // TODO: 实现发言功能
                                   CustomToast.show(
                                     context,
                                     message: '发言功能待实现',
                                     type: ToastType.info,
                                   );
                                 },
                                 borderRadius: BorderRadius.circular(12.r),
                                 child: Container(
                                   padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                   child: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       Icon(
                                         Icons.chat_bubble_outline,
                                         color: Colors.white,
                                         size: 14.sp,
                                       ),
                                       SizedBox(width: 4.w),
                                       Text(
                                         '发言',
                                         style: TextStyle(
                                           color: Colors.white,
                                           fontSize: 12.sp,
                                           fontWeight: FontWeight.w500,
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                               ),
                             ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                      ],

                      // 角色设定
                      if (currentRole['setting'] != null && currentRole['setting'].isNotEmpty) ...[
                        Text(
                          '角色设定',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppTheme.textSecondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppTheme.textSecondary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            currentRole['setting'],
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14.sp,
                              height: 1.5,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],

                      // 使用模型
                      if (currentRole['modelName'] != null && currentRole['modelName'].isNotEmpty) ...[
                        Text(
                          '使用模型',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            currentRole['modelName'],
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
