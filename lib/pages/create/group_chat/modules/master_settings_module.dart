import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import '../../character/select_model_page.dart';
import '../../../../widgets/expandable_text_field.dart';


class MasterSettingsModule extends StatefulWidget {
  final TextEditingController masterSettingController;
  final String masterModel;
  final String? coreControllerModel;
  final TextEditingController userRoleSettingController;
  final TextEditingController greetingController;
  final Function(String) onMasterModelChanged;
  final Function(String?) onCoreControllerModelChanged;

  const MasterSettingsModule({
    super.key,
    required this.masterSettingController,
    required this.masterModel,
    required this.coreControllerModel,
    required this.userRoleSettingController,
    required this.greetingController,
    required this.onMasterModelChanged,
    required this.onCoreControllerModelChanged,
  });

  @override
  State<MasterSettingsModule> createState() => _MasterSettingsModuleState();
}

class _MasterSettingsModuleState extends State<MasterSettingsModule> {
  // 当前字数统计
  int _masterSettingCount = 0;
  int _userRoleSettingCount = 0;
  int _greetingCount = 0;

  // 最大字数限制
  final int _maxMasterSettingCount = 50000;
  final int _maxUserRoleSettingCount = 5000;
  final int _maxGreetingCount = 1000;

  @override
  void initState() {
    super.initState();
    
    // 监听文本变化
    widget.masterSettingController.addListener(_updateMasterSettingCount);
    widget.userRoleSettingController.addListener(_updateUserRoleSettingCount);
    widget.greetingController.addListener(_updateGreetingCount);
    
    // 初始化字数统计
    _updateMasterSettingCount();
    _updateUserRoleSettingCount();
    _updateGreetingCount();
  }

  @override
  void dispose() {
    widget.masterSettingController.removeListener(_updateMasterSettingCount);
    widget.userRoleSettingController.removeListener(_updateUserRoleSettingCount);
    widget.greetingController.removeListener(_updateGreetingCount);
    super.dispose();
  }

  void _updateMasterSettingCount() {
    setState(() {
      _masterSettingCount = widget.masterSettingController.text.length;
    });
  }

  void _updateUserRoleSettingCount() {
    setState(() {
      _userRoleSettingCount = widget.userRoleSettingController.text.length;
    });
  }

  void _updateGreetingCount() {
    setState(() {
      _greetingCount = widget.greetingController.text.length;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // 主控设定文本框
        ExpandableTextField(
          title: '主控设定',
          controller: widget.masterSettingController,
          hintText: '请输入主控设定...\n\n例如：\n- 剧情发展方向\n- 关键事件触发条件\n- 重要决策点\n- 故事转折设定等',
          maxLength: _maxMasterSettingCount,
          previewLines: 5,
          description: RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
              children: [
                const TextSpan(text: '用于控制群聊的'),
                TextSpan(
                  text: '剧情走向和关键决策',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '，最多50000字'),
              ],
            ),
          ),
          onChanged: () => setState(() {}),
        ),

        SizedBox(height: 24.h),

        // 主控模型选择
        Text('主控模型', style: AppTheme.secondaryStyle),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
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
              const TextSpan(text: '来驱动群聊逻辑'),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.border.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.masterModel.isNotEmpty ? widget.masterModel : '点击选择模型',
                    style: TextStyle(
                      fontSize: AppTheme.captionSize,
                      color: widget.masterModel.isNotEmpty 
                          ? AppTheme.textPrimary 
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textSecondary,
                  size: 16.sp,
                ),
              ],
            ),
          ),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SelectModelPage(),
              ),
            );
            if (result != null && mounted) {
              widget.onMasterModelChanged(result);
            }
          },
        ),

        SizedBox(height: 24.h),

        // 核心控制器模型（可选）
        Text('核心控制器模型（可选）', style: AppTheme.secondaryStyle),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
            children: [
              const TextSpan(text: '可选，用于处理更'),
              TextSpan(
                text: '复杂的群聊控制逻辑',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Column(
          children: [
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectModelPage(),
                  ),
                );
                if (result != null && mounted) {
                  widget.onCoreControllerModelChanged(result);
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: AppTheme.border.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.coreControllerModel ?? '点击选择模型（可选）',
                        style: TextStyle(
                          fontSize: AppTheme.captionSize,
                          color: widget.coreControllerModel != null 
                              ? AppTheme.textPrimary 
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.textSecondary,
                      size: 16.sp,
                    ),
                  ],
                ),
              ),
            ),
            if (widget.coreControllerModel != null) ...[
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () => widget.onCoreControllerModelChanged(null),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.clear,
                        size: 14.sp,
                        color: Colors.red,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '清除选择',
                        style: TextStyle(
                          fontSize: AppTheme.smallSize,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),

        SizedBox(height: 24.h),

        // 用户角色设定
        ExpandableTextField(
          title: '用户角色设定',
          controller: widget.userRoleSettingController,
          hintText: '请输入用户角色设定...\n\n例如：\n- 用户的身份背景\n- 与其他角色的关系\n- 行为特点等',
          maxLength: _maxUserRoleSettingCount,
          previewLines: 4,
          description: RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
              children: [
                const TextSpan(text: '定义用户在群聊中的'),
                TextSpan(
                  text: '身份和行为',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '，最多5000字'),
              ],
            ),
          ),
          onChanged: () => setState(() {}),
        ),

        SizedBox(height: 24.h),

        // 开场白
        ExpandableTextField(
          title: '开场白',
          controller: widget.greetingController,
          hintText: '请输入开场白...\n\n例如：\n欢迎来到这个群聊！这里是一个充满魔法的世界...',
          maxLength: _maxGreetingCount,
          previewLines: 3,
          description: RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
              children: [
                const TextSpan(text: '群聊开始时的'),
                TextSpan(
                  text: '欢迎信息',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '，最多1000字'),
              ],
            ),
          ),
          onChanged: () => setState(() {}),
        ),

        SizedBox(height: 24.h),

        // 提示信息
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '设置提示',
                      style: TextStyle(
                        fontSize: AppTheme.captionSize,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '主控设定是群聊的核心，它定义了整个群聊的世界观、规则和氛围。\n\n建议包含：\n• 世界背景和设定\n• 角色互动规则\n• 对话风格要求\n• 特殊事件处理方式',
                      style: TextStyle(
                        fontSize: AppTheme.smallSize,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


}

