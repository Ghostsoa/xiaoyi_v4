import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import 'user_management_service.dart';
import '../../../widgets/custom_toast.dart';

class UserAssetRecordsPage extends StatefulWidget {
  final int userId;
  final String username;

  const UserAssetRecordsPage({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<UserAssetRecordsPage> createState() => _UserAssetRecordsPageState();
}

class _UserAssetRecordsPageState extends State<UserAssetRecordsPage> {
  final UserManagementService _userService = UserManagementService();
  String _selectedAssetType = '全部';
  int _currentPage = 1;
  final int _pageSize = 10;
  int _totalRecords = 0;
  bool _isLoading = false;
  List<dynamic> _records = [];
  Map<String, dynamic>? _userAsset;

  @override
  void initState() {
    super.initState();
    _loadUserAsset();
    _loadRecords();
  }

  // 加载用户资产信息
  Future<void> _loadUserAsset() async {
    try {
      final result = await _userService.getUserAsset(widget.userId);
      setState(() {
        _userAsset = result['data'];
      });
    } catch (e) {
      _showErrorToast('加载用户资产信息失败: $e');
    }
  }

  // 加载资产变动记录
  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? assetType;
      if (_selectedAssetType == '小懿币') {
        assetType = 'coin';
      } else if (_selectedAssetType == '经验值') {
        assetType = 'exp';
      } else if (_selectedAssetType == '畅玩时长') {
        assetType = 'play_time';
      } else if (_selectedAssetType == 'VIP') {
        assetType = 'vip';
      }

      final result = await _userService.getUserAssetRecords(
        widget.userId,
        assetType: assetType,
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        _records = result['data']['records'];
        _totalRecords = result['data']['total'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorToast('加载资产记录失败: $e');
    }
  }

  // 显示错误提示
  void _showErrorToast(String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.error,
    );
  }

  // 格式化日期时间（带时区调整：+8小时）
  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).add(const Duration(hours: 8));
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  // 计算剩余天数
  String _calculateRemainingDays(String? expiryDateStr) {
    if (expiryDateStr == null) return '';
    try {
      final expiryDate =
          DateTime.parse(expiryDateStr).add(const Duration(hours: 8));
      final now = DateTime.now();
      final difference = expiryDate.difference(now);
      final days = difference.inHours / 24.0;

      if (days <= 0) return '已过期';
      return '剩余 ${days.toStringAsFixed(1)} 天';
    } catch (e) {
      return '';
    }
  }

  // 获取资产类型显示文本
  String _getAssetTypeText(String type) {
    switch (type) {
      case 'coin':
        return '小懿币';
      case 'exp':
        return '经验值';
      case 'play_time':
        return '畅玩时长';
      case 'vip':
        return 'VIP会员';
      default:
        return '未知';
    }
  }

