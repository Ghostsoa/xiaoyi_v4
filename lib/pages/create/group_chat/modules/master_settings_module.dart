import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/custom_toast.dart';
import '../../material/select_text_page.dart';
import '../../character/select_model_page.dart';

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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('主控设定', style: AppTheme.secondaryStyle),
                const Spacer(),
                _buildMaterialSelector(
                  type: TextSelectType.setting,
                  onSelected: (content) {
                    // 追加到当前内容
                    final currentText = widget.masterSettingController.text;
                    final newText = currentText.isEmpty ? content : '$currentText\n\n$content';
                    widget.masterSettingController.text = newText;
                  },
                ),
              ],
            ),
            SizedBox(height: 4.h),
            RichText(
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
            SizedBox(height: 8.h),
            TextFormField(
              controller: widget.masterSettingController,
              decoration: InputDecoration(
                hintText: '请输入主控设定...\n\n例如：\n- 剧情发展方向\n- 关键事件触发条件\n- 重要决策点\n- 故事转折设定等',
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
                ),
                contentPadding: EdgeInsets.all(16.w),
                // 添加后缀计数器
                suffixText: '$_masterSettingCount/$_maxMasterSettingCount',
                suffixStyle: TextStyle(
                  color: _masterSettingCount > _maxMasterSettingCount
                      ? Colors.red
                      : AppTheme.textSecondary,
                  fontSize: 12.sp,
                ),
                // 添加错误提示
                errorText: _masterSettingCount > _maxMasterSettingCount
                    ? '超出最大字数限制'
                    : null,
                hintStyle: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
              style: AppTheme.bodyStyle,
              maxLines: 10,
              maxLength: _maxMasterSettingCount,
              // 隐藏内置计数器
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            ),
          ],
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
        Text('用户角色设定', style: AppTheme.secondaryStyle),
        SizedBox(height: 4.h),
        RichText(
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
        SizedBox(height: 8.h),
        TextFormField(
          controller: widget.userRoleSettingController,
          decoration: InputDecoration(
            hintText: '请输入用户角色设定...\n\n例如：\n- 用户的身份背景\n- 与其他角色的关系\n- 行为特点等',
            filled: true,
            fillColor: AppTheme.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
            ),
            contentPadding: EdgeInsets.all(16.w),
            // 添加后缀计数器
            suffixText: '$_userRoleSettingCount/$_maxUserRoleSettingCount',
            suffixStyle: TextStyle(
              color: _userRoleSettingCount > _maxUserRoleSettingCount
                  ? Colors.red
                  : AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
            // 添加错误提示
            errorText: _userRoleSettingCount > _maxUserRoleSettingCount
                ? '超出最大字数限制'
                : null,
            hintStyle: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          style: AppTheme.bodyStyle,
          maxLines: 8,
          maxLength: _maxUserRoleSettingCount,
          // 隐藏内置计数器
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
        ),

        SizedBox(height: 24.h),

        // 开场白
        Text('开场白', style: AppTheme.secondaryStyle),
        SizedBox(height: 4.h),
        RichText(
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
        SizedBox(height: 8.h),
        TextFormField(
          controller: widget.greetingController,
          decoration: InputDecoration(
            hintText: '请输入开场白...\n\n例如：\n欢迎来到这个群聊！这里是一个充满魔法的世界...',
            filled: true,
            fillColor: AppTheme.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
            ),
            contentPadding: EdgeInsets.all(16.w),
            // 添加后缀计数器
            suffixText: '$_greetingCount/$_maxGreetingCount',
            suffixStyle: TextStyle(
              color: _greetingCount > _maxGreetingCount
                  ? Colors.red
                  : AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
            // 添加错误提示
            errorText: _greetingCount > _maxGreetingCount
                ? '超出最大字数限制'
                : null,
            hintStyle: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          style: AppTheme.bodyStyle,
          maxLines: 6,
          maxLength: _maxGreetingCount,
          // 隐藏内置计数器
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
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

  Widget _buildMaterialSelector({
    required TextSelectType type,
    required Function(String) onSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectTextPage(
              source: TextSelectSource.myMaterial,
              type: type,
            ),
          ),
        );
        if (result != null && mounted) {
          onSelected(result);
          CustomToast.show(
            context,
            message: '已导入设定内容',
            type: ToastType.success,
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open,
              size: 14.sp,
              color: AppTheme.primaryColor,
            ),
            SizedBox(width: 4.w),
            Text(
              '从素材库选择',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

