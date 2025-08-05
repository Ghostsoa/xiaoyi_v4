import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';
import 'dart:async';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import '../../character_chat/pages/character_chat_page.dart';
import '../message_service.dart';
import '../../../services/file_service.dart';
import '../../../services/session_data_service.dart';

class CharacterSessionList extends StatefulWidget {
  const CharacterSessionList({
    Key? key,
    required this.isMultiSelectMode,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.onShowMenu,
  }) : super(key: key);

  final bool isMultiSelectMode;
  final Set<int> selectedIds;
  final ValueChanged<int> onSelectionChanged;
  final Function(BuildContext, Map<String, dynamic>, Offset) onShowMenu; // 🔥 添加位置参数

  @override
  CharacterSessionListState createState() => CharacterSessionListState();
}

class CharacterSessionListState extends State<CharacterSessionList> {
  final MessageService _messageService = MessageService();
  final FileService _fileService = FileService();
  final SessionDataService _sessionDataService = SessionDataService();
  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _sessions = [];
  int _currentPage = 1;
  bool _hasMore = true;
  final Map<String, Uint8List> _avatarCache = {};
  bool _isLoadingMore = false;
  bool _isSyncing = false; // 是否正在后台同步
  StreamSubscription? _sessionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initSessionDataService();
    _loadSessions();
  }

  @override
  void dispose() {
    _sessionStreamSubscription?.cancel();
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化会话数据服务
  Future<void> _initSessionDataService() async {
    await _sessionDataService.initDatabase();

    // 监听会话数据变化
    _sessionStreamSubscription = _sessionDataService.characterSessionsStream.listen(
      (sessions) {
        if (mounted) {
          setState(() {
            _sessions = sessions.map((session) => session.toApiJson()).toList();
          });
        }
      },
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreSessions();
    }
  }

  Future<void> _loadSessions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _sessions = [];
      _currentPage = 1;
    });

    try {
      // 优先从本地数据库加载
      final result = await _messageService.getCharacterSessions(
        page: _currentPage,
        pageSize: 10,
      );

      if (mounted) {
        setState(() {
          if (result['list'] is List) {
            _sessions = List<Map<String, dynamic>>.from(result['list']);
          } else {
            _sessions = [];
            debugPrint('获取本地会话列表返回数据格式错误: $result');
          }

          final int total = result['total'] is int ? result['total'] : 0;
          _hasMore = _sessions.length < total;
          _isLoading = false;
        });

        // 加载头像
        for (var session in _sessions) {
          _loadAvatar(session['cover_uri']);
        }

        // 静默同步API数据
        _syncWithApiInBackground();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _sessions = [];
        });
        debugPrint('加载本地会话列表失败: $e');
      }
    }
  }

  /// 后台静默同步API数据
  Future<void> _syncWithApiInBackground() async {
    if (_isSyncing) return;

    _isSyncing = true;
    try {
      await _messageService.syncCharacterSessionsFromApi(
        page: 1,
        pageSize: 1000, // 获取所有数据进行同步
      );
      debugPrint('[CharacterSessionList] 后台同步完成');
    } catch (e) {
      debugPrint('[CharacterSessionList] 后台同步失败: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _loadMoreSessions() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await _messageService.getCharacterSessions(
        page: _currentPage + 1,
        pageSize: 10,
      );

      if (mounted) {
        List<Map<String, dynamic>> newSessions = [];
        if (result['list'] is List) {
          newSessions = List<Map<String, dynamic>>.from(result['list']);
        } else {
          debugPrint('加载更多会话返回数据格式错误: $result');
        }

        setState(() {
          _sessions.addAll(newSessions);
          _currentPage++;
          final int total = result['total'] is int ? result['total'] : 0;
          _hasMore = _sessions.length < total;
          _isLoadingMore = false;
        });

        for (var session in newSessions) {
          _loadAvatar(session['cover_uri']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        debugPrint('加载更多会话失败: $e');
      }
    }
  }

  Future<void> onRefresh() async {
    _currentPage = 1;
    try {
      // 手动刷新时，强制从API同步最新数据
      await _messageService.syncCharacterSessionsFromApi(
        page: 1,
        pageSize: 1000, // 获取所有数据
      );

      // 然后从本地数据库重新加载第一页
      final result = await _messageService.getCharacterSessions(
        page: _currentPage,
        pageSize: 10,
      );

      if (mounted) {
        setState(() {
          if (result['list'] is List) {
            _sessions = List<Map<String, dynamic>>.from(result['list']);
          } else {
            _sessions = [];
            debugPrint('刷新会话列表返回数据格式错误: $result');
          }

          final int total = result['total'] is int ? result['total'] : 0;
          _hasMore = _sessions.length < total;
        });

        for (var session in _sessions) {
          _loadAvatar(session['cover_uri']);
        }
      }
      _refreshController.refreshCompleted();

      if (_hasMore) {
        _refreshController.loadComplete();
      }
    } catch (e) {
      _refreshController.refreshFailed();
      debugPrint('[CharacterSessionList] 刷新失败: $e');
    }
  }

  Future<void> _onLoading() async {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return;
    }

    try {
      final result = await _messageService.getCharacterSessions(
        page: _currentPage + 1,
        pageSize: 10,
      );

      if (mounted) {
        List<Map<String, dynamic>> newSessions = [];
        if (result['list'] is List) {
          newSessions = List<Map<String, dynamic>>.from(result['list']);
        } else {
          debugPrint('加载更多会话返回数据格式错误: $result');
        }

        if (newSessions.isNotEmpty) {
          setState(() {
            _sessions.addAll(newSessions);
            _currentPage++;
            final int total = (result['total'] is int ? result['total'] : 0);
            _hasMore = _sessions.length < total;
          });

          for (var session in newSessions) {
            _loadAvatar(session['cover_uri']);
          }
        }

        if (_hasMore) {
          _refreshController.loadComplete();
        } else {
          _refreshController.loadNoData();
        }
      }
    } catch (e) {
      _refreshController.loadFailed();
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
        return Container(
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
        return Container(
          height: 55.0,
          child: Center(child: body),
        );
      },
    );

    if (_isLoading && _sessions.isEmpty) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: 10,
        itemBuilder: (context, index) => _buildSkeletonItem(),
      );
    }

    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: true,
      header: customHeader,
      footer: customFooter,
      onRefresh: onRefresh,
      onLoading: _onLoading,
      child: _sessions.isEmpty
          ? _buildEmptyView()
          : ListView.builder(
              key: const PageStorageKey('message_list'),
              itemCount: _sessions.length,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemBuilder: (context, index) {
                try {
                  final session = _sessions[index];
                  return _buildSessionItem(
                    context,
                    session,
                  );
                } catch (e) {
                  debugPrint('构建消息项失败 index=$index: $e');
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
    );
  }

  Widget _buildSkeletonItem() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Shimmer.fromColors(
        baseColor: AppTheme.cardBackground,
        highlightColor: AppTheme.cardBackground.withOpacity(0.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cardBackground,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      color: AppTheme.cardBackground,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: 200.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      color: AppTheme.cardBackground,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40.w,
              height: 12.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.r),
                color: AppTheme.cardBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(
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
      debugPrint('获取会话 ID 失败: $e');
      return SizedBox.shrink();
    }

    final String? coverUri = session['cover_uri'];
    final bool hasAvatar = coverUri != null &&
        coverUri.isNotEmpty &&
        _avatarCache.containsKey(coverUri);
    final bool isSelected = widget.selectedIds.contains(sessionId);

    String sessionName = '';
    try {
      sessionName = session['name'] ?? '未命名会话';
    } catch (e) {
      sessionName = '未命名会话';
    }

    String lastMessage = '';
    try {
      lastMessage = session['last_message'] ?? '开始对话';
    } catch (e) {
      lastMessage = '开始对话';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: GestureDetector(
        onTap: () {
          if (widget.isMultiSelectMode) {
            widget.onSelectionChanged(sessionId);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CharacterChatPage(
                  sessionData: session,
                  characterData: session,
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.isMultiSelectMode) ...[
                Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected ? AppTheme.primaryColor : Colors.white38,
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
              ],
              if (coverUri != null && coverUri.isNotEmpty)
                hasAvatar
                    ? Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.memory(
                            _avatarCache[coverUri]!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildAvatarPlaceholder(sessionName);
                            },
                          ),
                        ),
                      )
                    : FutureBuilder(
                        future: _fileService.getFile(coverUri),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            if (!_avatarCache.containsKey(coverUri)) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  try {
                                    final data = snapshot.data!.data;
                                    if (data is Uint8List) {
                                      setState(() {
                                        _avatarCache[coverUri] = data;
                                      });
                                    } else {
                                      debugPrint(
                                          '头像数据不是Uint8List类型: ${data.runtimeType}');
                                    }
                                  } catch (e) {
                                    debugPrint('缓存头像失败: $e');
                                  }
                                }
                              });
                            }

                            try {
                              final data = snapshot.data!.data;
                              if (data is Uint8List) {
                                return Container(
                                  width: 40.w,
                                  height: 40.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: Image.memory(
                                      data,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return _buildAvatarPlaceholder(
                                            sessionName);
                                      },
                                    ),
                                  ),
                                );
                              } else {
                                debugPrint('头像数据类型错误: ${data.runtimeType}');
                                return _buildAvatarPlaceholder(sessionName);
                              }
                            } catch (e) {
                              debugPrint('渲染头像失败: $e');
                              return _buildAvatarPlaceholder(sessionName);
                            }
                          }
                          return _buildAvatarSkeleton(sessionName);
                        },
                      )
              else
                _buildAvatarSkeleton(sessionName),
              SizedBox(width: 12.w),
              Expanded(
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
                                  sessionName,
                                  style: AppTheme.titleStyle.copyWith(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
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
                          style: AppTheme.hintStyle.copyWith(fontSize: 13.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      lastMessage,
                      style: AppTheme.secondaryStyle.copyWith(fontSize: 14.sp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.cardBackground,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1) : '?',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSkeleton(String? name) {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardBackground,
      highlightColor: AppTheme.cardBackground.withOpacity(0.5),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.cardBackground,
        ),
        child: name != null
            ? Center(
                child: Text(
                  name.substring(0, 1),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48.sp,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            '暂无对话',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '快去探索角色，开始有趣的对话吧',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondary.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}
