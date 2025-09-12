import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import 'violation_monitoring_service.dart';
import 'violation_detail_page.dart';

class ViolationMonitoringPage extends StatefulWidget {
  const ViolationMonitoringPage({super.key});

  @override
  State<ViolationMonitoringPage> createState() => _ViolationMonitoringPageState();
}

class _ViolationMonitoringPageState extends State<ViolationMonitoringPage> {
  final ViolationMonitoringService _service = ViolationMonitoringService();

  // 筛选条件
  String? _selectedCardType;
  String? _selectedRiskLevel;
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _cardIdController = TextEditingController();
  final TextEditingController _victimIdController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();

  // 分页
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _pageSize = 20;

  // 数据
  List<dynamic> _violations = [];
  bool _isLoading = false;
  bool _isRefreshing = false;

  // 卡片类型选项
  final List<Map<String, String>> _cardTypes = [
    {'value': '', 'label': '全部类型'},
    {'value': 'character_card', 'label': '角色卡'},
    {'value': 'novel_card', 'label': '小说卡'},
    {'value': 'group_chat_card', 'label': '群聊卡'},
  ];

  // 风控级别选项
  final List<Map<String, String>> _riskLevels = [
    {'value': '', 'label': '全部级别'},
    {'value': 'suspicious', 'label': '可疑行为'},
    {'value': 'malicious', 'label': '恶意行为'},
  ];

  @override
  void initState() {
    super.initState();
    _loadViolations();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _cardIdController.dispose();
    _victimIdController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  Future<void> _loadViolations() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _service.getViolations(
        page: _currentPage,
        pageSize: _pageSize,
        userId: _userIdController.text.isNotEmpty ? int.tryParse(_userIdController.text) : null,
        relatedCardId: _cardIdController.text.isNotEmpty ? int.tryParse(_cardIdController.text) : null,
        cardType: _selectedCardType?.isNotEmpty == true ? _selectedCardType : null,
        riskLevel: _selectedRiskLevel?.isNotEmpty == true ? _selectedRiskLevel : null,
        victimId: _victimIdController.text.isNotEmpty ? int.tryParse(_victimIdController.text) : null,
        relatedCardName: _cardNameController.text.isNotEmpty ? _cardNameController.text : null,
      );

      if (response['code'] == 0) {
        final data = response['data'];
        setState(() {
          _violations = data['items'] ?? [];
          _totalItems = data['total'] ?? 0;
          _totalPages = (_totalItems / _pageSize).ceil();
        });
      } else {
        if (mounted) {
          CustomToast.show(context, message: response['msg'] ?? '获取数据失败', type: ToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '获取数据失败: $e', type: ToastType.error);
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
      _currentPage = 1;
    });
    await _loadViolations();
  }

  void _resetFilters() {
    setState(() {
      _selectedCardType = null;
      _selectedRiskLevel = null;
      _userIdController.clear();
      _cardIdController.clear();
      _victimIdController.clear();
      _cardNameController.clear();
      _currentPage = 1;
    });
    _loadViolations();
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 1;
    });
    _loadViolations();
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
      _loadViolations();
    }
  }

  String _getCardTypeLabel(String? cardType) {
    switch (cardType) {
      case 'character_card':
        return '角色卡';
      case 'novel_card':
        return '小说卡';
      case 'group_chat_card':
        return '群聊卡';
      default:
        return '未知';
    }
  }

  String _getRiskLevelLabel(String? riskLevel) {
    switch (riskLevel) {
      case 'suspicious':
        return '可疑行为';
      case 'malicious':
        return '恶意行为';
      default:
        return '未知';
    }
  }

  Color _getRiskLevelColor(String? riskLevel) {
    switch (riskLevel) {
      case 'suspicious':
        return Colors.orange;
      case 'malicious':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildViolationCard(Map<String, dynamic> violation) {
    final primaryColor = AppTheme.primaryColor;
    final surfaceColor = AppTheme.cardBackground;
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;

    final riskLevels = violation['risk_levels'] as List<dynamic>? ?? [];
    final latestRisk = riskLevels.isNotEmpty ? riskLevels.last : null;
    final riskLevel = latestRisk?['risk_level'] as String?;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      color: surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViolationDetailPage(
                violationId: violation['id'],
              ),
            ),
          ).then((_) => _loadViolations());
        },
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部信息
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _getRiskLevelColor(riskLevel).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border.all(
                        color: _getRiskLevelColor(riskLevel),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getRiskLevelLabel(riskLevel),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: _getRiskLevelColor(riskLevel),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      _getCardTypeLabel(violation['card_type']),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ID: ${violation['id']}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // 卡片信息
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          violation['related_card_name'] ?? '未知卡片',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '卡片ID: ${violation['related_card_id'] ?? '未知'}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '用户ID: ${violation['user_id']}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: textSecondary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '被害人ID: ${violation['victim_id'] ?? '未知'}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // 最新风控信息
              if (latestRisk != null) ...[
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_outlined,
                            size: 16.sp,
                            color: _getRiskLevelColor(riskLevel),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '最新检测',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            latestRisk['time'] ?? '',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        latestRisk['reason'] ?? '无原因说明',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
              ],

              // 底部信息
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14.sp,
                    color: textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '创建时间: ${violation['created_at'] ?? ''}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '会话数: ${(violation['session_ids'] as List<dynamic>?)?.length ?? 0}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: textSecondary,
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryColor;
    final background = AppTheme.background;
    final surfaceColor = AppTheme.cardBackground;
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          // 筛选区域
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // 第一行筛选条件
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _userIdController,
                        decoration: InputDecoration(
                          labelText: '用户ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: _cardIdController,
                        decoration: InputDecoration(
                          labelText: '卡片ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: _victimIdController,
                        decoration: InputDecoration(
                          labelText: '被害人ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // 第二行筛选条件
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCardType,
                        decoration: InputDecoration(
                          labelText: '卡片类型',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                        ),
                        items: _cardTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type['value'],
                            child: Text(type['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCardType = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRiskLevel,
                        decoration: InputDecoration(
                          labelText: '风控级别',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                        ),
                        items: _riskLevels.map((level) {
                          return DropdownMenuItem<String>(
                            value: level['value'],
                            child: Text(level['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRiskLevel = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: _cardNameController,
                        decoration: InputDecoration(
                          labelText: '卡片名称',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // 操作按钮
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _applyFilters,
                      icon: Icon(Icons.search, size: 16.sp),
                      label: Text('搜索'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    OutlinedButton.icon(
                      onPressed: _resetFilters,
                      icon: Icon(Icons.refresh, size: 16.sp),
                      label: Text('重置'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 数据统计
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '共 $_totalItems 条记录',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: textSecondary,
                  ),
                ),
                const Spacer(),
                if (_isRefreshing)
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
              ],
            ),
          ),

          // 列表内容
          Expanded(
            child: _isLoading && _violations.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : _violations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64.sp,
                              color: textSecondary.withOpacity(0.5),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              '暂无违规监测记录',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshData,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: _violations.length,
                          itemBuilder: (context, index) {
                            final violation = _violations[index];
                            return _buildViolationCard(violation);
                          },
                        ),
                      ),
          ),

          // 分页控件
          if (_totalPages > 1)
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                    icon: Icon(Icons.chevron_left),
                    color: primaryColor,
                  ),
                  Text(
                    '$_currentPage / $_totalPages',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                    icon: Icon(Icons.chevron_right),
                    color: primaryColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
