import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import 'model_series_service.dart';
import 'model_list_page.dart';
import 'api_key_page.dart';

class ModelManagementPage extends StatefulWidget {
  const ModelManagementPage({super.key});

  @override
  State<ModelManagementPage> createState() => _ModelManagementPageState();
}

class _ModelManagementPageState extends State<ModelManagementPage> {
  final ModelSeriesService _modelSeriesService = ModelSeriesService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _modelSeriesList = [];
  final int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadModelSeries();
  }

  // 加载模型系列数据
  Future<void> _loadModelSeries() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _modelSeriesService.getModelSeriesList(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (response.data['code'] == 0) {
        final data = response.data['data'];
        setState(() {
          _modelSeriesList = List<Map<String, dynamic>>.from(data['list']);
          _totalPages = (data['total'] / _pageSize).ceil();
        });
      }
    } catch (e) {
      _showErrorDialog('加载失败：$e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 创建模型系列
  Future<void> _createModelSeries() async {
    final result = await _showCreateEditDialog();
    if (result != null) {
      try {
        final response = await _modelSeriesService.createModelSeries(
          name: result['name'],
          displayName: result['displayName'],
          endpoint: result['endpoint'],
          status: result['status'],
        );

        if (response.data['code'] == 0) {
          _showSuccessSnackBar('创建成功');
          _loadModelSeries();
        } else {
          _showErrorDialog(response.data['msg']);
        }
      } catch (e) {
        _showErrorDialog('创建失败：$e');
      }
    }
  }

  // 更新模型系列
  Future<void> _updateModelSeries(Map<String, dynamic> series) async {
    final result = await _showCreateEditDialog(
      isEdit: true,
      initialData: series,
    );

    if (result != null) {
      try {
        final response = await _modelSeriesService.updateModelSeries(
          id: series['id'],
          name: result['name'],
          displayName: result['displayName'],
          endpoint: result['endpoint'],
          status: result['status'],
        );

        if (response.data['code'] == 0) {
          _showSuccessSnackBar('更新成功');
          _loadModelSeries();
        } else {
          _showErrorDialog(response.data['msg']);
        }
      } catch (e) {
        _showErrorDialog('更新失败：$e');
      }
    }
  }

  // 删除模型系列
  Future<void> _deleteModelSeries(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个模型系列吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _modelSeriesService.deleteModelSeries(id);
        if (response.data['code'] == 0) {
          _showSuccessSnackBar('删除成功');
          _loadModelSeries();
        } else {
          _showErrorDialog(response.data['msg']);
        }
      } catch (e) {
        _showErrorDialog('删除失败：$e');
      }
    }
  }

  // 显示创建/编辑对话框
  Future<Map<String, dynamic>?> _showCreateEditDialog({
    bool isEdit = false,
    Map<String, dynamic>? initialData,
  }) async {
    final TextEditingController nameController = TextEditingController(
      text: initialData?['name'] ?? '',
    );
    final TextEditingController displayNameController = TextEditingController(
      text: initialData?['displayName'] ?? '',
    );
    final TextEditingController endpointController = TextEditingController(
      text: initialData?['endpoint'] ?? '',
    );
    int status = initialData?['status'] ?? 1;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? '编辑模型系列' : '创建模型系列'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEdit)
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '系列名称',
                    hintText: '请输入系列名称（用于获取API Key）',
                  ),
                ),
              SizedBox(height: 16.h),
              TextField(
                controller: displayNameController,
                decoration: const InputDecoration(
                  labelText: '显示名称',
                  hintText: '请输入显示名称',
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: endpointController,
                decoration: const InputDecoration(
                  labelText: 'API端点',
                  hintText: '请输入API端点',
                ),
              ),
              SizedBox(height: 16.h),
              DropdownButtonFormField<int>(
                value: status,
                decoration: const InputDecoration(
                  labelText: '状态',
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('启用')),
                  DropdownMenuItem(value: 2, child: Text('禁用')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    status = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (!isEdit && nameController.text.isEmpty) {
                _showErrorDialog('请输入系列名称');
                return;
              }
              if (displayNameController.text.isEmpty) {
                _showErrorDialog('请输入显示名称');
                return;
              }
              if (endpointController.text.isEmpty) {
                _showErrorDialog('请输入API端点');
                return;
              }

              Navigator.pop(context, {
                if (!isEdit) 'name': nameController.text,
                'displayName': displayNameController.text,
                'endpoint': endpointController.text,
                'status': status,
              });
            },
            child: Text(isEdit ? '保存' : '创建'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
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
          // 顶部操作栏
          Container(
            padding: EdgeInsets.all(16.w),
            color: surfaceColor,
            child: Row(
              children: [
                Text(
                  '模型系列管理',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _createModelSeries,
                  icon: const Icon(Icons.add),
                  label: const Text('新建系列'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // 列表内容
          Expanded(
            child: _isLoading && _modelSeriesList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _modelSeriesList.length,
                    itemBuilder: (context, index) {
                      final series = _modelSeriesList[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        child: ListTile(
                          title: Text(
                            series['displayName'],
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                series['name'],
                                style: TextStyle(
                                  color: textPrimary.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: series['status'] == 1
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  series['status'] == 1 ? '启用' : '禁用',
                                  style: TextStyle(
                                    color: series['status'] == 1
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              IconButton(
                                icon: const Icon(Icons.key),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ApiKeyPage(
                                        seriesId: series['id'],
                                        displayName: series['displayName'],
                                      ),
                                    ),
                                  );
                                },
                                color: primaryColor,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _updateModelSeries(series),
                                color: primaryColor,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () =>
                                    _deleteModelSeries(series['id']),
                                color: Colors.red,
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ModelListPage(
                                  seriesId: series['id'],
                                  seriesName: series['displayName'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
