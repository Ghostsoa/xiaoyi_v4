import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import 'report_constants.dart';
import 'report_management_service.dart';
import 'report_detail_page.dart';
import 'penalty_management_page.dart';

class ReportManagementPage extends StatefulWidget {
  const ReportManagementPage({Key? key}) : super(key: key);

  @override
  State<ReportManagementPage> createState() => _ReportManagementPageState();
}

class _ReportManagementPageState extends State<ReportManagementPage>
    with SingleTickerProviderStateMixin {
  final ReportManagementService _service = ReportManagementService();

  // 筛选条件
  int _selectedStatus = ReportStatus.all;
  int _selectedReportType = ReportType.all;
  String? _searchKeyword;

  // 分页
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _pageSize = 10;

  // 数据
  List<dynamic> _reports = [];
  bool _isLoading = false;
  bool _isRefreshing = false;

  // Tab控制器
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _loadReports({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    if (refresh) {
      setState(() {
        _isRefreshing = true;
        _currentPage = 1;
      });
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final result = await _service.getReports(
        status: _selectedStatus,
        reportType: _selectedReportType,
        keyword: _searchKeyword,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (result['code'] == 0) {
        final data = result['data'];
        setState(() {
          _reports = data['items'] ?? [];
          _totalItems = data['total'] ?? 0;
          _totalPages = (_totalItems / _pageSize).ceil();
          _isLoading = false;
          _isRefreshing = false;
        });
      } else {
        throw Exception(result['msg'] ?? '获取举报列表失败');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      CustomToast.show(
        context,
        message: '加载举报列表失败: $e',
        type: ToastType.error,
      );
    }
  }

  Future<void> _navigateToDetail(dynamic report) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReportDetailPage(reportId: report['id'].toString()),
      ),
    );

    if (result == true) {
      _loadReports(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // 精简的Tab栏
          Container(
            color: AppTheme.cardBackground,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle:
                  TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              indicatorWeight: 2.0,
              tabs: [
                Tab(text: '举报列表'),
                Tab(text: '处罚记录'),
              ],
            ),
          ),
          // Tab内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReportListTab(),
                const PenaltyManagementPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportListTab() {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _isLoading && _reports.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _reports.isEmpty
                  ? Center(
                      child: Text(
                        '暂无举报记录',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16.sp,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadReports(refresh: true),
                      child: ListView.builder(
                        padding: EdgeInsets.all(8.w),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return _buildReportItem(report);
                        },
                      ),
                    ),
        ),
        _buildPagination(),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '搜索关键词',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                  ),
                  onChanged: (value) => _searchKeyword = value,
                  onSubmitted: (_) => _loadReports(refresh: true),
                ),
              ),
              SizedBox(width: 8.w),
              ElevatedButton.icon(
                onPressed: () => _loadReports(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('刷新'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  title: '状态',
                  value: _selectedStatus,
                  items: ReportStatus.getOptions(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _loadReports(refresh: true);
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildDropdown(
                  title: '类型',
                  value: _selectedReportType,
                  items: ReportType.getOptions(),
                  onChanged: (value) {
                    setState(() => _selectedReportType = value);
                    _loadReports(refresh: true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String title,
    required int value,
    required List<Map<String, dynamic>> items,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              borderRadius: BorderRadius.circular(8.r),
              items: items.map((item) {
                return DropdownMenuItem<int>(
                  value: item['value'],
                  child: Text(
                    item['label'],
                    style: TextStyle(fontSize: 14.sp),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportItem(dynamic report) {
    final int status = report['status'] ?? ReportStatus.pending;
    final int reportType = report['report_type'] ?? ReportType.illegal;

    Color statusColor;
    switch (status) {
      case ReportStatus.pending:
        statusColor = Colors.orange;
        break;
      case ReportStatus.approved:
        statusColor = Colors.green;
        break;
      case ReportStatus.rejected:
        statusColor = Colors.red;
        break;
      case ReportStatus.handled:
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(report),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${report['id']} - ${report['item_title'] ?? '未知内容'}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      ReportStatus.getName(status),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.report_problem_outlined,
                    size: 14.sp,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    ReportType.getName(reportType),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Icon(
                    Icons.person_outline,
                    size: 14.sp,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '举报人: ${report['reporter_name'] ?? '未知'}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                report['content'] ?? '无举报内容',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '举报时间: ${_formatDateTime(report['created_at'])}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '查看详情 >',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
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

  Widget _buildPagination() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadReports();
                  }
                : null,
            color: _currentPage > 1 ? AppTheme.primaryColor : Colors.grey,
          ),
          Text(
            '$_currentPage / $_totalPages',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadReports();
                  }
                : null,
            color: _currentPage < _totalPages
                ? AppTheme.primaryColor
                : Colors.grey,
          ),
          Text(
            '共 $_totalItems 条',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '未知时间';
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '时间格式错误';
    }
  }
}
