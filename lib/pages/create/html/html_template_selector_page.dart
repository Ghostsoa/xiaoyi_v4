import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import '../../../theme/app_theme.dart';
import '../services/html_template_service.dart';
import '../../../widgets/custom_toast.dart';

class HtmlTemplateSelectorPage extends StatefulWidget {
  final String initialSelected; // "100,200,300" 格式的字符串

  const HtmlTemplateSelectorPage({
    super.key,
    this.initialSelected = '',
  });

  @override
  State<HtmlTemplateSelectorPage> createState() => _HtmlTemplateSelectorPageState();
}

class _HtmlTemplateSelectorPageState extends State<HtmlTemplateSelectorPage> {
  final HtmlTemplateService _service = HtmlTemplateService();

  // 已选中的项目 ID 集合
  final Set<int> _selectedIds = {};
  
  // 当前选中的分类：0=我的，1=公开
  int _currentCategory = 0;

  @override
  void initState() {
    super.initState();
    _parseInitialSelected();
  }

  void _parseInitialSelected() {
    if (widget.initialSelected.isNotEmpty) {
      final ids = widget.initialSelected.split(',');
      for (var id in ids) {
        final parsedId = int.tryParse(id.trim());
        if (parsedId != null) {
          _selectedIds.add(parsedId);
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        // 限制最多选择10个模板
        if (_selectedIds.length >= 10) {
          CustomToast.show(
            context,
            message: '最多只能选择10个HTML模板',
            type: ToastType.warning,
          );
          return;
        }
        _selectedIds.add(id);
      }
    });
  }

  void _confirm() {
    final result = _selectedIds.join(',');
    Navigator.pop(context, result);
  }

