import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import 'model_series_service.dart';

class ModelListPage extends StatefulWidget {
  final int seriesId;
  final String seriesName;

  const ModelListPage({
    super.key,
    required this.seriesId,
    required this.seriesName,
  });

  @override
  State<ModelListPage> createState() => _ModelListPageState();
}

class _ModelListPageState extends State<ModelListPage> {
  final ModelSeriesService _modelService = ModelSeriesService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _modelList = [];
  final int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  // 加载模型数据
  Future<void> _loadModels() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _modelService.getModelList(
        seriesId: widget.seriesId,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (response.data['code'] == 0) {
        final data = response.data['data'];
        setState(() {
          _modelList = List<Map<String, dynamic>>.from(data['list']);
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

  // 创建模型
  Future<void> _createModel() async {
    final result = await _showCreateEditDialog();
    if (result != null) {
      try {
        final response = await _modelService.createModel(
          seriesId: widget.seriesId,
          name: result['name'],
          displayName: result['displayName'],
          description: result['description'],
          inputPrice: result['inputPrice'],
          outputPrice: result['outputPrice'],
          status: result['status'],
        );

        if (response.data['code'] == 0) {
          _showSuccessSnackBar('创建成功');
          _loadModels();
        } else {
          _showErrorDialog(response.data['msg']);
        }
      } catch (e) {
        _showErrorDialog('创建失败：$e');
      }
    }
  }

  // 更新模型
  Future<void> _updateModel(Map<String, dynamic> model) async {
    final result = await _showCreateEditDialog(
      isEdit: true,
      initialData: model,
    );

    if (result != null) {
      try {
        final response = await _modelService.updateModel(
          id: model['id'],
          name: result['name'],
          displayName: result['displayName'],
          description: result['description'],
          inputPrice: result['inputPrice'],
          outputPrice: result['outputPrice'],
          status: result['status'],
        );

        if (response.data['code'] == 0) {
          _showSuccessSnackBar('更新成功');
          _loadModels();
        } else {
          _showErrorDialog(response.data['msg']);
        }
      } catch (e) {
        _showErrorDialog('更新失败：$e');
      }
    }
  }

  // 删除模型
  Future<void> _deleteModel(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个模型吗？'),
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
        final response = await _modelService.deleteModel(id);
        if (response.data['code'] == 0) {
          _showSuccessSnackBar('删除成功');
          _loadModels();
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
    final TextEditingController descriptionController = TextEditingController(
      text: initialData?['description'] ?? '',
    );
    final TextEditingController inputPriceController = TextEditingController(
      text: initialData != null ? initialData['inputPrice'].toString() : '',
    );
    final TextEditingController outputPriceController = TextEditingController(
      text: initialData != null ? initialData['outputPrice'].toString() : '',
    );
    int status = initialData?['status'] ?? 1;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? '编辑模型' : '创建模型'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                enabled: !isEdit, // 编辑模式下不允许修改名称
                decoration: const InputDecoration(
                  labelText: '模型名称',
                  hintText: '请输入模型名称',
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
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '模型描述',
                  hintText: '请输入模型描述',
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: inputPriceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '输入价格',
                  hintText: '每1k token的输入价格',
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: outputPriceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '输出价格',
                  hintText: '每1k token的输出价格',
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
                _showErrorDialog('请输入模型名称');
                return;
              }
              if (displayNameController.text.isEmpty) {
                _showErrorDialog('请输入显示名称');
                return;
              }

              final inputPrice = double.tryParse(inputPriceController.text);
              final outputPrice = double.tryParse(outputPriceController.text);

              if (inputPrice == null || outputPrice == null) {
                _showErrorDialog('价格格式不正确');
                return;
              }

              Navigator.pop(context, {
                'name': nameController.text,
                'displayName': displayNameController.text,
                'description': descriptionController.text,
                'inputPrice': inputPrice,
                'outputPrice': outputPrice,
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

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        title: Text(
          '${widget.seriesName}的模型列表',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // 顶部操作栏
          Container(
            padding: EdgeInsets.all(16.w),
            color: surfaceColor,
            child: Row(
              children: [
                Text(
                  '模型管理',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _createModel,
                  icon: const Icon(Icons.add),
                  label: const Text('新建模型'),
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
            child: _isLoading && _modelList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _modelList.isEmpty
                    ? const Center(child: Text('暂无模型'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _modelList.length,
                        itemBuilder: (context, index) {
                          final model = _modelList[index];
                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            color: Colors.grey[900],
                            child: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              model['displayName'],
                                              style: TextStyle(
                                                color: textPrimary,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 18.sp,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              model['name'],
                                              style: TextStyle(
                                                color: textPrimary
                                                    .withOpacity(0.7),
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12.w,
                                              vertical: 6.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: model['status'] == 1
                                                  ? Colors.green
                                                      .withOpacity(0.2)
                                                  : Colors.red.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4.r),
                                            ),
                                            child: Text(
                                              model['status'] == 1
                                                  ? '启用'
                                                  : '禁用',
                                              style: TextStyle(
                                                color: model['status'] == 1
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (model['description'] != null &&
                                      model['description']
                                          .toString()
                                          .isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 8.h),
                                      child: Text(
                                        model['description'],
                                        style: TextStyle(
                                          color: textPrimary.withOpacity(0.7),
                                          fontSize: 14.sp,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  SizedBox(height: 16.h),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '使用次数: ${model['usageCount'] ?? 0}',
                                        style: TextStyle(
                                          color: textPrimary.withOpacity(0.8),
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon:
                                                const Icon(Icons.edit_outlined),
                                            onPressed: () =>
                                                _updateModel(model),
                                            color: primaryColor,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          SizedBox(width: 20.w),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline),
                                            onPressed: () =>
                                                _deleteModel(model['id']),
                                            color: Colors.red,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '输入:',
                                              style: TextStyle(
                                                color: textPrimary
                                                    .withOpacity(0.7),
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              '¥${model['inputPrice']}/1k tokens',
                                              style: TextStyle(
                                                color: textPrimary,
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '输出:',
                                              style: TextStyle(
                                                color: textPrimary
                                                    .withOpacity(0.7),
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              '¥${model['outputPrice']}/1k tokens',
                                              style: TextStyle(
                                                color: textPrimary,
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
