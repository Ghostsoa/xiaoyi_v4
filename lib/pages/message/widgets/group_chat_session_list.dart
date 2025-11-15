import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:typed_data';
import 'dart:async';

import '../../../theme/app_theme.dart';
import '../../group_chat/pages/group_chat_page.dart';
import '../message_service.dart';
import '../../../services/file_service.dart';
import '../../../services/session_data_service.dart';
import '../../../widgets/custom_toast.dart';

class GroupChatSessionList extends StatefulWidget {
  const GroupChatSessionList({
    super.key,
    required this.isMultiSelectMode,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.onShowMenu,
    this.onRefresh,
  });

  final bool isMultiSelectMode;
  final Set<int> selectedIds;
  final ValueChanged<int> onSelectionChanged;
  final Function(BuildContext, Map<String, dynamic>, Offset) onShowMenu;
  final VoidCallback? onRefresh;

  @override
  GroupChatSessionListState createState() => GroupChatSessionListState();
}

class GroupChatSessionListState extends State<GroupChatSessionList> {
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
      print('[GroupChatSessionList] [ERROR] 加载失败: $e');
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
    print('[GroupChatSessionList] 🔥 开始加载（新逻辑）');
    
    // 步骤1: 加载置顶会话（从SQLite）
    final pinnedList = await _sessionDataService.getPinnedGroupChatSessions();
    final List<Map<String, dynamic>> pinnedSessions = pinnedList.map((s) => s.toApiJson()).toList();
    final Set<int> pinnedIds = pinnedSessions.map((s) => s['id'] as int).toSet();
    
    print('[GroupChatSessionList] 步骤1: 加载置顶会话 ${pinnedSessions.length}条');
    
    // 步骤2: 调用API获取第1页
    final apiResult = await _messageService.syncGroupChatSessionsFromApi(
      page: 1,
      pageSize: 10,
      searchName: _searchKeyword.isEmpty ? null : _searchKeyword,
    );
    
    if (mounted && apiResult['items'] is List) {
      final List<Map<String, dynamic>> apiList = List<Map<String, dynamic>>.from(apiResult['items']);
      final int total = apiResult['total'] is int ? apiResult['total'] : 0;
      
      print('[GroupChatSessionList] 步骤2: API返回 ${apiList.length}条, total=$total');
      
      // 步骤3: 过滤掉置顶列表中已有的会话（群聊无activeArchiveId处理）
      final filteredList = apiList.where((session) => 
        !pinnedIds.contains(session['id'] as int)
      ).toList();
      
      print('[GroupChatSessionList] 步骤3: 过滤后剩余 ${filteredList.length}条');
      
      // 步骤4: 合并显示（置顶 + API）
      final allSessions = [...pinnedSessions, ...filteredList];
      
      setState(() {
        _sessions = allSessions;
        _currentPage = 1;
        _hasMore = total > 10;
      });
      
      print('[GroupChatSessionList] ✓ 最终显示 ${allSessions.length}条 (${pinnedSessions.length}置顶 + ${filteredList.length}API)');
      
      // 预加载头像
      for (var session in allSessions) {
        _loadAvatar(session['cover_uri']);
      }
    }
    
