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
    final result = await _showCreateDialog();
    if (result != null) {
      try {
        final response = await _modelService.createModel(
          seriesId: widget.seriesId,
          name: result['name'],
          displayName: result['displayName'],
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

  // 显示创建对话框
  Future<Map<String, dynamic>?> _showCreateDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController displayNameController = TextEditingController();
    final TextEditingController inputPriceController = TextEditingController();
    final TextEditingController outputPriceController = TextEditingController();
    int status = 1;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建模型'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
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
              if (nameController.text.isEmpty ||
                  displayNameController.text.isEmpty ||
                  inputPriceController.text.isEmpty ||
                  outputPriceController.text.isEmpty) {
                _showErrorDialog('请填写所有字段');
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
                'inputPrice': inputPrice,
                'outputPrice': outputPrice,
                'status': status,
              });
            },
            child: const Text('创建'),
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
                        child: ListTile(
                          title: Text(
                            model['displayName'],
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model['name'],
                                style: TextStyle(
                                  color: textPrimary.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '输入：¥${model['inputPrice']}/1k tokens  输出：¥${model['outputPrice']}/1k tokens',
                                style: TextStyle(
                                  color: textPrimary.withOpacity(0.7),
                                  fontSize: 12.sp,
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
                                  color: model['status'] == 1
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  model['status'] == 1 ? '启用' : '禁用',
                                  style: TextStyle(
                                    color: model['status'] == 1
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteModel(model['id']),
                                color: Colors.red,
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
