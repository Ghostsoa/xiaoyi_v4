import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:typed_data';
import '../theme/app_theme.dart';
import '../pages/home/services/home_service.dart';
import '../services/file_service.dart';
import '../pages/home/pages/item_detail_page.dart';

/// 抽卡弹窗组件
class DrawCardsDialog extends StatefulWidget {
  final VoidCallback? onCompleted;

  const DrawCardsDialog({
    super.key,
    this.onCompleted,
  });

  @override
  State<DrawCardsDialog> createState() => _DrawCardsDialogState();
}

class _DrawCardsDialogState extends State<DrawCardsDialog>
    with TickerProviderStateMixin {
  final HomeService _homeService = HomeService();
  final FileService _fileService = FileService();

  bool _isDrawing = false;
  bool _isCompleted = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<dynamic> _drawnCards = [];

  // 图片缓存
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, bool> _loadingImages = {};

  // 打字机效果
  String _typewriterText = '';
  Timer? _typewriterTimer;
  int _typewriterIndex = 0;
  final List<String> _typewriterMessages = [
    '✨ 魔力正在运转中 ✨',
    '神秘的卡片正在汇聚',
    '请稍候片刻...',
  ];

  @override
  void initState() {
    super.initState();
    _startDrawing();
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    super.dispose();
  }

  void _startTypewriter() {
    _typewriterIndex = 0;
    _typewriterText = '';
    _typewriterTimer?.cancel();

    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_typewriterIndex < _typewriterMessages.join('\n').length) {
        setState(() {
          _typewriterText = _typewriterMessages.join('\n').substring(0, _typewriterIndex + 1);
          _typewriterIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _startDrawing() async {
    setState(() {
      _isDrawing = true;
      _hasError = false;
      _errorMessage = '';
    });

    // 开始打字机效果
    _startTypewriter();

    try {
      // 并行执行：打字机效果和API调用同时进行
      final result = await _homeService.drawCards();

      if (mounted) {
        setState(() {
          _drawnCards = result['data']['cards'] ?? [];
          _isDrawing = false;
          _isCompleted = true;
        });

        // 停止打字机动画
        _typewriterTimer?.cancel();

        // 预加载卡片图片
        for (final card in _drawnCards) {
          if (card['cover_uri'] != null) {
            _loadCardImage(card['cover_uri']);
          }
        }

        widget.onCompleted?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDrawing = false;
          _hasError = true;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        _typewriterTimer?.cancel();
      }
    }
  }

  Future<void> _loadCardImage(String? coverUri) async {
    if (coverUri == null ||
        _loadingImages[coverUri] == true ||
        _imageCache.containsKey(coverUri)) {
      return;
    }

    _loadingImages[coverUri] = true;
    try {
      final result = await _fileService.getFile(coverUri);
      if (mounted) {
        setState(() {
          _imageCache[coverUri] = result.data;
          _loadingImages[coverUri] = false;
        });
      }
    } catch (e) {
      _loadingImages[coverUri] = false;
    }
  }

  void _retryDrawing() {
    _startDrawing();
  }

  void _viewCardDetail(Map<String, dynamic> card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailPage(item: card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      backgroundColor: AppTheme.cardBackground,
      child: Container(
        width: 350.w,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: AppTheme.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Icon(
                    Icons.casino_outlined,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  '随机抽卡',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cardBackground,
                    foregroundColor: AppTheme.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.all(8.w),
                    minimumSize: Size(36.w, 36.h),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 20.sp,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // 内容区域
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return _buildErrorState();
    } else if (_isDrawing) {
      return _buildDrawingState();
    } else if (_isCompleted) {
      return _buildCardsResult();
    }
    return const SizedBox();
  }

  Widget _buildDrawingState() {
    return Column(
      children: [
        SizedBox(height: 60.h),

        // 打字机效果文本
        Container(
          height: 120.h,
          alignment: Alignment.center,
          child: Text(
            _typewriterText,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // 装饰性图标
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 16.sp),
            SizedBox(width: 8.w),
            Icon(Icons.casino_outlined, color: AppTheme.primaryColor, size: 20.sp),
            SizedBox(width: 8.w),
            Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 16.sp),
          ],
        ),

        SizedBox(height: 60.h),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 48.sp,
        ),
        
        SizedBox(height: 12.h),

        Text(
          '抽卡失败',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),

        SizedBox(height: 12.h),

        Text(
          _errorMessage,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 16.h),

        // 重试按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _retryDrawing,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            child: Text(
              '重试',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardsResult() {
    return Column(
      children: [
        // 卡片网格
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: _drawnCards.length,
          itemBuilder: (context, index) {
            final card = _drawnCards[index];
            return _buildCardItem(card, index);
          },
        ),

        SizedBox(height: 12.h),

        // 再抽一次按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // 重新抽卡
              setState(() {
                _isCompleted = false;
                _drawnCards.clear();
              });
              _startDrawing();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            child: Text(
              '换一批',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(Map<String, dynamic> card, int index) {
    final String? coverUri = card['cover_uri'];

    return GestureDetector(
      onTap: () => _viewCardDetail(card),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Stack(
            children: [
              // 卡片图片
              _buildCardImage(coverUri, card['title']),

              // 标题遮罩
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(8.w, 20.h, 8.w, 8.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Text(
                    card['title'] ?? '',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // 新卡片标识
              Positioned(
                right: 6.w,
                top: 6.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage(String? coverUri, String? title) {
    if (coverUri != null && _imageCache.containsKey(coverUri)) {
      return Image.memory(
        _imageCache[coverUri]!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    // 加载中或无图片时显示占位符
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppTheme.cardBackground,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: AppTheme.textSecondary,
          size: 32.sp,
        ),
      ),
    );
  }

}