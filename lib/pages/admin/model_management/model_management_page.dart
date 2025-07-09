import 'package:flutter/material.dart';
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

  Future<void> _updateStatus(int status) async {
    if (_selectedApiKeys.isEmpty) return;

    try {
      final response = await _apiKeyService.updateOfficialApiKeysStatus(
        ids: _selectedApiKeys.toList(),
        status: status,
      );

      if (response.data['code'] == 0) {
        _showSuccessSnackBar('状态更新成功');
        _resetAndReload();
      } else {
        _showErrorDialog(response.data['msg']);
      }
    } catch (e) {
      _showErrorDialog('状态更新失败: $e');
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedApiKeys.isEmpty) return;

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
            child: const Text('确定'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
                        child: Container(
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
          Wrap(
            spacing: 8.w,
            children: [
              ElevatedButton(
                onPressed: _showAddApiKeyDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  minimumSize: Size(0, 32.h),
                  textStyle: TextStyle(fontSize: 12.sp),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16.sp),
                    SizedBox(width: 4.w),
                    const Text('添加'),
                  ],
                ),
              ),
              PopupMenuButton<int>(
                enabled: _selectedApiKeys.isNotEmpty,
                onSelected: (status) => _updateStatus(status),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 1, child: Text('启用选中')),
                  PopupMenuItem(value: 2, child: Text('禁用选中')),
                  PopupMenuItem(value: 3, child: Text('封禁选中')),
                ],
                child: ElevatedButton(
                  onPressed: _selectedApiKeys.isEmpty ? null : () {},
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    minimumSize: Size(0, 32.h),
                    textStyle: TextStyle(fontSize: 12.sp),
                  ),
                  child: const Text('更新状态'),
                ),
              ),
              ElevatedButton(
                onPressed: _selectedApiKeys.isNotEmpty ? _deleteSelected : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  minimumSize: Size(0, 32.h),
                  textStyle: TextStyle(fontSize: 12.sp),
                ),
                child: const Text('删除'),
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
  List<Map<String, TextEditingController>> _modelQuotas = [];

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
                    Text('上次重置: ' +
                        (quota['lastResetAt'] != null
                            ? (quota['lastResetAt'] as String)
                                .substring(0, 16)
                                .replaceFirst('T', ' ')
                            : 'N/A')),
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
