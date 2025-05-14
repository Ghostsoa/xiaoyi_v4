import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';

class StatusBar extends StatelessWidget {
  final Map<String, dynamic> statusData;
  final Color textColor;

  const StatusBar({
    Key? key,
    required this.statusData,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            textColor.withOpacity(0.1),
            textColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: textColor.withOpacity(0.1),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 2.h),
                  child: Text(
                    '状态',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: textColor.withOpacity(0.5),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 10.h),
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: statusData.entries.map((entry) {
                      final isNumeric = entry.value == "num" ||
                          (entry.value is num) ||
                          (entry.value is String &&
                              double.tryParse(entry.value.toString()) != null);

                      if (isNumeric) {
                        double value = 0;
                        if (entry.value is num) {
                          value = (entry.value as num).toDouble();
                        } else if (entry.value is String &&
                            double.tryParse(entry.value.toString()) != null) {
                          value = double.parse(entry.value.toString());
                        }

                        double maxValue = 100;
                        if (value > 1000) {
                          maxValue = 10000;
                        } else if (value > 100) {
                          maxValue = 1000;
                        }

                        double normalizedValue = value / maxValue;
                        if (normalizedValue > 1) normalizedValue = 1;
                        if (normalizedValue < 0) normalizedValue = 0;

                        return Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 4.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          "${entry.key}",
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          "${value.toInt()}",
                                          style: TextStyle(
                                            color: _getProgressColor(
                                                normalizedValue),
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2.h),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3.r),
                                child: LinearProgressIndicator(
                                  value: normalizedValue,
                                  backgroundColor: textColor.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getProgressColor(normalizedValue),
                                  ),
                                  minHeight: 4.h,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Container(
                          decoration: BoxDecoration(
                            color: textColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: textColor.withOpacity(0.1),
                              width: 0.5,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 4.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${entry.key}",
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                "${entry.value}",
                                style: TextStyle(
                                  color: textColor.withOpacity(0.9),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double value) {
    if (value < 0.3) {
      return Colors.redAccent;
    } else if (value < 0.6) {
      return Colors.amber;
    } else {
      return Color(0xFF00C853);
    }
  }
}
