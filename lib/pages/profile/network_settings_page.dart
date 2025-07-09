import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_theme.dart';
import '../../services/network_monitor_service.dart';
import '../../widgets/custom_toast.dart';

class NetworkSettingsPage extends StatefulWidget {
  const NetworkSettingsPage({super.key});

  @override
  State<NetworkSettingsPage> createState() => _NetworkSettingsPageState();
}

class _NetworkSettingsPageState extends State<NetworkSettingsPage> {
  final NetworkMonitorService _networkService = NetworkMonitorService();

  bool _isLoading = true;
  bool _isRefreshing = false;
  String _currentEndpoint = '';
  List<EndpointInfo> _defaultEndpoints = [];
  List<EndpointInfo> _customEndpoints = [];
  Map<String, dynamic> _endpointStatus = {};

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _editNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    _editNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取当前线路
      final currentEndpoint = await _networkService.getCurrentEndpoint();

      // 获取默认线路和自定义线路
      final defaultEndpoints = _networkService.getDefaultEndpoints();
      final customEndpoints = _networkService.getCustomEndpoints();

      // 获取所有线路状态
      final statusData = await _networkService.getAllEndpointStatus();

      setState(() {
        _currentEndpoint = currentEndpoint;
        _defaultEndpoints = defaultEndpoints;
        _customEndpoints = customEndpoints;
        _endpointStatus = statusData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showToast('加载线路信息失败: $e', ToastType.error);
    }
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // 刷新所有线路状态
      await _networkService.refreshEndpointStatus();

      // 重新获取状态数据
      final statusData = await _networkService.getAllEndpointStatus();

      setState(() {
        _endpointStatus = statusData;
        _isRefreshing = false;
      });

      _showToast('线路状态刷新成功', ToastType.success);
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
      _showToast('刷新线路状态失败: $e', ToastType.error);
    }
  }

  Future<void> _switchEndpoint(String url) async {
    final previousEndpoint = _currentEndpoint;

    setState(() {
      _currentEndpoint = url;
    });

    try {
      await _networkService.setCurrentEndpoint(url);
      _showToast('切换线路成功', ToastType.success);
    } catch (e) {
      setState(() {
        _currentEndpoint = previousEndpoint;
      });
      _showToast('切换线路失败: $e', ToastType.error);
    }
  }

  Future<void> _addCustomEndpoint() async {
    final url = _urlController.text.trim();
    final name = _nameController.text.trim();

    if (url.isEmpty) {
      _showToast('请输入线路URL', ToastType.warning);
      return;
    }

    if (name.isEmpty) {
      _showToast('请输入线路名称', ToastType.warning);
      return;
    }

    final addButtonKey = GlobalKey();
    showLoadingOverAddButton(addButtonKey);

    try {
      final success = await _networkService.addCustomEndpoint(url, name);

      if (success) {
        _urlController.clear();
        _nameController.clear();

        final newCustomEndpoint =
            EndpointInfo(url: url, name: name, isDefault: false);
        final statusData = await _networkService.getAllEndpointStatus();

        setState(() {
          _customEndpoints.add(newCustomEndpoint);
          _endpointStatus = statusData;
        });

        _showToast('添加自定义线路成功', ToastType.success);
      } else {
        _showToast('添加自定义线路失败: 可能URL格式不正确或线路已存在', ToastType.error);
      }
    } catch (e) {
      _showToast('添加自定义线路失败: $e', ToastType.error);
    } finally {
      hideLoadingOverlay();
    }
  }

  OverlayEntry? _overlayEntry;

  void showLoadingOverAddButton(GlobalKey key) {
    hideLoadingOverlay();
  }

  void hideLoadingOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _removeCustomEndpoint(String url) async {
    final removedIndex = _customEndpoints.indexWhere((e) => e.url == url);
    if (removedIndex == -1) return;

    final removedEndpoint = _customEndpoints[removedIndex];

    setState(() {
      _customEndpoints.removeAt(removedIndex);
    });

    try {
      final success = await _networkService.removeCustomEndpoint(url);

      if (!success) {
        setState(() {
          _customEndpoints.insert(removedIndex, removedEndpoint);
        });
        _showToast('删除自定义线路失败', ToastType.error);
      } else {
        _showToast('删除自定义线路成功', ToastType.success);

        if (_currentEndpoint == url) {
          final defaultUrl = _defaultEndpoints.isNotEmpty
              ? _defaultEndpoints.first.url
              : (_customEndpoints.isNotEmpty ? _customEndpoints.first.url : '');

          if (defaultUrl.isNotEmpty) {
            await _switchEndpoint(defaultUrl);
          }
        }
      }
    } catch (e) {
      setState(() {
        _customEndpoints.insert(removedIndex, removedEndpoint);
      });
      _showToast('删除自定义线路失败: $e', ToastType.error);
    }
  }

  Future<void> _updateEndpointName(String url, String currentName) async {
    _editNameController.text = currentName;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('修改线路名称',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            )),
        content: TextField(
          controller: _editNameController,
          decoration: InputDecoration(
            hintText: '请输入新的线路名称',
            hintStyle:
                TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppTheme.border.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
            child: Text('取消', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _editNameController.text.trim()),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
            child: Text('确认', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentName) {
      setState(() {
        for (final endpoint in _defaultEndpoints) {
          if (endpoint.url == url) {
            endpoint.name = result;
            break;
          }
        }

        for (final endpoint in _customEndpoints) {
          if (endpoint.url == url) {
            endpoint.name = result;
            break;
          }
        }
      });

      try {
        final success = await _networkService.updateEndpointName(url, result);
        if (success) {
          _showToast('修改线路名称成功', ToastType.success);
        } else {
          _showToast('修改线路名称失败', ToastType.error);
        }
      } catch (e) {
        _showToast('修改线路名称失败: $e', ToastType.error);
      }
    }
  }

  void _showToast(String message, ToastType type) {
    if (!mounted) return;
    CustomToast.show(context, message: message, type: type);
  }

  String _getResponseTimeDisplay(String url) {
    final endpointsMap = _endpointStatus['endpoints'] as Map<String, dynamic>?;
    if (endpointsMap == null) return '未知';

    final data = endpointsMap[url] as Map<String, dynamic>?;
    if (data == null) return '未知';

    final isAvailable = data['available'] as bool? ?? false;
    if (!isAvailable) return '不可用';

    final responseTime = data['responseTime'] as int? ?? 9999;
    return '${responseTime}ms';
  }

  Widget _buildEndpointItem(EndpointInfo endpoint, bool isSelected) {
    final url = endpoint.url;
    final name = endpoint.name;
    final isDefault = endpoint.isDefault;
    final responseTimeText = _getResponseTimeDisplay(url);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryColor.withOpacity(0.1)
            : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryColor
              : AppTheme.border.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        title: Text(name,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            )),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Row(
              children: [
                Text('延迟: ',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12.sp)),
                Text(
                  responseTimeText,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: responseTimeText == '不可用'
                        ? Colors.red
                        : responseTimeText == '未知'
                            ? AppTheme.textSecondary
                            : Colors.green,
                  ),
                ),
                if (isDefault) ...[
                  SizedBox(width: 12.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      '默认',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () {
          if (_currentEndpoint != url) {
            _switchEndpoint(url);
          }
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon:
                  Icon(Icons.edit, size: 20.sp, color: AppTheme.textSecondary),
              onPressed: () => _updateEndpointName(url, name),
              tooltip: '修改名称',
            ),
            if (!isDefault)
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20.sp, color: Colors.red.shade300),
                onPressed: () => _removeCustomEndpoint(url),
                tooltip: '删除线路',
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('网络线路设置'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.refresh, color: AppTheme.textPrimary),
                onPressed: _isRefreshing ? null : _refreshStatus,
                tooltip: '刷新线路状态',
              ),
              if (_isRefreshing)
                SizedBox(
                  width: 20.sp,
                  height: 20.sp,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 32.sp,
                    height: 32.sp,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text('加载中...',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('默认线路',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      )),
                  SizedBox(height: 12.h),
                  ...List.generate(
                    _defaultEndpoints.length,
                    (index) => _buildEndpointItem(
                      _defaultEndpoints[index],
                      _currentEndpoint == _defaultEndpoints[index].url,
                    ),
                  ),
                  if (_customEndpoints.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    Text('自定义线路',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        )),
                    SizedBox(height: 12.h),
                    ...List.generate(
                      _customEndpoints.length,
                      (index) => _buildEndpointItem(
                        _customEndpoints[index],
                        _currentEndpoint == _customEndpoints[index].url,
                      ),
                    ),
                  ],
                  SizedBox(height: 24.h),
                  Text('添加自定义线路',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      )),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(8.r),
                      border:
                          Border.all(color: AppTheme.border.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: '线路名称',
                            hintText: '请输入线路名称',
                            labelStyle: TextStyle(color: AppTheme.textPrimary),
                            hintStyle: TextStyle(
                                color: AppTheme.textSecondary.withOpacity(0.5)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                        SizedBox(height: 12.h),
                        TextField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            labelText: '线路URL',
                            hintText: '请输入线路URL，如: https://example.com',
                            labelStyle: TextStyle(color: AppTheme.textPrimary),
                            hintStyle: TextStyle(
                                color: AppTheme.textSecondary.withOpacity(0.5)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          key: GlobalKey(),
                          onPressed: _addCustomEndpoint,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            minimumSize: Size(double.infinity, 48.h),
                          ),
                          child: Text('添加',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
