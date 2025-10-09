import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import '../../../theme/app_theme.dart';
import '../services/html_template_service.dart';
import '../../../widgets/custom_toast.dart';
import 'html_template_detail_page.dart';

class PublicHtmlRepoPage extends StatefulWidget {
  const PublicHtmlRepoPage({super.key});

  @override
  State<PublicHtmlRepoPage> createState() => _PublicHtmlRepoPageState();
}

class _PublicHtmlRepoPageState extends State<PublicHtmlRepoPage> {
  final HtmlTemplateService _service = HtmlTemplateService();
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 10;

  List<Map<String, dynamic>> _projects = [];
  int _total = 0;

  // 筛选条件
  int _filterVersion = -1; // -1=全部，1=测试版本，2=生产版本
  int _filterAiOptimized = -1; // -1=全部，0=否，1=是
  
  // 防抖定时器
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProjects({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _projects.clear();
        _hasMore = true;
      }
    });

    try {
      final result = await _service.getPublicProjects(
        page: _currentPage,
        size: _pageSize,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        version: _filterVersion,
        aiOptimized: _filterAiOptimized == -1 ? null : _filterAiOptimized == 1,
      );

      if (mounted) {
        setState(() {
          _total = result['total'] ?? 0;
          final List<dynamic> newProjects = result['projects'] ?? [];
          
          if (refresh) {
            _projects = newProjects.cast<Map<String, dynamic>>();
          } else {
            _projects.addAll(newProjects.cast<Map<String, dynamic>>());
          }

          _hasMore = _projects.length < _total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomToast.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> onRefresh() async {
    await _loadProjects(refresh: true);
    if (mounted) {
      _refreshController.refreshCompleted();
    }
  }

  Future<void> _onLoading() async {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return;
    }

    _currentPage++;
    await _loadProjects();

    if (mounted) {
      if (_hasMore) {
        _refreshController.loadComplete();
      } else {
        _refreshController.loadNoData();
      }
    }
  }

  void _debounceFilter() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadProjects(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary;
    final background = AppTheme.background;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '公共HTML模板仓库',
          style: TextStyle(
            fontSize: AppTheme.titleSize,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterBar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final textPrimary = AppTheme.textPrimary;
    final background = AppTheme.background;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 6.h),
      color: background,
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontSize: AppTheme.captionSize,
          color: textPrimary,
        ),
        decoration: InputDecoration(
          hintText: '搜索项目名或用户名...',
          hintStyle: TextStyle(
            fontSize: AppTheme.captionSize,
            color: AppTheme.textSecondary,
          ),
          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary, size: 18.sp),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.textSecondary, size: 18.sp),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  onPressed: () {
                    _searchController.clear();
                    _debounceFilter();
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {});
          _debounceFilter();
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    final background = AppTheme.background;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
      color: background,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildDropdown(
              value: _filterVersion,
              items: [
                {'value': -1, 'label': '全部版本'},
                {'value': 1, 'label': '测试版'},
                {'value': 2, 'label': '生产版'},
              ],
              onChanged: (value) {
                setState(() => _filterVersion = value!);
                _debounceFilter();
              },
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            flex: 2,
            child: _buildDropdown(
              value: _filterAiOptimized,
              items: [
                {'value': -1, 'label': '全部'},
                {'value': 0, 'label': '未优化'},
                {'value': 1, 'label': '已优化'},
              ],
              onChanged: (value) {
                setState(() => _filterAiOptimized = value!);
                _debounceFilter();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required int value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<int?> onChanged,
  }) {
    final textPrimary = AppTheme.textPrimary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dropdownBg = isDark ? Colors.grey[800] : Colors.grey[100];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: dropdownBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: DropdownButton<int>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: textPrimary, size: 18.sp),
        style: TextStyle(
          fontSize: AppTheme.captionSize,
          color: textPrimary,
        ),
        dropdownColor: dropdownBg,
        isDense: true,
        items: items.map((item) {
          return DropdownMenuItem<int>(
            value: item['value'] as int,
            child: Text(
              item['label'] as String,
              style: TextStyle(
                fontSize: AppTheme.captionSize,
                color: textPrimary,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final shimmerBaseColor = isDark ? Colors.grey.withOpacity(0.3) : Colors.grey.withOpacity(0.5);
    final shimmerHighlightColor = isDark ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.2);
    
    final customHeader = CustomHeader(
      builder: (BuildContext context, RefreshStatus? mode) {
        Widget body;
        if (mode == RefreshStatus.idle) {
          body = Text(
            '下拉刷新',
            style: TextStyle(
              color: textColor,
              fontSize: 14.sp,
            ),
          );
        } else if (mode == RefreshStatus.refreshing) {
          body = Shimmer.fromColors(
            baseColor: shimmerBaseColor,
            highlightColor: shimmerHighlightColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor!),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '正在刷新...',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        } else if (mode == RefreshStatus.completed) {
          body = Text(
            '刷新完成',
            style: TextStyle(
              color: Colors.green,
              fontSize: 14.sp,
            ),
          );
        } else if (mode == RefreshStatus.failed) {
          body = Text(
            '刷新失败',
            style: TextStyle(
              color: Colors.red,
              fontSize: 14.sp,
            ),
          );
        } else {
          body = Text(
            '松开刷新',
            style: TextStyle(
              color: textColor,
              fontSize: 14.sp,
            ),
          );
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
          body = Text(
            '上拉加载更多',
            style: TextStyle(
              color: textColor,
              fontSize: 14.sp,
            ),
          );
        } else if (mode == LoadStatus.loading) {
          body = Shimmer.fromColors(
            baseColor: shimmerBaseColor,
            highlightColor: shimmerHighlightColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor!),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '加载中...',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        } else if (mode == LoadStatus.failed) {
          body = Text(
            '加载失败，点击重试',
            style: TextStyle(
              color: Colors.red,
              fontSize: 14.sp,
            ),
          );
        } else if (mode == LoadStatus.canLoading) {
          body = Text(
            '松开加载更多',
            style: TextStyle(
              color: textColor,
              fontSize: 14.sp,
            ),
          );
        } else {
          body = Text(
            '没有更多数据了',
            style: TextStyle(
              color: textColor,
              fontSize: 14.sp,
            ),
          );
        }
        return SizedBox(
          height: 55.0,
          child: Center(child: body),
        );
      },
    );

    if (_isLoading && _projects.isEmpty) {
      return Center(
        child: Shimmer.fromColors(
          baseColor: AppTheme.textSecondary.withOpacity(0.3),
          highlightColor: AppTheme.textSecondary.withOpacity(0.1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40.w,
                height: 40.w,
                child: const CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(height: 16.h),
              Text(
                '加载中...',
                style: TextStyle(
                  fontSize: AppTheme.bodySize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
      child: _projects.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                return _buildProjectCard(_projects[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.code_off,
            size: 64.sp,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            '暂无公开项目',
            style: TextStyle(
              fontSize: AppTheme.bodySize,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final cardBg = AppTheme.cardBackground;
    final textPrimary = AppTheme.textPrimary;

    final projectName = project['project_name'] ?? '未命名项目';
    final username = project['username'] ?? '未知用户';
    final taskStatus = project['task_status'] ?? 1;
    final aiOptimized = project['ai_optimized'] ?? false;
    final createdAt = project['created_at'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HtmlTemplateDetailPage(
                  project: project,
                  isOwner: false, // 公开项目，不是所有者
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 项目名和用户名
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            projectName,
                            style: TextStyle(
                              fontSize: AppTheme.titleSize,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14.sp,
                                color: AppTheme.textSecondary,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                username,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                
                // 标签和时间信息
                Row(
                  children: [
                    _buildCompactChip(
                      label: HtmlTemplateService.getTaskStatusText(taskStatus),
                      color: _getTaskStatusColor(taskStatus),
                    ),
                    if (aiOptimized) ...[
                      SizedBox(width: 6.w),
                      _buildCompactChip(
                        label: 'AI优化',
                        color: Colors.purple,
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      Icons.access_time,
                      size: 12.sp,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondary,
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

  Widget _buildCompactChip({required String label, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getTaskStatusColor(int taskStatus) {
    switch (taskStatus) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      case 4:
        return Colors.red;
      case 5:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${date.month}月${date.day}日';
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
      return '--';
    }
  }
}
