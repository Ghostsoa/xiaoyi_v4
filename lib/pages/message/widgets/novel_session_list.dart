import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';
import 'dart:async';

import '../../../theme/app_theme.dart';
import '../../novel/pages/novel_reading_page.dart';
import '../message_service.dart';
import '../../../services/file_service.dart';
import '../../../services/session_data_service.dart';
import '../../../models/session_model.dart';

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
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                childAspectRatio: 0.65,
              ),
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
                  child: GridView.builder(
                    key: const PageStorageKey('novel_list'),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      childAspectRatio: 0.65, // 宽高比，使卡片呈竖向长方形
                    ),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      try {
                        final session = _sessions[index];
                        return _buildNovelSessionItem(
                          context,
                          session,
                        );
                      } catch (e) {
                        debugPrint('构建小说项失败 index=$index: $e');
                        return Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground.withOpacity(0.3),
                          ),
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

    return GestureDetector(
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
                  final Offset globalPosition = details.globalPosition;
                  widget.onShowMenu(context, session, globalPosition);
                },
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground.withOpacity(0.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
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
              // 黑色渐变遮罩
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // 多选模式选择框
              if (widget.isMultiSelectMode)
                Positioned(
                  right: 8.w,
                  top: 8.h,
                  child: Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.white,
                        width: 2,
                      ),
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.black.withOpacity(0.3),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 14.sp,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              // 底部信息区域
              Positioned(
                left: 8.w,
                right: 8.w,
                bottom: 8.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 置顶标签
                    if ((session['is_pinned'] as int? ?? 0) == 1)
                      Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Icon(
                          Icons.push_pin,
                          size: 14.sp,
                          color: Colors.orange,
                        ),
                      ),
                    // 标题行
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 调试版标签
                        if (isDebugVersion) ...[
                          SizedBox(width: 4.w),
                          _buildDebugTag(),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
                    // 时间
                    Text(
                      _formatTime(_safeGet(session, 'updated_at', '')),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    // 标签
                    if (session['tags'] is List && (session['tags'] as List).isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Wrap(
                        spacing: 4.w,
                        runSpacing: 4.h,
                        children: (session['tags'] as List)
                            .take(2)
                            .map((tag) => Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    tag.toString(),
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildNovelSkeletonItem() {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardBackground,
      highlightColor: AppTheme.cardBackground.withOpacity(0.5),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: AppTheme.cardBackground,
              ),
            ),
            Positioned(
              left: 8.w,
              right: 8.w,
              bottom: 8.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    width: 60.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        width: 40.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 公共方法：置顶会话（供父组件调用，带乐观更新）
  Future<void> pinSession(int sessionId) async {
    Map<String, dynamic>? sessionData;
    
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
            sessionData = session; // 保存会话数据
          }
        });
      }

      // 先确保会话在本地数据库中存在
      if (sessionData != null) {
        final sessionModel = SessionModel.fromApiJson(sessionData!);
        await _sessionDataService.insertOrUpdateNovelSessions([sessionModel]);
      }
      
      // 然后调用置顶API（会更新本地数据库的is_pinned字段）
      await _messageService.pinNovelSession(sessionId);
    } catch (e) {
      debugPrint('[NovelSessionList] 置顶失败: $e');
      // 如果API失败，重新加载以恢复正确状态
      if (mounted) {
        _loadSessions();
      }
    }
  }

  /// 🔥 公共方法：取消置顶会话（供父组件调用，带乐观更新）
  Future<void> unpinSession(int sessionId) async {
    Map<String, dynamic>? sessionData;
    
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
            sessionData = session; // 保存会话数据
          }
        });
      }

      // 先确保会话在本地数据库中存在
      if (sessionData != null) {
        final sessionModel = SessionModel.fromApiJson(sessionData!);
        await _sessionDataService.insertOrUpdateNovelSessions([sessionModel]);
      }
      
      // 然后调用API（会更新本地数据库的is_pinned字段）
      await _messageService.unpinNovelSession(sessionId);
    } catch (e) {
      debugPrint('[NovelSessionList] 取消置顶失败: $e');
      // 如果API失败，重新加载以恢复正确状态
      if (mounted) {
        _loadSessions();
      }
    }
  }
}
