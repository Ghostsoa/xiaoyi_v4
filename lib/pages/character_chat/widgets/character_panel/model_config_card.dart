import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../pages/create/character/select_model_page.dart';
import '../../../../theme/app_theme.dart';

class ModelConfigCard extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final Map<String, dynamic> editedData;
  final Function(String, dynamic) onUpdateField;
  final TextEditingController temperatureController;
  final TextEditingController topPController;
  final TextEditingController topKController;
  final TextEditingController maxTokensController;
  final TextEditingController memoryTurnsController;
  final TextEditingController searchDepthController;

  const ModelConfigCard({
    super.key,
    required this.sessionData,
    required this.editedData,
    required this.onUpdateField,
    required this.temperatureController,
    required this.topPController,
    required this.topKController,
    required this.maxTokensController,
    required this.memoryTurnsController,
    required this.searchDepthController,
  });

  @override
  State<ModelConfigCard> createState() => _ModelConfigCardState();
}

class _ModelConfigCardState extends State<ModelConfigCard> {
  bool _isCustomModelMode = false;
  final TextEditingController _customModelController = TextEditingController();

  @override
  void dispose() {
    _customModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModelSelector(context),
        _buildEnhanceModeSelector(context),
        _buildParametersContainer(),
      ],
    );
  }

  Widget _buildParametersContainer() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.r),
        border:
            Border(left: BorderSide(color: AppTheme.primaryColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: AppTheme.primaryColor,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  '模型参数配置',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildSliderItem(
            '温度',
            'temperature',
            widget.temperatureController,
            0.0,
            2.0,
            40,
            accentColor: AppTheme.primaryColor,
            description: '控制回复的随机性，值越高创造性越强，值越低回复越稳定',
          ),
          _buildSliderItem(
            'Top P',
            'top_p',
            widget.topPController,
            0.0,
            1.0,
            20,
            accentColor: AppTheme.primaryLight,
            description: '控制输出的多样性，值越低输出越集中于高概率词',
          ),
          _buildSliderItem(
            'Top K',
            'top_k',
            widget.topKController,
            1,
            100,
            99,
            isInt: true,
            accentColor: AppTheme.accentPink,
            description: '限制每步生成时考虑的候选词数量',
          ),
          _buildSliderItem(
            '最大Token',
            'max_tokens',
            widget.maxTokensController,
            100,
            8192,
            81,
            isInt: true,
            accentColor: AppTheme.primaryColor.withBlue(180),
            description: '单次回复的最大长度限制，越大回复越长',
          ),
          _buildSliderItem(
            '记忆轮数',
            'memory_turns',
            widget.memoryTurnsController,
            1,
            500,
            499,
            isInt: true,
            accentColor: AppTheme.primaryColor.withRed(180),
            description: '角色能记住的对话历史轮数，越大记忆越长',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhanceModeSelector(BuildContext context) {
    final currentMode =
        widget.editedData['enhance_mode'] ?? widget.sessionData['enhance_mode'] ?? 'disabled';
    final accentColor = AppTheme.accentPink;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: accentColor,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                '回复增强技术',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'Beta',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding:
                EdgeInsets.only(left: 44.w, right: 16.w, top: 4.h, bottom: 8.h),
            child: Text(
              '利用特殊技术增强角色的回复质量，选择合适的模式获得更好的体验',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
            ),
          ),
          Column(
            children: [
              _buildEnhanceModeOption(
                context,
                'disabled',
                '禁用回复增强',
                '使用原生模型输出，不进行特殊处理',
                currentMode,
              ),
              SizedBox(height: 8.h),
              _buildEnhanceModeOption(
                context,
                'full',
                '回复超级增强',
                '对所有回复进行增强，大幅度提升\n回复质量，文笔，内容，逻辑，等',
                currentMode,
              ),
              SizedBox(height: 8.h),
              _buildEnhanceModeOption(
                context,
                'partial',
                '回复UI增强',
                '对UI显示效果，内容进行增强，\n平衡了UI显示与回复质量',
                currentMode,
              ),
              SizedBox(height: 8.h),
              _buildEnhanceModeOption(
                context,
                'fullpromax',
                '???',
                '???',
                currentMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhanceModeOption(
    BuildContext context,
    String mode,
    String title,
    String description,
    String currentMode,
  ) {
    final bool isSelected = currentMode == mode;
    final Color optionColor = _getColorForEnhanceMode(mode);

    return GestureDetector(
      onTap: () {
        widget.onUpdateField('enhance_mode', mode);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color:
              isSelected ? optionColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: isSelected ? optionColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: isSelected ? optionColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? optionColor : AppTheme.textSecondary,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 14.sp,
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? optionColor : AppTheme.textPrimary,
                      fontSize: 14.sp,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForEnhanceMode(String mode) {
    switch (mode) {
      case 'disabled':
        return AppTheme.textHint;
      case 'full':
        return AppTheme.accentPink;
      case 'partial':
        return AppTheme.primaryLight;
      case 'fullpromax':
        return AppTheme.error;
      default:
        return AppTheme.textHint;
    }
  }

  Widget _buildModelSelector(BuildContext context) {
    final accentColor = AppTheme.primaryColor;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: accentColor,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                '模型',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '可编辑',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppTheme.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _isCustomModelMode
                    ? TextField(
                        controller: _customModelController,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: '输入自定义模型名称',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            setState(() {
                              _isCustomModelMode = false;
                            });
                            widget.onUpdateField('model_name', value.trim());
                          }
                        },
                      )
                    : Text(
                        widget.editedData['model_name'] ??
                            widget.sessionData['model_name'] ??
                            '未知',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                ),
                // 编辑按钮（自定义模型）
                IconButton(
                  icon: Icon(
                    _isCustomModelMode ? Icons.check : Icons.edit,
                    size: 16.sp,
                    color: _isCustomModelMode ? Colors.green : AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    if (_isCustomModelMode) {
                      // 确认自定义输入
                      if (_customModelController.text.trim().isNotEmpty) {
                        setState(() {
                          _isCustomModelMode = false;
                        });
                        widget.onUpdateField('model_name', _customModelController.text.trim());
                      }
                    } else {
                      // 进入编辑模式
                      setState(() {
                        _isCustomModelMode = true;
                        _customModelController.text = widget.editedData['model_name'] ??
                            widget.sessionData['model_name'] ??
                            '';
                      });
                    }
                  },
                ),
                // 选择按钮（预设模型）
                IconButton(
                  icon: Icon(
                    _isCustomModelMode ? Icons.close : Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: _isCustomModelMode ? Colors.red : AppTheme.textSecondary,
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
                      if (result != null) {
                        widget.onUpdateField('model_name', result);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 8.w, right: 8.w),
            child: Text(
              '选择不同的模型会影响角色的回复风格、质量和速度',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderItem(
    String label,
    String field,
    TextEditingController controller,
    double min,
    double max,
    int divisions, {
    bool isInt = false,
    bool isDisabled = false,
    required Color accentColor,
    bool isLast = false,
    String? description,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, isLast ? 12.h : 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                    child: Icon(
                      _getIconForField(field),
                      color: accentColor,
                      size: 14.sp,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  controller.text,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (description != null)
            Padding(
              padding: EdgeInsets.only(
                  left: 32.w, right: 8.w, top: 2.h, bottom: 4.h),
              child: Text(
                description,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          SizedBox(height: 4.h),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withOpacity(0.2),
              thumbColor: accentColor,
              overlayColor: accentColor.withOpacity(0.2),
              trackHeight: 4.h,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: 8.r,
                disabledThumbRadius: 6.r,
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: 16.r,
              ),
            ),
            child: Slider(
              value: (double.tryParse(controller.text)?.toDouble() ??
                  (isInt ? min.toInt().toDouble() : min)).clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: isDisabled
                  ? null
                  : (value) {
                      final newValue = isInt ? value.toInt() : value;
                      controller.text = isInt
                          ? newValue.toString()
                          : newValue.toStringAsFixed(2);
                      widget.onUpdateField(field, newValue);
                    },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  min.toString(),
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10.sp,
                  ),
                ),
                Text(
                  max.toString(),
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Divider(
                height: 1,
                color: AppTheme.textSecondary.withOpacity(0.1),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForField(String field) {
    switch (field) {
      case 'temperature':
        return Icons.thermostat;
      case 'top_p':
        return Icons.bar_chart;
      case 'top_k':
        return Icons.format_list_numbered;
      case 'max_tokens':
        return Icons.text_fields;
      case 'memory_turns':
        return Icons.history;
      default:
        return Icons.settings;
    }
  }
}
