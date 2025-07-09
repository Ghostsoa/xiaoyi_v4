import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import 'base_card.dart';

class SettingCard extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final Function(String, dynamic) onUpdateField;
  final TextEditingController settingController;
  final TextEditingController userSettingController;

  const SettingCard({
    super.key,
    required this.sessionData,
    required this.onUpdateField,
    required this.settingController,
    required this.userSettingController,
  });

  @override
  State<SettingCard> createState() => _SettingCardState();
}

class _SettingCardState extends State<SettingCard> {
  // 保存每个字段的展开状态
  final Map<String, bool> _expandedState = {};

  // 控制器
  late TextEditingController _worldBackgroundController;
  late TextEditingController _rulesController;
  late TextEditingController _positiveDialogController;
  late TextEditingController _negativeDialogController;
  late TextEditingController _supplementSettingController;

  // 全局可编辑状态
  bool get _isEditable => widget.sessionData['setting_editable'] == true;

  @override
  void initState() {
    super.initState();
    // 初始化控制器
    _initControllers();
  }

  void _initControllers() {
    _worldBackgroundController = TextEditingController(
        text: widget.sessionData['world_background'] ?? '');
    _rulesController =
        TextEditingController(text: widget.sessionData['rules'] ?? '');
    _positiveDialogController = TextEditingController(
        text: widget.sessionData['positive_dialog_examples'] ?? '');
    _negativeDialogController = TextEditingController(
        text: widget.sessionData['negative_dialog_examples'] ?? '');
    _supplementSettingController = TextEditingController(
        text: widget.sessionData['supplement_setting'] ?? '');

    // 添加监听器
    _worldBackgroundController.addListener(() => widget.onUpdateField(
        'world_background', _worldBackgroundController.text));
    _rulesController.addListener(
        () => widget.onUpdateField('rules', _rulesController.text));
    _positiveDialogController.addListener(() => widget.onUpdateField(
        'positive_dialog_examples', _positiveDialogController.text));
    _negativeDialogController.addListener(() => widget.onUpdateField(
        'negative_dialog_examples', _negativeDialogController.text));
    _supplementSettingController.addListener(() => widget.onUpdateField(
        'supplement_setting', _supplementSettingController.text));
    widget.userSettingController.addListener(() => widget.onUpdateField(
        'user_setting', widget.userSettingController.text));
  }

  @override
  void dispose() {
    // 释放控制器资源
    _worldBackgroundController.dispose();
    _rulesController.dispose();
    _positiveDialogController.dispose();
    _negativeDialogController.dispose();
    _supplementSettingController.dispose();
    super.dispose();
  }

  // 切换展开/折叠状态
  void _toggleExpand(String field) {
    setState(() {
      _expandedState[field] = !(_expandedState[field] ?? false);
    });
  }

  // 获取文本的行数
  int _getLineCount(String text) {
    if (text.isEmpty) return 0;
    return '\n'.allMatches(text).length + 1;
  }

  // 获取前4行文本
  String _getPreviewText(String text) {
    if (text.isEmpty) return '';
    final lines = text.split('\n');
    if (lines.length <= 4) return text;

    return '${lines.sublist(0, 4).join('\n')}...';
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      title: '设定',
      children: [
        // 不可编辑状态时，显示一条提示信息
        if (!_isEditable) _buildNonEditableNotice(),

        // 可编辑状态时，显示所有设定项
        if (_isEditable) ...[
          _buildSettingField(
            '角色设定',
            'setting',
            widget.settingController,
            icon: Icons.psychology,
          ),
          _buildSettingField(
            '世界设定',
            'world_background',
            _worldBackgroundController,
            icon: Icons.public,
          ),
          _buildSettingField(
            '规则约束',
            'rules',
            _rulesController,
            icon: Icons.rule,
          ),
          _buildSettingField(
            '正对话示例',
            'positive_dialog_examples',
            _positiveDialogController,
            icon: Icons.thumb_up_alt_outlined,
          ),
          _buildSettingField(
            '反对话示例',
            'negative_dialog_examples',
            _negativeDialogController,
            icon: Icons.thumb_down_alt_outlined,
          ),
          _buildSettingField(
            '补充设定',
            'supplement_setting',
            _supplementSettingController,
            icon: Icons.add_circle_outline,
          ),
        ],

        // 用户设定始终显示，不受限制
        _buildUserSettingField(),
      ],
    );
  }

  // 构建不可编辑状态的提示
  Widget _buildNonEditableNotice() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.grey,
            size: 18.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '相关设定不可查看',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建普通设定字段
  Widget _buildSettingField(
    String label,
    String field,
    TextEditingController controller, {
    required IconData icon,
  }) {
    final text = controller.text;
    final lineCount = _getLineCount(text);
    final needsCollapse = lineCount > 4; // 只有超过4行才需要折叠
    final isExpanded = _expandedState[field] ?? false;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.textPrimary.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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
          ),

          // 内容区
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                16.w, 4.h, 16.w, needsCollapse ? 8.h : 16.h),
            child: InkWell(
              onTap: needsCollapse ? () => _toggleExpand(field) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 内容显示/编辑区
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppTheme.textPrimary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: controller,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        hintText: text.isEmpty ? '点击这里编辑$label...' : null,
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      maxLines: needsCollapse && !isExpanded ? 4 : null,
                    ),
                  ),

                  // 展开/折叠按钮
                  if (needsCollapse)
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () => _toggleExpand(field),
                        style: ButtonStyle(
                          minimumSize: WidgetStateProperty.all(Size(0, 24.h)),
                          padding: WidgetStateProperty.all(
                              EdgeInsets.symmetric(horizontal: 8.w)),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isExpanded ? '收起' : '展开编辑',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: AppTheme.primaryColor,
                              size: 14.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建用户设定字段（没有高度限制）
  Widget _buildUserSettingField() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.textPrimary.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryColor,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    '用户设定',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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
          ),

          // 内容区 - 用户设定没有折叠限制
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppTheme.textPrimary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: widget.userSettingController,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  hintText: widget.userSettingController.text.isEmpty
                      ? '点击这里编辑用户设定...'
                      : null,
                  hintStyle: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                maxLines: null, // 没有行数限制
              ),
            ),
          ),
        ],
      ),
    );
  }
}
