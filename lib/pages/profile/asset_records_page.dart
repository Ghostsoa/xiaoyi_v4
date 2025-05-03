import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_toast.dart';
import 'profile_server.dart';

class AssetRecordsPage extends StatefulWidget {
  final String? assetType;
  final String title;

  const AssetRecordsPage({
    super.key,
    this.assetType,
    this.title = '资产记录',
  });

  @override
  State<AssetRecordsPage> createState() => _AssetRecordsPageState();
}

class _AssetRecordsPageState extends State<AssetRecordsPage>
    with SingleTickerProviderStateMixin {
  final ProfileServer _profileServer = ProfileServer();
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  late AnimationController _shimmerController;

  List<dynamic> _records = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalRecords = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
    _loadRecords();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    try {
      final result = await _profileServer.getAssetRecords(
        assetType: widget.assetType,
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        if (result['success']) {
          final data = result['data'];
          _records = data['records'] ?? [];
          _totalRecords = data['total'] ?? 0;
        } else {
          // 显示错误消息
          CustomToast.show(
            context,
            message: result['msg'],
            type: ToastType.error,
          );
          _records = [];
          _totalRecords = 0;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _records = [];
        _totalRecords = 0;
      });

      if (mounted) {
        CustomToast.show(
          context,
          message: e.toString(),
          type: ToastType.error,
        );
      }
    }
  }

  void _onRefresh() async {
    try {
      final result = await _profileServer.getAssetRecords(
        assetType: widget.assetType,
        page: 1,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (result['success']) {
            final data = result['data'];
            _records = data['records'] ?? [];
            _totalRecords = data['total'] ?? 0;
            _currentPage = 1;
            _refreshController.refreshCompleted();
          } else {
            // 显示错误消息
            CustomToast.show(
              context,
              message: result['msg'],
              type: ToastType.error,
            );
            _refreshController.refreshFailed();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: e.toString(),
          type: ToastType.error,
        );
        _refreshController.refreshFailed();
      }
    }
  }

  void _onLoading() async {
    if (_records.length >= _totalRecords) {
      _refreshController.loadNoData();
      return;
    }

    try {
      final nextPage = _currentPage + 1;
      final result = await _profileServer.getAssetRecords(
        assetType: widget.assetType,
        page: nextPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        if (result['success']) {
          final data = result['data'];
          final newRecords = data['records'] ?? [];

          if (newRecords.isNotEmpty) {
            setState(() {
              _records.addAll(newRecords);
              _currentPage = nextPage;
            });
            _refreshController.loadComplete();
          } else {
            _refreshController.loadNoData();
          }
        } else {
          // 显示错误消息
          CustomToast.show(
            context,
            message: result['msg'],
            type: ToastType.error,
          );
          _refreshController.loadFailed();
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: e.toString(),
          type: ToastType.error,
        );
        _refreshController.loadFailed();
      }
    }
  }

  // 构建骨架加载项
  Widget _buildRecordSkeleton() {
    final baseColor = AppTheme.cardBackground;
    final highlightColor = AppTheme.primaryDark.withOpacity(0.3);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.border.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    baseColor,
                    highlightColor,
                    baseColor,
                  ],
                  stops: const [
                    0.0,
                    0.5,
                    1.0,
                  ],
                  begin: Alignment(-1.0 + 2 * _shimmerController.value, 0.0),
                  end: Alignment(1.0 + 2 * _shimmerController.value, 0.0),
                  tileMode: TileMode.clamp,
                ).createShader(bounds);
              },
              child: child,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 资产类型标志
                  Container(
                    width: 50.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // 变动类型
                  Container(
                    width: 40.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  Spacer(),
                  // 变动金额
                  Container(
                    width: 70.w,
                    height: 20.h,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // 描述
              Container(
                width: double.infinity,
                height: 16.h,
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: 200.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 8.h),
              // 底部信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 时间
                  Container(
                    width: 120.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  // 余额
                  Container(
                    width: 80.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4.r),
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

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime =
          DateTime.parse(dateTimeStr).add(const Duration(hours: 8));
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  String _getAssetTypeLabel(String assetType) {
    switch (assetType) {
      case 'coin':
        return '小懿币';
      case 'exp':
        return '经验值';
      case 'play_time':
        return '畅玩时长';
      default:
        return '未知类型';
    }
  }

  Color _getChangeTypeColor(String changeType) {
    switch (changeType) {
      case 'income':
        return AppTheme.success;
      case 'expense':
        return AppTheme.error;
      default:
        return AppTheme.textPrimary;
    }
  }

  String _getChangePrefix(String changeType) {
    return changeType == 'income' ? '+' : '-';
  }

  String _getChangeTypeLabel(String changeType) {
    switch (changeType) {
      case 'income':
        return '获得';
      case 'expense':
        return '消耗';
      default:
        return '变动';
    }
  }

  LinearGradient _getStatusGradient(String status) {
    switch (status) {
      case 'success':
        return LinearGradient(
          colors: AppTheme.successGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'warning':
        return LinearGradient(
          colors: AppTheme.warningGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'error':
        return LinearGradient(
          colors: AppTheme.errorGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: AppTheme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: Text(
          widget.title,
          style: AppTheme.titleStyle,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textPrimary,
            size: 20.sp,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return _buildRecordSkeleton();
                },
              ),
            )
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 60.sp,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '暂无资产记录',
                        style: AppTheme.secondaryStyle,
                      ),
                    ],
                  ),
                )
              : SmartRefresher(
                  enablePullDown: true,
                  enablePullUp: _records.length < _totalRecords,
                  header: ClassicHeader(
                    refreshStyle: RefreshStyle.Follow,
                    idleText: '下拉刷新',
                    releaseText: '松开刷新',
                    refreshingText: '正在刷新...',
                    completeText: '刷新成功 ',
                    failedText: '刷新失败',
                    textStyle: AppTheme.secondaryStyle,
                    iconPos: IconPosition.left,
                    spacing: 8,
                    completeIcon: Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.success,
                      size: 18.sp,
                    ),
                  ),
                  footer: CustomFooter(
                    builder: (context, mode) {
                      Widget body;
                      if (mode == LoadStatus.idle) {
                        body = Text("上拉加载更多", style: AppTheme.secondaryStyle);
                      } else if (mode == LoadStatus.loading) {
                        body = const CircularProgressIndicator.adaptive(
                            strokeWidth: 2);
                      } else if (mode == LoadStatus.failed) {
                        body = Text("加载失败，点击重试",
                            style: TextStyle(color: AppTheme.error));
                      } else if (mode == LoadStatus.canLoading) {
                        body = Text("松开加载更多", style: AppTheme.secondaryStyle);
                      } else {
                        body = Text("没有更多数据了", style: AppTheme.secondaryStyle);
                      }
                      return SizedBox(
                        height: 55.0,
                        child: Center(child: body),
                      );
                    },
                  ),
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  onLoading: _onLoading,
                  child: ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      final changeType = record['change_type'] ?? '';
                      final assetType = record['asset_type'] ?? '';
                      final amount = record['amount'] ?? 0;
                      final balance = record['balance'] ?? 0;
                      final description = record['description'] ?? '';
                      final createdAt = record['created_at'] ?? '';

                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 2),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // 资产类型标志
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: assetType == 'coin'
                                          ? Colors.amber.withOpacity(0.2)
                                          : assetType == 'exp'
                                              ? Colors.blue.withOpacity(0.2)
                                              : Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      _getAssetTypeLabel(assetType),
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w500,
                                        color: assetType == 'coin'
                                            ? Colors.amber[800]
                                            : assetType == 'exp'
                                                ? Colors.blue[800]
                                                : Colors.green[800],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  // 变动类型
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: changeType == 'income'
                                          ? AppTheme.success.withOpacity(0.15)
                                          : AppTheme.error.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      _getChangeTypeLabel(changeType),
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w500,
                                        color: changeType == 'income'
                                            ? AppTheme.success
                                            : AppTheme.error,
                                      ),
                                    ),
                                  ),
                                  Spacer(),
                                  // 变动金额
                                  Text(
                                    '${_getChangePrefix(changeType)}$amount',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: _getChangeTypeColor(changeType),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              // 描述
                              Text(
                                description,
                                style: AppTheme.secondaryStyle,
                              ),
                              SizedBox(height: 8.h),
                              // 底部信息
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // 时间
                                  Text(
                                    _formatDateTime(createdAt),
                                    style: AppTheme.secondaryStyle,
                                  ),
                                  // 余额，根据资产类型显示不同名称
                                  Text(
                                    assetType == 'coin'
                                        ? '小懿币: $balance'
                                        : assetType == 'exp'
                                            ? '经验值: $balance'
                                            : assetType == 'play_time'
                                                ? '畅玩时长: $balance小时'
                                                : '余额: $balance',
                                    style: AppTheme.secondaryStyle,
                                  ),
                                ],
                              ),
                              if (assetType == 'play_time' &&
                                  record['play_time_expire_at'] != null) ...[
                                SizedBox(height: 8.h),
                                Text(
                                  '有效期至: ${_formatDateTime(record['play_time_expire_at'])}',
                                  style: AppTheme.secondaryStyle,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
