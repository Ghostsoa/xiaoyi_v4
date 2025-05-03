import 'package:flutter/material.dart';
import '../services/world_book_service.dart';
import 'world_book_detail_page.dart';
import '../../../theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PublicWorldBookPage extends StatefulWidget {
  const PublicWorldBookPage({super.key});

  @override
  State<PublicWorldBookPage> createState() => _PublicWorldBookPageState();
}

class _PublicWorldBookPageState extends State<PublicWorldBookPage> {
  final _worldBookService = WorldBookService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _worldBooks = [];
  int _currentPage = 1;
  int _total = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _keyword;

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
      final result = await _worldBookService.getPublicWorldBooks(
        page: _currentPage,
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
            _scrollController.position.maxScrollExtent - 200 &&
        _worldBooks.length < _total) {
      _loadData();
    }
  }

  void _onSearch(String value) {
    _keyword = value.trim().isEmpty ? null : value.trim();
    _loadData(refresh: true);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '公共世界书',
                    style: TextStyle(
                      fontSize: AppTheme.headingSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
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
                      style: TextStyle(color: AppTheme.textPrimary),
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
                  : RefreshIndicator(
                      onRefresh: () => _loadData(refresh: true),
                      child: ListView.builder(
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
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorldBookDetailPage(
                                  worldBook: item,
                                ),
                              ),
                            ),
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
                                    Text(
                                      item['title'] ?? '',
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
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '关键词：',
                                            style: TextStyle(
                                              fontSize: AppTheme.smallSize,
                                              height: 1.4,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Expanded(
                                            child: Wrap(
                                              spacing: 6.w,
                                              runSpacing: 6.h,
                                              children:
                                                  (item['keywords'] as List)
                                                      .map((keyword) {
                                                return Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 6.w,
                                                    vertical: 2.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppTheme.primaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppTheme
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
                                          ),
                                        ],
                                      ),
                                    ],
                                    SizedBox(height: 8.h),
                                    DefaultTextStyle(
                                      style: TextStyle(
                                        fontSize: AppTheme.smallSize,
                                        height: 1.4,
                                        color: AppTheme.textSecondary,
                                      ),
                                      child: Row(
                                        children: [
                                          Text('@${item['author_name'] ?? ''}'),
                                          SizedBox(width: 12.w),
                                          Icon(
                                            Icons.bar_chart,
                                            size: 14.sp,
                                            color: AppTheme.textSecondary,
                                          ),
                                          SizedBox(width: 2.w),
                                          Text(
                                              '${item['usage_count'] ?? 0}次使用'),
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
            ),
          ],
        ),
      ),
    );
  }
}
