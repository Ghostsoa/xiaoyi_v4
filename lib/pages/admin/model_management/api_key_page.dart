import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import 'model_series_service.dart';

class ApiKeyPage extends StatefulWidget {
  final String seriesName;
  final String displayName;

  const ApiKeyPage({
    super.key,
    required this.seriesName,
    required this.displayName,
  });

  @override
  State<ApiKeyPage> createState() => _ApiKeyPageState();
}

class _ApiKeyPageState extends State<ApiKeyPage> {
  final ModelSeriesService _modelService = ModelSeriesService();
  Map<String, String> _apiKeys = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
  }

  // 加载API密钥
  Future<void> _loadApiKeys() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _modelService.getApiKeys(widget.seriesName);
      if (response.data['code'] == 0) {
        final data = response.data['data'] as Map<String, dynamic>;
        setState(() {
          _apiKeys = Map<String, String>.from(data);
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

  // 添加API密钥
  Future<void> _addApiKey() async {
    final key = await _showAddDialog();
    if (key != null) {
      try {
        final response = await _modelService.addApiKey(
          seriesName: widget.seriesName,
          key: key,
        );

        if (response.data['code'] == 0) {
          _showSuccessSnackBar('添加成功');
          _loadApiKeys();
        } else {
          _showErrorDialog(response.data['msg']);
        }
      } catch (e) {
        _showErrorDialog('添加失败：$e');
      }
    }
  }

  // 删除API密钥
  Future<void> _deleteApiKey(String key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个API密钥吗？'),
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
        final response = await _modelService.deleteApiKey(
          seriesName: widget.seriesName,
          key: key,
        );

        if (response.data['code'] == 0) {
          _showSuccessSnackBar('删除成功');
          _loadApiKeys();
        } else {
          _showErrorDialog(response.data['msg']);
        }
      } catch (e) {
        _showErrorDialog('删除失败：$e');
      }
    }
  }

  // 显示添加对话框
  Future<String?> _showAddDialog() async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加API密钥'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'API密钥',
            hintText: '请输入API密钥',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isEmpty) {
                _showErrorDialog('请输入API密钥');
                return;
              }
              Navigator.pop(context, controller.text);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  // 复制密钥
  Future<void> _copyKey(String key) async {
    await Clipboard.setData(ClipboardData(text: key));
    _showSuccessSnackBar('密钥已复制到剪贴板');
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
          '${widget.displayName}的API密钥管理',
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
                  'API密钥管理',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addApiKey,
                  icon: const Icon(Icons.add),
                  label: const Text('添加密钥'),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _apiKeys.length,
                    itemBuilder: (context, index) {
                      final id = _apiKeys.keys.elementAt(index);
                      final key = _apiKeys[id]!;
                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  key,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _copyKey(key),
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('复制'),
                                style: TextButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.w),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteApiKey(key),
                            color: Colors.red,
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
}
