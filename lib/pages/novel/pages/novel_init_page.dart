import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/novel_service.dart';
import '../../../services/file_service.dart';
import 'dart:typed_data';
import 'novel_reading_page.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';

class NovelInitPage extends StatefulWidget {
  final Map<String, dynamic> novelData;

  const NovelInitPage({
    super.key,
    required this.novelData,
  });

  @override
  State<NovelInitPage> createState() => _NovelInitPageState();
}

class _NovelInitPageState extends State<NovelInitPage>
    with SingleTickerProviderStateMixin {
  final NovelService _novelService = NovelService();
  final FileService _fileService = FileService();

  bool _isLoading = false;

  // 缓存封面图片
  Uint8List? _cachedCoverImage;
  bool _isLoadingCover = false;

  @override
  void initState() {
    super.initState();
    _loadCoverImage();

    // 使用微任务确保在构建完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createSession();
    });
  }

  Future<void> _loadCoverImage() async {
    if (widget.novelData['cover_uri'] == null ||
        _isLoadingCover ||
        _cachedCoverImage != null) {
      return;
    }

    _isLoadingCover = true;
    try {
      final result = await _fileService.getFile(widget.novelData['cover_uri']);
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

  Future<void> _createSession() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final novelId = widget.novelData['item_id'] as int;
      final result = await _novelService.createNovelSession(novelId);

      if (mounted) {
        if (result['code'] == 0) {
          final sessionData = result['data']['session'] as Map<String, dynamic>;

          // 跳转到小说阅读页面
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => NovelReadingPage(
                sessionData: sessionData,
                novelData: widget.novelData,
              ),
            ),
          );
        } else {
          throw result['message'] ?? result['msg'] ?? '创建会话失败';
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: e.toString(),
          type: ToastType.error,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
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
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          // 标题和描述
          Positioned(
            bottom: 150.h,
            left: 24.w,
            right: 24.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.novelData['title'] ?? '无标题',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 3.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '@${widget.novelData["author_name"] ?? "未知作者"}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withOpacity(0.8),
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  widget.novelData['description'] ?? '暂无描述',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.7),
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 加载指示器
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      SizedBox(height: 16.h),
                      Text(
                        '正在初始化小说...',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
