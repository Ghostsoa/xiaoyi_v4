import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_theme.dart';

class DataAnalysisPage extends StatefulWidget {
  const DataAnalysisPage({super.key});

  @override
  State<DataAnalysisPage> createState() => _DataAnalysisPageState();
}

class _DataAnalysisPageState extends State<DataAnalysisPage> {
  String _timeRange = '本周';

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryColor;
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 数据概览
            Row(
              children: [
                Expanded(
                  child: _buildDataItem(
                    title: '今日活跃用户',
                    value: '1,248',
                    subtext: '↑ 5.2%',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ),
                Expanded(
                  child: _buildDataItem(
                    title: '总用户数',
                    value: '12,548',
                    subtext: '↑ 1.8%',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ),
                Expanded(
                  child: _buildDataItem(
                    title: '今日收入',
                    value: '¥1,234',
                    subtext: '↑ 3.5%',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),

            // 活跃用户趋势
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '活跃用户趋势',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _timeRange,
                      isDense: true,
                      underline: const SizedBox(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: primaryColor,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _timeRange = newValue!;
                        });
                      },
                      items: <String>['今天', '本周', '本月', '全年']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  height: 200.h,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.05,
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              crossAxisSpacing: 1,
                              mainAxisSpacing: 1,
                            ),
                            itemCount: 28,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return Container();
                            },
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '这里将显示用户活跃度趋势图表',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),

            // 用户分析
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '用户构成',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 180.h,
                        child: Center(
                          child: Text(
                            '用户性别分布',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 180.h,
                        child: Center(
                          child: Text(
                            '用户年龄分布',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 32.h),

            // 收入统计
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '收入统计',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  height: 200.h,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.05,
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              crossAxisSpacing: 1,
                              mainAxisSpacing: 1,
                            ),
                            itemCount: 28,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return Container();
                            },
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '这里将显示收入统计图表',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem({
    required String title,
    required String value,
    required String subtext,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              color: textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
