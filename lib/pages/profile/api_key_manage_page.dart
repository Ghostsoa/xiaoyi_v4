import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_toast.dart';
import 'profile_server.dart';

class ApiKeyManagePage extends StatefulWidget {
  const ApiKeyManagePage({super.key});

  @override
  State<ApiKeyManagePage> createState() => _ApiKeyManagePageState();
}

class _ApiKeyManagePageState extends State<ApiKeyManagePage> {
  final ProfileServer _profileServer = ProfileServer();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMsg = '';
  List<dynamic> _apiKeys = [];

  // 添加/编辑API Key的控制器
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  // 加载API密钥列表
  Future<void> _loadApiKeys() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await _profileServer.getApiKeys();

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success']) {
            _apiKeys = result['data'] ?? [];
          } else {
            _hasError = true;
            _errorMsg = result['msg'] ?? '获取API密钥失败';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMsg = '获取API密钥失败: $e';
        });
      }
    }
  }

  // 添加API密钥
  Future<void> _addApiKey() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final apiKey = _apiKeyController.text.trim();
    final endpoint = _endpointController.text.trim();

    // 显示加载指示器
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _profileServer.addApiKey(
        apiKey: apiKey,
        endpoint: endpoint,
      );

      if (mounted) {
        if (result['success']) {
          // 清空输入框
          _apiKeyController.clear();
          _endpointController.clear();

          // 关闭对话框
          Navigator.of(context).pop();

          // 显示成功消息
          _showToast(result['msg'], ToastType.success);

          // 重新加载API密钥列表
          _loadApiKeys();
        } else {
          // 显示错误消息
          _showToast(result['msg'], ToastType.error);
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showToast('添加API密钥失败: $e', ToastType.error);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 更新API密钥
  Future<void> _updateApiKey(int id) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final apiKey = _apiKeyController.text.trim();
    final endpoint = _endpointController.text.trim();

    // 显示加载指示器
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _profileServer.updateApiKey(
        id: id,
        apiKey: apiKey,
        endpoint: endpoint,
      );

      if (mounted) {
        if (result['success']) {
          // 清空输入框
          _apiKeyController.clear();
          _endpointController.clear();

          // 关闭对话框
          Navigator.of(context).pop();

          // 显示成功消息
          _showToast(result['msg'], ToastType.success);

          // 重新加载API密钥列表
          _loadApiKeys();
        } else {
          // 显示错误消息
          _showToast(result['msg'], ToastType.error);
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showToast('更新API密钥失败: $e', ToastType.error);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 删除API密钥
  Future<void> _deleteApiKey(int id) async {
    // 显示加载指示器
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _profileServer.deleteApiKey(id);

      if (mounted) {
        if (result['success']) {
          // 显示成功消息
          _showToast(result['msg'], ToastType.success);

          // 重新加载API密钥列表
          _loadApiKeys();
        } else {
          // 显示错误消息
          _showToast(result['msg'], ToastType.error);
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showToast('删除API密钥失败: $e', ToastType.error);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 显示添加API密钥对话框
  Future<void> _showAddApiKeyDialog() async {
    _apiKeyController.clear();
    _endpointController.text =
        "https://generativelanguage.googleapis.com/v1beta/openai/";

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: Text(
                '添加API密钥',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _apiKeyController,
                        decoration: InputDecoration(
                          labelText: 'API Key',
                          labelStyle: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14.sp,
                          ),
                          hintText: '请输入API Key，例如：sk-xxxx',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.5),
                            fontSize: 12.sp,
                          ),
                          fillColor: AppTheme.cardBackground.withOpacity(0.5),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14.sp,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入API Key';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      TextFormField(
                        controller: _endpointController,
                        decoration: InputDecoration(
                          labelText: 'Endpoint',
                          labelStyle: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14.sp,
                          ),
                          hintText: '请输入Endpoint，例如：https://api.example.com',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.5),
                            fontSize: 12.sp,
                          ),
                          fillColor: AppTheme.cardBackground.withOpacity(0.5),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14.sp,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入Endpoint';
                          }
                          if (!value.trim().startsWith('http')) {
                            return 'Endpoint必须以http://或https://开头';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _addApiKey,
                  child: _isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                            strokeWidth: 2.w,
                          ),
                        )
                      : Text(
                          '添加',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 显示编辑API密钥对话框
  Future<void> _showEditApiKeyDialog(dynamic apiKey) async {
    _apiKeyController.text = apiKey['apiKey'] ?? '';
    _endpointController.text = apiKey['endpoint'] ?? '';

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: Text(
                '编辑API密钥',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _apiKeyController,
                        decoration: InputDecoration(
                          labelText: 'API Key',
                          labelStyle: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14.sp,
                          ),
                          hintText: '请输入API Key，例如：sk-xxxx',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.5),
                            fontSize: 12.sp,
                          ),
                          fillColor: AppTheme.cardBackground.withOpacity(0.5),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14.sp,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入API Key';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      TextFormField(
                        controller: _endpointController,
                        decoration: InputDecoration(
                          labelText: 'Endpoint',
                          labelStyle: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14.sp,
                          ),
                          hintText: '请输入Endpoint，例如：https://api.example.com',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.5),
                            fontSize: 12.sp,
                          ),
                          fillColor: AppTheme.cardBackground.withOpacity(0.5),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14.sp,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入Endpoint';
                          }
                          if (!value.trim().startsWith('http')) {
                            return 'Endpoint必须以http://或https://开头';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      _isLoading ? null : () => _updateApiKey(apiKey['id']),
                  child: _isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                            strokeWidth: 2.w,
                          ),
                        )
                      : Text(
                          '保存',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 显示删除确认对话框
  Future<void> _showDeleteConfirmDialog(dynamic apiKey) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            '确认删除',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Text(
            '确定要删除此API密钥吗？此操作不可恢复。',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '取消',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteApiKey(apiKey['id']);
              },
              child: Text(
                '删除',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 显示Toast消息
  void _showToast(String message, ToastType type) {
    if (!mounted) return;
    CustomToast.show(context, message: message, type: type);
  }

  // 构建API密钥列表项
  Widget _buildApiKeyItem(dynamic apiKey) {
    final status = apiKey['status'] ?? 0;
    final statusText = status == 1 ? '正常' : '已禁用';
    final statusColor = status == 1 ? Colors.green : Colors.red;

    final createdAt = apiKey['createdAt'] != null
        ? DateTime.parse(apiKey['createdAt'])
            .toLocal()
            .toString()
            .substring(0, 16)
        : '未知';

    // 对API密钥进行脱敏处理
    String maskedApiKey = apiKey['apiKey'] ?? '';
    if (maskedApiKey.length > 8) {
      maskedApiKey =
          '${maskedApiKey.substring(0, 4)}...${maskedApiKey.substring(maskedApiKey.length - 4)}';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    maskedApiKey,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.h),
                Text(
                  '${apiKey['endpoint'] ?? 'Unknown Endpoint'}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  '使用次数: ${apiKey['usageCount'] ?? 0}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondary.withOpacity(0.8),
                  ),
                ),
                Text(
                  '创建时间: $createdAt',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              bottom: 12.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditApiKeyDialog(apiKey),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 16.sp,
                    color: AppTheme.primaryColor,
                  ),
                  label: Text(
                    '编辑',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14.sp,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmDialog(apiKey),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 16.sp,
                    color: Colors.red,
                  ),
                  label: Text(
                    '删除',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14.sp,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: Text(
          'API Key管理',
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppTheme.textPrimary,
              size: 24.sp,
            ),
            onPressed: _isLoading ? null : _loadApiKeys,
            tooltip: '刷新',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddApiKeyDialog,
        backgroundColor: AppTheme.primaryColor,
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 24.sp,
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60.sp,
                        color: Colors.red,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        _errorMsg,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton(
                        onPressed: _loadApiKeys,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        child: Text(
                          '重试',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _apiKeys.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.vpn_key_outlined,
                            size: 60.sp,
                            color: AppTheme.primaryColor.withOpacity(0.6),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            '暂无API密钥',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '点击右下角的按钮添加API密钥',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: _apiKeys.length,
                      itemBuilder: (context, index) {
                        return _buildApiKeyItem(_apiKeys[index]);
                      },
                    ),
    );
  }
}
