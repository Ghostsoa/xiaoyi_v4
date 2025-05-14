import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'material_service.dart' as material;
import '../../../services/file_service.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class MaterialManagementPage extends StatefulWidget {
  const MaterialManagementPage({super.key});

  @override
  State<MaterialManagementPage> createState() => _MaterialManagementPageState();
}

class _MaterialManagementPageState extends State<MaterialManagementPage> {
  final material.MaterialService _materialService = material.MaterialService();
  material.MaterialType? _selectedType;
  material.MaterialStatus? _selectedStatus;
  List<dynamic> _materials = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    _loadMaterials(refresh: true);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    _currentPage = 1;
    await _loadMaterials(refresh: true);
    _refreshController.refreshCompleted();
  }

  Future<void> _onLoading() async {
    await _loadMaterials(refresh: false);
    _refreshController.loadComplete();
  }

  Future<void> _loadMaterials({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _materials = [];
      }
    });

    try {
      final response = await _materialService.getMaterials(
        page: _currentPage,
        pageSize: _pageSize,
        type: _selectedType,
        status: _selectedStatus,
      );

      if (response.statusCode == 200) {
        final newItems = response.data['data']['items'] ?? [];
        final total = response.data['data']['total'] ?? 0;

        setState(() {
          if (refresh) {
            _materials = newItems;
          } else {
            _materials.addAll(newItems);
          }

          if (_materials.length >= total) {
            _refreshController.loadNoData();
          } else {
            _currentPage += 1;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：${response.data['msg'] ?? '未知错误'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败：$e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMaterialStatus(int id, String currentStatus) async {
    final newStatus = currentStatus == 'private' ? 'published' : 'private';
    try {
      final response =
          await _materialService.updateMaterialStatus(id, newStatus);
      if (response.statusCode == 200) {
        setState(() {
          final index = _materials.indexWhere((item) => item['id'] == id);
          if (index != -1) {
            _materials[index]['status'] = newStatus;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('状态更新成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('状态更新失败：${response.data['msg'] ?? '未知错误'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('状态更新失败：$e')),
      );
    }
  }

  Future<void> _deleteMaterial(int id) async {
    try {
      final response = await _materialService.deleteMaterial(id);
      if (response.statusCode == 200) {
        setState(() {
          _materials.removeWhere((item) => item['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：${response.data['msg'] ?? '未知错误'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildFilterBar(theme),
          Expanded(
            child: SmartRefresher(
              controller: _refreshController,
              enablePullDown: true,
              enablePullUp: true,
              header: const WaterDropHeader(),
              footer: const ClassicFooter(),
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              child: _materials.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        '暂无数据',
                        style:
                            TextStyle(color: theme.textTheme.bodyMedium?.color),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _materials.length,
                      itemBuilder: (context, index) {
                        final item = _materials[index];
                        return _buildMaterialCard(item, theme);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<material.MaterialType>(
              value: _selectedType,
              hint: Text('全部类型', style: TextStyle(color: theme.hintColor)),
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
              items: material.MaterialType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    material.MaterialService.getMaterialTypeName(type),
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                  ),
                );
              }).toList(),
              onChanged: (material.MaterialType? value) {
                setState(() {
                  _selectedType = value;
                  _loadMaterials(refresh: true);
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<material.MaterialStatus>(
              value: _selectedStatus,
              hint: Text('全部状态', style: TextStyle(color: theme.hintColor)),
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
              items: material.MaterialStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    material.MaterialService.getMaterialStatusName(status),
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                  ),
                );
              }).toList(),
              onChanged: (material.MaterialStatus? value) {
                setState(() {
                  _selectedStatus = value;
                  _loadMaterials(refresh: true);
                });
              },
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.iconTheme.color),
            onPressed: () => _loadMaterials(refresh: true),
            tooltip: '刷新',
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(dynamic item, ThemeData theme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: theme.cardColor,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: item['type'] == 'image'
                ? FutureBuilder<Response>(
                    future: FileService().getFile(item['metadata']),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Image.memory(
                            snapshot.data!.data,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        print('Load error: ${snapshot.error}');
                        return Center(
                          child: Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                            size: 32,
                          ),
                        );
                      }
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(theme.primaryColor),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Icon(
                      _getIconForType(item['type']),
                      size: 48,
                      color: theme.iconTheme.color?.withOpacity(0.5),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '作者：${item['author_name']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () =>
                            _toggleMaterialStatus(item['id'], item['status']),
                        child: Text(
                          item['status'] == 'private' ? '私有' : '已发布',
                          style: TextStyle(
                            color: item['status'] == 'private'
                                ? theme.textTheme.bodySmall?.color
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: () => _deleteMaterial(item['id']),
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

  IconData _getIconForType(String type) {
    switch (type) {
      case 'template':
        return Icons.description;
      case 'prefix':
        return Icons.format_quote;
      case 'suffix':
        return Icons.format_quote;
      default:
        return Icons.insert_drive_file;
    }
  }
}
