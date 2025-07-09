import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';

class LevelDistributionPage extends StatelessWidget {
  final int currentExp;
  final int currentLevel;
  final String currentLevelName;

  const LevelDistributionPage({
    super.key,
    required this.currentExp,
    required this.currentLevel,
    required this.currentLevelName,
  });

  @override
  Widget build(BuildContext context) {
    // 等级分布数据
    final levelDistribution = [
      {'level': 1, 'minExp': 0, 'maxExp': 999, 'levelName': '小小懿'},
      {'level': 2, 'minExp': 1000, 'maxExp': 2999, 'levelName': '小懿'},
      {'level': 3, 'minExp': 3000, 'maxExp': 9999, 'levelName': '劳懿'},
      {'level': 4, 'minExp': 10000, 'maxExp': 49999, 'levelName': '大牢懿'},
      {'level': 5, 'minExp': 50000, 'maxExp': 999999999, 'levelName': '神懿'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: Text(
          '等级分布',
          style: AppTheme.titleStyle,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textPrimary,
            size: 20.sp,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 当前等级信息卡片
              _buildCurrentLevelCard(context),
              SizedBox(height: 24.h),
              // 等级分布说明
              Text(
                '等级分布',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              // 等级列表
              ...levelDistribution.map((level) => _buildLevelItem(
                    context,
                    level: level['level'] as int,
                    minExp: level['minExp'] as int,
                    maxExp: level['maxExp'] as int,
                    levelName: level['levelName'] as String,
                    isCurrentLevel: level['level'] == currentLevel,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLevelCard(BuildContext context) {
    // 计算到下一级所需的经验值
    int nextLevelExp = 0;
    String nextLevelName = '';

    switch (currentLevel) {
      case 1:
        nextLevelExp = 1000;
        nextLevelName = '小懿';
        break;
      case 2:
        nextLevelExp = 3000;
        nextLevelName = '劳懿';
        break;
      case 3:
        nextLevelExp = 10000;
        nextLevelName = '大牢懿';
        break;
      case 4:
        nextLevelExp = 50000;
        nextLevelName = '神懿';
        break;
      default:
        nextLevelExp = 0;
        nextLevelName = '';
    }

    // 计算当前等级的最小经验值
    int currentLevelMinExp = 0;
    switch (currentLevel) {
      case 2:
        currentLevelMinExp = 1000;
        break;
      case 3:
        currentLevelMinExp = 3000;
        break;
      case 4:
        currentLevelMinExp = 10000;
        break;
      case 5:
        currentLevelMinExp = 50000;
        break;
    }

    // 计算升级进度
    double progress = 0;
    if (currentLevel < 5 && nextLevelExp > currentLevelMinExp) {
      progress = (currentExp - currentLevelMinExp) /
          (nextLevelExp - currentLevelMinExp);
      progress = progress.clamp(0.0, 1.0); // 确保进度在0-1之间
    } else if (currentLevel == 5) {
      progress = 1.0; // 最高等级已经达到100%
    }

    // 获取当前等级的会话数限制
    String sessionLimit;
    switch (currentLevel) {
      case 1:
        sessionLimit = '30';
        break;
      case 2:
        sessionLimit = '50';
        break;
      case 3:
        sessionLimit = '100';
        break;
      case 4:
        sessionLimit = '500';
        break;
      case 5:
        sessionLimit = '无限';
        break;
      default:
        sessionLimit = '';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前等级',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),
          _buildCurrentLevelNameWithEffect(),
          SizedBox(height: 12.h),
          Row(
            children: [
              Text(
                '当前经验值: $currentExp',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              SizedBox(width: 16.w),
              Icon(
                Icons.chat_bubble_outline,
                size: 16.sp,
                color: Colors.white.withOpacity(0.9),
              ),
              SizedBox(width: 4.w),
              Text(
                '会话数限制: $sessionLimit',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          if (currentLevel < 5) ...[
            SizedBox(height: 24.h),
            Text(
              '距离下一级 "Lv.${currentLevel + 1} $nextLevelName"',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            SizedBox(height: 8.h),
            Stack(
              children: [
                Container(
                  height: 8.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                Container(
                  height: 8.h,
                  width: MediaQuery.of(context).size.width * 0.85 * progress,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              nextLevelExp > 0
                  ? '还需 ${nextLevelExp - currentExp} 经验值'
                  : '已达到最高等级',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentLevelNameWithEffect() {
    final levelText = 'Lv.$currentLevel $currentLevelName';
    final levelTextStyle = TextStyle(
      fontSize: 28.sp,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    // 为不同等级添加不同特效
    if (currentLevel == 5) {
      // 5级神懿 - 彩虹渐变流光
      return ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) {
          return LinearGradient(
            colors: _getRainbowColors(),
            stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
            tileMode: TileMode.mirror,
          ).createShader(bounds);
        },
        child: Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.8),
          highlightColor: Colors.white,
          period: const Duration(milliseconds: 2000),
          child: Text(
            levelText,
            style: levelTextStyle,
          ),
        ),
      );
    } else if (currentLevel >= 3) {
      // 3-4级 - 普通流光效果
      final colors = _getLevelColors(currentLevel);
      return Shimmer.fromColors(
        baseColor: colors['start']!,
        highlightColor: colors['end']!,
        period: const Duration(milliseconds: 2000),
        child: Text(
          levelText,
          style: levelTextStyle,
        ),
      );
    } else {
      // 1-2级 - 无特效
      return Text(
        levelText,
        style: levelTextStyle,
      );
    }
  }

  Widget _buildLevelItem(
    BuildContext context, {
    required int level,
    required int minExp,
    required int maxExp,
    required String levelName,
    required bool isCurrentLevel,
  }) {
    // 添加会话数限制说明
    String sessionLimit;
    switch (level) {
      case 1:
        sessionLimit = '会话数限制: 30';
        break;
      case 2:
        sessionLimit = '会话数限制: 50';
        break;
      case 3:
        sessionLimit = '会话数限制: 100';
        break;
      case 4:
        sessionLimit = '会话数限制: 500';
        break;
      case 5:
        sessionLimit = '会话数限制: 无限';
        break;
      default:
        sessionLimit = '';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.border.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLevelNameWithEffect(
                  level: level,
                  levelName: levelName,
                ),
                SizedBox(height: 8.h),
                Text(
                  level == 5 ? '经验值要求: $minExp+' : '经验值要求: $minExp-$maxExp',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 14.sp,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      sessionLimit,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isCurrentLevel)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.primaryColor,
                    size: 14.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '当前',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLevelNameWithEffect({
    required int level,
    required String levelName,
  }) {
    final levelText = 'Lv.$level $levelName';
    final textStyle = TextStyle(
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
      color: AppTheme.textPrimary,
    );

    // 为不同等级添加不同特效
    if (level == 5) {
      // 5级神懿 - 彩虹渐变流光
      return ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) {
          return LinearGradient(
            colors: _getRainbowColors(),
            stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
            tileMode: TileMode.mirror,
          ).createShader(bounds);
        },
        child: Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.8),
          highlightColor: Colors.white,
          period: const Duration(milliseconds: 2000),
          child: Text(
            levelText,
            style: textStyle,
          ),
        ),
      );
    } else if (level >= 3) {
      // 3-4级 - 普通流光效果
      final colors = _getLevelColors(level);
      return Shimmer.fromColors(
        baseColor: colors['start']!,
        highlightColor: colors['end']!,
        period: const Duration(milliseconds: 2000),
        child: Text(
          levelText,
          style: textStyle,
        ),
      );
    } else {
      // 1-2级 - 无特效
      return Text(
        levelText,
        style: textStyle,
      );
    }
  }

  // 根据等级返回对应的颜色配置
  Map<String, Color> _getLevelColors(int level) {
    switch (level) {
      case 1:
        return {'start': Colors.white, 'end': Colors.white}; // 纯白色
      case 2:
        return {
          'start': const Color(0xFFE0E0E0),
          'end': const Color(0xFFAAAAAA)
        }; // 银色
      case 3:
        return {
          'start': const Color(0xFFFFFFFF),
          'end': const Color(0xFFD0D0D0)
        }; // 银白流光
      case 4:
        return {
          'start': const Color(0xFFFFF8E1),
          'end': const Color(0xFFFFD54F)
        }; // 金色流光
      case 5:
        return {
          'start': const Color(0xFFFFF9C4),
          'end': const Color(0xFFFFD700)
        }; // 金色流光（基础颜色）
      default:
        return {'start': Colors.white, 'end': Colors.white};
    }
  }

  // 获取5级彩虹渐变颜色
  List<Color> _getRainbowColors() {
    return [
      const Color(0xFFFF5252), // 红
      const Color(0xFFFF7043), // 橙
      const Color(0xFFFFCA28), // 黄
      const Color(0xFF66BB6A), // 绿
      const Color(0xFF29B6F6), // 蓝
      const Color(0xFF7E57C2), // 紫
    ];
  }
}
