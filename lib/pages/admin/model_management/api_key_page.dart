import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import 'model_series_service.dart';

class ApiKeyPage extends StatefulWidget {
  final int seriesId;
  final String displayName;

  const ApiKeyPage({
    super.key,
    required this.seriesId,
    required this.displayName,
  });

  @override
  State<ApiKeyPage> createState() => _ApiKeyPageState();
}

class _ApiKeyPageState extends State<ApiKeyPage> {
  final ModelSeriesService _modelService = ModelSeriesService();
  List<Map<String, dynamic>> _apiKeys = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  static const int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // 滚动监听器
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadMoreApiKeys();
    }
  }

  // 加载API密钥
  Future<void> _loadApiKeys() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    try {
      final response = await _modelService.getApiKeys(
        seriesId: widget.seriesId,
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (response.data['code'] == 0) {
        final data = response.data['data'];
        setState(() {
          _apiKeys = List<Map<String, dynamic>>.from(data['list']);
          _totalPages = (data['total'] / _pageSize).ceil();
          _totalCount = data['total'];
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

  // 加载更多API密钥
  Future<void> _loadMoreApiKeys() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final response = await _modelService.getApiKeys(
        seriesId: widget.seriesId,
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (response.data['code'] == 0) {
        final data = response.data['data'];
        final newList = List<Map<String, dynamic>>.from(data['list']);
        setState(() {
          _apiKeys.addAll(newList);
          _totalPages = (data['total'] / _pageSize).ceil();
          _totalCount = data['total'];
        });
      }
    } catch (e) {
      setState(() {
        _currentPage--; // 恢复页码
      });
      _showErrorDialog('加载更多失败：$e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // 添加API密钥
  Future<void> _addApiKey() async {
    final key = await _showAddDialog();
    if (key != null) {
      try {
        final response = await _modelService.addApiKey(
          seriesId: widget.seriesId,
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

  // 批量添加API密钥
  Future<void> _batchAddApiKeys() async {
    final keys = await _showBatchAddDialog();
    if (keys != null && keys.isNotEmpty) {
      try {
        final response = await _modelService.batchAddApiKeys(
          seriesId: widget.seriesId,
          keys: keys,
        );

        if (response.data['code'] == 0) {
          _showSuccessSnackBar('批量添加成功');
          _loadApiKeys();
        } else {
          _showErrorDialog(response.data['msg']);
        }
      } catch (e) {
        _showErrorDialog('批量添加失败：$e');
      }
    }
  }

  // 删除API密钥
  Future<void> _deleteApiKey(int id) async {
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
        final response = await _modelService.deleteApiKey(id);

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

  // 显示批量添加对话框
  Future<List<String>?> _showBatchAddDialog() async {
    final TextEditingController controller = TextEditingController();

    return showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量添加API密钥'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'API密钥列表',
                hintText: '请输入API密钥，每行一个',
              ),
            ),
            SizedBox(height: 8.h),
            const Text('请输入API密钥，每行一个'),
          ],
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
              final keys = controller.text
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              if (keys.isEmpty) {
                _showErrorDialog('请输入有效的API密钥');
                return;
              }
              Navigator.pop(context, keys);
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
                SizedBox(width: 8.w),
                Text(
                  '(共${_totalCount}个)',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: textPrimary.withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _batchAddApiKeys,
                      icon: const Icon(Icons.playlist_add, size: 16),
                      label: Text(
                        '批量添加',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 0,
                        ),
                        minimumSize: Size(60.w, 32.h),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    ElevatedButton.icon(
                      onPressed: _addApiKey,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        '添加密钥',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 0,
                        ),
                        minimumSize: Size(60.w, 32.h),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 列表内容
          Expanded(
            child: _isLoading && _apiKeys.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _apiKeys.isEmpty
                    ? const Center(child: Text('暂无API密钥'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _apiKeys.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _apiKeys.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final apiKey = _apiKeys[index];
                          final key = apiKey['key'];
                          final id = apiKey['id'];
                          final status = apiKey['status'];
                          final usageCount = apiKey['usageCount'] ??
                              apiKey['usage_count'] ??
                              0;

                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: status == 1
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4.r),
                                        ),
                                        child: Text(
                                          status == 1 ? '正常' : '冻结',
                                          style: TextStyle(
                                            color: status == 1
                                                ? Colors.green
                                                : Colors.red,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        '使用次数: $usageCount',
                                        style: TextStyle(
                                          color: textPrimary.withOpacity(0.7),
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 20),
                                        onPressed: () => _deleteApiKey(id),
                                        color: Colors.red,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  SelectableText(
                                    key,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _copyKey(key),
                                      icon: const Icon(Icons.copy, size: 16),
                                      label: const Text('复制'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 6.h,
                                        ),
                                        textStyle: TextStyle(fontSize: 12.sp),
                                      ),
                                    ),
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
}
