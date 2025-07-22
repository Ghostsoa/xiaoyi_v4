import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import 'report_constants.dart';
import 'report_management_service.dart';
import 'penalty_detail_page.dart';

class PenaltyManagementPage extends StatefulWidget {
  const PenaltyManagementPage({Key? key}) : super(key: key);

  @override
  State<PenaltyManagementPage> createState() => _PenaltyManagementPageState();
}

class _PenaltyManagementPageState extends State<PenaltyManagementPage> {
  final ReportManagementService _service = ReportManagementService();

  // 筛选条件
  int _selectedStatus = PenaltyStatus.all;
  int _selectedPenaltyType = PenaltyType.all;
  String? _searchKeyword;

  // 分页
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _pageSize = 10;

  // 数据
  List<dynamic> _penalties = [];
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadPenalties();
  }

  Future<void> _loadPenalties({bool refresh = false}) async {
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
      final result = await _service.getPenalties(
        status: _selectedStatus,
        penaltyType: _selectedPenaltyType,
        keyword: _searchKeyword,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (result['code'] == 0) {
        final data = result['data'];
        setState(() {
          _penalties = data['items'] ?? [];
          _totalItems = data['total'] ?? 0;
          _totalPages = (_totalItems / _pageSize).ceil();
          _isLoading = false;
          _isRefreshing = false;
        });
      } else {
        throw Exception(result['msg'] ?? '获取处罚列表失败');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      CustomToast.show(
        context,
        message: '加载处罚列表失败: $e',
        type: ToastType.error,
      );
    }
  }

  Future<void> _navigateToDetail(dynamic penalty) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PenaltyDetailPage(penaltyId: penalty['id'].toString()),
      ),
    );

    if (result == true) {
      _loadPenalties(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _isLoading && _penalties.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _penalties.isEmpty
                  ? Center(
                      child: Text(
                        '暂无处罚记录',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16.sp,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadPenalties(refresh: true),
                      child: ListView.builder(
                        padding: EdgeInsets.all(8.w),
                        itemCount: _penalties.length,
                        itemBuilder: (context, index) {
                          final penalty = _penalties[index];
                          return _buildPenaltyItem(penalty);
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
                  onSubmitted: (_) => _loadPenalties(refresh: true),
                ),
              ),
              SizedBox(width: 8.w),
              ElevatedButton.icon(
                onPressed: () => _loadPenalties(refresh: true),
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
                  items: PenaltyStatus.getOptions(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _loadPenalties(refresh: true);
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildDropdown(
                  title: '处罚类型',
                  value: _selectedPenaltyType,
                  items: PenaltyType.getOptions(),
                  onChanged: (value) {
                    setState(() => _selectedPenaltyType = value);
                    _loadPenalties(refresh: true);
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

  Widget _buildPenaltyItem(dynamic penalty) {
    final int status = penalty['status'] ?? PenaltyStatus.active;
    final int penaltyType = penalty['penalty_type'] ?? PenaltyType.warning;

    Color statusColor;
    switch (status) {
      case PenaltyStatus.active:
        statusColor = Colors.red;
        break;
      case PenaltyStatus.expired:
        statusColor = Colors.grey;
        break;
      case PenaltyStatus.revoked:
        statusColor = Colors.orange;
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
        onTap: () => _navigateToDetail(penalty),
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
                      '#${penalty['id']} - ${penalty['item_title'] ?? '未知内容'}',
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
                      PenaltyStatus.getName(status),
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
                    Icons.gavel,
                    size: 14.sp,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    PenaltyType.getName(penaltyType),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (penaltyType == PenaltyType.authorBanTemp &&
                      penalty['duration'] != null) ...[
                    SizedBox(width: 4.w),
                    Text(
                      '(${penalty['duration']}天)',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  SizedBox(width: 16.w),
                  Icon(
                    Icons.person_outline,
                    size: 14.sp,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      '作者: ${penalty['author_name'] ?? '未知'}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                penalty['reason'] ?? '无处理原因',
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
                    '处罚时间: ${_formatDateTime(penalty['created_at'])}',
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
              if (penalty['status'] == PenaltyStatus.active &&
                  penalty['expiry_time'] != null) ...[
                Divider(height: 16.h),
                Text(
                  '到期时间: ${_formatDateTime(penalty['expiry_time'])}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.red.shade800,
                  ),
                ),
              ]
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
                    _loadPenalties();
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
                    _loadPenalties();
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
