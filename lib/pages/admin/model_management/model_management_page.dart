import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import 'model_series_service.dart';

class ModelManagementPage extends StatefulWidget {
  const ModelManagementPage({super.key});

  @override
  State<ModelManagementPage> createState() => _ModelManagementPageState();
}

class _ModelManagementPageState extends State<ModelManagementPage> {
  final ModelSeriesService _apiKeyService = ModelSeriesService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _apiKeyList = [];
  final Set<int> _selectedApiKeys = {};
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          _currentPage < _totalPages) {
        _currentPage++;
        _loadApiKeys(isLoadMore: true);
      }
    });
  }

  Future<void> _loadApiKeys({bool isLoadMore = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiKeyService.getOfficialApiKeys(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (response.data['code'] == 0) {
        final data = response.data['data'];
        setState(() {
          if (isLoadMore) {
            _apiKeyList.addAll(List<Map<String, dynamic>>.from(data));
          } else {
            _apiKeyList = List<Map<String, dynamic>>.from(data);
          }
          _totalPages = 1; // 暂时设为1，因为API可能没有返回总页数
        });
      }
    } catch (e) {
      _showErrorDialog('加载失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddApiKeyDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddApiKeyDialog(),
    );

    if (result != null) {
      try {
        final response = await _apiKeyService.batchAddOfficialApiKeys(
          apiKeys: result['apiKeys'],
          endpoint: result['endpoint'],
          modelQuotas: result['modelQuotas'],
        );

        if (response.data['code'] == 0) {
          _showSuccessSnackBar('添加成功');
          _resetAndReload();
        } else {
          _showErrorDialog(response.data['msg']);
        }
      } catch (e) {
        _showErrorDialog('添加失败: $e');
      }
    }
  }



  // 处理菜单操作
  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _showExportDialog();
        break;
      case 'quota':
        _showBatchQuotaDialog();
        break;
      case 'delete':
        _handleDelete();
        break;
    }
  }

  // 智能删除处理
  Future<void> _handleDelete() async {
    if (_selectedApiKeys.isNotEmpty) {
      // 有选中项，直接删除选中项
      await _deleteSelected();
    } else {
      // 无选中项，显示删除类型选择
      await _showDeleteTypeDialog();
    }
  }

  // 删除选中项
  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedApiKeys.length} 个API密钥吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiKeyService
            .batchDeleteOfficialApiKeys(_selectedApiKeys.toList());
        _showSuccessSnackBar('删除成功');
        _resetAndReload();
      } catch (e) {
        _showErrorDialog('删除失败: $e');
      }
    }
  }

  // 显示导出对话框
  Future<void> _showExportDialog() async {
    final exportType = await showDialog<int>(
      context: context,
      builder: (context) => const _ExportDialog(),
    );

    if (exportType != null) {
      await _exportApiKeys(exportType);
    }
  }

  // 导出API密钥到剪切板
  Future<void> _exportApiKeys(int exportType) async {
    try {
      final response = await _apiKeyService.exportOfficialApiKeys(
        exportType: exportType,
      );

      if (response.data['code'] == 0) {
        final List<dynamic> apiKeyData = response.data['data'];
        // 只提取API密钥字符串
        final List<String> apiKeys = apiKeyData
            .map((item) => item['apiKey'] as String)
            .toList();

        // 将密钥复制到剪切板，每行一个
        final String keysText = apiKeys.join('\n');
        await Clipboard.setData(ClipboardData(text: keysText));

        _showSuccessSnackBar('已复制 ${apiKeys.length} 个密钥到剪切板');
      } else {
        _showErrorDialog(response.data['msg']);
      }
    } catch (e) {
      _showErrorDialog('导出失败: $e');
    }
  }

  // 显示删除类型对话框
  Future<void> _showDeleteTypeDialog() async {
    final deleteType = await showDialog<int>(
      context: context,
      builder: (context) => const _DeleteTypeDialog(),
    );

    if (deleteType != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除'),
          content: Text(_getDeleteTypeDescription(deleteType)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('确定'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          final response = await _apiKeyService.deleteOfficialApiKeysByType(
            deleteType: deleteType,
          );

          if (response.data['code'] == 0) {
            _showSuccessSnackBar('删除成功');
            _resetAndReload();
          } else {
            _showErrorDialog(response.data['msg']);
          }
        } catch (e) {
          _showErrorDialog('删除失败: $e');
        }
      }
    }
  }

  // 显示批量设置配额对话框
  Future<void> _showBatchQuotaDialog() async {
    final modelQuotas = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) => const _BatchQuotaDialog(),
    );

    if (modelQuotas != null && modelQuotas.isNotEmpty) {
      try {
        final response = await _apiKeyService.batchSetQuotas(
          modelQuotas: modelQuotas,
        );

        if (response.data['code'] == 0) {
          _showSuccessSnackBar('配额设置成功');
        } else {
          _showErrorDialog(response.data['msg']);
        }
      } catch (e) {
        _showErrorDialog('配额设置失败: $e');
      }
    }
  }

  String _getDeleteTypeDescription(int deleteType) {
    switch (deleteType) {
      case 1:
        return '确定要删除全部API密钥吗？';
      case 2:
        return '确定要删除所有有效（启用状态）的API密钥吗？';
      case 3:
        return '确定要删除所有封禁状态的API密钥吗？';
      default:
        return '确定要执行删除操作吗？';
    }
  }

  Future<void> _showQuotaDetails(int apiKeyId) async {
    try {
      final response = await _apiKeyService.getOfficialApiKeyQuotas(apiKeyId);
      if (response.data['code'] == 0) {
        final quotas = List<Map<String, dynamic>>.from(response.data['data']);
        await showDialog(
          context: context,
          builder: (context) => _QuotaDetailsDialog(
              quotas: quotas, apiKeyService: _apiKeyService),
        );
      } else {
        _showErrorDialog(response.data['msg']);
      }
    } catch (e) {
      _showErrorDialog('获取配额失败: $e');
    }
  }

  void _resetAndReload() {
    _selectedApiKeys.clear();
    _currentPage = 1;
    _loadApiKeys();
  }

  void _onSelectChanged(bool? selected, int keyId) {
    setState(() {
      if (selected == true) {
        _selectedApiKeys.add(keyId);
      } else {
        _selectedApiKeys.remove(keyId);
      }
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('确定')),
        ],
      ),
    );
  }

  String _formatApiKey(String apiKey) {
    if (apiKey.length > 7) {
      return '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}';
    }
    return apiKey;
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return '启用';
      case 2:
        return '禁用';
      case 3:
        return '封禁';
      default:
        return '未知';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryLight;
    final background = AppTheme.background;
    final surfaceColor = AppTheme.cardBackground;
    final textPrimary = AppTheme.textPrimary;

    return Container(
      color: background,
      child: Column(
        children: [
          _buildTopBar(primaryColor, surfaceColor, textPrimary),
          Expanded(
            child: _isLoading && _apiKeyList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _apiKeyList.isEmpty
                    ? Center(
                        child: Text(
                          '暂无官方API密钥，请点击右上角添加。',
                          style: TextStyle(color: textPrimary.withOpacity(0.7)),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 1200
                              .w, // Provide ample width for horizontal scrolling
                          child: Column(
                            children: [
                              _buildHeader(textPrimary),
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: () async => _resetAndReload(),
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount: _apiKeyList.length +
                                        (_isLoading ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _apiKeyList.length) {
                                        return _isLoading
                                            ? const Padding(
                                                padding: EdgeInsets.all(16.0),
                                                child: Center(
                                                    child:
                                                        CircularProgressIndicator()),
                                              )
                                            : const SizedBox.shrink();
                                      }
                                      final apiKey = _apiKeyList[index];
                                      final isSelected = _selectedApiKeys
                                          .contains(apiKey['id']);
                                      return _buildApiKeyTile(
                                          apiKey, isSelected, textPrimary);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Container _buildTopBar(
      Color primaryColor, Color surfaceColor, Color textPrimary) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: surfaceColor,
      child: Row(
        children: [
          Text(
            '官方API密钥管理',
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: textPrimary),
          ),
          const Spacer(),
          Row(
            children: [
              // 添加密钥按钮（独立）
              ElevatedButton(
                onPressed: _showAddApiKeyDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  minimumSize: Size(0, 32.h),
                  textStyle: TextStyle(fontSize: 12.sp),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16.sp),
                    SizedBox(width: 4.w),
                    const Text('添加密钥'),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // 功能菜单（折叠）
              PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download),
                        SizedBox(width: 8),
                        Text('导出'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'quota',
                    child: Row(
                      children: [
                        Icon(Icons.settings),
                        SizedBox(width: 8),
                        Text('设置配额'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text('删除'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  height: 32.h,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '功能',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 16.sp,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Padding _buildHeader(Color textPrimary) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Checkbox(
            value: _selectedApiKeys.length == _apiKeyList.length &&
                _apiKeyList.isNotEmpty,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedApiKeys
                      .addAll(_apiKeyList.map((e) => e['id'] as int));
                } else {
                  _selectedApiKeys.clear();
                }
              });
            },
          ),
          SizedBox(width: 10.w),
          Expanded(
              flex: 3,
              child: Text('API Key',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textPrimary))),
          Expanded(
              flex: 2,
              child: Text('Endpoint',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textPrimary))),
          Expanded(
              flex: 1,
              child: Text('Status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textPrimary))),
          Expanded(
              flex: 2,
              child: Text('Rate Limit Until',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textPrimary))),
          const Expanded(
              flex: 1,
              child: Text('操作', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Card _buildApiKeyTile(
      Map<String, dynamic> apiKey, bool isSelected, Color textPrimary) {
    final id = apiKey['id'] is String
        ? int.tryParse(apiKey['id'].toString()) ?? 0
        : apiKey['id'] as int;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (bool? selected) => _onSelectChanged(selected, id),
            ),
            SizedBox(width: 10.w),
            Expanded(
                flex: 3,
                child: Text(_formatApiKey(apiKey['apiKey']),
                    style: TextStyle(color: textPrimary))),
            Expanded(
                flex: 2,
                child: Text(apiKey['endpoint'] ?? '-',
                    style: TextStyle(color: textPrimary))),
            Expanded(
              flex: 1,
              child: Text(
                _getStatusText(apiKey['status']),
                style: TextStyle(color: _getStatusColor(apiKey['status'])),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                apiKey['rateLimitUntil'] != null
                    ? (apiKey['rateLimitUntil'] as String)
                        .substring(0, 16)
                        .replaceFirst('T', ' ')
                    : 'N/A',
                style: TextStyle(color: textPrimary.withOpacity(0.7)),
              ),
            ),
            Expanded(
              flex: 1,
              child: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showQuotaDetails(id),
                color: AppTheme.primaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _AddApiKeyDialog extends StatefulWidget {
  const _AddApiKeyDialog();

  @override
  State<_AddApiKeyDialog> createState() => _AddApiKeyDialogState();
}

class _AddApiKeyDialogState extends State<_AddApiKeyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeysController = TextEditingController();
  final _endpointController = TextEditingController();
  final List<Map<String, TextEditingController>> _modelQuotas = [];

  @override
  void initState() {
    super.initState();
    _addModelQuota();
  }

  void _addModelQuota() {
    setState(() {
      _modelQuotas.add({
        'modelName': TextEditingController(),
        'dailyLimit': TextEditingController(),
      });
    });
  }

  void _removeModelQuota(int index) {
    setState(() {
      _modelQuotas[index]['modelName']!.dispose();
      _modelQuotas[index]['dailyLimit']!.dispose();
      _modelQuotas.removeAt(index);
    });
  }

  @override
  void dispose() {
    _apiKeysController.dispose();
    _endpointController.dispose();
    for (var quota in _modelQuotas) {
      quota['modelName']!.dispose();
      quota['dailyLimit']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('批量添加API密钥'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _apiKeysController,
                decoration: const InputDecoration(
                  labelText: 'API密钥',
                  hintText: '每行一个或用,分割',
                ),
                maxLines: 5,
                validator: (value) => value!.isEmpty ? '请输入至少一个API密钥' : null,
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _endpointController,
                decoration: const InputDecoration(
                  labelText: 'API端点 (可选)',
                  hintText: 'https://api.example.com',
                ),
              ),
              SizedBox(height: 16.h),
              const Text('模型配额设置',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ..._modelQuotas.asMap().entries.map((entry) {
                int index = entry.key;
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: entry.value['modelName'],
                        decoration: const InputDecoration(labelText: '模型名称'),
                        validator: (v) => v!.isEmpty ? '必填' : null,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextFormField(
                        controller: entry.value['dailyLimit'],
                        decoration: const InputDecoration(labelText: '每日限额'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? '必填' : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _removeModelQuota(index),
                    ),
                  ],
                );
              }),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('添加模型配额'),
                onPressed: _addModelQuota,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final apiKeys = _apiKeysController.text
                  .split(RegExp(r'[\n,]'))
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              final modelQuotas = _modelQuotas
                  .map((c) => {
                        'modelName': c['modelName']!.text,
                        'dailyLimit': int.parse(c['dailyLimit']!.text),
                      })
                  .toList();

              Navigator.pop(context, {
                'apiKeys': apiKeys,
                'endpoint': _endpointController.text,
                'modelQuotas': modelQuotas,
              });
            }
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}

class _QuotaDetailsDialog extends StatelessWidget {
  final List<Map<String, dynamic>> quotas;
  final ModelSeriesService apiKeyService;

  const _QuotaDetailsDialog(
      {required this.quotas, required this.apiKeyService});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('配额详情'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: quotas.length,
          itemBuilder: (context, index) {
            final quota = quotas[index];
            return Card(
              child: ListTile(
                title: Text(quota['modelName']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('每日限额: ${quota['dailyLimit'] ?? 'N/A'}'),
                    Text('当前用量: ${quota['currentUsage'] ?? 'N/A'}'),
                    Text('上次重置: ${quota['lastResetAt'] != null
                        ? (quota['lastResetAt'] as String)
                            .substring(0, 16)
                            .replaceFirst('T', ' ')
                        : 'N/A'}'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

// 导出对话框
class _ExportDialog extends StatelessWidget {
  const _ExportDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导出API密钥'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildExportOption(
            context,
            '导出全部密钥',
            '导出所有API密钥到剪切板',
            Icons.download,
            1,
          ),
          const SizedBox(height: 8),
          _buildExportOption(
            context,
            '导出有效密钥',
            '导出启用状态的API密钥',
            Icons.check_circle,
            2,
          ),
          const SizedBox(height: 8),
          _buildExportOption(
            context,
            '导出封禁密钥',
            '导出封禁状态的API密钥',
            Icons.block,
            3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _buildExportOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    int value,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

// 删除类型对话框
class _DeleteTypeDialog extends StatelessWidget {
  const _DeleteTypeDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择删除类型'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDeleteOption(
            context,
            '删除全部密钥',
            '删除所有API密钥',
            Icons.delete_forever,
            Colors.red,
            1,
          ),
          const SizedBox(height: 8),
          _buildDeleteOption(
            context,
            '删除有效密钥',
            '删除启用状态的API密钥',
            Icons.delete,
            Colors.orange,
            2,
          ),
          const SizedBox(height: 8),
          _buildDeleteOption(
            context,
            '删除封禁密钥',
            '删除封禁状态的API密钥',
            Icons.remove_circle,
            Colors.grey,
            3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _buildDeleteOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    int value,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

// 批量设置配额对话框
class _BatchQuotaDialog extends StatefulWidget {
  const _BatchQuotaDialog();

  @override
  State<_BatchQuotaDialog> createState() => _BatchQuotaDialogState();
}

class _BatchQuotaDialogState extends State<_BatchQuotaDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, TextEditingController>> _modelQuotas = [];

  @override
  void initState() {
    super.initState();
    _addModelQuota();
  }

  void _addModelQuota() {
    setState(() {
      _modelQuotas.add({
        'modelName': TextEditingController(),
        'dailyLimit': TextEditingController(),
      });
    });
  }

  void _removeModelQuota(int index) {
    setState(() {
      _modelQuotas[index]['modelName']!.dispose();
      _modelQuotas[index]['dailyLimit']!.dispose();
      _modelQuotas.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var quota in _modelQuotas) {
      quota['modelName']!.dispose();
      quota['dailyLimit']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('批量设置配额'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '为所有API密钥设置模型配额',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ..._modelQuotas.asMap().entries.map((entry) {
                  int index = entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: entry.value['modelName'],
                            decoration: const InputDecoration(
                              labelText: '模型名称',
                              hintText: '如: gemini-2.0-flash',
                            ),
                            validator: (v) => v!.isEmpty ? '必填' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: entry.value['dailyLimit'],
                            decoration: const InputDecoration(
                              labelText: '每日限额',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? '必填' : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _modelQuotas.length > 1
                              ? () => _removeModelQuota(index)
                              : null,
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('添加模型配额'),
                  onPressed: _addModelQuota,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final modelQuotas = _modelQuotas
                  .map((c) => {
                        'modelName': c['modelName']!.text,
                        'dailyLimit': int.parse(c['dailyLimit']!.text),
                      })
                  .toList();

              Navigator.pop(context, modelQuotas);
            }
          },
          child: const Text('设置'),
        ),
      ],
    );
  }
}
