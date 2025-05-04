import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/world_book_service.dart';
import '../../../theme/app_theme.dart';

enum WorldBookSelectSource {
  myWorldBook,
  publicWorldBook,
}

class SelectWorldBookPage extends StatefulWidget {
  final WorldBookSelectSource source;
  final List<Map<String, dynamic>>? initialSelected;

  const SelectWorldBookPage({
    super.key,
    required this.source,
    this.initialSelected,
  });

  @override
  State<SelectWorldBookPage> createState() => _SelectWorldBookPageState();
}

class _SelectWorldBookPageState extends State<SelectWorldBookPage> {
  final WorldBookService _service = WorldBookService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _selectedIds = <String>{};
  final Map<String, Map<String, dynamic>> _worldBookMap = {};

  final List<Map<String, dynamic>> _worldBooks = [];
  int _currentPage = 1;
  int _total = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _keyword;
  late WorldBookSelectSource _currentSource;

  @override
  void initState() {
    super.initState();
    _currentSource = widget.source;
    if (widget.initialSelected != null) {
      for (var book in widget.initialSelected!) {
        final id = book['id'].toString();
        _selectedIds.add(id);
        _worldBookMap[id] = book;
      }
    }
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildSourceSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: _buildSourceButton(
              title: '我的世界书',
              icon: Icons.folder_outlined,
              source: WorldBookSelectSource.myWorldBook,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _buildSourceButton(
              title: '公开世界书',
              icon: Icons.folder_shared_outlined,
              source: WorldBookSelectSource.publicWorldBook,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceButton({
    required String title,
    required IconData icon,
    required WorldBookSelectSource source,
  }) {
    final bool isSelected = _currentSource == source;
    return GestureDetector(
      onTap: () {
        if (_currentSource != source) {
          setState(() {
            _currentSource = source;
            _loadData(refresh: true);
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.border,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: AppTheme.bodySize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
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
      final result = _currentSource == WorldBookSelectSource.myWorldBook
          ? await _service.getMyWorldBooks(
              page: _currentPage,
              pageSize: 10,
              keyword: _keyword,
              context: context,
            )
          : await _service.getPublicWorldBooks(
              page: _currentPage,
              keyword: _keyword,
              context: context,
            );

      final items = (result['items'] as List).cast<Map<String, dynamic>>();
      final total = result['total'] as int;

      setState(() {
        _worldBooks.addAll(items);
        for (var item in items) {
          _worldBookMap[item['id'].toString()] = item;
        }
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

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          '选择世界书',
          style: TextStyle(
            fontSize: AppTheme.titleSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _selectedIds.isEmpty
                ? null
                : () {
                    final selectedWorldBooks =
                        _selectedIds.map((id) => _worldBookMap[id]!).toList();
                    Navigator.pop(context, selectedWorldBooks);
                  },
            child: Text(
              '完成(${_selectedIds.length})',
              style: TextStyle(
                fontSize: AppTheme.captionSize,
                color: _selectedIds.isEmpty
                    ? AppTheme.textSecondary
                    : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSourceSelector(),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索世界书',
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
          Expanded(
            child: _worldBooks.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.public,
                          size: 48.sp,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '暂无世界书',
                          style: TextStyle(
                            fontSize: AppTheme.captionSize,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                      final id = item['id'].toString();
                      final isSelected = _selectedIds.contains(id);

                      return InkWell(
                        onTap: () => _toggleSelect(id),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 12.h,
                            horizontal: 16.w,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppTheme.border.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? '',
                                      style: TextStyle(
                                        fontSize: AppTheme.bodySize,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (item['keywords'] != null &&
                                        (item['keywords'] as List)
                                            .isNotEmpty) ...[
                                      SizedBox(height: 8.h),
                                      Wrap(
                                        spacing: 8.w,
                                        runSpacing: 4.h,
                                        children: (item['keywords'] as List)
                                            .map((keyword) => Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8.w,
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
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Container(
                                width: 24.w,
                                height: 24.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : AppTheme.border.withOpacity(0.3),
                                    width: 2.w,
                                  ),
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: 16.sp,
                                        color: AppTheme.textPrimary,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
