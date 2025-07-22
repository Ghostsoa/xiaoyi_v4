import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_theme.dart';
import '../../../dao/user_dao.dart';
import '../../../services/file_service.dart';
import 'dart:typed_data';
import '../level_distribution_page.dart';

class UserInfoWidget extends StatefulWidget {
  final String username;
  final int userId;
  final int userRole;
  final String roleDescription;
  final int level;
  final String levelName;
  final double exp;
  final VoidCallback onEditPressed;

  const UserInfoWidget({
    super.key,
    required this.username,
    required this.userId,
    required this.userRole,
    required this.roleDescription,
    required this.level,
    required this.levelName,
    required this.exp,
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

    // 添加安全检查，确保不会一直显示加载中状态
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoadingAvatar) {
        setState(() {
          _isLoadingAvatar = false;
        });
      }
    });
  }

  Future<void> _loadAvatar() async {
    if (_isLoadingAvatar) return; // 防止重复加载

    try {
      final avatarUri = await _userDao.getAvatar();
      debugPrint('Avatar URI: $avatarUri'); // 添加日志

      setState(() {
        _avatarUri = avatarUri;
      });

      if (avatarUri != null && avatarUri.isNotEmpty) {
        setState(() {
          _isLoadingAvatar = true;
        });

        try {
          debugPrint('开始加载头像: $avatarUri');

          // 构造正确的URL或URI
          final String processedUri =
              avatarUri.startsWith('http') ? avatarUri : avatarUri.trim();

          debugPrint('处理后的URI: $processedUri');

          final response = await _fileService
              .getFile(processedUri)
              .timeout(const Duration(seconds: 10));

          debugPrint(
              '头像加载结果: ${response.statusCode}, 数据长度: ${response.data?.length ?? 0}');

          if (response.statusCode == 200 &&
              response.data != null &&
              response.data is Uint8List &&
              (response.data as Uint8List).isNotEmpty) {
            if (mounted) {
              setState(() {
                _avatarBytes = response.data;
                _isLoadingAvatar = false;
              });
              debugPrint('成功设置头像数据，长度: ${_avatarBytes!.length}');
            }
          } else {
            debugPrint('头像数据无效: ${response.statusCode}');
            if (mounted) {
              setState(() {
                _avatarBytes = null;
                _isLoadingAvatar = false;
              });
            }
          }
        } catch (error) {
          debugPrint('加载头像出错: $error');
          if (mounted) {
            setState(() {
              _avatarBytes = null;
              _isLoadingAvatar = false;
            });
          }
        }
      } else {
        debugPrint('头像URI为空或无效');
        if (mounted) {
          setState(() {
            _isLoadingAvatar = false;
          });
        }
      }
    } catch (e) {
      debugPrint('获取头像URI出错: $e');
      if (mounted) {
        setState(() {
          _isLoadingAvatar = false;
        });
      }
    }
  }

  void _navigateToLevelDistribution() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelDistributionPage(
          currentExp: widget.exp.toInt(),
          currentLevel: widget.level,
          currentLevelName: widget.levelName,
        ),
      ),
    );
  }

  // 根据等级返回对应的颜色配置
  Map<String, Color> _getLevelColors(int level) {
    switch (level) {
      case 1:
        return {'start': Colors.white, 'end': Colors.white}; // 纯白色
      case 2:
        return {
          'start': const Color(0xFFE0E0E0),
          'end': const Color(0xFFAAAAAA)
        }; // 银色
      case 3:
        return {
          'start': const Color(0xFFFFFFFF),
          'end': const Color(0xFFD0D0D0)
        }; // 银白流光
      case 4:
        return {
          'start': const Color(0xFFFFF8E1),
          'end': const Color(0xFFFFD54F)
        }; // 金色流光
      case 5:
        return {
          'start': const Color(0xFFFFF9C4),
          'end': const Color(0xFFFFD700)
        }; // 金色流光（基础颜色）
      default:
        return {'start': Colors.white, 'end': Colors.white};
    }
  }

  // 获取5级彩虹渐变颜色
  List<Color> _getRainbowColors() {
    return [
      const Color(0xFFFF5252), // 红
      const Color(0xFFFF7043), // 橙
      const Color(0xFFFFCA28), // 黄
      const Color(0xFF66BB6A), // 绿
      const Color(0xFF29B6F6), // 蓝
      const Color(0xFF7E57C2), // 紫
    ];
  }

  @override
  Widget build(BuildContext context) {
    final levelColors = _getLevelColors(widget.level);

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
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.8),
                            AppTheme.primaryColor,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white.withOpacity(0.7),
                          size: 40.sp,
                        ),
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
                          errorBuilder: (context, error, stackTrace) {
                            // 图像加载失败时显示默认头像图标
                            return Container(
                              width: 80.w,
                              height: 80.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primaryColor.withOpacity(0.8),
                                    AppTheme.primaryColor,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 40.sp,
                                ),
                              ),
                            );
                          },
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
                SizedBox(height: 8.h),
                GestureDetector(
                  onTap: _navigateToLevelDistribution,
                  child: Row(
                    children: [
                      _buildLevelText(levelColors),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12.sp,
                        color: widget.level >= 3
                            ? levelColors['end']
                            : AppTheme.textSecondary,
                      ),
                    ],
                  ),
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

  // 构建等级文本
  Widget _buildLevelText(Map<String, Color> levelColors) {
    // 创建基本的文本行
    final levelTextRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 5级前面添加星星图标
        if (widget.level == 5) ...[
          Icon(
            Icons.star,
            color: const Color(0xFFFFD700),
            size: 16.sp,
          ),
          SizedBox(width: 2.w),
        ],
        Text(
          'LV.${widget.level}',
          style: TextStyle(
            color: widget.level <= 2 ? levelColors['end'] : levelColors['end'],
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          widget.levelName,
          style: TextStyle(
            color: widget.level <= 2 ? levelColors['end'] : levelColors['end'],
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    // 5级使用彩虹渐变流光
    if (widget.level == 5) {
      return ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) {
          return LinearGradient(
            colors: _getRainbowColors(),
            stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
            tileMode: TileMode.mirror,
          ).createShader(
            Rect.fromLTWH(
              0,
              0,
              bounds.width,
              bounds.height,
            ),
          );
        },
        child: Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.8),
          highlightColor: Colors.white,
          period: const Duration(milliseconds: 2000),
          child: levelTextRow,
        ),
      );
    }
    // 3-4级添加普通流光效果
    else if (widget.level >= 3) {
      return Shimmer.fromColors(
        baseColor: levelColors['start']!,
        highlightColor: levelColors['end']!,
        period: const Duration(milliseconds: 2000),
        child: levelTextRow,
      );
    } else {
      // 1-2级没有流光效果
      return levelTextRow;
    }
  }
}
