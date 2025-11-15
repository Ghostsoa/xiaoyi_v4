import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import '../../character/select_model_page.dart';

class NovelModelConfigModule extends StatefulWidget {
  final String modelName;
  final Function(String) onModelNameChanged;

  const NovelModelConfigModule({
    super.key,
    required this.modelName,
    required this.onModelNameChanged,
  });

  @override
  State<NovelModelConfigModule> createState() => _NovelModelConfigModuleState();
}

class _NovelModelConfigModuleState extends State<NovelModelConfigModule> {
  bool _isCustomModelMode = false;
  final TextEditingController _customModelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 检查当前模型是否为自定义模型（不在预设列表中）
    _checkIfCustomModel();
  }

  @override
  void didUpdateWidget(NovelModelConfigModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当模型名称变化时重新检查
    if (oldWidget.modelName != widget.modelName) {
      _checkIfCustomModel();
    }
  }

  @override
  void dispose() {
    _customModelController.dispose();
    super.dispose();
  }

  void _checkIfCustomModel() {
    // 默认不进入自定义模式，用户手动点击编辑按钮进入
    _isCustomModelMode = false;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 16.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppTheme.titleSize,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('模型配置'),

        // 模型选择
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            '模型选择',
            style: TextStyle(
              fontSize: AppTheme.bodySize,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4.h),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: AppTheme.captionSize,
                    color: textSecondary,
                  ),
                  children: [
                    const TextSpan(text: '选择'),
                    TextSpan(
                      text: '合适的AI模型',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '来'),
                    TextSpan(
                      text: '驱动小说生成',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，不同模型有'),
                    TextSpan(
                      text: '不同特点',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              _isCustomModelMode
                ? TextField(
                    controller: _customModelController,
                    style: TextStyle(
                      fontSize: AppTheme.bodySize,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: '输入自定义模型名称',
                      hintStyle: TextStyle(
                        fontSize: AppTheme.bodySize,
                        color: textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: BorderSide(
                          color: textSecondary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        setState(() {
                          _isCustomModelMode = false;
                        });
                        widget.onModelNameChanged(value.trim());
                      }
                    },
                  )
                : Text(
                    widget.modelName,
                    style: TextStyle(
                      fontSize: AppTheme.bodySize,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 编辑按钮（自定义模型）
              IconButton(
                icon: Icon(
                  _isCustomModelMode ? Icons.check : Icons.edit,
                  size: 16.sp,
                  color: _isCustomModelMode ? Colors.green : textSecondary,
                ),
                onPressed: () {
                  if (_isCustomModelMode) {
                    // 确认自定义输入
                    if (_customModelController.text.trim().isNotEmpty) {
                      setState(() {
                        _isCustomModelMode = false;
                      });
                      widget.onModelNameChanged(_customModelController.text.trim());
                    }
                  } else {
                    // 进入编辑模式
                    setState(() {
                      _isCustomModelMode = true;
                      _customModelController.text = widget.modelName;
                    });
                  }
                },
              ),
              // 选择按钮（预设模型）
              IconButton(
                icon: Icon(
                  _isCustomModelMode ? Icons.close : Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: _isCustomModelMode ? Colors.red : textSecondary,
                ),
                onPressed: () async {
                  if (_isCustomModelMode) {
                    // 取消编辑
                    setState(() {
                      _isCustomModelMode = false;
                      _customModelController.clear();
                    });
                  } else {
                    // 选择预设模型
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SelectModelPage(),
                      ),
                    );
                    if (result != null && mounted) {
                      widget.onModelNameChanged(result);
                    }
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // 底部提示
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.amber,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: AppTheme.captionSize,
                      color: textSecondary,
                    ),
                    children: [
                      const TextSpan(text: '提示：小说使用的模型将决定'),
                      TextSpan(
                        text: '创作风格',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '和'),
                      TextSpan(
                        text: '生成质量',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '，请根据您的需求选择合适的模型'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // 模型选择建议
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '重要提示',
                    style: TextStyle(
                      fontSize: AppTheme.bodySize,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: AppTheme.captionSize,
                    color: textSecondary,
                  ),
                  children: [
                    const TextSpan(text: '建议优先选择'),
                    TextSpan(
                      text: 'Gemini系列模型',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，因为它拥有'),
                    TextSpan(
                      text: '100万token上下文窗口',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，而其他模型普遍仅有'),
                    TextSpan(
                      text: '12.8万或20万',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，这对于'),
                    TextSpan(
                      text: '完整编写长篇小说',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '至关重要'),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // 上下文窗口限制警告
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.purple,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '上下文窗口限制',
                    style: TextStyle(
                      fontSize: AppTheme.bodySize,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: AppTheme.captionSize,
                    color: textSecondary,
                  ),
                  children: [
                    const TextSpan(text: '请注意：如果选择上下文窗口较小的模型，当您的小说写到'),
                    TextSpan(
                      text: '全本的一半甚至三分之一',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: '时，可能会'),
                    TextSpan(
                      text: '无法继续创作',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: '，这是因为'),
                    TextSpan(
                      text: '超过了模型的上下文窗口限制',
                      style: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '。建议选择'),
                    TextSpan(
                      text: '更大上下文窗口的模型',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // 具体示例
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '模型上下文对比',
                    style: TextStyle(
                      fontSize: AppTheme.bodySize,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                '以下是不同模型可支持的小说篇幅估算：',
                style: TextStyle(
                  fontSize: AppTheme.captionSize,
                  color: textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              _buildModelComparisonItem(
                '常规模型 (12.8万token)',
                '约10-15万字小说',
                '小型短篇',
                Colors.amber,
              ),
              SizedBox(height: 8.h),
              _buildModelComparisonItem(
                'Claude/GPT系列 (20万token)',
                '约15-25万字小说',
                '中型作品',
                Colors.orange,
              ),
              SizedBox(height: 8.h),
              _buildModelComparisonItem(
                'Gemini系列 (100万token)',
                '约80-100万字小说',
                '长篇巨著',
                Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModelComparisonItem(
    String modelName,
    String wordCount,
    String recommendation,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.circle,
          size: 10.sp,
          color: color,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: AppTheme.captionSize,
                color: AppTheme.textSecondary,
              ),
              children: [
                TextSpan(
                  text: '$modelName: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                TextSpan(text: '$wordCount，适合'),
                TextSpan(
                  text: recommendation,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
