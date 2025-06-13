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

  // 添加批量操作状态变量
  bool _isInBatchDeleteMode = false;
  final Set<int> _selectedApiKeyIds = {};

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
            // 退出批量删除模式并清空选择
            _isInBatchDeleteMode = false;
            _selectedApiKeyIds.clear();
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

    // 检查是否为批量添加（按行分割）
    List<String> apiKeys = apiKey
        .split('\n')
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toList();

    // 显示加载指示器
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      // 判断是单条添加还是批量添加
      if (apiKeys.length == 1) {
        // 单条添加
        result = await _profileServer.addApiKey(
          apiKey: apiKeys[0],
          endpoint: endpoint,
        );
      } else {
        // 批量添加
        result = await _profileServer.batchAddApiKeys(
          apiKeys: apiKeys,
          endpoint: endpoint,
        );
      }

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

  // 批量删除API密钥
  Future<void> _batchDeleteApiKeys() async {
    if (_selectedApiKeyIds.isEmpty) {
      _showToast('请至少选择一个API密钥', ToastType.warning);
      return;
    }

    // 显示加载指示器
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _profileServer.batchDeleteApiKeys(
        ids: _selectedApiKeyIds.toList(),
      );

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
        _showToast('批量删除API密钥失败: $e', ToastType.error);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 更新API密钥状态
  Future<void> _updateApiKeyStatus(int id, int status) async {
    try {
      final result = await _profileServer.updateApiKeyStatus(
        id: id,
        status: status,
      );

      if (mounted) {
        if (result['success']) {
          // 显示成功消息
          _showToast(result['msg'], ToastType.success);

          // 重新加载API密钥列表
          _loadApiKeys();
        } else {
          // 显示错误消息
          _showToast(result['msg'], ToastType.error);

          // 重新加载API密钥列表以恢复原状态
          _loadApiKeys();
        }
      }
    } catch (e) {
      if (mounted) {
        _showToast('更新API密钥状态失败: $e', ToastType.error);

        // 重新加载API密钥列表以恢复原状态
        _loadApiKeys();
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
                          labelText: 'API Key (支持批量，一行一个)',
                          labelStyle: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14.sp,
                          ),
                          hintText:
                              '请输入API Key，一行一个\n例如：\nsk-xxxx\nAI-yyyy\nsk-zzzz',
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
                        maxLines: 5,
                        minLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入至少一个API Key';
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

  // 显示批量删除确认对话框
  Future<void> _showBatchDeleteConfirmDialog() async {
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
            '确认批量删除',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Text(
            '确定要删除选中的${_selectedApiKeyIds.length}个API密钥吗？此操作不可恢复。',
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
                _batchDeleteApiKeys();
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
    // 更新状态文本和颜色逻辑
    String statusText;
    Color statusColor;

    switch (status) {
      case 1:
        statusText = '启用';
        statusColor = Colors.green;
        break;
      case 0:
        statusText = '停用';
        statusColor = Colors.orange;
        break;
      case 3:
        statusText = '封禁';
        statusColor = Colors.red;
        break;
      default:
        statusText = '未知';
        statusColor = Colors.grey;
    }

    final id = apiKey['id'] ?? 0;
    final isSelected = _selectedApiKeyIds.contains(id);

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
        border: _isInBatchDeleteMode && isSelected
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            leading: _isInBatchDeleteMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedApiKeyIds.add(id);
                        } else {
                          _selectedApiKeyIds.remove(id);
                        }
                      });
                    },
                    activeColor: AppTheme.primaryColor,
                  )
                : null,
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
                GestureDetector(
                  onTap: _isInBatchDeleteMode || status == 3
                      ? null
                      : () {
                          // 切换状态 (1 -> 0 或 0 -> 1)
                          _updateApiKeyStatus(
                              apiKey['id'], status == 1 ? 0 : 1);
                        },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          status == 1
                              ? Icons.check_circle
                              : (status == 0
                                  ? Icons.pause_circle_outline
                                  : Icons.block),
                          size: 14.sp,
                          color: statusColor,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: statusColor,
                          ),
                        ),
                      ],
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
            onTap: _isInBatchDeleteMode
                ? () {
                    setState(() {
                      if (isSelected) {
                        _selectedApiKeyIds.remove(id);
                      } else {
                        _selectedApiKeyIds.add(id);
                      }
                    });
                  }
                : null,
          ),
          if (!_isInBatchDeleteMode)
            Padding(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                bottom: 12.h,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 添加状态开关
                  Row(
                    children: [
                      Text(
                        '启用状态:',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Switch(
                        value: status == 1,
                        onChanged: status == 3
                            ? null // 封禁状态下禁用开关
                            : (value) {
                                _updateApiKeyStatus(
                                    apiKey['id'], value ? 1 : 0);
                              },
                        activeColor:
                            status == 3 ? Colors.grey : AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  Row(
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
          if (_isInBatchDeleteMode)
            TextButton(
              onPressed: () {
                setState(() {
                  _isInBatchDeleteMode = false;
                  _selectedApiKeyIds.clear();
                });
              },
              child: Text(
                '取消',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_isInBatchDeleteMode)
            TextButton(
              onPressed: _selectedApiKeyIds.isEmpty
                  ? null
                  : _showBatchDeleteConfirmDialog,
              child: Text(
                '删除(${_selectedApiKeyIds.length})',
                style: TextStyle(
                  color: _selectedApiKeyIds.isEmpty ? Colors.grey : Colors.red,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (!_isInBatchDeleteMode && _apiKeys.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.delete_sweep,
                color: AppTheme.textPrimary,
                size: 24.sp,
              ),
              onPressed: () {
                setState(() {
                  _isInBatchDeleteMode = true;
                });
              },
              tooltip: '批量删除',
            ),
          if (!_isInBatchDeleteMode)
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
      floatingActionButton: !_isInBatchDeleteMode
          ? FloatingActionButton(
              onPressed: _showAddApiKeyDialog,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 24.sp,
              ),
            )
          : null,
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
