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
  List<Map<String, dynamic>> _modelSeriesList = [];

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
      setState(() {
        _modelSeriesList = models;
      });
    } catch (e) {
      _showErrorDialog('加载模型列表失败：$e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.cardBackground,
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
                    border: Border.all(color: AppTheme.border),
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
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _modelSeriesList.length,
              itemBuilder: (context, index) {
                final series = _modelSeriesList[index];
                final models =
                    List<Map<String, dynamic>>.from(series['models']);

                return Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              series['displayName'] ?? '未命名模型',
                              style: AppTheme.titleStyle,
                            ),
                            if (series['endpoint']?.isNotEmpty == true)
                              Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: Text(
                                  series['endpoint'],
                                  style: AppTheme.secondaryStyle,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: AppTheme.border,
                      ),
                      ...models.map((model) {
                        return ListTile(
                          title: Text(
                            model['displayName'] ?? '未命名',
                            style: AppTheme.bodyStyle,
                          ),
                          subtitle: Text(
                            '输入：${model['inputPrice']}/1K tokens  输出：${model['outputPrice']}/1K tokens',
                            style: AppTheme.secondaryStyle,
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16.sp,
                            color: AppTheme.textSecondary,
                          ),
                          onTap: () {
                            Navigator.pop(context, model['name']);
                          },
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
