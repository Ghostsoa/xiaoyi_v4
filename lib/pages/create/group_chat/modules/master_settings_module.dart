import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import '../../character/select_model_page.dart';
import '../../../../widgets/expandable_text_field.dart';


class MasterSettingsModule extends StatefulWidget {
  final TextEditingController masterSettingController;
  final String masterModel;
  final TextEditingController sharedContextController;
  final TextEditingController userRoleSettingController;
  final Function(String) onMasterModelChanged;

  const MasterSettingsModule({
    super.key,
    required this.masterSettingController,
    required this.masterModel,
    required this.sharedContextController,
    required this.userRoleSettingController,
    required this.onMasterModelChanged,
  });

  @override
  State<MasterSettingsModule> createState() => _MasterSettingsModuleState();
}

class _MasterSettingsModuleState extends State<MasterSettingsModule> {
  // 最大字数限制
  final int _maxMasterSettingCount = 2000;
  final int _maxSharedContextCount = 50000;
  final int _maxUserRoleSettingCount = 5000;



  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // 控制器设定文本框
        ExpandableTextField(
          title: '控制器设定',
          controller: widget.masterSettingController,
          hintText: '(非必要不填)给控制器模型增加额外提示\n\n例如：\n- 谁应该更多发言，谁应该更少发言\n- 群聊的剧情走向和关键决策',
          maxLength: _maxMasterSettingCount,
          previewLines: 5,
          description: RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
              children: [
                const TextSpan(text: '控制器设定是给'),
                TextSpan(
                  text: '控制器模型',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '增加'),
                TextSpan(
                  text: '额外提示',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '的地方，最多2000字'),
              ],
            ),
          ),
          onChanged: () => setState(() {}),
        ),

        SizedBox(height: 24.h),

        // 控制器模型选择
        Text('控制器模型', style: AppTheme.secondaryStyle),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
            children: [
              const TextSpan(text: '智能'),
              TextSpan(
                text: '决策出发言角色',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '的模型，推荐'),
              TextSpan(
                text: '轻量、响应迅速',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '的模型'),
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

        // 共享上下文
        ExpandableTextField(
          title: '共享上下文',
          controller: widget.sharedContextController,
          hintText: '请输入所有角色共用的背景设定...\n\n例如：\n- 世界背景设定\n- 共同历史事件\n- 环境描述\n- 通用规则等',
          maxLength: _maxSharedContextCount,
          previewLines: 4,
          description: RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
              children: [
                const TextSpan(text: '所有角色共享的'),
                TextSpan(
                  text: '上下文信息',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '，不仅限于背景设定和环境，最多50000字'),
              ],
            ),
          ),
          onChanged: () => setState(() {}),
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
      ],
    );
  }


}

