import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';
import '../../../theme/app_theme.dart';
import '../services/characte_service.dart';
import '../services/novel_service.dart';
import '../../../services/file_service.dart';
import '../../../widgets/custom_toast.dart';
import '../character/create_character_page.dart';
import '../novel/create_novel_page.dart';

class DraftPage extends StatefulWidget {
  const DraftPage({super.key});

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  int _selectedIndex = 0; // 0: 角色卡, 1: 小说
  final _characterService = CharacterService();
  final _novelService = NovelService();
  final ScrollController _scrollController = ScrollController();
  final Map<String, Uint8List> _imageCache = {}; // 图片缓存

  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _characterList = [];
  List<Map<String, dynamic>> _novelList = [];
  int _total = 0;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMoreData = true;

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
    } else {
      await _loadNovelData();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadCharacterData() async {
    try {
      final response = await _characterService.getCharacterList(
        page: _currentPage,
        pageSize: _pageSize,
        status: 'draft',
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
        status: 'draft',
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

  // 预加载图片到缓存
  Future<void> _preloadImages(List<Map<String, dynamic>> items) async {
    for (final item in items) {
      if (item['coverUri'] != null &&
          !_imageCache.containsKey(item['coverUri'])) {
        try {
          final fileData = await FileService().getFile(item['coverUri']);
          if (fileData != null && fileData.data != null) {
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
    } else {
      await _loadMoreNovelData();
    }

    setState(() => _isLoadingMore = false);
  }

  Future<void> _loadMoreCharacterData() async {
    try {
      final response = await _characterService.getCharacterList(
        page: _currentPage + 1,
        pageSize: _pageSize,
        status: 'draft',
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
        status: 'draft',
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

  void _showToast(String message, {ToastType type = ToastType.info}) {
    if (!mounted) return;
    CustomToast.show(context, message: message, type: type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
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
                        color: AppTheme.textPrimary,
                        size: 18.sp,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '草稿箱',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 32.w),
                ],
              ),
            ),

            // 切换按钮
            Container(
              margin: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
              child: Row(
                children: [
                  _buildSwitchButton('角色卡', 0),
                  SizedBox(width: 24.w),
                  _buildSwitchButton('小说', 1),
                ],
              ),
            ),

            // 内容区域
            Expanded(
              child: _isLoading
                  ? _buildSkeletonList()
                  : _selectedIndex == 0
                      ? _buildCharacterList()
                      : _buildNovelList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchButton(String text, int index) {
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
          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
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
              Icons.edit_note_outlined,
              size: 48.sp,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              '暂无草稿',
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
      itemCount:
          _characterList.length + (_isLoadingMore || _hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        // 显示加载更多的指示器
        if (index == _characterList.length) {
          return _buildLoadMoreIndicator();
        }

        final character = _characterList[index];
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
                          color: AppTheme.textSecondary,
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
                      // 第一行：名字和按钮
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              character['name'] ?? '',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 编辑和删除按钮
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 16.sp,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              GestureDetector(
                                onTap: () {
                                  _showDeleteConfirmDialog(character);
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 16.sp,
                                    color: AppTheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),

                      // 第二行：简介
                      Expanded(
                        child: Text(
                          character['description'] ?? '',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppTheme.textSecondary,
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
                            color: AppTheme.textSecondary,
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
                          color: AppTheme.textSecondary,
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
          if (fileData != null && fileData.data != null) {
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
              color: AppTheme.textSecondary,
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

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      alignment: Alignment.center,
      child: _isLoadingMore
          ? SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : GestureDetector(
              onTap: _hasMoreData ? _loadMoreData : null,
              child: Text(
                _hasMoreData ? '加载更多' : '没有更多数据了',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: _hasMoreData
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                ),
              ),
            ),
    );
  }

  Widget _buildShimmerImage() {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardBackground.withOpacity(0.3),
      highlightColor: AppTheme.cardBackground.withOpacity(0.1),
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
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              '暂无草稿',
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
      itemCount: _novelList.length + (_isLoadingMore || _hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        // 显示加载更多的指示器
        if (index == _novelList.length) {
          return _buildLoadMoreIndicator();
        }

        final novel = _novelList[index];
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
                          Icons.book_outlined,
                          color: AppTheme.textSecondary,
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
                      // 第一行：名字和按钮
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              novel['title'] ?? '',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 编辑和删除按钮
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                    // 如果返回的结果为true，表示编辑成功，刷新列表
                                    if (result != null) {
                                      _loadData();
                                    }
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 16.sp,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              GestureDetector(
                                onTap: () {
                                  _showDeleteNovelConfirmDialog(novel);
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 16.sp,
                                    color: AppTheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),

                      // 第二行：简介
                      Expanded(
                        child: Text(
                          novel['description'] ?? '',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppTheme.textSecondary,
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
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      SizedBox(height: 2.h),
                      // 第四行：作者和时间
                      Row(
                        children: [
                          // 状态指示器
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: novel['status'] == 'draft'
                                  ? Colors.orange.withOpacity(0.1)
                                  : AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              novel['status'] == 'draft' ? '草稿' : '已发布',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: novel['status'] == 'draft'
                                    ? Colors.orange
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              '${_formatTime(novel['createdAt'])}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Text(
            '确认删除',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.titleSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            '确定要删除角色"${character['name']}"吗？此操作不可恢复。',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.bodySize,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                '取消',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.bodySize,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                '删除',
                style: TextStyle(
                  color: AppTheme.error,
                  fontSize: AppTheme.bodySize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteCharacter(character['id'].toString());
              },
            ),
          ],
        );
      },
    );
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
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Text(
            '确认删除',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.titleSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            '确定要删除小说"${novel['title']}"吗？此操作不可恢复。',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.bodySize,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                '取消',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.bodySize,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                '删除',
                style: TextStyle(
                  color: AppTheme.error,
                  fontSize: AppTheme.bodySize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteNovel(novel['id'].toString());
              },
            ),
          ],
        );
      },
    );
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
}
