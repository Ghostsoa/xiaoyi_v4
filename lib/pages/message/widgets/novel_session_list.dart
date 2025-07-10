import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';

import '../../../theme/app_theme.dart';
import '../../novel/pages/novel_reading_page.dart';
import '../message_service.dart';
import '../../../services/file_service.dart';

class NovelSessionList extends StatefulWidget {
  const NovelSessionList({
    Key? key,
    required this.isMultiSelectMode,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.onShowMenu,
  }) : super(key: key);

  final bool isMultiSelectMode;
  final Set<int> selectedIds;
  final ValueChanged<int> onSelectionChanged;
  final Function(BuildContext, Map<String, dynamic>) onShowMenu;

  @override
  NovelSessionListState createState() => NovelSessionListState();
}

class NovelSessionListState extends State<NovelSessionList> {
  final MessageService _messageService = MessageService();
  final FileService _fileService = FileService();
  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _sessions = [];
  int _currentPage = 1;
  bool _hasMore = true;
  final Map<String, Uint8List> _avatarCache = {};
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSessions();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      final result = await _messageService.getNovelSessions(
        page: _currentPage,
        pageSize: 10,
      );

      if (mounted) {
        setState(() {
          if (result['sessions'] is List) {
            _sessions = List<Map<String, dynamic>>.from(result['sessions']);
          } else {
            _sessions = [];
            debugPrint('获取小说会话列表返回数据格式错误: $result');
          }

          final int total = result['total'] is int ? result['total'] : 0;
          _hasMore = _sessions.length < total;
          _isLoading = false;
        });

        for (var session in _sessions) {
          _loadAvatar(session['cover_uri']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _sessions = [];
        });
        debugPrint('加载小说会话列表失败: $e');
      }
    }
  }

  Future<void> _loadMoreSessions() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await _messageService.getNovelSessions(
        page: _currentPage + 1,
        pageSize: 10,
      );

      if (mounted) {
        List<Map<String, dynamic>> newSessions = [];
        if (result['sessions'] is List) {
          newSessions = List<Map<String, dynamic>>.from(result['sessions']);
        } else {
          debugPrint('加载更多小说会话返回数据格式错误: $result');
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
        debugPrint('加载更多小说会话失败: $e');
      }
    }
  }

  Future<void> onRefresh() async {
    _currentPage = 1;
    try {
      final result = await _messageService.getNovelSessions(
        page: _currentPage,
        pageSize: 10,
      );

      if (mounted) {
        setState(() {
          if (result['sessions'] is List) {
            _sessions = List<Map<String, dynamic>>.from(result['sessions']);
          } else {
            _sessions = [];
            debugPrint('刷新小说会话列表返回数据格式错误: $result');
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
    }
  }

  Future<void> _onLoading() async {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return;
    }

    try {
      final result = await _messageService.getNovelSessions(
        page: _currentPage + 1,
        pageSize: 10,
      );

      if (mounted) {
        List<Map<String, dynamic>> newSessions = [];
        if (result['sessions'] is List) {
          newSessions = List<Map<String, dynamic>>.from(result['sessions']);
        } else {
          debugPrint('加载更多小说会话返回数据格式错误: $result');
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
        itemBuilder: (context, index) => _buildNovelSkeletonItem(),
      );
    }

    return _sessions.isEmpty
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
              controller: _scrollController,
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

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: InkWell(
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
        onLongPress: widget.isMultiSelectMode
            ? null
            : () {
                widget.onShowMenu(context, session);
              },
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        splashColor: Colors.transparent,
        highlightColor: Colors.white.withOpacity(0.05),
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
                          child: Text(
                            title,
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
    );
  }

  Widget _buildNovelSkeletonItem() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
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
}
