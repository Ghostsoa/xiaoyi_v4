import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import 'base_card.dart';
import '../../../../pages/create/character/select_model_page.dart';

class ModelConfigCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BaseCard(
      title: 'AI模型配置',
      children: [
        _buildModelSelector(context),
        _buildEnhanceModeSelector(context),
        _buildSliderItem(
          '温度',
          'temperature',
          temperatureController,
          0.0,
          2.0,
          40,
        ),
        _buildSliderItem(
          'Top P',
          'top_p',
          topPController,
          0.0,
          1.0,
          20,
        ),
        _buildSliderItem(
          'Top K',
          'top_k',
          topKController,
          1,
          100,
          99,
          isInt: true,
        ),
        _buildSliderItem(
          '最大Token',
          'max_tokens',
          maxTokensController,
          100,
          8192,
          81,
          isInt: true,
        ),
        _buildSliderItem(
          '记忆轮数',
          'memory_turns',
          memoryTurnsController,
          1,
          500,
          499,
          isInt: true,
        ),
        _buildSliderItem(
          '搜索深度',
          'search_depth',
          searchDepthController,
          1,
          10,
          9,
          isInt: true,
        ),
      ],
    );
  }

  Widget _buildEnhanceModeSelector(BuildContext context) {
    final currentMode =
        editedData['enhance_mode'] ?? sessionData['enhance_mode'] ?? 'disabled';

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primaryColor,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                '回复增强',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'Beta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 36.w),
            child: Text(
              '利用特殊技术增强角色的回复质量，选择合适的模式获得更好的体验',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12.sp,
              ),
            ),
          ),
          SizedBox(height: 12.h),
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

    return GestureDetector(
      onTap: () {
        onUpdateField('enhance_mode', mode);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.white.withOpacity(0.3),
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
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      fontSize: 14.sp,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
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

  Widget _buildModelSelector(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: AppTheme.primaryColor,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                '模型',
                style: TextStyle(
                  color: Colors.white,
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
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '可编辑',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SelectModelPage(),
                ),
              );
              if (result != null) {
                onUpdateField('model_name', result);
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      editedData['model_name'] ??
                          sessionData['model_name'] ??
                          '未知',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: AppTheme.primaryColor,
                  ),
                ],
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
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor
                          .withOpacity(isDisabled ? 0.05 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForField(field),
                      color: AppTheme.primaryColor
                          .withOpacity(isDisabled ? 0.5 : 1.0),
                      size: 16.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(isDisabled ? 0.5 : 1.0),
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
                      color: AppTheme.primaryColor
                          .withOpacity(isDisabled ? 0.1 : 0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      isDisabled ? '已锁定' : '可编辑',
                      style: TextStyle(
                        color: isDisabled
                            ? AppTheme.primaryColor.withOpacity(0.5)
                            : AppTheme.primaryColor,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color:
                      AppTheme.primaryColor.withOpacity(isDisabled ? 0.1 : 0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  controller.text,
                  style: TextStyle(
                    color: isDisabled
                        ? AppTheme.primaryColor.withOpacity(0.5)
                        : AppTheme.primaryColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: isDisabled
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : AppTheme.primaryColor,
                inactiveTrackColor: isDisabled
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.primaryColor.withOpacity(0.2),
                thumbColor: isDisabled
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : AppTheme.primaryColor,
                overlayColor: AppTheme.primaryColor.withOpacity(0.2),
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
                value: double.tryParse(controller.text)?.toDouble() ??
                    (isInt ? min.toInt().toDouble() : min),
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
                        onUpdateField(field, newValue);
                      },
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  min.toString(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10.sp,
                  ),
                ),
                Text(
                  max.toString(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10.sp,
                  ),
                ),
              ],
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
      case 'search_depth':
        return Icons.search;
      default:
        return Icons.settings;
    }
  }
}