  Widget _buildCategoryButton(int index, String label, IconData icon) {
    final isSelected = _currentCategory == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentCategory = index;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.grey[800] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16.sp,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTheme.captionSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          'HTML模板选择',
          style: TextStyle(
            fontSize: AppTheme.titleSize,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: TextButton(
                onPressed: _confirm,
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '确定 (${_selectedIds.length})',
                  style: TextStyle(
                    fontSize: AppTheme.captionSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 自定义分类选择器
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            color: background,
            child: Row(
              children: [
                _buildCategoryButton(0, '我的模板', Icons.folder_outlined),
                SizedBox(width: 8.w),
                _buildCategoryButton(1, '公开模板', Icons.public),
              ],
            ),
          ),
          
          // 内容区域
          Expanded(
            child: _TemplateListTab(
              key: ValueKey(_currentCategory),
              service: _service,
              isMyTemplates: _currentCategory == 0,
              selectedIds: _selectedIds,
              onToggle: _toggleSelection,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateListTab extends StatefulWidget {
  final HtmlTemplateService service;
  final bool isMyTemplates;
  final Set<int> selectedIds;
  final Function(int) onToggle;

  const _TemplateListTab({
    super.key,
    required this.service,
    required this.isMyTemplates,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  State<_TemplateListTab> createState() => _TemplateListTabState();
}

class _TemplateListTabState extends State<_TemplateListTab>
    with AutomaticKeepAliveClientMixin {
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 10;

  List<Map<String, dynamic>> _projects = [];
  int _total = 0;

  Timer? _debounceTimer;

  @override
  bool get wantKeepAlive => true;

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
      final result = widget.isMyTemplates
          ? await widget.service.getMyProjects(
              page: _currentPage,
              size: _pageSize,
              search: _searchController.text.trim().isEmpty
                  ? null
                  : _searchController.text.trim(),
            )
          : await widget.service.getPublicProjects(
              page: _currentPage,
              size: _pageSize,
              search: _searchController.text.trim().isEmpty
                  ? null
                  : _searchController.text.trim(),
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
    super.build(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final shimmerBaseColor = isDark ? Colors.grey.withOpacity(0.3) : Colors.grey.withOpacity(0.5);
    final shimmerHighlightColor = isDark ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.2);

    final customHeader = CustomHeader(
      builder: (BuildContext context, RefreshStatus? mode) {
        Widget body;
        if (mode == RefreshStatus.idle) {
          body = Text('下拉刷新', style: TextStyle(color: textColor, fontSize: 14.sp));
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
                  child: CircularProgressIndicator(strokeWidth: 2.w, valueColor: AlwaysStoppedAnimation<Color>(textColor!)),
                ),
                SizedBox(width: 8.w),
                Text('正在刷新...', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: textColor)),
              ],
            ),
          );
        } else if (mode == RefreshStatus.completed) {
          body = Text('刷新完成', style: TextStyle(color: Colors.green, fontSize: 14.sp));
        } else if (mode == RefreshStatus.failed) {
          body = Text('刷新失败', style: TextStyle(color: Colors.red, fontSize: 14.sp));
        } else {
          body = Text('松开刷新', style: TextStyle(color: textColor, fontSize: 14.sp));
        }
        return SizedBox(height: 55.0, child: Center(child: body));
      },
    );

    final customFooter = CustomFooter(
      builder: (BuildContext context, LoadStatus? mode) {
        Widget body;
        if (mode == LoadStatus.idle) {
          body = Text('上拉加载更多', style: TextStyle(color: textColor, fontSize: 14.sp));
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
                  child: CircularProgressIndicator(strokeWidth: 2.w, valueColor: AlwaysStoppedAnimation<Color>(textColor!)),
                ),
                SizedBox(width: 8.w),
                Text('加载中...', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: textColor)),
              ],
            ),
          );
        } else if (mode == LoadStatus.failed) {
          body = Text('加载失败，点击重试', style: TextStyle(color: Colors.red, fontSize: 14.sp));
        } else if (mode == LoadStatus.canLoading) {
          body = Text('松开加载更多', style: TextStyle(color: textColor, fontSize: 14.sp));
        } else {
          body = Text('没有更多数据了', style: TextStyle(color: textColor, fontSize: 14.sp));
        }
        return SizedBox(height: 55.0, child: Center(child: body));
      },
    );

    return Column(
      children: [
        // 搜索框
        _buildSearchBar(),

        // 列表
        Expanded(
          child: _isLoading && _projects.isEmpty
              ? Center(
                  child: Shimmer.fromColors(
                    baseColor: AppTheme.textSecondary.withOpacity(0.3),
                    highlightColor: AppTheme.textSecondary.withOpacity(0.1),
                    child: Text(
                      '加载中...',
                      style: TextStyle(
                        fontSize: AppTheme.titleSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                  child: _projects.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: _projects.length,
                          itemBuilder: (context, index) {
                            return _buildProjectCard(_projects[index]);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final textPrimary = AppTheme.textPrimary;
    final background = AppTheme.background;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      color: background,
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontSize: AppTheme.captionSize,
          color: textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.isMyTemplates ? '搜索我的项目...' : '搜索公开项目...',
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
                    setState(() {});
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
            widget.isMyTemplates ? '暂无模板' : '暂无公开模板',
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

    final projectId = project['id'] as int;
    final projectName = project['project_name'] ?? '未命名项目';
    final version = project['version'] ?? 1; // 1=测试版，2=生产版
    final isSelected = widget.selectedIds.contains(projectId);
    final isProduction = version == 2; // 只有生产版本可选

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Opacity(
        opacity: isProduction ? 1.0 : 0.5,
        child: Material(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            onTap: () {
              if (isProduction) {
                widget.onToggle(projectId);
              } else {
                // 显示提示
                CustomToast.show(
                  context,
                  message: '只能选择生产版本的模板',
                  type: ToastType.warning,
                );
              }
            },
            child: Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected 
                      ? AppTheme.primaryColor 
                      : (isProduction ? Colors.transparent : AppTheme.textSecondary.withOpacity(0.3)),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                children: [
                  // 复选框
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected 
                            ? AppTheme.primaryColor 
                            : (isProduction ? AppTheme.textSecondary : AppTheme.textSecondary.withOpacity(0.3)),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 16.sp)
                        : (!isProduction 
                            ? Icon(Icons.lock, color: AppTheme.textSecondary.withOpacity(0.5), size: 14.sp)
                            : null),
                  ),
                  SizedBox(width: 12.w),

                  // 项目名称和版本标签
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectName,
                          style: TextStyle(
                            fontSize: AppTheme.bodySize,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isProduction) ...[
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4.r),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '测试版',
                              style: TextStyle(
                                fontSize: AppTheme.smallSize,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
}

