import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import '../select_model_page.dart';

class ModelConfigModule extends StatefulWidget {
  final String modelName;
  final double temperature;
  final double topP;
  final int topK;
  final int maxTokens;
  final Function(String) onModelNameChanged;
  final Function(double) onTemperatureChanged;
  final Function(double) onTopPChanged;
  final Function(int) onTopKChanged;
  final Function(int) onMaxTokensChanged;

  const ModelConfigModule({
    super.key,
    required this.modelName,
    required this.temperature,
    required this.topP,
    required this.topK,
    required this.maxTokens,
    required this.onModelNameChanged,
    required this.onTemperatureChanged,
    required this.onTopPChanged,
    required this.onTopKChanged,
    required this.onMaxTokensChanged,
  });

  @override
  State<ModelConfigModule> createState() => _ModelConfigModuleState();
}

class _ModelConfigModuleState extends State<ModelConfigModule> {
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h, bottom: 16.h),
      child: Text(
        title,
        style: AppTheme.titleStyle.copyWith(
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildParameterSection({
    required String title,
    required Widget description,
    required String value,
    required Widget slider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTheme.secondaryStyle,
            ),
            Text(
              value,
              style: AppTheme.bodyStyle,
            ),
          ],
        ),
        SizedBox(height: 4.h),
        description,
        SizedBox(height: 8.h),
        slider,
        SizedBox(height: 20.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('模型配置'),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '模型选择',
                  style: AppTheme.secondaryStyle,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4.h),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: AppTheme.captionSize,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: '选择合适的'),
                          TextSpan(
                            text: 'AI模型',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: '来驱动角色对话'),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      widget.modelName,
                      style: AppTheme.bodyStyle,
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: AppTheme.textSecondary,
                ),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelectModelPage(),
                    ),
                  );
                  if (result != null && mounted) {
                    widget.onModelNameChanged(result);
                  }
                },
              ),
              SizedBox(height: 16.h),
              _buildParameterSection(
                title: '温度',
                description: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: AppTheme.captionSize,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: '控制回复的'),
                      TextSpan(
                        text: '随机性',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ',值越大回复越'),
                      TextSpan(
                        text: '有创意',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ',值越小回复越'),
                      TextSpan(
                        text: '稳定保守',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                value: widget.temperature.toStringAsFixed(2),
                slider: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
                    thumbColor: AppTheme.primaryColor,
                    overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                    trackHeight: 4.h,
                  ),
                  child: Slider(
                    value: widget.temperature,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: widget.onTemperatureChanged,
                  ),
                ),
              ),
              _buildParameterSection(
                title: 'Top P',
                description: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: AppTheme.captionSize,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: '控制'),
                      TextSpan(
                        text: '词汇采样范围',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ',值越大用词越'),
                      TextSpan(
                        text: '丰富',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ',值越小用词越'),
                      TextSpan(
                        text: '保守',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                value: widget.topP.toStringAsFixed(2),
                slider: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
                    thumbColor: AppTheme.primaryColor,
                    overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                    trackHeight: 4.h,
                  ),
                  child: Slider(
                    value: widget.topP,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: widget.onTopPChanged,
                  ),
                ),
              ),
              _buildParameterSection(
                title: 'Top K',
                description: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: AppTheme.captionSize,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: '控制每次选词时考虑的'),
                      TextSpan(
                        text: '候选词数量',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ',值越大'),
                      TextSpan(
                        text: '选词范围',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '越广'),
                    ],
                  ),
                ),
                value: widget.topK.toString(),
                slider: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
                    thumbColor: AppTheme.primaryColor,
                    overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                    trackHeight: 4.h,
                  ),
                  child: Slider(
                    value: widget.topK.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (value) => widget.onTopKChanged(value.toInt()),
                  ),
                ),
              ),
              _buildParameterSection(
                title: '最大Token',
                description: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: AppTheme.captionSize,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: '控制单次回复的'),
                      TextSpan(
                        text: '最大长度',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ',值越大回复可以'),
                      TextSpan(
                        text: '更长',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                value: widget.maxTokens.toString(),
                slider: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
                    thumbColor: AppTheme.primaryColor,
                    overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                    trackHeight: 4.h,
                  ),
                  child: Slider(
                    value: widget.maxTokens.toDouble(),
                    min: 100,
                    max: 8196,
                    divisions: 81,
                    onChanged: (value) =>
                        widget.onMaxTokensChanged(value.toInt()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
