import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/group_chat_session_service.dart';
import '../../../services/file_service.dart';
import 'dart:typed_data';

import 'dart:async'; // Added for Timer
import 'package:shimmer/shimmer.dart';
import 'group_chat_page.dart';
import '../../../theme/app_theme.dart';

class GroupChatInitPage extends StatefulWidget {
  final Map<String, dynamic> groupChatData;
  final bool isDebug;

  const GroupChatInitPage({
    super.key,
    required this.groupChatData,
    this.isDebug = false,
  });

  @override
  State<GroupChatInitPage> createState() => _GroupChatInitPageState();
}

class _GroupChatInitPageState extends State<GroupChatInitPage>
    with SingleTickerProviderStateMixin {
  final GroupChatSessionService _groupChatSessionService = GroupChatSessionService();
  final FileService _fileService = FileService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // 加载提示语
  final List<String> _loadingTips = [
    "正在初始化群聊...",
    "正在生成角色记忆...",
    "正在加载人格设定...",
    "正在设置交互参数...",
    "即将进入群聊...",
    "正在构建对话场景...",
    "正在调整AI模型...",
    "马上就好...",
  ];
  int _currentTipIndex = 0;
  Timer? _tipTimer;

  // 缓存封面图片
  Uint8List? _cachedCoverImage;
  bool _isLoadingCover = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _loadCoverImage();

    // 直接自动初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createSession();
    });
  }

  // 开始轮播提示语
  void _startTipRotation() {
    // 如果已经有计时器，先取消
    _tipTimer?.cancel();

    // 创建新计时器，每3秒切换一次提示语
    _tipTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _isLoading) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _loadingTips.length;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadCoverImage() async {
    if (widget.groupChatData['cover_uri'] == null ||
        _isLoadingCover ||
        _cachedCoverImage != null) {
      return;
    }

    _isLoadingCover = true;
    try {
      final result =
          await _fileService.getFile(widget.groupChatData['cover_uri']);
      if (mounted) {
        setState(() {
          _cachedCoverImage = result.data;
          _isLoadingCover = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCover = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tipTimer?.cancel();
    super.dispose();
  }

  Future<void> _createSession() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _currentTipIndex = 0;
    });

    // 开始轮播提示语
    _startTipRotation();

    try {
      // 获取群聊ID：大厅传递的是item_id，我的创建传递的是id
      final groupChatId = (widget.groupChatData['item_id'] ?? widget.groupChatData['id']) as int;
      
      // 统一使用 GroupChatSessionService，传递 isDebug 参数
      final result = await _groupChatSessionService.createGroupChatSession(
        groupChatId,
        isDebug: widget.isDebug,
      );

      if (mounted) {
        // 预加载背景图
        final sessionData = result['data'] as Map<String, dynamic>;
        if (sessionData['background_uri'] != null) {
          try {
            await _fileService.getFile(sessionData['background_uri']);
          } catch (e) {
            // 背景图加载失败不阻止页面跳转
            debugPrint('背景图加载失败: $e');
          }
        }

        // 跳转到群聊页面
        if (result['code'] == 0) {
          _tipTimer?.cancel();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => GroupChatPage(
                sessionData: sessionData,
                groupChatData: sessionData, // 直接使用服务端返回的完整会话数据
              ),
            ),
          );
        } else {
          throw result['msg'] ?? '创建群聊会话失败';
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
        _tipTimer?.cancel();
      }
    }
  }


  Widget _buildErrorView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                    width: 1,
                  ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48.w,
                      color: Colors.amber[300],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      '初始化失败',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[300],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.amber[200],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.6),
                              width: 1.5,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            '返回',
                            style: TextStyle(
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        ElevatedButton(
                          onPressed: _createSession,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            backgroundColor: Colors.white.withOpacity(0.3),
                          ),
                          child: Text(
                            '重试',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ),
    );
  }

  Widget _buildLoadingTips() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Shimmer.fromColors(
        key: ValueKey<int>(_currentTipIndex),
        baseColor: Colors.white,
        highlightColor: Colors.white.withOpacity(0.5),
        child: Text(
          _loadingTips[_currentTipIndex],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // 背景图片
          if (_cachedCoverImage != null)
            Positioned.fill(
              child: Image.memory(
                _cachedCoverImage!,
                fit: BoxFit.cover,
              ),
            ),
          // 背景渐变遮罩
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
          // 内容
          if (_hasError)
            _buildErrorView()
          else if (_isLoading)
            Center(
              child: _buildLoadingTips(),
            ),
        ],
      ),
    );
  }
}
