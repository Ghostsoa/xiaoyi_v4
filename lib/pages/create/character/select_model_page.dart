import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  List<Map<String, dynamic>> _filteredModelsList = [];
  List<String> _providers = ['全部'];
  String _selectedProvider = '全部';

  @override
  void initState() {
    super.initState();
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
        _filteredModelsList = models;
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

  void _filterModelsByProvider(String provider) {
    setState(() {
      _selectedProvider = provider;
      if (provider == '全部') {
        _filteredModelsList = _modelsList;
      } else {
        _filteredModelsList = _modelsList
            .where((model) => model['provider'] == provider)
            .toList();
      }
    });
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

                            return Container(
                              margin: EdgeInsets.only(bottom: 16.h),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                title: Text(
                                  model['name'] ?? '未命名',
                                  style: AppTheme.bodyStyle,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4.h),
                                    Text(
                                      model['description'] ?? '暂无描述',
                                      style: AppTheme.secondaryStyle,
                                    ),
                                    SizedBox(height: 2.h),
                                    Row(
                                      children: [
                                        Text(
                                          '提供商：${model['provider'] ?? '未知'}',
                                          style:
                                              AppTheme.secondaryStyle.copyWith(
                                            fontSize: 12.sp,
                                            color: AppTheme.textSecondary
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                        if (model['update'] != null &&
                                            model['update']
                                                .toString()
                                                .isNotEmpty)
                                          Text(
                                            ' · 更新：${model['update']}',
                                            style: AppTheme.secondaryStyle
                                                .copyWith(
                                              fontSize: 12.sp,
                                              color: AppTheme.textSecondary
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16.sp,
                                  color: AppTheme.textSecondary,
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
