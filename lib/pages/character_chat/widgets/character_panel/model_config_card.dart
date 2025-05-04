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
        _buildSliderItem(
          '温度',
          'temperature',
          temperatureController,
          0.0,
          1.0,
          20,
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
          8196,
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

  Widget _buildModelSelector(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '模型',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 4.w,
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
          SizedBox(height: 8.h),
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
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: Colors.white.withOpacity(0.6),
                ),
              ],
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
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
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
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
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
              Text(
                controller.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withOpacity(0.2),
              trackHeight: 4.h,
            ),
            child: Slider(
              value: double.tryParse(controller.text)?.toDouble() ??
                  (isInt ? min.toInt().toDouble() : min),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (value) {
                final newValue = isInt ? value.toInt() : value;
                controller.text =
                    isInt ? newValue.toString() : newValue.toStringAsFixed(2);
                onUpdateField(field, newValue);
              },
            ),
          ),
        ],
      ),
    );
  }
}
