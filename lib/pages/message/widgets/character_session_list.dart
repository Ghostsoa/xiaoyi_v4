import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:typed_data';
import 'dart:async';

import '../../../theme/app_theme.dart';
import '../../character_chat/pages/character_chat_page.dart';
import '../message_service.dart';
import '../../../services/file_service.dart';
import '../../../services/session_data_service.dart';
import '../../../widgets/custom_toast.dart';

class CharacterSessionList extends StatefulWidget {
  const CharacterSessionList({
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
  final Function(BuildContext, Map<String, dynamic>, Offset) onShowMenu; // 🔥 添加位置参数
  final VoidCallback? onRefresh; // 刷新回调

  @override
  CharacterSessionListState createState() => CharacterSessionListState();
}

class CharacterSessionListState extends State<CharacterSessionList> {
  final MessageService _messageService = MessageService();
  final FileService _fileService = FileService();
  final SessionDataService _sessionDataService = SessionDataService();
  final RefreshController _refreshController = RefreshController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _sessions = [];
  int _currentPage = 1;
  bool _hasMore = true;
  final Map<String, Uint8List> _avatarCache = {};
  StreamSubscription? _sessionStreamSubscription;

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
    super.dispose();
  }

  /// 初始化会话数据服务
  Future<void> _initSessionDataService() async {
    await _sessionDataService.initDatabase();

    // 🔥 不使用监听器，避免在加载更多时被覆盖
    // 改为手动控制刷新时机
  }

  Future<void> _loadSessions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _sessions = [];
      _currentPage = 1;
    });

    try {
      // 🔥 步骤1: 先从本地缓存快速显示（只读第一页）
      final localResult = await _messageService.getCharacterSessions(
        page: 1,
        pageSize: 10,
      );

      if (mounted && localResult['list'] is List) {
        final localSessions = List<Map<String, dynamic>>.from(localResult['list']);
        setState(() {
          _sessions = localSessions;
          _isLoading = false;
        });

        // 预加载头像
        for (var session in localSessions) {
          _loadAvatar(session['cover_uri']);
        }
      }

      // 🔥 步骤2: 后台异步请求API静默更新
      print('========================================');
      print('[CharacterSessionList] >>> 开始API异步更新第一页...');
      final apiResult = await _messageService.syncCharacterSessionsFromApi(
        page: 1,
        pageSize: 10,
      );

      print('[CharacterSessionList] <<< API更新完成，当前页码: $_currentPage');
      
      if (mounted && _currentPage == 1) { // 🔥 只有还在第一页时才更新
        print('[CharacterSessionList] [✓] 更新第一页数据到UI');
        // 重新从本地读取（包含置顶排序）
        final updatedResult = await _messageService.getCharacterSessions(
          page: 1,
          pageSize: 10,
        );

        if (updatedResult['list'] is List) {
          final updatedSessions = List<Map<String, dynamic>>.from(updatedResult['list']);
          final int total = apiResult['total'] is int ? apiResult['total'] : 0;
          
          setState(() {
            _sessions = updatedSessions;
            _hasMore = total > 10;
          });

          // 预加载新头像
          for (var session in updatedSessions) {
            _loadAvatar(session['cover_uri']);
          }
        }
      } else if (mounted) {
        // 如果已经加载了更多页，只更新 _hasMore 状态
        print('[CharacterSessionList] [!] 第一页API更新完成，但当前已在第$_currentPage页，跳过UI更新');
        final int total = apiResult['total'] is int ? apiResult['total'] : 0;
        setState(() {
          _hasMore = _currentPage * 10 < total;
        });
      }
      print('========================================');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_sessions.isEmpty) {
            debugPrint('加载会话列表失败: $e');
          }
        });
      }
    }
  }

  Future<void> onRefresh() async {
    _currentPage = 1;
    try {
      // 🔥 直接从API同步第一页数据
      final apiResult = await _messageService.syncCharacterSessionsFromApi(
        page: 1,
        pageSize: 10,
      );

      // 从本地读取（包含置顶排序）
      final result = await _messageService.getCharacterSessions(
        page: 1,
        pageSize: 10,
      );

      if (mounted) {
        if (result['list'] is List) {
          final int total = apiResult['total'] is int ? apiResult['total'] : 0;
          
          setState(() {
            _sessions = List<Map<String, dynamic>>.from(result['list']);
            _hasMore = total > 10;
          });

          for (var session in _sessions) {
            _loadAvatar(session['cover_uri']);
          }
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
      final nextPage = _currentPage + 1;

      print('========================================');
      print('[CharacterSessionList] >>> 加载更多：第$nextPage页');

      // 🔥 直接从API请求数据（不走本地缓存，不同步到本地数据库）
      final apiResult = await _messageService.syncCharacterSessionsFromApi(
        page: nextPage,
        pageSize: 10,
        syncToLocal: false, // 🔥 第二页及以后不同步到本地
      );

      if (mounted && apiResult['list'] is List) {
        // 🔥 直接使用API返回的数据，不要从本地数据库读取（避免排序不一致）
        final apiSessions = (apiResult['list'] as List).cast<Map<String, dynamic>>();
        
        // 🔥 获取当前已有的所有会话ID（包括置顶的）
        final existingIds = _sessions.map((s) => s['id'] as int).toSet();

        print('[CharacterSessionList] 当前已有ID: $existingIds');
        print('[CharacterSessionList] API返回ID: ${apiSessions.map((s) => s['id']).toList()}');

        // 🔥 过滤掉已存在的会话（避免置顶会话重复）
        final newSessions = apiSessions
            .where((session) => !existingIds.contains(session['id'] as int))
            .toList();

        final int total = apiResult['total'] is int ? apiResult['total'] : 0;

        print('[CharacterSessionList] API返回${apiSessions.length}条，去重后${newSessions.length}条');

        if (newSessions.isNotEmpty) {
          final oldLength = _sessions.length;
          setState(() {
            _sessions.addAll(newSessions);
            _currentPage = nextPage;
            _hasMore = _currentPage * 10 < total;
          });

          print('[CharacterSessionList] [SUCCESS] 数据累加：从$oldLength条增加到${_sessions.length}条');
          print('[CharacterSessionList] [STATE] page=$_currentPage, total=$total, hasMore=$_hasMore');

          for (var session in newSessions) {
            _loadAvatar(session['cover_uri']);
          }

          _refreshController.loadComplete();
        } else {
          // 去重后没有新数据，可能都是置顶的，尝试加载下一页
          print('[CharacterSessionList] [WARNING] 去重后无新数据，尝试继续...');
          setState(() {
            _currentPage = nextPage;
            _hasMore = nextPage * 10 < total;
          });

          if (_hasMore) {
            _refreshController.loadComplete();
            // 递归加载下一页
            await _onLoading();
          } else {
            _refreshController.loadNoData();
          }
        }
        
        print('========================================');
      } else {
        _refreshController.loadComplete();
      }
    } catch (e) {
      print('[CharacterSessionList] [ERROR] 加载失败: $e');
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
      padding: EdgeInsets.symmetric(vertical: 6.h),
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

    // 解析会话名称，分离调试版前缀
    final parsedName = _parseSessionName(sessionName);
    final bool isDebugVersion = parsedName['prefix']!.isNotEmpty;
    final String displayName = parsedName['name']!;

    String lastMessage = '';
    try {
      lastMessage = session['last_message'] ?? '开始对话';
    } catch (e) {
      lastMessage = '开始对话';
    }

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
                _showRenameDialog(sessionId, session['name'] ?? '未命名会话');
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CharacterChatPage(
                    sessionData: session,
                    characterData: session,
                  ),
                ),
              ).then((result) {
                // 如果返回值为 true，说明需要刷新列表
                if (result == true) {
                  widget.onRefresh?.call();
                }
              });
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
                                  displayName,
                                  style: AppTheme.titleStyle.copyWith(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
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

  /// 置顶会话
  Future<void> _pinSession(int sessionId) async {
    try {
      final MessageService messageService = MessageService();
      await messageService.pinCharacterSession(sessionId);

      if (mounted) {
        // 静默更新本地数据
        setState(() {
          final index = _sessions.indexWhere((s) => s['id'] == sessionId);
          if (index != -1) {
            _sessions[index]['is_pinned'] = 1;
          }
        });
      }
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

  /// 取消置顶会话
  Future<void> _unpinSession(int sessionId) async {
    try {
      final MessageService messageService = MessageService();
      await messageService.unpinCharacterSession(sessionId);

      if (mounted) {
        // 静默更新本地数据
        setState(() {
          final index = _sessions.indexWhere((s) => s['id'] == sessionId);
          if (index != -1) {
            _sessions[index]['is_pinned'] = 0;
          }
        });
      }
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
          title: Text('重命名会话'),
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
      final result = await _messageService.renameSession(sessionId, newName);

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
          content: Text('确定要删除这个会话吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('删除', style: TextStyle(color: Colors.red)),
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
      final Map<String, dynamic> result = await _messageService.batchDeleteCharacterSessions([sessionId]);

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
