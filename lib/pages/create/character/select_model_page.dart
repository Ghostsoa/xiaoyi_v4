import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../services/model_service.dart';
import '../../../theme/app_theme.dart';

class SelectModelPage extends StatefulWidget {
  const SelectModelPage({super.key});

  @override
  State<SelectModelPage> createState() => _SelectModelPageState();
}

class _SelectModelPageState extends State<SelectModelPage> {
  final ModelService _modelService = ModelService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _modelsList = [];
  List<Map<String, dynamic>> _customModelsList = [];
  List<Map<String, dynamic>> _filteredModelsList = [];
  List<String> _providers = ['全部'];
  String _selectedProvider = '全部';

  @override
  void initState() {
    super.initState();
    _loadCustomModels();
    _loadModels();
  }

  Future<void> _loadModels() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final models = await _modelService.getAvailableModels();

      // 提取所有供应商
      final Set<String> providersSet = {'全部'};
      for (var model in models) {
        if (model['provider'] != null &&
            model['provider'].toString().isNotEmpty) {
          providersSet.add(model['provider']);
        }
      }

      setState(() {
        _modelsList = models;
        _updateFilteredList();
        _providers = providersSet.toList();
      });
    } catch (e) {
      _showErrorDialog('加载模型列表失败：$e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateFilteredList() {
    if (_selectedProvider == '全部') {
      _filteredModelsList = [..._customModelsList, ..._modelsList];
    } else {
      _filteredModelsList = _modelsList
          .where((model) => model['provider'] == _selectedProvider)
          .toList();
    }
  }

  void _filterModelsByProvider(String provider) {
    setState(() {
      _selectedProvider = provider;
      _updateFilteredList();
    });
  }

  Future<void> _loadCustomModels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customModelsJson = prefs.getString('custom_models');
      if (customModelsJson != null) {
        final List<dynamic> decoded = json.decode(customModelsJson);
        setState(() {
          _customModelsList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      print('加载自定义模型失败: $e');
    }
  }

  Future<void> _saveCustomModels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customModelsJson = json.encode(_customModelsList);
      await prefs.setString('custom_models', customModelsJson);
    } catch (e) {
      print('保存自定义模型失败: $e');
    }
  }

  void _showAddCustomModelDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          '添加自定义模型',
          style: AppTheme.titleStyle.copyWith(
            color: AppTheme.primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: AppTheme.bodyStyle,
              decoration: InputDecoration(
                labelText: '模型名称',
                labelStyle: AppTheme.secondaryStyle,
                hintText: '请输入模型名称',
                hintStyle: AppTheme.secondaryStyle.copyWith(
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                    color: AppTheme.textSecondary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: descController,
              style: AppTheme.bodyStyle,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '模型描述',
                labelStyle: AppTheme.secondaryStyle,
                hintText: '请输入模型描述（可选）',
                hintStyle: AppTheme.secondaryStyle.copyWith(
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                    color: AppTheme.textSecondary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            child: Text(
              '取消',
              style: AppTheme.buttonTextStyle.copyWith(
                color: AppTheme.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                _showErrorDialog('请输入模型名称');
                return;
              }

              final now = DateTime.now();
              final customModel = {
                'name': nameController.text.trim(),
                'description': descController.text.trim().isEmpty
                    ? '自定义模型'
                    : descController.text.trim(),
                'provider': 'custom',
                'update': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                'isCustom': true,
              };

              setState(() {
                _customModelsList.insert(0, customModel);
                _updateFilteredList();
              });
              _saveCustomModels();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              '添加',
              style: AppTheme.buttonTextStyle.copyWith(
                color: AppTheme.primaryColor,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteCustomModel(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          '删除确认',
          style: AppTheme.titleStyle.copyWith(
            color: AppTheme.error,
          ),
        ),
        content: Text(
          '确定要删除这个自定义模型吗？',
          style: AppTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: AppTheme.buttonTextStyle.copyWith(
                color: AppTheme.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _customModelsList.removeAt(index);
                _updateFilteredList();
              });
              _saveCustomModels();
              Navigator.pop(context);
            },
            child: Text(
              '删除',
              style: AppTheme.buttonTextStyle.copyWith(
                color: AppTheme.error,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          '错误',
          style: AppTheme.titleStyle.copyWith(
            color: AppTheme.error,
          ),
        ),
        content: Text(
          message,
          style: AppTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              '确定',
              style: AppTheme.buttonTextStyle.copyWith(
                color: AppTheme.primaryColor,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 36.h,
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _providers.length,
        itemBuilder: (context, index) {
          final provider = _providers[index];
          final isSelected = provider == _selectedProvider;

          return GestureDetector(
            onTap: () => _filterModelsByProvider(provider),
            child: Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                provider,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.background,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Container(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 8.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppTheme.textPrimary,
                    size: 18.sp,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '选择模型',
                    style: AppTheme.titleStyle,
                  ),
                ),
              ),
              SizedBox(width: 32.w),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 32.sp,
                    height: 32.sp,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '加载中...',
                    style: AppTheme.secondaryStyle,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildCategoryTabs(),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                  child: InkWell(
                    onTap: _showAddCustomModelDialog,
                    child: Container(
                      height: 40.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppTheme.textSecondary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            size: 20.sp,
                            color: AppTheme.textSecondary.withOpacity(0.7),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '添加自定义模型',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredModelsList.isEmpty
                      ? Center(
                          child: Text(
                            '没有符合条件的模型',
                            style: AppTheme.secondaryStyle,
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: _filteredModelsList.length,
                          itemBuilder: (context, index) {
                            final model = _filteredModelsList[index];
                            final isCustom = model['isCustom'] == true;

                            return Container(
                              margin: EdgeInsets.only(bottom: 16.h),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                                border: isCustom
                                    ? Border.all(
                                        color: AppTheme.primaryColor.withOpacity(0.5),
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                title: Text(
                                  model['name'] ?? '未命名',
                                  style: AppTheme.bodyStyle.copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 6.h),
                                    Text(
                                      model['description'] ?? '暂无描述',
                                      style: AppTheme.secondaryStyle.copyWith(
                                        fontSize: 13.sp,
                                        color: AppTheme.textSecondary.withOpacity(0.6),
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 6.h),
                                    Row(
                                      children: [
                                        if (isCustom)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6.w,
                                              vertical: 2.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(3.r),
                                              border: Border.all(
                                                color: AppTheme.primaryColor.withOpacity(0.6),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              '自定义',
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          )
                                        else
                                          Text(
                                            '提供商：${model['provider'] ?? '未知'}',
                                            style:
                                                AppTheme.secondaryStyle.copyWith(
                                              fontSize: 11.sp,
                                              color: AppTheme.textSecondary
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        if (model['update'] != null &&
                                            model['update']
                                                .toString()
                                                .isNotEmpty) ...[                                          Text(
                                            ' · ',
                                            style: AppTheme.secondaryStyle
                                                .copyWith(
                                              fontSize: 11.sp,
                                              color: AppTheme.textSecondary
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                          Text(
                                            '${isCustom ? '创建' : '更新'}：${model['update']}',
                                            style: AppTheme.secondaryStyle
                                                .copyWith(
                                              fontSize: 11.sp,
                                              color: AppTheme.textSecondary
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isCustom)
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          size: 18.sp,
                                          color: AppTheme.error,
                                        ),
                                        onPressed: () {
                                          final customIndex =
                                              _customModelsList.indexWhere(
                                            (m) => m['name'] == model['name'],
                                          );
                                          if (customIndex != -1) {
                                            _deleteCustomModel(customIndex);
                                          }
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                      ),
                                    SizedBox(width: 8.w),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16.sp,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pop(context, model['name']);
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
}
