import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:typed_data';
import 'dart:async';

import '../../../theme/app_theme.dart';
import '../../novel/pages/novel_reading_page.dart';
import '../message_service.dart';
import '../../../services/file_service.dart';
import '../../../services/session_data_service.dart';
import '../../../widgets/custom_toast.dart';

class NovelSessionList extends StatefulWidget {
  const NovelSessionList({
    super.key,
    required this.isMultiSelectMode,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.onShowMenu,
  });

  final bool isMultiSelectMode;
  final Set<int> selectedIds;
  final ValueChanged<int> onSelectionChanged;
  final Function(BuildContext, Map<String, dynamic>, Offset) onShowMenu; // 🔥 添加位置参数

  @override
  NovelSessionListState createState() => NovelSessionListState();
}

class NovelSessionListState extends State<NovelSessionList> {
  final MessageService _messageService = MessageService();
  final FileService _fileService = FileService();
  final SessionDataService _sessionDataService = SessionDataService();
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _sessions = [];
  int _currentPage = 1;
  bool _hasMore = true;
  final Map<String, Uint8List> _avatarCache = {};
  StreamSubscription? _sessionStreamSubscription;
  
  // 🔥 搜索相关
  String _searchKeyword = '';
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _initSessionDataService();
    _loadSessions();
  }

  @override
  void dispose() {
    _sessionStreamSubscription?.cancel();
    _refreshController.dispose();
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  /// 初始化会话数据服务
  Future<void> _initSessionDataService() async {
    await _sessionDataService.initDatabase();

    // 🔥 不使用监听器，避免在加载更多时被覆盖
    // 改为手动控制刷新时机
  }

  /// 🔥 重构后的加载逻辑：置顶(SQLite) + API分页
  Future<void> _loadSessions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _sessions = [];
      _currentPage = 1;
    });

    try {
      await _loadSessionsCore();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[NovelSessionList] [ERROR] 加载失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 🔥 核心加载逻辑（可静默执行，不触发骨架屏）
  Future<void> _loadSessionsCore() async {
    print('========================================');
    print('[NovelSessionList] 🔥 开始加载（新逻辑）');
    
    // 步骤1: 加载置顶会话（从SQLite）
    final pinnedList = await _sessionDataService.getPinnedNovelSessions();
    final List<Map<String, dynamic>> pinnedSessions = pinnedList.map((s) => s.toApiJson()).toList();
    final Set<int> pinnedIds = pinnedSessions.map((s) => s['id'] as int).toSet();
    
    print('[NovelSessionList] 步骤1: 加载置顶会话 ${pinnedSessions.length}条');
    
    // 步骤2: 调用API获取第1页
    final apiResult = await _messageService.syncNovelSessionsFromApi(
      page: 1,
      pageSize: 10,
      searchName: _searchKeyword.isEmpty ? null : _searchKeyword,
    );
    
    if (mounted && apiResult['sessions'] is List) {
      final List<Map<String, dynamic>> apiList = List<Map<String, dynamic>>.from(apiResult['sessions']);
      final int total = apiResult['total'] is int ? apiResult['total'] : 0;
      
      print('[NovelSessionList] 步骤2: API返回 ${apiList.length}条, total=$total');
      
      // 步骤3: 过滤掉置顶列表中已有的会话
      final filteredList = apiList.where((session) => 
        !pinnedIds.contains(session['id'] as int)
      ).toList();
      
      print('[NovelSessionList] 步骤3: 过滤后剩余 ${filteredList.length}条');
      
      // 步骤4: 从SharedPreferences获取activeArchiveId
      for (var session in filteredList) {
        final archiveId = _sessionDataService.getNovelArchiveId(session['id'] as int);
        if (archiveId != null) {
          session['active_archive_id'] = archiveId;
        }
      }
      
      // 步骤5: 合并显示（置顶 + API）
      final allSessions = [...pinnedSessions, ...filteredList];
      
      setState(() {
        _sessions = allSessions;
        _currentPage = 1;
        _hasMore = total > 10;
      });
      
      print('[NovelSessionList] ✓ 最终显示 ${allSessions.length}条 (${pinnedSessions.length}置顶 + ${filteredList.length}API)');
      
      // 预加载头像
      for (var session in allSessions) {
        _loadAvatar(session['cover_uri']);
      }
    }
    
    print('========================================');
  }

  /// 🔥 下拉刷新（静默更新，不显示骨架屏）
  Future<void> onRefresh() async {
    _currentPage = 1;
    try {
      await _loadSessionsCore(); // 静默刷新，不触发_isLoading
      _refreshController.refreshCompleted();
      if (_hasMore) {
        _refreshController.loadComplete();
      }
    } catch (e) {
      _refreshController.refreshFailed();
      debugPrint('[NovelSessionList] 刷新失败: $e');
    }
  }

  /// 🔥 加载更多（加载下一页API数据）
  Future<void> _onLoading() async {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return;
    }

    try {
      final nextPage = _currentPage + 1;
      print('[NovelSessionList] >>> 加载更多：第$nextPage页');

      // 调用API获取下一页
      final apiResult = await _messageService.syncNovelSessionsFromApi(
        page: nextPage,
        pageSize: 10,
        searchName: _searchKeyword.isEmpty ? null : _searchKeyword,
      );

      if (mounted && apiResult['sessions'] is List) {
        final List<Map<String, dynamic>> apiList = List<Map<String, dynamic>>.from(apiResult['sessions']);
        final int total = apiResult['total'] is int ? apiResult['total'] : 0;

        // 获取当前置顶会话的ID集合（重新加载以防有变化）
        final pinnedList = await _sessionDataService.getPinnedNovelSessions();
        final Set<int> pinnedIds = pinnedList.map((s) => s.id).toSet();

        // 过滤掉置顶列表中已有的会话
        final filteredList = apiList.where((session) => 
          !pinnedIds.contains(session['id'] as int)
        ).toList();

        // 从SharedPreferences获取activeArchiveId
        for (var session in filteredList) {
          final archiveId = _sessionDataService.getNovelArchiveId(session['id'] as int);
          if (archiveId != null) {
            session['active_archive_id'] = archiveId;
          }
        }

        setState(() {
          _sessions.addAll(filteredList);
          _currentPage = nextPage;
          _hasMore = nextPage * 10 < total;
        });

        print('[NovelSessionList] ✓ 第$nextPage页: API返回${apiList.length}条, 过滤后${filteredList.length}条, 总计${_sessions.length}条');

        for (var session in filteredList) {
          _loadAvatar(session['cover_uri']);
        }

        _refreshController.loadComplete();
      }
    } catch (e) {
      print('[NovelSessionList] [ERROR] 加载更多失败: $e');
      _refreshController.loadFailed();
    }
  }

  /// 🔥 处理搜索输入
  void _onSearchChanged(String value) {
    // 取消之前的防抖Timer
    _searchDebounceTimer?.cancel();
    
    // 设置新的防抖Timer（500ms）
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchKeyword != value) {
        setState(() {
          _searchKeyword = value;
        });
        // 重新加载数据
        _loadSessions();
      }
    });
  }

  /// 🔥 清除搜索
  void _clearSearch() {
    _searchController.clear();
    if (_searchKeyword.isNotEmpty) {
      setState(() {
        _searchKeyword = '';
      });
      _loadSessions();
    }
  }

  Future<void> _loadAvatar(String? coverUri) async {
    if (coverUri == null ||
        coverUri.isEmpty ||
        _avatarCache.containsKey(coverUri)) {
      return;
    }

    try {
      final result = await _fileService.getFile(coverUri);
      if (mounted && result.data != null) {
        final data = result.data;
        if (data is Uint8List) {
          setState(() => _avatarCache[coverUri] = data);
        } else {
          debugPrint('预加载头像数据类型错误: ${data.runtimeType}');
        }
      }
    } catch (e) {
      debugPrint('加载头像失败: $e');
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final dateTime = DateTime.parse(timeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return '刚刚';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}分钟前';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}小时前';
      } else if (difference.inDays < 30) {
        return '${difference.inDays}天前';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months个月前';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years年前';
      }
    } catch (e) {
      return '';
    }
  }

  T _safeGet<T>(Map<String, dynamic>? map, String key, T defaultValue) {
    if (map == null) return defaultValue;
    try {
      final value = map[key];
      if (value == null) return defaultValue;
      if (value is T) return value;
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  /// 解析小说标题，分离调试版前缀
  Map<String, String> _parseNovelTitle(String title) {
    if (title.startsWith('(调试版)')) {
      return {
        'prefix': '(调试版)',
        'title': title.substring(5).trim(),
      };
    }
    return {
      'prefix': '',
      'title': title,
    };
  }

  /// 构建调试版标签
  Widget _buildDebugTag() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppTheme.buttonGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: const GradientRotation(0.4),
        ),
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.buttonGradient.first.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '调试版',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customHeader = CustomHeader(
      builder: (BuildContext context, RefreshStatus? mode) {
        Widget body;
        if (mode == RefreshStatus.idle) {
          body = Text('下拉刷新',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp));
        } else if (mode == RefreshStatus.refreshing) {
          body = Shimmer.fromColors(
            baseColor: Colors.white70,
            highlightColor: Colors.white,
            child: Text(
              '正在刷新...',
              style: TextStyle(fontSize: 14.sp),
            ),
          );
        } else if (mode == RefreshStatus.failed) {
          body = Text('刷新失败',
              style: TextStyle(color: Colors.amber, fontSize: 14.sp));
        } else if (mode == RefreshStatus.canRefresh) {
          body = Text('松开刷新',
              style: TextStyle(color: Colors.white, fontSize: 14.sp));
        } else {
          body = Text('刷新完成',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp));
        }
        return SizedBox(
          height: 55.0,
          child: Center(child: body),
        );
      },
    );

    final customFooter = CustomFooter(
      builder: (BuildContext context, LoadStatus? mode) {
        Widget body;
        if (mode == LoadStatus.idle) {
          body = Text('上拉加载更多',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp));
        } else if (mode == LoadStatus.loading) {
          body = Shimmer.fromColors(
            baseColor: Colors.white70,
            highlightColor: Colors.white,
            child: Text(
              '正在加载...',
              style: TextStyle(fontSize: 14.sp),
            ),
          );
        } else if (mode == LoadStatus.failed) {
          body = Text('加载失败',
              style: TextStyle(color: Colors.amber, fontSize: 14.sp));
        } else if (mode == LoadStatus.canLoading) {
          body = Text('释放加载更多',
              style: TextStyle(color: Colors.white, fontSize: 14.sp));
        } else {
          body = Text('没有更多数据了',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp));
        }
        return SizedBox(
          height: 55.0,
          child: Center(child: body),
        );
      },
    );

    if (_isLoading && _sessions.isEmpty) {
      return Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: 10,
              itemBuilder: (context, index) => _buildNovelSkeletonItem(),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // 🔥 搜索栏
        _buildSearchBar(),
        // 列表
        Expanded(
          child: _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 48.sp,
                        color: AppTheme.textSecondary.withOpacity(0.3),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '暂无小说',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '开始创作您的第一本小说吧',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondary.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                )
              : SmartRefresher(
                  controller: _refreshController,
                  enablePullDown: true,
                  enablePullUp: true,
                  header: customHeader,
                  footer: customFooter,
                  onRefresh: onRefresh,
                  onLoading: _onLoading,
                  child: ListView.builder(
                    key: const PageStorageKey('novel_list'),
                    itemCount: _sessions.length,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    itemBuilder: (context, index) {
                      try {
                        final session = _sessions[index];
                        return _buildNovelSessionItem(
                          context,
                          session,
                        );
                      } catch (e) {
                        debugPrint('构建小说项失败 index=$index: $e');
                        return SizedBox(
                          height: 60.h,
                          child: Center(
                            child: Text(
                              '加载失败',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
        ),
      ],
    );
  }

  /// 🔥 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      height: 44.h,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppTheme.border.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppTheme.textSecondary.withOpacity(0.6),
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14.sp,
              ),
              decoration: InputDecoration(
                hintText: '搜索小说',
                hintStyle: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.5),
                  fontSize: 14.sp,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
                fillColor: Colors.transparent,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // 清除按钮（有内容时显示）
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) {
              if (value.text.isEmpty) {
                return const SizedBox.shrink();
              }
              return GestureDetector(
                onTap: _clearSearch,
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  child: Icon(
                    Icons.cancel,
                    color: AppTheme.textSecondary.withOpacity(0.6),
                    size: 18.sp,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNovelSessionItem(
    BuildContext context,
    Map<String, dynamic> session,
  ) {
    if (session.isEmpty) {
      return SizedBox.shrink();
    }

    final int sessionId;
    try {
      sessionId = session['id'] as int;
    } catch (e) {
      debugPrint('获取小说会话 ID 失败: $e');
      return SizedBox.shrink();
    }

    final String? coverUri = session['cover_uri'];
    final bool hasAvatar = coverUri != null &&
        coverUri.isNotEmpty &&
        _avatarCache.containsKey(coverUri);
    final bool isSelected = widget.selectedIds.contains(sessionId);

    String title = '';
    try {
      title = session['title'] ?? '未命名小说';
    } catch (e) {
      title = '未命名小说';
    }

    // 解析小说标题，分离调试版前缀
    final parsedTitle = _parseNovelTitle(title);
    final bool isDebugVersion = parsedTitle['prefix']!.isNotEmpty;
    final String displayTitle = parsedTitle['title']!;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Slidable(
        enabled: !widget.isMultiSelectMode,
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            CustomSlidableAction(
              borderRadius: BorderRadius.circular(12.r),
              onPressed: (context) {
                final bool isPinned = (session['is_pinned'] as int? ?? 0) == 1;
                if (isPinned) {
                  _unpinSession(sessionId);
                } else {
                  _pinSession(sessionId);
                }
                // 关闭滑动状态
                Slidable.of(context)?.close();
              },
              backgroundColor: (session['is_pinned'] as int? ?? 0) == 1 ? const Color(0xFF8E8E93) : const Color(0xFFFF9500),
              foregroundColor: Colors.white,
              icon: (session['is_pinned'] as int? ?? 0) == 1 ? Icons.push_pin_outlined : Icons.push_pin,
              label: (session['is_pinned'] as int? ?? 0) == 1 ? '取消置顶' : '置顶',
              iconSize: 16.sp,
              labelStyle: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.5,
          children: [
            CustomSlidableAction(
              borderRadius: BorderRadius.circular(12.r),
              onPressed: (context) {
                _showRenameDialog(sessionId, session['title'] ?? '未命名小说');
                // 关闭滑动状态
                Slidable.of(context)?.close();
              },
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: '重命名',
              iconSize: 16.sp,
              labelStyle: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.w500),
            ),
            CustomSlidableAction(
              borderRadius: BorderRadius.circular(12.r),
              onPressed: (context) {
                _showDeleteConfirmDialog(sessionId);
                // 关闭滑动状态
                Slidable.of(context)?.close();
              },
              backgroundColor: const Color(0xFFFF3B30),
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: '删除',
              iconSize: 16.sp,
              labelStyle: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            if (widget.isMultiSelectMode) {
              widget.onSelectionChanged(sessionId);
            } else {
              final Map<String, dynamic> safeNovelData = {
                'title': title,
                'id': sessionId,
                'cover_uri': coverUri,
              };

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NovelReadingPage(
                    sessionData: session,
                    novelData: safeNovelData,
                  ),
                ),
              );
            }
          },
          onLongPressStart: widget.isMultiSelectMode
              ? null
              : (LongPressStartDetails details) {
                  // 🔥 修复：使用LongPressStartDetails获取准确的触摸位置
                  final Offset globalPosition = details.globalPosition;
                  widget.onShowMenu(context, session, globalPosition);
                },
        child: Container(
          height: 60.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            color: AppTheme.cardBackground.withOpacity(0.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: coverUri != null && coverUri.isNotEmpty
                    ? hasAvatar
                        ? Image.memory(
                            _avatarCache[coverUri]!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppTheme.cardBackground,
                              );
                            },
                          )
                        : FutureBuilder(
                            future: _fileService.getFile(coverUri),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                if (!_avatarCache.containsKey(coverUri)) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted) {
                                      try {
                                        final data = snapshot.data!.data;
                                        if (data is Uint8List) {
                                          setState(() {
                                            _avatarCache[coverUri] = data;
                                          });
                                        }
                                      } catch (e) {
                                        debugPrint('缓存封面失败: $e');
                                      }
                                    }
                                  });
                                }

                                try {
                                  final data = snapshot.data!.data;
                                  if (data is Uint8List) {
                                    return Image.memory(
                                      data,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: AppTheme.cardBackground,
                                        );
                                      },
                                    );
                                  } else {
                                    return Container(
                                      color: AppTheme.cardBackground,
                                    );
                                  }
                                } catch (e) {
                                  return Container(
                                    color: AppTheme.cardBackground,
                                  );
                                }
                              }
                              return Shimmer.fromColors(
                                baseColor: AppTheme.cardBackground,
                                highlightColor:
                                    AppTheme.cardBackground.withOpacity(0.5),
                                child: Container(
                                  color: AppTheme.cardBackground,
                                ),
                              );
                            },
                          )
                    : Container(
                        color: AppTheme.cardBackground,
                      ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.isMultiSelectMode)
                Positioned(
                  left: 12.w,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected ? AppTheme.primaryColor : Colors.white,
                          width: 2,
                        ),
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 16.sp,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              Positioned(
                left: widget.isMultiSelectMode ? 48.w : 16.w,
                right: 16.w,
                bottom: 8.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  displayTitle,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 1),
                                        blurRadius: 3.0,
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              // 🔥 调试版标签
                              if (isDebugVersion) ...[
                                SizedBox(width: 4.w),
                                _buildDebugTag(),
                              ],
                              // 🔥 置顶图标
                              if ((session['is_pinned'] as int? ?? 0) == 1) ...[
                                SizedBox(width: 4.w),
                                Icon(
                                  Icons.push_pin,
                                  size: 12.sp,
                                  color: Colors.orange,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          _formatTime(_safeGet(session, 'updated_at', '')),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white.withOpacity(0.8),
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2.0,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (session['tags'] is List &&
                        (session['tags'] as List).isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: Wrap(
                          spacing: 6.w,
                          runSpacing: 4.h,
                          children: (session['tags'] as List)
                              .take(2)
                              .map((tag) => Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      tag.toString(),
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
          ),
        ),
    );
  }

  Widget _buildNovelSkeletonItem() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Shimmer.fromColors(
        baseColor: AppTheme.cardBackground,
        highlightColor: AppTheme.cardBackground.withOpacity(0.5),
        child: Container(
          height: 60.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            color: AppTheme.cardBackground,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 120.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    Container(
                      width: 40.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      width: 40.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔥 置顶会话（本地UI调整，无需重新加载）
  Future<void> _pinSession(int sessionId) async {
    try {
      // 先在UI上立即更新（乐观更新）
      if (mounted) {
        setState(() {
          final index = _sessions.indexWhere((s) => s['id'] == sessionId);
          if (index != -1) {
            final session = _sessions.removeAt(index);
            session['is_pinned'] = 1;
            session['pinned_at'] = DateTime.now().toIso8601String();
            _sessions.insert(0, session);
          }
        });
      }

      // 后台调用API
      final MessageService messageService = MessageService();
      await messageService.pinNovelSession(sessionId);
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '置顶失败: $e',
          type: ToastType.error,
        );
      }
    }
  }

  /// 🔥 取消置顶会话（本地UI调整，无需重新加载）
  Future<void> _unpinSession(int sessionId) async {
    try {
      // 先在UI上立即更新（乐观更新）
      if (mounted) {
        setState(() {
          final index = _sessions.indexWhere((s) => s['id'] == sessionId);
          if (index != -1) {
            final session = _sessions.removeAt(index);
            session['is_pinned'] = 0;
            session['pinned_at'] = null;
            final firstUnpinnedIndex = _sessions.indexWhere((s) => (s['is_pinned'] as int? ?? 0) == 0);
            if (firstUnpinnedIndex != -1) {
              _sessions.insert(firstUnpinnedIndex, session);
            } else {
              _sessions.add(session);
            }
          }
        });
      }

      // 后台调用API
      final MessageService messageService = MessageService();
      await messageService.unpinNovelSession(sessionId);
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '取消置顶失败: $e',
          type: ToastType.error,
        );
      }
    }
  }

  /// 显示重命名对话框
  void _showRenameDialog(int sessionId, String currentName) {
    final TextEditingController controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('重命名小说'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: '请输入新名称',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  _renameSession(sessionId, newName);
                }
                Navigator.of(context).pop();
              },
              child: Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// 重命名会话
  Future<void> _renameSession(int sessionId, String newName) async {
    try {
      final result = await _messageService.renameNovelSession(sessionId, newName);

      if (result['success'] == true) {
        if (mounted) {
          CustomToast.show(
            context,
            message: '重命名成功',
            type: ToastType.success,
          );
          _loadSessions();
        }
      } else {
        if (mounted) {
          CustomToast.show(
            context,
            message: result['msg'] ?? '重命名失败',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '重命名失败: $e',
          type: ToastType.error,
        );
      }
    }
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteConfirmDialog(int sessionId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('确认删除'),
          content: Text('确定要删除这个小说会话吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('取消', style: TextStyle(decoration: TextDecoration.none)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('删除', style: TextStyle(color: Colors.red, decoration: TextDecoration.none)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _deleteSingleSession(sessionId);
    }
  }

  /// 删除单个会话
  Future<void> _deleteSingleSession(int sessionId) async {
    try {
      final Map<String, dynamic> result = await _messageService.batchDeleteNovelSessions([sessionId]);

      if (mounted) {
        CustomToast.show(
          context,
          message: result['msg'] ?? '删除完成',
          type: result['success'] ? ToastType.success : ToastType.error,
        );
        _loadSessions();
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '删除失败: $e',
          type: ToastType.error,
        );
      }
    }
  }
}

/// 自定义滑动按钮，支持调整图标和文字大小
class CustomSlidableAction extends StatelessWidget {
  const CustomSlidableAction({
    super.key,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    this.borderRadius,
    this.iconSize,
    this.labelStyle,
  });

  final void Function(BuildContext) onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String label;
  final BorderRadius? borderRadius;
  final double? iconSize;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onPressed(context),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: foregroundColor,
                size: iconSize ?? 20.sp,
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: labelStyle ?? TextStyle(
                  color: foregroundColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
