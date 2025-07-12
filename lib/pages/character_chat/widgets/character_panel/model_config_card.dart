import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
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
    final Color pageColor = Colors.green.shade400; // 使用分页的绿色

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 移除标题部分
        _buildModelSelector(context),
        _buildEnhanceModeSelector(context),
        _buildSliderItem(
          '温度',
          'temperature',
          temperatureController,
          0.0,
          2.0,
          40,
          accentColor: Colors.orange,
        ),
        _buildSliderItem(
          'Top P',
          'top_p',
          topPController,
          0.0,
          1.0,
          20,
          accentColor: Colors.purple,
        ),
        _buildSliderItem(
          'Top K',
          'top_k',
          topKController,
          1,
          100,
          99,
          isInt: true,
          accentColor: Colors.indigo,
        ),
        _buildSliderItem(
          '最大Token',
          'max_tokens',
          maxTokensController,
          100,
          8192,
          81,
          isInt: true,
          accentColor: Colors.teal,
        ),
        _buildSliderItem(
          '记忆轮数',
          'memory_turns',
          memoryTurnsController,
          1,
          500,
          499,
          isInt: true,
          accentColor: Colors.blue,
        ),
        _buildSliderItem(
          '搜索深度',
          'search_depth',
          searchDepthController,
          1,
          10,
          9,
          isInt: true,
          accentColor: Colors.cyan,
        ),
      ],
    );
  }

  Widget _buildEnhanceModeSelector(BuildContext context) {
    final currentMode =
        editedData['enhance_mode'] ?? sessionData['enhance_mode'] ?? 'disabled';
    final accentColor = Colors.amber;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.2),
                  Colors.black.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withOpacity(0.8),
                              accentColor.withOpacity(0.5),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
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
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.withOpacity(0.8),
                              Colors.orange.withOpacity(0.8)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
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
                ),
                Padding(
                  padding:
                      EdgeInsets.only(left: 44.w, right: 16.w, bottom: 12.h),
                  child: Text(
                    '利用特殊技术增强角色的回复质量，选择合适的模式获得更好的体验',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12.sp,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 1,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  child: Column(
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
                ),
              ],
            ),
          ),
        ),
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
        onUpdateField('enhance_mode', mode);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    optionColor.withOpacity(0.6),
                    optionColor.withOpacity(0.3),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected
                ? optionColor.withOpacity(0.8)
                : optionColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: optionColor.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          optionColor.withOpacity(0.8),
                          optionColor.withOpacity(0.5),
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? optionColor : Colors.white.withOpacity(0.5),
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
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.8),
                      fontSize: 14.sp,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: isSelected ? 2 : 1,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12.sp,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 1,
                          offset: Offset(0, 1),
                        ),
                      ],
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
        return Colors.grey.shade500;
      case 'full':
        return Colors.purple.shade500;
      case 'partial':
        return Colors.blue.shade500;
      case 'fullpromax':
        return Colors.red.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  Widget _buildModelSelector(BuildContext context) {
    final accentColor = Colors.deepPurple;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.2),
                  Colors.black.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withOpacity(0.8),
                              accentColor.withOpacity(0.5),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.smart_toy,
                          color: Colors.white,
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
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withOpacity(0.8),
                              accentColor.withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '可编辑',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                  child: GestureDetector(
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
                      padding: EdgeInsets.symmetric(
                          vertical: 10.h, horizontal: 12.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor.withOpacity(0.4),
                            accentColor.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: accentColor.withOpacity(0.4),
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
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.2),
                  Colors.black.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accentColor
                                      .withOpacity(isDisabled ? 0.4 : 0.8),
                                  accentColor
                                      .withOpacity(isDisabled ? 0.2 : 0.5),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              _getIconForField(field),
                              color: Colors.white
                                  .withOpacity(isDisabled ? 0.5 : 1.0),
                              size: 16.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            label,
                            style: TextStyle(
                              color: Colors.white
                                  .withOpacity(isDisabled ? 0.5 : 1.0),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accentColor
                                      .withOpacity(isDisabled ? 0.4 : 0.8),
                                  accentColor
                                      .withOpacity(isDisabled ? 0.2 : 0.5),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              isDisabled ? '已锁定' : '可编辑',
                              style: TextStyle(
                                color: Colors.white
                                    .withOpacity(isDisabled ? 0.5 : 1.0),
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withOpacity(isDisabled ? 0.4 : 0.6),
                              accentColor.withOpacity(isDisabled ? 0.2 : 0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          controller.text,
                          style: TextStyle(
                            color: Colors.white
                                .withOpacity(isDisabled ? 0.5 : 1.0),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 1,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: isDisabled
                          ? accentColor.withOpacity(0.3)
                          : accentColor.withOpacity(0.8),
                      inactiveTrackColor: isDisabled
                          ? accentColor.withOpacity(0.1)
                          : accentColor.withOpacity(0.2),
                      thumbColor: isDisabled
                          ? accentColor.withOpacity(0.3)
                          : accentColor,
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
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        min.toString(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10.sp,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 1,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        max.toString(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10.sp,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 1,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
