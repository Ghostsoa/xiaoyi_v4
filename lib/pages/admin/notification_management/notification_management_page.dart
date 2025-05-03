import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import 'notification_service.dart';
import 'create_notification_page.dart';

class NotificationManagementPage extends StatefulWidget {
  const NotificationManagementPage({super.key});

  @override
  State<NotificationManagementPage> createState() =>
      _NotificationManagementPageState();
}

class _NotificationManagementPageState
    extends State<NotificationManagementPage> {
  final NotificationService _notificationService = NotificationService();

  // 列表数据
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalItems = 0;
  int _totalPages = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // 加载通知列表
  Future<void> _loadNotifications() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _notificationService.getNotifications(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (result['code'] == 0) {
        final data = result['data'];
        setState(() {
          _notifications = data['notifications'] ?? [];
          _totalItems = data['total'] ?? 0;
          _totalPages = (_totalItems / _pageSize).ceil();
        });
      } else {
        _showErrorToast('获取失败: ${result['msg']}');
      }
    } catch (e) {
      _showErrorToast('加载通知列表失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 删除通知
  Future<void> _deleteNotification(int notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      _showSuccessToast('通知已删除');
      _loadNotifications(); // 刷新列表
    } catch (e) {
      _showErrorToast('删除通知失败: $e');
    }
  }

  // 确认删除通知
  Future<void> _confirmDeleteNotification(int notificationId) async {
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('确认删除'),
            content: Text('确定要删除该通知吗？此操作不可撤销，将移除所有用户收到的此通知。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: Text('删除'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      _deleteNotification(notificationId);
    }
  }

  // 显示创建通知页面
  void _showCreateNotificationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNotificationPage(
          onNotificationCreated: () {
            _currentPage = 1;
            _loadNotifications();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryColor;
    final background = AppTheme.background;
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;
    final surfaceColor = AppTheme.cardBackground;

    return Scaffold(
      backgroundColor: background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部标题和创建按钮
          Container(
            padding: EdgeInsets.all(16.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '通知管理',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateNotificationPage,
                  icon: Icon(Icons.add),
                  label: Text('创建通知'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 列表区域
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 列表标题
                  Row(
                    children: [
                      Text(
                        '通知列表',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        '共 $_totalItems 条记录',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // 通知列表
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : _notifications.isEmpty
                            ? Center(
                                child: Text(
                                  '暂无通知数据',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: textSecondary,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _notifications.length,
                                itemBuilder: (context, index) {
                                  final notification = _notifications[index];

                                  // 解析创建时间
                                  String createdAt = '';
                                  if (notification['created_at'] != null) {
                                    try {
                                      final dateTime = DateTime.parse(
                                          notification['created_at']);
                                      createdAt =
                                          '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                                    } catch (e) {
                                      createdAt =
                                          notification['created_at'].toString();
                                    }
                                  }

                                  // 根据级别设置标签颜色
                                  int level = notification['level'] ?? 0;
                                  Color levelColor;
                                  String levelText;

                                  switch (level) {
                                    case 1:
                                      levelColor = AppTheme.warning;
                                      levelText = '重要';
                                      break;
                                    case 2:
                                      levelColor = AppTheme.error;
                                      levelText = '紧急';
                                      break;
                                    case 0:
                                    default:
                                      levelColor = AppTheme.success;
                                      levelText = '普通';
                                      break;
                                  }

                                  // 根据类型设置图标
                                  IconData typeIcon;
                                  String typeText;

                                  switch (notification['type']) {
                                    case 'activity':
                                      typeIcon = Icons.event;
                                      typeText = '活动通知';
                                      break;
                                    case 'update':
                                      typeIcon = Icons.system_update;
                                      typeText = '更新通知';
                                      break;
                                    case 'reminder':
                                      typeIcon = Icons.notifications_active;
                                      typeText = '提醒通知';
                                      break;
                                    case 'promotion':
                                      typeIcon = Icons.local_offer;
                                      typeText = '促销通知';
                                      break;
                                    case 'system':
                                    default:
                                      typeIcon = Icons.info;
                                      typeText = '系统通知';
                                      break;
                                  }

                                  // 是否广播
                                  final isBroadcast =
                                      notification['is_broadcast'] ?? false;

                                  return Container(
                                    margin: EdgeInsets.only(bottom: 16.h),
                                    padding: EdgeInsets.all(16.r),
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(8.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 10,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 通知标题和操作
                                        Row(
                                          children: [
                                            // 通知类型图标
                                            Container(
                                              padding: EdgeInsets.all(8.r),
                                              decoration: BoxDecoration(
                                                color: primaryColor
                                                    .withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                typeIcon,
                                                color: primaryColor,
                                                size: 16.sp,
                                              ),
                                            ),
                                            SizedBox(width: 12.w),

                                            // 通知标题
                                            Expanded(
                                              child: Text(
                                                notification['title'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),

                                            // 删除按钮
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: Colors.red.shade300,
                                                size: 20.sp,
                                              ),
                                              tooltip: '删除通知',
                                              onPressed: () =>
                                                  _confirmDeleteNotification(
                                                      notification['id']),
                                            ),
                                          ],
                                        ),

                                        // 时间显示
                                        Padding(
                                          padding: EdgeInsets.only(
                                              left: 8.w, top: 4.h, bottom: 8.h),
                                          child: Text(
                                            '发布时间: $createdAt',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ),

                                        SizedBox(height: 4.h),

                                        // 通知内容
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(12.r),
                                          decoration: BoxDecoration(
                                            color:
                                                surfaceColor.withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(6.r),
                                          ),
                                          child: Text(
                                            notification['content'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color:
                                                  textPrimary.withOpacity(0.8),
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(height: 16.h),

                                        // 底部标签行
                                        Row(
                                          children: [
                                            // 通知级别
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8.w,
                                                  vertical: 4.h),
                                              decoration: BoxDecoration(
                                                color:
                                                    levelColor.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4.r),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 8.r,
                                                    height: 8.r,
                                                    decoration: BoxDecoration(
                                                      color: levelColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  SizedBox(width: 6.w),
                                                  Text(
                                                    levelText,
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color: levelColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 12.w),

                                            // 通知类型
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8.w,
                                                  vertical: 4.h),
                                              decoration: BoxDecoration(
                                                color: primaryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4.r),
                                              ),
                                              child: Text(
                                                typeText,
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12.w),

                                            // 发送方式
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8.w,
                                                  vertical: 4.h),
                                              decoration: BoxDecoration(
                                                color: isBroadcast
                                                    ? Colors.blue
                                                        .withOpacity(0.1)
                                                    : Colors.purple
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4.r),
                                              ),
                                              child: Text(
                                                isBroadcast ? '全部用户' : '指定用户',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: isBroadcast
                                                      ? Colors.blue
                                                      : Colors.purple,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),

                  // 分页控制
                  if (_totalItems > 0)
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '共 $_totalItems 条记录，每页 $_pageSize 条',
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
                                        _loadNotifications();
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
                                  '$_currentPage / $_totalPages',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.chevron_right),
                                onPressed:
                                    (_currentPage < _totalPages && !_isLoading)
                                        ? () {
                                            setState(() {
                                              _currentPage++;
                                            });
                                            _loadNotifications();
                                          }
                                        : null,
                                color: _currentPage < _totalPages && !_isLoading
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
          ),
        ],
      ),
    );
  }

  // 显示错误提示
  void _showErrorToast(String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.error,
    );
  }

  // 显示成功提示
  void _showSuccessToast(String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.success,
    );
  }
}