  // 获取变动类型显示文本和颜色
  Map<String, dynamic> _getChangeTypeInfo(String type) {
    switch (type) {
      case 'add':
        return {
          'text': '增加',
          'color': Colors.green,
        };
      case 'deduct':
        return {
          'text': '扣除',
          'color': Colors.red,
        };
      default:
        return {
          'text': '未知',
          'color': Colors.grey,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryColor;
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;
    final surfaceColor = AppTheme.cardBackground;
    final background = AppTheme.background;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text('${widget.username} 的资产记录'),
        backgroundColor: surfaceColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户资产信息卡片
            if (_userAsset != null)
              Card(
                color: surfaceColor,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Lv.${_userAsset!['level']}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _userAsset!['level_name'],
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildAssetItem(
                            '小懿币',
                            _userAsset!['assets']['coin'].toString(),
                            Icons.monetization_on,
                            Colors.amber,
                          ),
                          _buildAssetItem(
                            '经验值',
                            _userAsset!['assets']['exp'].toString(),
                            Icons.star,
                            Colors.blue,
                          ),
                          _buildAssetItem(
                            '畅玩时长',
                            '${_userAsset!['assets']['play_time']}小时',
                            Icons.timer,
                            Colors.purple,
                            subtitle: _userAsset!['assets']
                                        ['play_time_expire_at'] !=
                                    null
                                ? '有效期至：${_formatDateTime(_userAsset!['assets']['play_time_expire_at'])}'
                                : null,
                          ),
                          if (_userAsset!['assets']['vip_expire_at'] != null)
                            _buildAssetItem(
                              'VIP会员',
                              _calculateRemainingDays(
                                  _userAsset!['assets']['vip_expire_at']),
                              Icons.card_membership,
                              Colors.deepOrange,
                              subtitle:
                                  '有效期至：${_formatDateTime(_userAsset!['assets']['vip_expire_at'])}',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 16.h),

            // 筛选区域
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedAssetType,
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: textSecondary),
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        items: ['全部', '小懿币', '经验值', '畅玩时长', 'VIP']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedAssetType = newValue;
                              _currentPage = 1;
                            });
                            _loadRecords();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                SizedBox(
                  height: 40.h,
                  child: TextButton(
                    onPressed: _isLoading ? null : _loadRecords,
                    style: TextButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      disabledBackgroundColor: primaryColor.withOpacity(0.6),
                      disabledForegroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('刷新'),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // 记录列表
            Expanded(
              child: _isLoading && _records.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor))
                  : _records.isEmpty
                      ? Center(
                          child: Text(
                            '没有找到资产记录',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _records.length,
                          itemBuilder: (context, index) {
                            final record = _records[index];
                            final changeTypeInfo =
                                _getChangeTypeInfo(record['change_type']);

                            return Card(
                              color: surfaceColor,
                              child: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8.w,
                                                vertical: 2.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: changeTypeInfo['color']
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(2.r),
                                              ),
                                              child: Text(
                                                changeTypeInfo['text'],
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color:
                                                      changeTypeInfo['color'],
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              _getAssetTypeText(
                                                  record['asset_type']),
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          _formatDateTime(record['created_at']),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            record['description'],
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          record['asset_type'] == 'vip'
                                              ? '${record['change_type'] == 'add' ? '+' : '-'}${record['amount']}天'
                                              : '${record['change_type'] == 'add' ? '+' : '-'}${record['amount']}',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: changeTypeInfo['color'],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (record['asset_type'] == 'play_time' &&
                                        record['play_time_start_at'] != null &&
                                        record['play_time_expire_at'] != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: 8.h),
                                        child: Text(
                                          '有效期：${_formatDateTime(record['play_time_start_at'])} 至 ${_formatDateTime(record['play_time_expire_at'])}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ),
                                    if (record['asset_type'] == 'vip' &&
                                        record['vip_expire_at'] != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: 8.h),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '有效期至：${_formatDateTime(record['vip_expire_at'])}',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: textSecondary,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              _calculateRemainingDays(
                                                  record['vip_expire_at']),
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.deepOrange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // 分页控制
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '共 $_totalRecords 条记录，每页 $_pageSize 条',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left),
                        onPressed: (_currentPage > 1 && !_isLoading)
                            ? () {
                                setState(() {
                                  _currentPage--;
                                });
                                _loadRecords();
                              }
                            : null,
                        color: _currentPage > 1 && !_isLoading
                            ? primaryColor
                            : Colors.grey.withOpacity(0.5),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 4.h),
                        child: Text(
                          '$_currentPage / ${(_totalRecords / _pageSize).ceil()}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right),
                        onPressed: (_currentPage <
                                    (_totalRecords / _pageSize).ceil() &&
                                !_isLoading)
                            ? () {
                                setState(() {
                                  _currentPage++;
                                });
                                _loadRecords();
                              }
                            : null,
                        color:
                            _currentPage < (_totalRecords / _pageSize).ceil() &&
                                    !_isLoading
                                ? primaryColor
                                : Colors.grey.withOpacity(0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetItem(String title, String value, IconData icon, Color color,
      {String? subtitle}) {
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;

    return Column(
      children: [
        Icon(icon, color: color, size: 24.sp),
        SizedBox(height: 4.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            color: textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.sp,
              color: textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
