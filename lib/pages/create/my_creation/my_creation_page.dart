import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:typed_data';
import 'dart:async';
import '../../../theme/app_theme.dart';
import '../services/characte_service.dart';
import '../services/novel_service.dart';
import '../../../services/file_service.dart';
import '../services/group_chat_service.dart';
import '../../../widgets/custom_toast.dart';
import '../../../widgets/confirmation_dialog.dart';
import '../character/create_character_page.dart';
import '../novel/create_novel_page.dart';
import '../group_chat/create_group_chat_page.dart';
import '../../../pages/character_chat/pages/character_init_page.dart';
import '../../../pages/novel/pages/novel_init_page.dart';
import '../../../pages/group_chat/pages/group_chat_init_page.dart';

class MyCreationPage extends StatefulWidget {
  const MyCreationPage({super.key});

  @override
  State<MyCreationPage> createState() => _MyCreationPageState();
}

class _MyCreationPageState extends State<MyCreationPage> {
  int _selectedIndex = 0; // 0: 角色卡, 1: 小说, 2: 群聊
  String _status = 'published'; // published: 公开, private: 私密
  final _characterService = CharacterService();
  final _novelService = NovelService();
  final _groupChatService = GroupChatService();
  final ScrollController _scrollController = ScrollController();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final Map<String, Uint8List> _imageCache = {}; // 图片缓存
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _characterList = [];
  List<Map<String, dynamic>> _novelList = [];
  List<Map<String, dynamic>> _groupChatList = [];
  int _total = 0;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMoreData = true;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _refreshController.dispose();
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMoreData = true;
    });

    if (_selectedIndex == 0) {
      await _loadCharacterData();
    } else if (_selectedIndex == 1) {
      await _loadNovelData();
    } else {
      await _loadGroupChatData();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadCharacterData() async {
    try {
      final response = await _characterService.getCharacterList(
        page: _currentPage,
        pageSize: _pageSize,
        status: _status,
        keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
      );

      if (response['code'] == 0) {
        setState(() {
          _characterList =
              List<Map<String, dynamic>>.from(response['data']['items']);
          _total = response['data']['total'];
          _hasMoreData = _characterList.length < _total;
        });

        // 预加载图片
        _preloadImages(_characterList);
      } else {
        _showToast('加载失败：${response['message']}', type: ToastType.error);
      }
    } catch (e) {
      _showToast('加载失败：$e', type: ToastType.error);
    }
  }

  Future<void> _loadNovelData() async {
    try {
      final response = await _novelService.getUserNovels(
        page: _currentPage,
        pageSize: _pageSize,
        status: _status,
        keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
      );

      if (response['code'] == 0) {
        setState(() {
          _novelList =
              List<Map<String, dynamic>>.from(response['data']['novels'] ?? []);
          _total = response['data']['total'] ?? 0;
          _hasMoreData = _novelList.length < _total;
        });

        // 预加载图片
        _preloadImages(_novelList);
      } else {
        _showToast('加载失败：${response['message']}', type: ToastType.error);
      }
    } catch (e) {
      _showToast('加载失败：$e', type: ToastType.error);
    }
  }

  Future<void> _loadGroupChatData() async {
    try {
      final response = await _groupChatService.getGroupChatList(
        page: _currentPage,
        pageSize: _pageSize,
        status: _status,
        keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
      );

      if (response['code'] == 0) {
        setState(() {
          _groupChatList =
              List<Map<String, dynamic>>.from(response['data']['items'] ?? []);
          _total = response['data']['total'] ?? 0;
          _hasMoreData = _groupChatList.length < _total;
        });

        // 预加载图片
        _preloadImages(_groupChatList);
      } else {
        _showToast('加载失败：${response['message']}', type: ToastType.error);
      }
    } catch (e) {
      _showToast('加载失败：$e', type: ToastType.error);
    }
  }

  // 预加载图片到缓存
  Future<void> _preloadImages(List<Map<String, dynamic>> items) async {
    for (final item in items) {
      if (item['coverUri'] != null &&
          !_imageCache.containsKey(item['coverUri'])) {
        try {
          final fileData = await FileService().getFile(item['coverUri']);
          if (fileData.data != null) {
            _imageCache[item['coverUri']] = fileData.data;
          }
        } catch (e) {
          // 忽略加载失败的图片
        }
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (!_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    if (_selectedIndex == 0) {
      await _loadMoreCharacterData();
    } else if (_selectedIndex == 1) {
      await _loadMoreNovelData();
    } else {
      await _loadMoreGroupChatData();
    }

    setState(() => _isLoadingMore = false);
  }

  Future<void> _loadMoreCharacterData() async {
    try {
      final response = await _characterService.getCharacterList(
        page: _currentPage + 1,
        pageSize: _pageSize,
        status: _status,
        keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
      );

      if (response['code'] == 0) {
        final newItems =
            List<Map<String, dynamic>>.from(response['data']['items']);

        if (newItems.isNotEmpty) {
          setState(() {
            _characterList.addAll(newItems);
            _currentPage += 1;
            _hasMoreData = _characterList.length < _total;
          });

          // 预加载新加载的图片
          _preloadImages(newItems);
        } else {
          setState(() => _hasMoreData = false);
        }
      } else {
        _showToast('加载更多失败：${response['message']}', type: ToastType.error);
      }
    } catch (e) {
      _showToast('加载更多失败：$e', type: ToastType.error);
    }
  }

  Future<void> _loadMoreNovelData() async {
    try {
      final response = await _novelService.getUserNovels(
        page: _currentPage + 1,
        pageSize: _pageSize,
        status: _status,
        keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
      );

      if (response['code'] == 0) {
        final newItems =
            List<Map<String, dynamic>>.from(response['data']['novels'] ?? []);

        if (newItems.isNotEmpty) {
          setState(() {
            _novelList.addAll(newItems);
            _currentPage += 1;
            _hasMoreData = _novelList.length < _total;
          });

          // 预加载新加载的图片
          _preloadImages(newItems);
        } else {
          setState(() => _hasMoreData = false);
        }
      } else {
        _showToast('加载更多失败：${response['message']}', type: ToastType.error);
      }
    } catch (e) {
      _showToast('加载更多失败：$e', type: ToastType.error);
    }
  }

  Future<void> _loadMoreGroupChatData() async {
    try {
      final response = await _groupChatService.getGroupChatList(
        page: _currentPage + 1,
        pageSize: _pageSize,
        status: _status,
        keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
      );

      if (response['code'] == 0) {
        final newItems =
            List<Map<String, dynamic>>.from(response['data']['items'] ?? []);

        if (newItems.isNotEmpty) {
          setState(() {
            _groupChatList.addAll(newItems);
            _currentPage += 1;
            _hasMoreData = _groupChatList.length < _total;
          });

          // 预加载新加载的图片
          _preloadImages(newItems);
        } else {
          setState(() => _hasMoreData = false);
        }
      } else {
        _showToast('加载更多失败：${response['message']}', type: ToastType.error);
      }
    } catch (e) {
      _showToast('加载更多失败：$e', type: ToastType.error);
    }
  }

  /// 黑盒调试功能
  void _showBlackBoxDebug(Map<String, dynamic> item) {
    // 支持角色卡和群聊调试
    if (item.containsKey('name') && _selectedIndex == 0) {
      // 角色卡调试
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CharacterInitPage(
            characterData: {
              'id': item['id'],
              'item_id': item['id'],
              'cover_uri': item['coverUri'],
              'init_fields': item['initFields'],
            },
            isDebug: true,
          ),
        ),
      );
    } else if (_selectedIndex == 2) {
      // 群聊调试
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupChatInitPage(
            groupChatData: item,
            isDebug: true,
          ),
        ),
      );
    } else {
      _showToast('当前仅支持角色卡和群聊调试', type: ToastType.info);
    }
  }

  void _showToast(String message, {ToastType type = ToastType.info}) {
    if (!mounted) return;
    CustomToast.show(context, message: message, type: type);
  }

  // 搜索处理方法
  void _onSearchChanged(String value) {
    // 取消之前的定时器
    _searchDebounceTimer?.cancel();

    // 设置新的定时器，500ms后执行搜索
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _searchKeyword != value) {
        setState(() {
          _searchKeyword = value;
        });
        _loadData();
      }
    });
  }

  // 清空搜索
  void _clearSearch() {
    _searchController.clear();
    if (_searchKeyword.isNotEmpty) {
      setState(() {
        _searchKeyword = '';
      });
      _loadData();
    }
  }

  // 下拉刷新 - 静默更新数据
  void _onRefresh() async {
    try {
      // 重置分页状态
      _currentPage = 1;
      _hasMoreData = true;

      // 静默加载数据，不显示loading状态
      if (_selectedIndex == 0) {
        final response = await _characterService.getCharacterList(
          page: _currentPage,
          pageSize: _pageSize,
          status: _status,
          keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
        );

        if (response['code'] == 0) {
          if (mounted) {
            setState(() {
              _characterList = List<Map<String, dynamic>>.from(response['data']['items']);
              _total = response['data']['total'];
              _hasMoreData = _characterList.length < _total;
            });
            // 预加载图片
            _preloadImages(_characterList);
          }
        }
      } else if (_selectedIndex == 1) {
        final response = await _novelService.getUserNovels(
          page: _currentPage,
          pageSize: _pageSize,
          status: _status,
          keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
        );

        if (response['code'] == 0) {
          if (mounted) {
            setState(() {
              _novelList = List<Map<String, dynamic>>.from(response['data']['novels'] ?? []);
              _total = response['data']['total'] ?? 0;
              _hasMoreData = _novelList.length < _total;
            });
          }
        }
      } else {
        final response = await _groupChatService.getGroupChatList(
          page: _currentPage,
          pageSize: _pageSize,
          status: _status,
          keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
        );

        if (response['code'] == 0) {
          if (mounted) {
            setState(() {
              _groupChatList = List<Map<String, dynamic>>.from(response['data']['items'] ?? []);
              _total = response['data']['total'] ?? 0;
              _hasMoreData = _groupChatList.length < _total;
            });
            // 预加载图片
            _preloadImages(_groupChatList);
          }
        }
      }

      if (mounted) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      if (mounted) {
        _refreshController.refreshFailed();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary;
    final background = AppTheme.background;
    final primaryColor = AppTheme.primaryColor;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题栏
            Container(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 8.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: textPrimary,
                        size: 18.sp,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '我的创建',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 32.w),
                ],
              ),
            ),

            // 切换按钮和状态过滤
            Container(
              margin: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧类型切换
                  Row(
                    children: [
                      _buildSwitchButton('角色卡', 0, primaryColor, textPrimary),
                      SizedBox(width: 24.w),
                      _buildSwitchButton('小说', 1, primaryColor, textPrimary),
                      SizedBox(width: 24.w),
                      _buildSwitchButton('群聊', 2, primaryColor, textPrimary),
                    ],
                  ),

                  // 右侧状态过滤
                  Row(
                    children: [
                      _buildStatusButton(
                          '公开', 'published', primaryColor, textPrimary),
                      SizedBox(width: 16.w),
                      _buildStatusButton(
                          '私密', 'private', primaryColor, textPrimary),
                    ],
                  ),
                ],
              ),
            ),

            // 搜索框
            _buildSearchBox(),

            // 内容区域
            Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _onRefresh,
                enablePullDown: true,
                enablePullUp: false, // 禁用SmartRefresher的上拉加载，使用自定义滚动监听
                header: CustomHeader(
                  builder: (BuildContext context, RefreshStatus? mode) {
                    Widget body;
                    if (mode == RefreshStatus.idle) {
                      body = Text('下拉刷新',
                          style: TextStyle(color: Colors.grey, fontSize: 14.sp));
                    } else if (mode == RefreshStatus.refreshing) {
                      body = Text('加载中...',
                          style: TextStyle(color: Colors.grey, fontSize: 14.sp)); // 显示加载中
                    } else if (mode == RefreshStatus.failed) {
                      body = Text('刷新失败',
                          style: TextStyle(color: Colors.red, fontSize: 14.sp));
                    } else if (mode == RefreshStatus.canRefresh) {
                      body = Text('松开刷新',
                          style: TextStyle(color: Colors.grey, fontSize: 14.sp));
                    } else {
                      body = Text('刷新完成',
                          style: TextStyle(color: Colors.green, fontSize: 14.sp));
                    }
                    return SizedBox(
                      height: 55.h,
                      child: Center(child: body),
                    );
                  },
                ),
                child: _isLoading
                    ? _buildSkeletonList()
                    : _selectedIndex == 0
                        ? _buildCharacterList()
                        : _selectedIndex == 1
                            ? _buildNovelList()
                            : _buildGroupChatList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchButton(
      String text, int index, Color primaryColor, Color textPrimary) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        _loadData();
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? primaryColor : textPrimary.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildStatusButton(
      String text, String status, Color primaryColor, Color textPrimary) {
    final isSelected = _status == status;
    return GestureDetector(
      onTap: () {
        setState(() => _status = status);
        _loadData();
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? primaryColor : textPrimary.withOpacity(0.5),
        ),
      ),
    );
  }

  // 构建搜索框
  Widget _buildSearchBox() {
    return Container(
      margin: EdgeInsets.fromLTRB(24.w, 0, 24.w, 16.h),
      child: Container(
        height: 40.h,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppTheme.border.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            _onSearchChanged(value);
            // 触发重建以更新清除按钮显示状态
            setState(() {});
          },
          style: TextStyle(
            fontSize: 14.sp,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '搜索标题、简介、关键词...',
            hintStyle: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondary.withOpacity(0.6),
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 20.sp,
              color: AppTheme.textSecondary.withOpacity(0.6),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: _clearSearch,
                    child: Icon(
                      Icons.clear,
                      size: 20.sp,
                      color: AppTheme.textSecondary.withOpacity(0.6),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 10.h,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterList() {
    if (_characterList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 48.sp,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              '暂无角色卡',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      itemCount: _characterList.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        // 显示加载更多的指示器
        if (index == _characterList.length) {
          return _buildCustomLoadMoreIndicator();
        }

        final character = _characterList[index];
        return Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppTheme.border.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 封面图片
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: character['coverUri'] != null
                        ? _buildCachedImage(character['coverUri'])
                        : Container(
                            width: 96.h,
                            height: 96.h,
                            color: AppTheme.cardBackground,
                            child: Icon(
                              Icons.image_outlined,
                              color: AppTheme.textSecondary.withOpacity(0.5),
                            ),
                          ),
                  ),

                  SizedBox(width: 12.w),

                  // 内容区域
                  Expanded(
                    child: SizedBox(
                      height: 96.h,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 角色名称
                          Text(
                            character['name'] ?? '',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),

                          // 第二行：简介
                          Expanded(
                            child: Text(
                              character['description'] ?? '',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppTheme.textPrimary.withOpacity(0.8),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // 第三行：标签
                          if (character['tags'] != null &&
                              (character['tags'] as List).isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              (character['tags'] as List)
                                  .map((tag) => '#$tag')
                                  .join(' '),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          SizedBox(height: 2.h),
                          // 第四行：作者和时间
                          Text(
                            '@${character['authorName'] ?? ''} · ${_formatTime(character['createdAt'])}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 底部按钮行
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 状态切换按钮
                  GestureDetector(
                    onTap: () {
                      _showStatusChangeDialog(character);
                    },
                    child: Row(
                      children: [
                        Icon(
                          character['status'] == 'published'
                              ? Icons.public
                              : Icons.lock_outline,
                          size: 18.sp,
                          color: const Color(0xFF666666),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          character['status'] == 'published' ? '公开' : '私密',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 编辑按钮
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateCharacterPage(
                            character: character,
                            isEdit: true,
                          ),
                        ),
                      ).then((result) {
                        // 如果返回的结果为true，表示编辑成功，刷新列表
                        if (result == true) {
                          _loadData();
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18.sp,
                          color: const Color(0xFF666666),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '编辑',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 聊天按钮
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CharacterInitPage(
                            characterData: {
                              'id': character['id'],
                              'item_id': character['id'],
                              'cover_uri': character['coverUri'],
                              'init_fields': character['initFields'],
                            },
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_outlined,
                          size: 18.sp,
                          color: const Color(0xFF666666),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '聊天',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 黑盒调试按钮
                  GestureDetector(
                    onTap: () {
                      _showBlackBoxDebug(character);
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.bug_report_outlined,
                          size: 18.sp,
                          color: const Color(0xFF9C27B0),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '调试',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9C27B0),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 删除按钮
                  GestureDetector(
                    onTap: () {
                      _showDeleteConfirmDialog(character);
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18.sp,
                          color: const Color(0xFFFF5252),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '删除',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFFF5252),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建缓存图片组件
  Widget _buildCachedImage(String uri) {
    // 如果图片已经在缓存中
    if (_imageCache.containsKey(uri)) {
      return Image.memory(
        _imageCache[uri]!,
        width: 96.h,
        height: 96.h,
        fit: BoxFit.cover,
      );
    }

    // 图片不在缓存中，需要加载
    return FutureBuilder(
      future: () async {
        try {
          final fileData = await FileService().getFile(uri);
          if (fileData.data != null) {
            // 添加到缓存
            _imageCache[uri] = fileData.data;
            return fileData;
          }
        } catch (e) {
          // 加载失败
        }
        return null;
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerImage();
        }
        if (!snapshot.hasData || snapshot.hasError) {
          return Container(
            width: 96.h,
            height: 96.h,
            color: AppTheme.cardBackground,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
          );
        }
        return Image.memory(
          snapshot.data!.data,
          width: 96.h,
          height: 96.h,
          fit: BoxFit.cover,
        );
      },
    );
  }

  // 自定义加载更多指示器 - 纯文本
  Widget _buildCustomLoadMoreIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      alignment: Alignment.center,
      child: Text(
        _isLoadingMore
            ? '加载中...'
            : _hasMoreData
                ? '上滑加载更多'
                : '没有更多数据了',
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey, // 使用固定灰色，与下拉刷新保持一致
        ),
      ),
    );
  }

  Widget _buildShimmerImage() {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardBackground,
      highlightColor: AppTheme.cardBackground.withOpacity(0.2),
      child: Container(
        width: 96.h,
        height: 96.h,
        color: AppTheme.cardBackground,
      ),
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final time = DateTime.parse(timeStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}年前';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}月前';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildNovelList() {
    if (_novelList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 48.sp,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              '暂无小说',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      itemCount: _novelList.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        // 显示加载更多的指示器
        if (index == _novelList.length) {
          return _buildCustomLoadMoreIndicator();
        }

        final novel = _novelList[index];
        return Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppTheme.border.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 封面图片
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: novel['coverUri'] != null
                        ? _buildCachedImage(novel['coverUri'])
                        : Container(
                            width: 96.h,
                            height: 96.h,
                            color: AppTheme.cardBackground,
                            child: Icon(
                              Icons.image_outlined,
                              color: AppTheme.textSecondary.withOpacity(0.5),
                            ),
                          ),
                  ),

                  SizedBox(width: 12.w),

                  // 内容区域
                  Expanded(
                    child: SizedBox(
                      height: 96.h,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 小说标题
                          Text(
                            novel['title'] ?? '',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),

                          // 第二行：简介
                          Expanded(
                            child: Text(
                              novel['description'] ?? '',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppTheme.textPrimary.withOpacity(0.8),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // 第三行：标签
                          if (novel['tags'] != null &&
                              (novel['tags'] as List).isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              (novel['tags'] as List)
                                  .map((tag) => '#$tag')
                                  .join(' '),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          SizedBox(height: 2.h),
                          // 第四行：作者和时间
                          Text(
                            '@${novel['authorName'] ?? ''} · ${_formatTime(novel['createdAt'])}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 底部按钮行 (小说)
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 状态切换按钮
                  GestureDetector(
                    onTap: () {
                      _showNovelStatusChangeDialog(novel);
                    },
                    child: Row(
                      children: [
                        Icon(
                          novel['status'] == 'published'
                              ? Icons.public
                              : Icons.lock_outline,
                          size: 18.sp,
                          color: const Color(0xFF666666),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          novel['status'] == 'published' ? '公开' : '私密',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 编辑按钮
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateNovelPage(
                            novel: novel,
                            isEdit: true,
                          ),
                        ),
                      ).then((result) {
                        if (result == true) {
                          _loadData();
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18.sp,
                          color: const Color(0xFF666666),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '编辑',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 聊天按钮(阅读小说)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NovelInitPage(
                            novelData: {
                              'id': novel['id'],
                              'item_id': novel['id'],
                              'cover_uri': novel['coverUri'],
                              'title': novel['title'],
                              'description': novel['description'],
                              'author_name': novel['authorName'],
                            },
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 18.sp,
                          color: const Color(0xFF666666),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '对话',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 黑盒调试按钮
                  GestureDetector(
                    onTap: () {
                      _showBlackBoxDebug(novel);
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.bug_report_outlined,
                          size: 18.sp,
                          color: const Color(0xFF9C27B0),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '调试',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9C27B0),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 删除按钮
                  GestureDetector(
                    onTap: () {
                      _showDeleteNovelConfirmDialog(novel);
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18.sp,
                          color: const Color(0xFFFF5252),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '删除',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFFF5252),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppTheme.cardBackground.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面图片骨架
              Shimmer.fromColors(
                baseColor: AppTheme.cardBackground,
                highlightColor: AppTheme.cardBackground.withOpacity(0.2),
                child: Container(
                  width: 96.h,
                  height: 96.h,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // 内容区域骨架
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题和按钮行
                    Row(
                      children: [
                        Expanded(
                          child: Shimmer.fromColors(
                            baseColor: AppTheme.cardBackground,
                            highlightColor:
                                AppTheme.cardBackground.withOpacity(0.2),
                            child: Container(
                              height: 20.h,
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // 按钮骨架
                        Row(
                          children: [
                            Shimmer.fromColors(
                              baseColor: AppTheme.cardBackground,
                              highlightColor:
                                  AppTheme.cardBackground.withOpacity(0.2),
                              child: Container(
                                width: 24.w,
                                height: 24.w,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Shimmer.fromColors(
                              baseColor: AppTheme.cardBackground,
                              highlightColor:
                                  AppTheme.cardBackground.withOpacity(0.2),
                              child: Container(
                                width: 24.w,
                                height: 24.w,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Shimmer.fromColors(
                              baseColor: AppTheme.cardBackground,
                              highlightColor:
                                  AppTheme.cardBackground.withOpacity(0.2),
                              child: Container(
                                width: 24.w,
                                height: 24.w,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    // 简介骨架
                    Column(
                      children: [
                        Shimmer.fromColors(
                          baseColor: AppTheme.cardBackground,
                          highlightColor:
                              AppTheme.cardBackground.withOpacity(0.2),
                          child: Container(
                            height: 16.h,
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Shimmer.fromColors(
                          baseColor: AppTheme.cardBackground,
                          highlightColor:
                              AppTheme.cardBackground.withOpacity(0.2),
                          child: Container(
                            height: 16.h,
                            width: 200.w,
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    // 标签骨架
                    Shimmer.fromColors(
                      baseColor: AppTheme.cardBackground,
                      highlightColor: AppTheme.cardBackground.withOpacity(0.2),
                      child: Container(
                        height: 14.h,
                        width: 150.w,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // 作者和时间骨架
                    Shimmer.fromColors(
                      baseColor: AppTheme.cardBackground,
                      highlightColor: AppTheme.cardBackground.withOpacity(0.2),
                      child: Container(
                        height: 12.h,
                        width: 120.w,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmDialog(Map<String, dynamic> character) async {
    final bool? confirmed = await ConfirmationDialog.show(
      context: context,
      title: '确认删除',
      content: '确定要删除角色"${character['name']}"吗？此操作不可恢复。',
      confirmText: '删除',
      cancelText: '取消',
      isDangerous: true,
    );

    if (confirmed == true) {
      await _deleteCharacter(character['id'].toString());
    }
  }

  Future<void> _deleteCharacter(String id) async {
    setState(() => _isLoading = true);

    try {
      final response = await _characterService.deleteCharacter(id);
      if (response['code'] == 0) {
        _showToast('删除成功', type: ToastType.success);
        _loadData(); // 重新加载列表
      } else {
        _showToast('删除失败: ${response['message']}', type: ToastType.error);
      }
    } catch (e) {
      _showToast('删除失败: $e', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showDeleteNovelConfirmDialog(Map<String, dynamic> novel) async {
    final bool? confirmed = await ConfirmationDialog.show(
      context: context,
      title: '确认删除',
      content: '确定要删除小说"${novel['title']}"吗？此操作不可恢复。',
      confirmText: '删除',
      cancelText: '取消',
      isDangerous: true,
    );

    if (confirmed == true) {
      await _deleteNovel(novel['id'].toString());
    }
  }

  Future<void> _deleteNovel(String id) async {
    setState(() => _isLoading = true);

    try {
      final response = await _novelService.deleteNovel(id);
      if (response['code'] == 0) {
        _showToast('删除成功', type: ToastType.success);
        _loadData(); // 重新加载列表
      } else {
        _showToast('删除失败: ${response['message']}', type: ToastType.error);
      }
    } catch (e) {
      _showToast('删除失败: $e', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 添加切换状态对话框
  Future<void> _showStatusChangeDialog(Map<String, dynamic> character) async {
    final currentStatus = character['status'] ?? 'published';
    final newStatus = currentStatus == 'published' ? 'private' : 'published';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('修改状态'),
          content: Text(
              '确定要将角色"${character['name']}"的状态从${currentStatus == 'published' ? '公开' : '私密'}切换为${newStatus == 'published' ? '公开' : '私密'}吗？'),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确定'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateCharacterStatus(
                    character['id'].toString(), newStatus);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateCharacterStatus(String id, String status) async {
    setState(() => _isLoading = true);

    try {
      final response =
          await _characterService.updateCharacterStatus(id, status);
      if (response['code'] == 0) {
        _showToast('状态更新成功', type: ToastType.success);
        _loadData(); // 重新加载列表
      } else {
        _showToast('状态更新失败: ${response['message']}', type: ToastType.error);
      }
    } catch (e) {
      _showToast('状态更新失败: $e', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 添加切换小说状态对话框
  Future<void> _showNovelStatusChangeDialog(Map<String, dynamic> novel) async {
    final currentStatus = novel['status'] ?? 'published';
    final newStatus = currentStatus == 'published' ? 'private' : 'published';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('修改状态'),
          content: Text(
              '确定要将小说"${novel['title']}"的状态从${currentStatus == 'published' ? '公开' : '私密'}切换为${newStatus == 'published' ? '公开' : '私密'}吗？'),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确定'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateNovelStatus(novel['id'].toString(), newStatus);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateNovelStatus(String id, String status) async {
    setState(() => _isLoading = true);

    try {
      final response = await _novelService.updateNovelStatus(id, status);
      if (response['code'] == 0) {
        _showToast('状态更新成功', type: ToastType.success);
        _loadData(); // 重新加载列表
      } else {
        _showToast('状态更新失败: ${response['message']}', type: ToastType.error);
      }
    } catch (e) {
      _showToast('状态更新失败: $e', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildGroupChatList() {
    if (_groupChatList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 48.sp,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              '暂无群聊',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      itemCount: _groupChatList.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        // 显示加载更多的指示器
        if (index == _groupChatList.length) {
          return _buildCustomLoadMoreIndicator();
        }

        final groupChat = _groupChatList[index];
        return Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppTheme.border.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 封面图片
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: groupChat['coverUri'] != null
                        ? _buildCachedImage(groupChat['coverUri'])
                        : Container(
                            width: 96.h,
                            height: 96.h,
                            color: AppTheme.cardBackground,
                            child: Icon(
                              Icons.group_outlined,
                              color: AppTheme.textSecondary.withOpacity(0.5),
                            ),
                          ),
                  ),

                  SizedBox(width: 12.w),

                  // 内容区域
                  Expanded(
                    child: SizedBox(
                      height: 96.h,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 群聊名称
                          Text(
                            groupChat['name'] ?? '未命名群聊',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),

                          // 第二行：简介
                          Expanded(
                            child: Text(
                              groupChat['description'] ?? '',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppTheme.textPrimary.withOpacity(0.8),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // 第三行：标签
                          if (groupChat['tags'] != null &&
                              (groupChat['tags'] as List).isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              (groupChat['tags'] as List)
                                  .map((tag) => '#$tag')
                                  .join(' '),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          SizedBox(height: 2.h),
                          // 第四行：作者和时间
                          Text(
                            '@${groupChat['authorName'] ?? ''} · ${_formatTime(groupChat['createdAt'])}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 底部按钮行
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 状态切换按钮
                  GestureDetector(
                    onTap: () {
                      _toggleGroupChatStatus(groupChat);
                    },
                    child: Row(
                      children: [
                        Icon(
                          groupChat['status'] == 'published'
                              ? Icons.public
                              : Icons.lock_outline,
                          size: 18.sp,
                          color: const Color(0xFF666666),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          groupChat['status'] == 'published' ? '公开' : '私密',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 编辑按钮
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateGroupChatPage(
                            groupChat: groupChat,
                            isEdit: true,
                          ),
                        ),
                      ).then((result) {
                        // 如果返回的结果为true，表示编辑成功，刷新列表
                        if (result == true) {
                          _loadData();
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18.sp,
                          color: const Color(0xFF666666),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '编辑',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 聊天按钮
                  GestureDetector(
                    onTap: () {
                      // 启动正常群聊（非调试模式）
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupChatInitPage(
                            groupChatData: groupChat,
                            isDebug: false,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_outlined,
                          size: 18.sp,
                          color: const Color(0xFF666666),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '聊天',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 黑盒调试按钮
                  GestureDetector(
                    onTap: () {
                      _showBlackBoxDebug(groupChat);
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.bug_report_outlined,
                          size: 18.sp,
                          color: const Color(0xFF9C27B0),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '调试',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9C27B0),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 删除按钮
                  GestureDetector(
                    onTap: () {
                      _deleteGroupChat(groupChat['id']);
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18.sp,
                          color: const Color(0xFFE57373),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '删除',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFE57373),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }



  Future<void> _deleteGroupChat(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: '删除群聊',
        content: '确定要删除这个群聊吗？此操作不可撤销。',
        confirmText: '删除',
        cancelText: '取消',
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final response = await _groupChatService.deleteGroupChat(id);
        if (response['code'] == 200 || response['code'] == 0) {
          _showToast('删除成功', type: ToastType.success);
          _loadData(); // 重新加载列表
        } else {
          _showToast('删除失败: ${response['msg']}', type: ToastType.error);
        }
      } catch (e) {
        _showToast('删除失败: $e', type: ToastType.error);
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _toggleGroupChatStatus(Map<String, dynamic> groupChat) async {
    // 在公开和私密之间切换
    final currentStatus = groupChat['status'];
    final newStatus = currentStatus == 'published' ? 'private' : 'published';

    await _updateGroupChatStatus(groupChat['id'], newStatus);
  }

  Future<void> _updateGroupChatStatus(int id, String status) async {
    setState(() => _isLoading = true);

    try {
      final response = await _groupChatService.updateGroupChatStatus(id, status);
      if (response['code'] == 0) {
        _showToast('状态更新成功', type: ToastType.success);
        _loadData(); // 重新加载列表
      } else {
        _showToast('状态更新失败: ${response['msg']}', type: ToastType.error);
      }
    } catch (e) {
      _showToast('状态更新失败: $e', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
