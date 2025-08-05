import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/message_cache_service.dart';
import '../pages/character_chat/services/character_service.dart';
import '../services/session_data_service.dart';

/// 拉取缓存对话框
/// 显示分页拉取进度，1秒1次的频率
class CachePullDialog extends StatefulWidget {
  final int sessionId;
  final String archiveId;
  final VoidCallback? onCompleted;

  const CachePullDialog({
    Key? key,
    required this.sessionId,
    required this.archiveId,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<CachePullDialog> createState() => _CachePullDialogState();
}

class _CachePullDialogState extends State<CachePullDialog> {
  final MessageCacheService _messageCacheService = MessageCacheService();
  final CharacterService _characterService = CharacterService();
  final SessionDataService _sessionDataService = SessionDataService();
  
  bool _isPulling = false;
  bool _isCompleted = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalMessages = 0;
  int _pulledMessages = 0;

  @override
  void initState() {
    super.initState();
    _startPulling();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 开始拉取缓存
  Future<void> _startPulling() async {
    setState(() {
      _isPulling = true;
      _hasError = false;
    });

    try {
      // 先清空现有缓存，确保完全覆盖
      await _messageCacheService.clearArchiveCache(
        sessionId: widget.sessionId,
        archiveId: widget.archiveId,
      );

      debugPrint('[CachePullDialog] 已清空现有缓存，开始拉取最新数据');

      // 先获取第一页，确定总页数（使用更大的分页减少请求次数）
      final firstPageResult = await _characterService.getSessionMessages(
        widget.sessionId,
        page: 1,
        pageSize: 50,
      );

      final pagination = firstPageResult['pagination'] ?? {};
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
      final result = await _characterService.getSessionMessages(
        widget.sessionId,
        page: _currentPage,
        pageSize: 50,
      );

      await _processPageData(result);

      setState(() {
        _currentPage++;
      });

      // 立即拉取下一页，不等待
      if (_currentPage <= _totalPages) {
        _pullNextPage(); // 递归调用，立即拉取下一页
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
    final List<dynamic> messageList = result['list'] ?? [];
    
    if (messageList.isNotEmpty) {
      // 转换消息格式
      final messages = messageList.map((msg) => {
        'msgId': msg['msgId'],
        'content': msg['content'] ?? '',
        'role': msg['role'],
        'createdAt': msg['createdAt'],
        'tokenCount': msg['tokenCount'] ?? 0,
        'statusBar': msg['statusBar'],
        'enhanced': msg['enhanced'],
        'keywords': msg['keywords'],
      }).toList();
      
      // 存储到本地缓存
      await _messageCacheService.insertOrUpdateMessages(
        sessionId: widget.sessionId,
        archiveId: widget.archiveId,
        messages: messages,
      );
      
      setState(() {
        _pulledMessages += messages.length;
      });
    }
  }

  /// 完成拉取
  void _completePulling() {
    setState(() {
      _isPulling = false;
      _isCompleted = true;
    });

    // 拉取完成后，写入存档ID到会话记录
    _updateSessionActiveArchive();

    // 延迟1秒后自动关闭对话框
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCompleted?.call();
      }
    });
  }

  /// 更新会话的激活存档ID
  Future<void> _updateSessionActiveArchive() async {
    try {
      await _sessionDataService.initDatabase();

      // 获取当前会话数据
      final sessionResponse = await _sessionDataService.getLocalCharacterSessions(
        page: 1,
        pageSize: 1000
      );

      final session = sessionResponse.sessions.firstWhere(
        (s) => s.id == widget.sessionId,
        orElse: () => throw '会话不存在',
      );

      // 更新激活存档ID
      final updatedSession = session.copyWith(
        activeArchiveId: widget.archiveId,
        lastSyncTime: DateTime.now(),
      );

      await _sessionDataService.updateCharacterSession(updatedSession);

      debugPrint('[CachePullDialog] ✅ 拉取完成，已写入存档ID: ${widget.archiveId}');
    } catch (e) {
      debugPrint('[CachePullDialog] ❌ 写入存档ID失败: $e');
    }
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
              '拉取存档缓存',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // 🔥 优化：使用横条进度指示器，更直观的动画效果
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
                '共拉取 $_pulledMessages 条消息',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (_isPulling) ...[
              Text(
                '已拉取 $_pulledMessages / $_totalMessages 条消息',
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
            ] else if (!_isCompleted) ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  '取消',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
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
