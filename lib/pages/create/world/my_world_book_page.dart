import 'package:flutter/material.dart';
import '../services/world_book_service.dart';
import 'edit_world_book_page.dart';
import 'world_book_detail_page.dart';
import '../../../theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyWorldBookPage extends StatefulWidget {
  const MyWorldBookPage({super.key});

  @override
  State<MyWorldBookPage> createState() => _MyWorldBookPageState();
}

class _MyWorldBookPageState extends State<MyWorldBookPage> {
  final WorldBookService _service = WorldBookService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _worldBooks = [];
  int _currentPage = 1;
  int _total = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _keyword;

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else if (date.year == now.year) {
      return '${date.month}月${date.day}日';
    } else {
      return '${date.year}年${date.month}月${date.day}日';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _currentPage = 1;
      _worldBooks.clear();
      _hasMore = true;
    }

    if (!_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final result = await _service.getMyWorldBooks(
        page: _currentPage,
        pageSize: 10,
        keyword: _keyword,
        context: context,
      );

      final items = (result['items'] as List).cast<Map<String, dynamic>>();
      final total = result['total'] as int;

      setState(() {
        _worldBooks.addAll(items);
        _total = total;
        _currentPage++;
        _hasMore = _worldBooks.length < total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadData();
    }
  }

  Future<void> _onSearch(String value) async {
    _keyword = value.trim().isEmpty ? null : value.trim();
    await _loadData(refresh: true);
  }

  Future<void> _showCreateDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const EditWorldBookPage(),
      ),
    );

    if (result == true && mounted) {
      _loadData(refresh: true);
    }
  }

  Future<void> _editWorldBook(Map<String, dynamic> worldBook) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditWorldBookPage(worldBook: worldBook),
      ),
    );

    if (result == true && mounted) {
      _loadData(refresh: true);
    }
  }

  Future<void> _deleteWorldBook(String id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          '确认删除',
          style: TextStyle(
            fontSize: AppTheme.titleSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          '确定要删除这个世界书吗？',
          style: TextStyle(
            fontSize: AppTheme.bodySize,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '取消',
              style: TextStyle(
                fontSize: AppTheme.bodySize,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            child: Text(
              '删除',
              style: TextStyle(
                fontSize: AppTheme.bodySize,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await _service.deleteWorldBook(id, context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
          _loadData(refresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '我的世界书',
                        style: TextStyle(
                          fontSize: AppTheme.headingSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Spacer(),
                      FilledButton(
                        onPressed: _showCreateDialog,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add,
                                size: 20.sp, color: AppTheme.textPrimary),
                            SizedBox(width: 8.w),
                            Text(
                              '创建世界书',
                              style: TextStyle(
                                fontSize: AppTheme.bodySize,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    height: 40.h,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜索世界书',
                        prefixIcon:
                            Icon(Icons.search, color: AppTheme.textSecondary),
                        hintStyle: TextStyle(
                          fontSize: AppTheme.bodySize,
                          color: AppTheme.textHint,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                      ),
                      onSubmitted: _onSearch,
                      style: TextStyle(
                        fontSize: AppTheme.bodySize,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _worldBooks.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 64.sp,
                            color: AppTheme.textSecondary.withOpacity(0.5),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            '暂无世界书',
                            style: TextStyle(
                              fontSize: AppTheme.bodySize,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      itemCount: _worldBooks.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _worldBooks.length) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor),
                              ),
                            ),
                          );
                        }

                        final item = _worldBooks[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorldBookDetailPage(
                                  worldBook: item,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppTheme.border.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['title'],
                                              style: TextStyle(
                                                fontSize: AppTheme.bodySize,
                                                height: 1.4,
                                                fontWeight: FontWeight.w500,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            if (item['keywords'] != null &&
                                                (item['keywords'] as List)
                                                    .isNotEmpty) ...[
                                              SizedBox(height: 8.h),
                                              Wrap(
                                                spacing: 6.w,
                                                runSpacing: 6.h,
                                                children:
                                                    (item['keywords'] as List)
                                                        .map((keyword) {
                                                  return Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 6.w,
                                                      vertical: 2.h,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppTheme.primaryColor,
                                                      borderRadius: BorderRadius
                                                          .circular(AppTheme
                                                              .radiusXSmall),
                                                    ),
                                                    child: Text(
                                                      keyword.toString(),
                                                      style: TextStyle(
                                                        fontSize:
                                                            AppTheme.smallSize,
                                                        height: 1.4,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                _editWorldBook(item),
                                            icon: Icon(
                                              Icons.edit_outlined,
                                              size: 16.sp,
                                              color: AppTheme.primaryColor,
                                            ),
                                            style: IconButton.styleFrom(
                                              padding: EdgeInsets.all(8.w),
                                              minimumSize: Size(32.w, 32.w),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            tooltip: '编辑',
                                          ),
                                          IconButton(
                                            onPressed: () => _deleteWorldBook(
                                                item['id'].toString()),
                                            icon: Icon(
                                              Icons.delete_outline,
                                              size: 16.sp,
                                              color: AppTheme.error,
                                            ),
                                            style: IconButton.styleFrom(
                                              padding: EdgeInsets.all(8.w),
                                              minimumSize: Size(32.w, 32.w),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            tooltip: '删除',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  DefaultTextStyle(
                                    style: TextStyle(
                                      fontSize: AppTheme.smallSize,
                                      height: 1.4,
                                      color: AppTheme.textSecondary,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6.w,
                                            vertical: 1.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: item['status'] == 'published'
                                                ? AppTheme.primaryColor
                                                : Colors.grey,
                                            borderRadius: BorderRadius.circular(
                                                AppTheme.radiusXSmall),
                                          ),
                                          child: Text(
                                            item['status'] == 'published'
                                                ? '已公开'
                                                : '私密',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Icon(
                                          Icons.bar_chart,
                                          size: 14.sp,
                                          color: AppTheme.textSecondary,
                                        ),
                                        SizedBox(width: 2.w),
                                        Text('${item['usage_count'] ?? 0}次使用'),
                                        SizedBox(width: 12.w),
                                        Icon(
                                          Icons.access_time,
                                          size: 14.sp,
                                          color: AppTheme.textSecondary,
                                        ),
                                        SizedBox(width: 2.w),
                                        Text(_formatDate(item['updated_at'])),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
