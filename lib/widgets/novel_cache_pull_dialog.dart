import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/message_cache_service.dart';
import '../pages/novel/services/novel_service.dart';
import '../pages/novel/utils/novel_content_parser.dart';

/// 小说缓存拉取对话框
/// 显示分页拉取进度
class NovelCachePullDialog extends StatefulWidget {
  final int sessionId;
  final VoidCallback? onCompleted;

  const NovelCachePullDialog({
    super.key,
    required this.sessionId,
    this.onCompleted,
  });

  @override
  State<NovelCachePullDialog> createState() => _NovelCachePullDialogState();
}

class _NovelCachePullDialogState extends State<NovelCachePullDialog> {
  final MessageCacheService _messageCacheService = MessageCacheService();
  final NovelService _novelService = NovelService();
  
  bool _isPulling = false;
  bool _isCompleted = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalMessages = 0;
  int _pulledChapters = 0;

  @override
  void initState() {
    super.initState();
    _startPulling();
  }

  /// 开始拉取缓存
  Future<void> _startPulling() async {
    setState(() {
      _isPulling = true;
      _hasError = false;
    });

    try {
      // 先清空现有缓存，确保完全覆盖
      await _messageCacheService.clearNovelCache(widget.sessionId);

      debugPrint('[NovelCachePullDialog] 已清空现有缓存，开始拉取最新数据');

      // 先获取第一页，确定总页数
      final firstPageResult = await _novelService.getNovelMessages(
        widget.sessionId.toString(),
        page: 1,
        pageSize: 20,
      );

      if (firstPageResult['code'] != 0) {
        throw firstPageResult['msg'] ?? '请求失败';
      }

      final data = firstPageResult['data'] as Map<String, dynamic>;
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      _totalPages = pagination['total_pages'] ?? 1;
      _totalMessages = pagination['total_count'] ?? 0;

      // 处理第一页数据
      await _processPageData(firstPageResult);

      // 如果有多页，立即开始拉取剩余页面
      if (_totalPages > 1) {
        _currentPage = 2;
        _pullNextPage();
      } else {
        _completePulling();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = '拉取失败: $e';
        _isPulling = false;
      });
    }
  }

  /// 拉取下一页
  Future<void> _pullNextPage() async {
    if (_currentPage > _totalPages) {
      _completePulling();
      return;
    }

    try {
      final result = await _novelService.getNovelMessages(
        widget.sessionId.toString(),
        page: _currentPage,
        pageSize: 20,
      );

      if (result['code'] != 0) {
        throw result['msg'] ?? '请求失败';
      }

      await _processPageData(result);

      setState(() {
        _currentPage++;
      });

      // 立即拉取下一页
      if (_currentPage <= _totalPages) {
        _pullNextPage();
      } else {
        _completePulling();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = '拉取第 $_currentPage 页失败: $e';
        _isPulling = false;
      });
    }
  }

  /// 处理页面数据
  Future<void> _processPageData(Map<String, dynamic> result) async {
    final data = result['data'] as Map<String, dynamic>;
    final List<dynamic> messageList = data['list'] ?? [];
    
    if (messageList.isNotEmpty) {
      // 转换消息为章节格式
      final chapters = <Map<String, dynamic>>[];
      
      for (final message in messageList) {
        if (message['role'] == 'assistant') {
          final content = message['content'] as String? ?? '';
          final chapterTitle = message['chapterTitle'] as String? ?? 
              NovelContentParser.getDefaultChapterTitle(chapters.length + 1);
          final paragraphs = NovelContentParser.parseContent(content);

          chapters.add({
            'msgId': message['msgId'] ?? '',
            'title': chapterTitle,
            'content': paragraphs,
            'createdAt': message['createdAt'] ?? message['created_at'] ?? DateTime.now().toIso8601String(),
          });
        }
      }
      
      if (chapters.isNotEmpty) {
        // 存储到本地缓存
        await _messageCacheService.insertOrUpdateNovelChapters(
          sessionId: widget.sessionId,
          chapters: chapters,
        );
        
        setState(() {
          _pulledChapters += chapters.length;
        });
      }
    }
  }

  /// 完成拉取
  void _completePulling() {
    setState(() {
      _isPulling = false;
      _isCompleted = true;
    });

    debugPrint('[NovelCachePullDialog] ✅ 拉取完成，共拉取 $_pulledChapters 个章节');

    // 延迟关闭对话框并调用回调
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCompleted?.call();
      }
    });
  }

  /// 获取进度百分比
  double get _progress {
    if (_totalPages <= 1) return _isCompleted ? 1.0 : 0.0;
    return (_currentPage - 1) / _totalPages;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Text(
              '拉取小说缓存',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // 进度指示器
            Column(
              children: [
                // 进度百分比显示
                Text(
                  _hasError
                      ? '拉取失败'
                      : _isCompleted
                          ? '拉取完成'
                          : '进度 ${(_progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: _hasError ? Colors.red : AppTheme.textPrimary,
                  ),
                ),

                SizedBox(height: 16.h),

                // 横条进度指示器
                Container(
                  width: double.infinity,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _hasError ? Colors.red : AppTheme.primaryColor,
                      ),
                      minHeight: 8.h,
                    ),
                  ),
                ),

                SizedBox(height: 8.h),

                // 进度详情
                if (!_hasError && !_isCompleted)
                  Text(
                    '第 ${_currentPage - 1} / $_totalPages 页',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 24.h),
            
            // 状态信息
            if (_hasError) ...[
              Text(
                _errorMessage,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (_isCompleted) ...[
              Text(
                '共拉取 $_pulledChapters 个章节',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (_isPulling) ...[
              Text(
                '已拉取 $_pulledChapters 个章节',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            SizedBox(height: 24.h),
            
            // 按钮
            if (_hasError) ...[
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentPage = 1;
                        });
                        _startPulling();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        '重试',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (!_isPulling && !_isCompleted) ...[
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  '关闭',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
