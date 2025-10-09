import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import '../../../theme/app_theme.dart';
import '../services/html_template_service.dart';
import '../../../widgets/custom_toast.dart';
import 'create_html_template_page.dart';
import 'html_template_detail_page.dart';

class MyHtmlRepoPage extends StatefulWidget {
  const MyHtmlRepoPage({super.key});

  @override
  State<MyHtmlRepoPage> createState() => _MyHtmlRepoPageState();
}

class _MyHtmlRepoPageState extends State<MyHtmlRepoPage> {
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
  int _filterStatus = -1; // -1=全部，1=私有，2=公开
  int _filterTaskStatus = -1; // -1=全部
  int _filterVersion = -1; // -1=全部
  
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
      final result = await _service.getMyProjects(
        page: _currentPage,
        size: _pageSize,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _filterStatus,
        taskStatus: _filterTaskStatus,
        version: _filterVersion,
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
    _currentPage = 1;
    try {
      final result = await _service.getMyProjects(
        page: 1,
        size: _pageSize,
        status: _filterStatus,
        taskStatus: _filterTaskStatus,
        version: _filterVersion,
      );

      if (mounted) {
        setState(() {
          _total = result['total'] ?? 0;
          final List<dynamic> newProjects = result['projects'] ?? [];
          _projects = newProjects.cast<Map<String, dynamic>>();
          _hasMore = _projects.length < _total;
        });
      }

      _refreshController.refreshCompleted();
      if (_hasMore) {
        _refreshController.loadComplete();
      }
    } catch (e) {
      _refreshController.refreshFailed();
      if (mounted) {
        CustomToast.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _onLoading() async {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return;
    }

    try {
      final nextPage = _currentPage + 1;
      final result = await _service.getMyProjects(
        page: nextPage,
        size: _pageSize,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _filterStatus,
        taskStatus: _filterTaskStatus,
        version: _filterVersion,
      );

      if (mounted) {
        final List<dynamic> newProjects = result['projects'] ?? [];
        final int total = result['total'] ?? 0;

        if (newProjects.isNotEmpty) {
          setState(() {
            _projects.addAll(newProjects.cast<Map<String, dynamic>>());
            _currentPage = nextPage;
            _hasMore = _projects.length < total;
            _total = total;
          });
          _refreshController.loadComplete();
        } else {
          _refreshController.loadNoData();
        }
      }
    } catch (e) {
      _refreshController.loadFailed();
      if (mounted) {
        CustomToast.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          type: ToastType.error,
        );
      }
    }
  }

  // 防抖筛选
  void _debounceFilter() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadProjects(refresh: true);
    });
  }

  void _navigateToCreatePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateHtmlTemplatePage(),
      ),
    );

    // 如果创建成功，刷新列表
    if (result == true) {
      _loadProjects(refresh: true);
    }
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '我的HTML模板仓库',
          style: TextStyle(
            fontSize: AppTheme.titleSize,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 搜索框
          _buildSearchBar(),
          
          // 筛选栏
          _buildFilterBar(),
          
          // 列表
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreatePage,
        icon: Icon(Icons.add),
        label: Text('创建项目'),
        backgroundColor: AppTheme.primaryColor,
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
          hintText: '搜索项目名...',
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

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
      child: Row(
        children: [
          // 状态筛选
          Expanded(
            flex: 2,
            child: _buildDropdown(
              value: _filterStatus,
              items: [
                {'value': -1, 'label': '全部'},
                {'value': 1, 'label': '私有'},
                {'value': 2, 'label': '公开'},
              ],
              onChanged: (value) {
                setState(() => _filterStatus = value!);
                _debounceFilter();
              },
            ),
          ),
          SizedBox(width: 8.w),
          // 任务状态筛选
          Expanded(
            flex: 3,
            child: _buildDropdown(
              value: _filterTaskStatus,
              items: [
                {'value': -1, 'label': '全部状态'},
                {'value': 1, 'label': '创建成功'},
                {'value': 2, 'label': 'AI介入优化中'},
                {'value': 3, 'label': '已完成'},
                {'value': 4, 'label': 'AI优化失败'},
                {'value': 5, 'label': 'AI优化待确认'},
              ],
              onChanged: (value) {
                setState(() => _filterTaskStatus = value!);
                _debounceFilter();
              },
            ),
          ),
          SizedBox(width: 8.w),
          // 版本筛选
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.code,
                size: 80.sp,
                color: Colors.white,
              ),
              SizedBox(height: 16.h),
              Text(
                '正在加载项目列表...',
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
            size: 80.sp,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            '暂无HTML模板项目',
            style: TextStyle(
              fontSize: AppTheme.bodySize,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '点击右下角按钮创建第一个项目',
            style: TextStyle(
              fontSize: AppTheme.captionSize,
              color: AppTheme.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final taskStatus = project['task_status'] ?? 1;
    final status = project['status'] ?? 1;
    final version = project['version'] ?? 1;
    final aiOptimized = project['ai_optimized'] ?? false;

    Color taskStatusColor = Colors.grey;
    switch (taskStatus) {
      case 1:
        taskStatusColor = Colors.green;
        break;
      case 2:
        taskStatusColor = Colors.orange;
        break;
      case 3:
        taskStatusColor = Colors.blue;
        break;
      case 4:
        taskStatusColor = Colors.red;
        break;
      case 5:
        taskStatusColor = Colors.amber;
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HtmlTemplateDetailPage(
                project: project,
                isOwner: true,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行：项目名称 + 操作菜单
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      project['project_name'] ?? '未命名项目',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  // 操作菜单按钮
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18.sp, color: AppTheme.textSecondary),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _navigateToEditPage(project);
                          break;
                        case 'toggle_status':
                          _toggleProjectStatus(project);
                          break;
                        case 'toggle_version':
                          _toggleProjectVersion(project);
                          break;
                        case 'delete':
                          _confirmDeleteProject(project);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        enabled: !aiOptimized,
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18.sp,
                              color: aiOptimized 
                                  ? AppTheme.textSecondary.withOpacity(0.3) 
                                  : AppTheme.primaryColor,
                            ),
                            SizedBox(width: 12.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '编辑项目',
                                  style: TextStyle(
                                    color: aiOptimized 
                                        ? AppTheme.textSecondary.withOpacity(0.3) 
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                if (aiOptimized)
                                  Text(
                                    'AI已介入不可编辑',
                                    style: TextStyle(
                                      fontSize: AppTheme.smallSize,
                                      color: AppTheme.textSecondary.withOpacity(0.5),
                                    ),
                                  )
                                else if (version == 2)
                                  Text(
                                    '生产版仅可编辑部分内容',
                                    style: TextStyle(
                                      fontSize: AppTheme.smallSize,
                                      color: AppTheme.textSecondary.withOpacity(0.7),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_status',
                        child: Row(
                          children: [
                            Icon(
                              status == 1 ? Icons.public : Icons.lock_outline,
                              size: 18.sp,
                              color: AppTheme.textPrimary,
                            ),
                            SizedBox(width: 12.w),
                            Text(status == 1 ? '设为公开' : '设为私有'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_version',
                        enabled: !aiOptimized && version == 1,
                        child: Row(
                          children: [
                            Icon(
                              Icons.rocket_launch,
                              size: 18.sp,
                              color: (aiOptimized || version == 2) 
                                  ? AppTheme.textSecondary.withOpacity(0.3) 
                                  : AppTheme.textPrimary,
                            ),
                            SizedBox(width: 12.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '设为生产版',
                                  style: TextStyle(
                                    color: (aiOptimized || version == 2) 
                                        ? AppTheme.textSecondary.withOpacity(0.3) 
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                if (aiOptimized)
                                  Text(
                                    'AI已介入不可修改',
                                    style: TextStyle(
                                      fontSize: AppTheme.smallSize,
                                      color: AppTheme.textSecondary.withOpacity(0.5),
                                    ),
                                  )
                                else if (version == 2)
                                  Text(
                                    '生产版不可切换',
                                    style: TextStyle(
                                      fontSize: AppTheme.smallSize,
                                      color: AppTheme.textSecondary.withOpacity(0.5),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18.sp, color: Colors.red),
                            SizedBox(width: 12.w),
                            Text('删除项目', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 8.h),
              
              // 标签和元信息合并为一行
              Row(
                children: [
                  // 状态标签
                  _buildCompactChip(
                    HtmlTemplateService.getStatusText(status),
                    status == 1 ? Colors.grey : Colors.green,
                  ),
                  SizedBox(width: 6.w),
                  // 任务状态标签
                  _buildCompactChip(
                    HtmlTemplateService.getTaskStatusText(taskStatus),
                    taskStatusColor,
                  ),
                  SizedBox(width: 6.w),
                  // 版本标签
                  _buildCompactChip(
                    HtmlTemplateService.getVersionText(version),
                    version == 1 ? Colors.orange : Colors.blue,
                  ),
                  if (aiOptimized) ...[
                    SizedBox(width: 6.w),
                    _buildCompactChip('AI', Colors.purple),
                  ],
                  
                  Spacer(),
                  
                  // 时间信息
                  Icon(Icons.access_time, size: 12.sp, color: AppTheme.textSecondary.withOpacity(0.6)),
                  SizedBox(width: 4.w),
                  Text(
                    _formatDate(project['created_at']),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 紧凑型标签
  Widget _buildCompactChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3.r),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '未知时间';
    try {
      final date = DateTime.parse(dateStr.toString());
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inDays < 1) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';

      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.toString();
    }
  }

  // 导航到编辑页面
  Future<void> _navigateToEditPage(Map<String, dynamic> project) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateHtmlTemplatePage(project: project),
      ),
    );

    // 如果编辑成功，刷新列表
    if (result == true && mounted) {
      _loadProjects(refresh: true);
    }
  }

  // 切换项目状态（私有/公开）
  Future<void> _toggleProjectStatus(Map<String, dynamic> project) async {
    final projectId = project['id'];
    final currentStatus = project['status'] ?? 1;
    final newStatus = currentStatus == 1 ? 2 : 1;
    final statusText = newStatus == 1 ? '私有' : '公开';

    try {
      await _service.updateProjectStatus(
        projectId: projectId,
        status: newStatus,
      );

      if (mounted) {
        // 更新本地数据
        setState(() {
          project['status'] = newStatus;
        });

        CustomToast.show(
          context,
          message: '已设为$statusText',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          type: ToastType.error,
        );
      }
    }
  }

  // 切换项目版本（测试版/生产版）
  Future<void> _toggleProjectVersion(Map<String, dynamic> project) async {
    final projectId = project['id'];
    final currentVersion = project['version'] ?? 1;
    final aiOptimized = project['ai_optimized'] ?? false;

    // AI已介入的项目不允许修改版本
    if (aiOptimized) {
      CustomToast.show(
        context,
        message: 'AI已介入优化的项目不允许修改版本',
        type: ToastType.error,
      );
      return;
    }

    // 只允许从测试版切换到生产版，不允许反向切换
    if (currentVersion == 2) {
      CustomToast.show(
        context,
        message: '生产版本不允许切换回测试版本',
        type: ToastType.error,
      );
      return;
    }

    final newVersion = 2; // 只能从测试版（1）切换到生产版（2）
    final versionText = '生产版';

    try {
      await _service.updateProjectVersion(
        projectId: projectId,
        version: newVersion,
      );

      if (mounted) {
        // 更新本地数据
        setState(() {
          project['version'] = newVersion;
        });

        CustomToast.show(
          context,
          message: '已设为$versionText',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          type: ToastType.error,
        );
      }
    }
  }

  // 确认删除项目
  void _confirmDeleteProject(Map<String, dynamic> project) {
    final projectName = project['project_name'] ?? '未命名项目';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8.w),
            Text('确认删除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '确定要删除项目吗？',
              style: TextStyle(
                fontSize: AppTheme.bodySize,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.code, size: 16.sp, color: AppTheme.primaryColor),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      projectName,
                      style: TextStyle(
                        fontSize: AppTheme.captionSize,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              '此操作不可撤销，请谨慎操作。',
              style: TextStyle(
                fontSize: AppTheme.captionSize,
                color: Colors.red,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProject(project);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('确认删除'),
          ),
        ],
      ),
    );
  }

  // 删除项目
  Future<void> _deleteProject(Map<String, dynamic> project) async {
    final projectId = project['id'];
    final projectName = project['project_name'] ?? '未命名项目';

    try {
      await _service.deleteProject(projectId: projectId);

      if (mounted) {
        // 从列表中移除
        setState(() {
          _projects.remove(project);
          _total--;
        });

        CustomToast.show(
          context,
          message: '已删除「$projectName」',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          type: ToastType.error,
        );
      }
    }
  }
}