    print('========================================');
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
      debugPrint('[GroupChatSessionList] 刷新失败: $e');
    }
  }

  Future<void> _onLoadMore() async {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return;
    }

    try {
      final nextPage = _currentPage + 1;

      print('========================================');
      print('[GroupChatSessionList] >>> 加载更多：第$nextPage页');

      // 调用API获取下一页
      final apiResult = await _messageService.syncGroupChatSessionsFromApi(
        page: nextPage,
        pageSize: 10,
        searchName: _searchKeyword.isEmpty ? null : _searchKeyword,
      );

      if (mounted && apiResult['items'] is List) {
        final List<Map<String, dynamic>> apiList = List<Map<String, dynamic>>.from(apiResult['items']);
        final int total = apiResult['total'] is int ? apiResult['total'] : 0;

        // 获取当前置顶会话的ID集合（重新加载以防有变化）
        final pinnedList = await _sessionDataService.getPinnedGroupChatSessions();
        final Set<int> pinnedIds = pinnedList.map((s) => s.id).toSet();

        // 过滤掉置顶列表中已有的会话
        final filteredList = apiList.where((session) => 
          !pinnedIds.contains(session['id'] as int)
        ).toList();

        setState(() {
          _sessions.addAll(filteredList);
          _currentPage = nextPage;
          _hasMore = nextPage * 10 < total;
        });

        print('[GroupChatSessionList] ✓ 第$nextPage页: API返回${apiList.length}条, 过滤后${filteredList.length}条, 总计${_sessions.length}条');

        for (var session in filteredList) {
          _loadAvatar(session['cover_uri']);
        }

        _refreshController.loadComplete();
      }
    } catch (e) {
      print('[GroupChatSessionList] [ERROR] 加载失败: $e');
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
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
          );
        } else if (mode == RefreshStatus.canRefresh) {
          body = Text('释放刷新',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp));
        } else if (mode == RefreshStatus.completed) {
          body = Text('刷新完成',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp));
        } else {
          body = Text('下拉刷新',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp));
        }
        return Container(
          height: 55.0.h,
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
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
          );
        } else if (mode == LoadStatus.canLoading) {
          body = Text('释放加载更多',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp));
        } else if (mode == LoadStatus.noMore) {
          body = Text('没有更多数据了',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp));
        } else {
          body = Text('上拉加载更多',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp));
        }
        return Container(
          height: 55.0.h,
          child: Center(child: body),
        );
      },
    );

    if (_isLoading && _sessions.isEmpty) {
      return Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildLoadingState()),
        ],
      );
    }

    return Column(
      children: [
        // 🔥 搜索栏
        _buildSearchBar(),
        // 列表
        Expanded(
          child: SmartRefresher(
            controller: _refreshController,
            enablePullDown: true,
            enablePullUp: true,
            header: customHeader,
            footer: customFooter,
            onRefresh: onRefresh,
            onLoading: _onLoadMore,
            child: _sessions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    key: const PageStorageKey('group_chat_list'),
                    itemCount: _sessions.length,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return _buildSessionItem(session, index);
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
                hintText: '搜索群聊',
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

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: AppTheme.cardBackground,
        highlightColor: AppTheme.cardBackground.withOpacity(0.5),
        child: Container(
          height: 80.h,
          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 64.sp,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            '暂无群聊会话',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '开始创建或加入群聊吧！',
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.7),
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSessionItem(Map<String, dynamic> session, int index) {
    final sessionId = session['id'] as int;
    final isSelected = widget.selectedIds.contains(sessionId);
    final coverUri = session['cover_uri'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Slidable(
        key: ValueKey(sessionId),
        enabled: !widget.isMultiSelectMode,
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          CustomSlidableAction(
            onPressed: (context) {
              final bool isPinned = (session['is_pinned'] as int? ?? 0) == 1;
              if (isPinned) {
                unpinSession(sessionId);
              } else {
                pinSession(sessionId);
              }
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
            onPressed: (context) {
              _showRenameDialog(session);
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
            onPressed: (context) {
              _deleteSession(session);
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
        onTap: () => _handleSessionTap(session),
        onLongPressStart: widget.isMultiSelectMode
            ? null
            : (details) => _handleSessionLongPress(session, details.globalPosition),
        child: Container(
          height: 64.h,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            border: isSelected 
                ? Border.all(color: AppTheme.primaryColor, width: 2)
                : null,
          ),
          child: Stack(
            children: [
              // 背景封面图片
              if (coverUri != null)
                Positioned.fill(
                  child: _avatarCache.containsKey(coverUri)
                      ? Image.memory(
                          _avatarCache[coverUri]!,
                          fit: BoxFit.cover,
                        )
                      : FutureBuilder(
                          future: _fileService.getFile(coverUri),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.data != null) {
                              final imageData = snapshot.data!.data as Uint8List;
                              if (!_avatarCache.containsKey(coverUri)) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() {
                                      _avatarCache[coverUri] = imageData;
                                    });
                                  }
                                });
                              }
                              return Image.memory(
                                imageData,
                                fit: BoxFit.cover,
                              );
                            }
                            return Container(
                              color: AppTheme.cardBackground,
                            );
                          },
                        ),
                ),
              // 半透明遮罩
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ),
              // 内容层
              Positioned.fill(
                child: Row(
                  children: [
                    if (widget.isMultiSelectMode) ...[
                      Container(
                        width: 40.w,
                        child: Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? AppTheme.primaryColor : Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ],
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 群聊名称和时间
                            Builder(
                              builder: (context) {
                                // 解析会话名称，分离调试版前缀
                                final parsedName = _parseSessionName(session['name'] ?? '未命名群聊');
                                final bool isDebugVersion = parsedName['prefix']!.isNotEmpty;
                                final String displayName = parsedName['name']!;

                                return Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              displayName,
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(1, 1),
                                                    blurRadius: 2,
                                                    color: Colors.black.withOpacity(0.8),
                                                  ),
                                                ],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
                                      _getTimeText(session['updated_at'] as String?),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.white.withOpacity(0.9),
                                        shadows: [
                                          Shadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                            color: Colors.black.withOpacity(0.8),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            // 角色头像列表
                            _buildCompactRolesList(session['roles'] as List<dynamic>?),
                          ],
                        ),
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


  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 7) {
      return '${time.month}-${time.day}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  String _getTimeText(String? updatedAt) {
    if (updatedAt == null) return '';
    try {
      final updateTime = DateTime.parse(updatedAt).toLocal();
      return _formatTime(updateTime);
    } catch (e) {
      return '';
    }
  }

  /// 解析会话名称，分离调试版前缀
  Map<String, String> _parseSessionName(String sessionName) {
    if (sessionName.startsWith('(调试版)')) {
      return {
        'prefix': '(调试版)',
        'name': sessionName.substring(5).trim(),
      };
    }
    return {
      'prefix': '',
      'name': sessionName,
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

  Widget _buildCompactRolesList(List<dynamic>? roles) {
    if (roles == null || roles.isEmpty) {
      return Text(
        '暂无角色',
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.white.withOpacity(0.8),
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.8),
            ),
          ],
        ),
      );
    }

    final displayRoles = roles.take(6).toList(); // 最多显示6个角色
    final hasMore = roles.length > 6;

    return Row(
      children: [
        // 角色头像
        ...displayRoles.asMap().entries.map((entry) {
          final role = entry.value as Map<String, dynamic>;
          final avatarUri = role['avatarUri'] as String?;
          
          return Container(
            margin: EdgeInsets.only(right: 4.w),
            child: Container(
              width: 18.w,
              height: 18.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: avatarUri != null && _avatarCache.containsKey(avatarUri)
                    ? Image.memory(
                        _avatarCache[avatarUri]!,
                        fit: BoxFit.cover,
                      )
                    : avatarUri != null
                        ? FutureBuilder(
                            future: _fileService.getFile(avatarUri),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data!.data != null) {
                                final imageData = snapshot.data!.data as Uint8List;
                                if (!_avatarCache.containsKey(avatarUri)) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) {
                                      setState(() {
                                        _avatarCache[avatarUri] = imageData;
                                      });
                                    }
                                  });
                                }
                                return Image.memory(
                                  imageData,
                                  fit: BoxFit.cover,
                                );
                              }
                              return Container(
                                color: AppTheme.primaryColor.withOpacity(0.8),
                                child: Center(
                                  child: Text(
                                    (role['name'] ?? '?').toString().substring(0, 1),
                                    style: TextStyle(
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppTheme.primaryColor.withOpacity(0.8),
                            child: Center(
                              child: Text(
                                (role['name'] ?? '?').toString().substring(0, 1),
                                style: TextStyle(
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
              ),
            ),
          );
        }).toList(),
        // 更多指示器
        if (hasMore)
          Container(
            margin: EdgeInsets.only(left: 4.w),
            child: Text(
              '+${roles.length - 6}',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _handleSessionTap(Map<String, dynamic> session) {
    if (widget.isMultiSelectMode) {
      widget.onSelectionChanged(session['id'] as int);
    } else {
      _enterGroupChat(session);
    }
  }

  void _handleSessionLongPress(Map<String, dynamic> session, Offset position) {
    if (!widget.isMultiSelectMode) {
      widget.onShowMenu(context, session, position);
    }
  }

  void _enterGroupChat(Map<String, dynamic> session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatPage(
          sessionData: session,
          groupChatData: session,
        ),
      ),
    );
  }

  void _deleteSession(Map<String, dynamic> session) async {
    final sessionId = session['id'] as int;
    
    try {
      final result = await _messageService.deleteGroupChatSession(sessionId);
      
      if (result['success'] == true) {
        setState(() {
          _sessions.removeWhere((s) => s['id'] == sessionId);
        });
        CustomToast.show(
          context,
          message: '删除成功',
          type: ToastType.success,
        );
      } else {
        CustomToast.show(
          context,
          message: result['msg'] ?? '删除失败',
          type: ToastType.error,
        );
      }
    } catch (e) {
      CustomToast.show(
        context,
        message: '删除失败: $e',
        type: ToastType.error,
      );
    }
  }

  void _showRenameDialog(Map<String, dynamic> session) {
    final sessionId = session['id'] as int;
    final currentName = session['name'] ?? '未命名群聊';
    final TextEditingController controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          title: Text(
            '重命名群聊',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: '请输入新名称',
              hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '取消',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != currentName) {
                  _renameSession(sessionId, newName);
                }
                Navigator.of(context).pop();
              },
              child: Text(
                '确定',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _renameSession(int sessionId, String newName) async {
    try {
      final result = await _messageService.renameGroupChatSession(sessionId, newName);
      
      if (result['success'] == true) {
        // 更新本地会话列表中的名称
        setState(() {
          final index = _sessions.indexWhere((s) => s['id'] == sessionId);
          if (index != -1) {
            _sessions[index]['name'] = newName;
          }
        });
        CustomToast.show(
          context,
          message: '重命名成功',
          type: ToastType.success,
        );
      } else {
        CustomToast.show(
          context,
          message: result['msg'] ?? '重命名失败',
          type: ToastType.error,
        );
      }
    } catch (e) {
      CustomToast.show(
        context,
        message: '重命名失败: $e',
        type: ToastType.error,
      );
    }
  }

  /// 🔥 公共方法：置顶群聊会话（供父组件调用，带乐观更新）
  Future<void> pinSession(int sessionId) async {
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
      await _messageService.pinGroupChatSession(sessionId);
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

  /// 🔥 公共方法：取消置顶群聊会话（供父组件调用，带乐观更新）
  Future<void> unpinSession(int sessionId) async {
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
      await _messageService.unpinGroupChatSession(sessionId);
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
          height: 64.h, // 与群聊卡片高度一致
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
