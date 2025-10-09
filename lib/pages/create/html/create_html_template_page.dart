import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/expandable_text_field.dart';
import '../../../widgets/custom_toast.dart';
import '../services/html_template_service.dart';

class CreateHtmlTemplatePage extends StatefulWidget {
  final Map<String, dynamic>? project; // 如果提供，则为编辑模式

  const CreateHtmlTemplatePage({
    super.key,
    this.project,
  });

  @override
  State<CreateHtmlTemplatePage> createState() => _CreateHtmlTemplatePageState();
}

class _CreateHtmlTemplatePageState extends State<CreateHtmlTemplatePage> {
  final HtmlTemplateService _service = HtmlTemplateService();

  // 表单控制器
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _htmlController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();

  // 状态
  int _selectedStatus = 1; // 1=私有，2=公开
  bool _needAiAutomation = false; // 是否需要AI自动化
  bool _isSubmitting = false;

  // 编辑模式相关
  bool get isEditMode => widget.project != null;
  bool get isProductionVersion => isEditMode && (widget.project!['version'] ?? 1) == 2;
  bool get isAiOptimized => isEditMode && (widget.project!['ai_optimized'] ?? false);
  bool get canEdit => !isAiOptimized; // 只有AI介入时不能编辑
  bool get canEditHtml => !isProductionVersion && !isAiOptimized; // HTML模板：生产版和AI介入都不能编辑

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadProjectData();
    }
  }

  void _loadProjectData() {
    final project = widget.project!;
    _nameController.text = project['project_name'] ?? '';
    _htmlController.text = project['html_template'] ?? '';
    _exampleController.text = project['example_data'] ?? '';
    _promptController.text = project['prompt_instruction'] ?? '';
    _selectedStatus = project['status'] ?? 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _htmlController.dispose();
    _exampleController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _submitProject() async {
    // 验证表单
    if (_nameController.text.trim().isEmpty) {
      CustomToast.show(
        context,
        message: '请输入项目名称',
        type: ToastType.error,
      );
      return;
    }

    if (_htmlController.text.trim().isEmpty) {
      CustomToast.show(
        context,
        message: '请输入HTML模板',
        type: ToastType.error,
      );
      return;
    }

    if (_exampleController.text.trim().isEmpty) {
      CustomToast.show(
        context,
        message: '请输入示例数据',
        type: ToastType.error,
      );
      return;
    }

    if (_promptController.text.trim().isEmpty) {
      CustomToast.show(
        context,
        message: '请输入提示词指令',
        type: ToastType.error,
      );
      return;
    }

    // 编辑模式下检查是否允许编辑
    if (isEditMode && !canEdit) {
      CustomToast.show(
        context,
        message: 'AI已介入优化的项目不允许修改内容',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (isEditMode) {
        // 更新项目
        await _service.updateProject(
          projectId: widget.project!['id'],
          projectName: _nameController.text.trim(),
          status: _selectedStatus,
          htmlTemplate: canEditHtml ? _htmlController.text.trim() : null, // 生产版不更新HTML
          exampleData: _exampleController.text.trim(),
          promptInstruction: _promptController.text.trim(),
        );

        if (mounted) {
          CustomToast.show(
            context,
            message: '更新成功',
            type: ToastType.success,
          );
          Navigator.pop(context, true);
        }
      } else {
        // 创建项目
        await _service.createProject(
          projectName: _nameController.text.trim(),
          status: _selectedStatus,
          htmlTemplate: _htmlController.text.trim(),
          exampleData: _exampleController.text.trim(),
          promptInstruction: _promptController.text.trim(),
          needAiAutomation: _needAiAutomation,
        );

        if (mounted) {
          CustomToast.show(
            context,
            message: '创建成功',
            type: ToastType.success,
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        CustomToast.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary;
    final background = AppTheme.background;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary, size: 20.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditMode ? '编辑HTML模板项目' : '创建HTML模板项目',
          style: TextStyle(
            fontSize: AppTheme.titleSize,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          // 右上角保存/更新按钮
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: _isSubmitting
                  ? SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    )
                  : TextButton(
                      onPressed: (isEditMode && !canEdit) ? null : _submitProject,
                      style: TextButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: Text(
                        isEditMode ? '更新' : '创建',
                        style: TextStyle(
                          fontSize: AppTheme.bodySize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 编辑模式警告提示
            if (isEditMode && isAiOptimized) ...[
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'AI已介入优化的项目不允许修改内容',
                        style: TextStyle(
                          fontSize: AppTheme.captionSize,
                          color: Colors.orange[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ] else if (isEditMode && isProductionVersion) ...[
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        '生产版本：HTML模板已锁定，仅可编辑示例数据、提示词指令、名称和状态',
                        style: TextStyle(
                          fontSize: AppTheme.captionSize,
                          color: Colors.blue[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],

            // 项目名称
            Text(
              '项目名称',
              style: AppTheme.secondaryStyle,
            ),
            SizedBox(height: 8.h),
            Container(
              decoration: AppTheme.inputDecoration,
              child: TextField(
                controller: _nameController,
                maxLength: 100,
                enabled: canEdit,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.bodySize,
                ),
                decoration: InputDecoration(
                  hintText: '请输入项目名称（最多100字符）',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.6),
                    fontSize: AppTheme.bodySize,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  counterText: '',
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // 状态选择
            Text(
              '项目状态',
              style: AppTheme.secondaryStyle,
            ),
            SizedBox(height: 8.h),
            _buildStatusSelector(),
            SizedBox(height: 24.h),

            // HTML模板
            ExpandableTextField(
              title: 'HTML模板',
              controller: _htmlController,
              hintText: '请输入HTML模板代码\n\n例如：\n<div class="card">\n  <h3>{{name}} Lv.{{level}}</h3>\n  <div class="status">{{status_code}}</div>\n</div>',
              previewLines: 5,
              enabled: canEditHtml, // 生产版和AI介入都不能编辑HTML
              helpIcon: GestureDetector(
                onTap: _showHtmlHelp,
                child: Icon(
                  Icons.help_outline,
                  size: 16.sp,
                  color: AppTheme.primaryColor,
                ),
              ),
              description: Text(
                isProductionVersion && !isAiOptimized
                    ? 'HTML模板已锁定（生产版本）'
                    : '支持使用 {{变量名}} 作为占位符',
                style: TextStyle(
                  fontSize: AppTheme.smallSize,
                  color: isProductionVersion && !isAiOptimized 
                      ? Colors.orange 
                      : AppTheme.textSecondary,
                ),
              ),
              onChanged: () => setState(() {}),
            ),
            SizedBox(height: 24.h),

            // 示例数据
            ExpandableTextField(
              title: '示例数据',
              controller: _exampleController,
              hintText: '请输入JSON格式的示例数据\n\n例如：\n{\n  "name": "小懿",\n  "level": 10,\n  "status_code": "<span class=\'healthy\'>健康</span>"\n}',
              previewLines: 5,
              enabled: canEdit,
              helpIcon: GestureDetector(
                onTap: _showExampleHelp,
                child: Icon(
                  Icons.help_outline,
                  size: 16.sp,
                  color: AppTheme.primaryColor,
                ),
              ),
              description: Text(
                '提供模板变量的示例值，用于预览渲染效果',
                style: TextStyle(
                  fontSize: AppTheme.smallSize,
                  color: AppTheme.textSecondary,
                ),
              ),
              onChanged: () => setState(() {}),
            ),
            SizedBox(height: 24.h),

            // 提示词指令
            ExpandableTextField(
              title: '提示词指令',
              controller: _promptController,
              hintText: '请输入提示词指令\n\n例如：\n模板ID: {{projectId}}\n用途: 角色状态展示\n\n字段说明:\n- {{name}} [文本] 角色名称\n- {{level}} [数字] 等级\n- {{status_code}} [HTML] 状态标签',
              previewLines: 8,
              enabled: canEdit,
              helpIcon: GestureDetector(
                onTap: _showPromptHelp,
                child: Icon(
                  Icons.help_outline,
                  size: 16.sp,
                  color: AppTheme.primaryColor,
                ),
              ),
              description: Text(
                '描述模板的用途和字段说明，帮助AI理解如何使用此模板',
                style: TextStyle(
                  fontSize: AppTheme.smallSize,
                  color: AppTheme.textSecondary,
                ),
              ),
              onChanged: () => setState(() {}),
            ),
            SizedBox(height: 24.h),

            // AI自动化开关（仅创建模式）
            if (!isEditMode) ...[
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI自动化优化',
                            style: TextStyle(
                              fontSize: AppTheme.bodySize,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '提交后由AI自动优化HTML模板和提示词',
                            style: TextStyle(
                              fontSize: AppTheme.captionSize,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _needAiAutomation,
                      onChanged: (value) {
                        setState(() => _needAiAutomation = value);
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusOption(
              label: '私有',
              icon: Icons.lock_outline,
              value: 1,
              selected: _selectedStatus == 1,
            ),
          ),
          Container(
            width: 1.w,
            height: 40.h,
            color: AppTheme.border.withOpacity(0.1),
          ),
          Expanded(
            child: _buildStatusOption(
              label: '公开',
              icon: Icons.public,
              value: 2,
              selected: _selectedStatus == 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption({
    required String label,
    required IconData icon,
    required int value,
    required bool selected,
  }) {
    return InkWell(
      onTap: canEdit ? () => setState(() => _selectedStatus = value) : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.bodySize,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHtmlHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppTheme.primaryColor),
            SizedBox(width: 8.w),
            Text('HTML模板说明'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '使用 {{变量名}} 作为占位符，系统会在渲染时自动替换为实际值。',
                style: TextStyle(fontSize: AppTheme.bodySize),
              ),
              SizedBox(height: 12.h),
              Text('示例：', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '<div class="card">\n  <h3>{{name}} Lv.{{level}}</h3>\n  <div class="hp">HP: {{hp}}/{{max_hp}}</div>\n</div>',
                  style: TextStyle(
                    fontSize: AppTheme.captionSize,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _showExampleHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppTheme.primaryColor),
            SizedBox(width: 8.w),
            Text('示例数据说明'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '提供JSON格式的示例数据，用于预览HTML模板的渲染效果。',
                style: TextStyle(fontSize: AppTheme.bodySize),
              ),
              SizedBox(height: 12.h),
              Text('示例：', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '{\n  "name": "小懿",\n  "level": 10,\n  "hp": 850,\n  "max_hp": 1000\n}',
                  style: TextStyle(
                    fontSize: AppTheme.captionSize,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _showPromptHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppTheme.primaryColor),
            SizedBox(width: 8.w),
            Text('提示词指令说明'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '描述模板的用途和字段说明，帮助AI理解如何正确使用此模板。',
                style: TextStyle(fontSize: AppTheme.bodySize),
              ),
              SizedBox(height: 12.h),
              Text('建议包含：', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Text('• 模板ID和用途'),
              Text('• 每个字段的名称、类型和说明'),
              Text('• 特殊字段的格式要求'),
              SizedBox(height: 12.h),
              Text('示例：', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '模板ID: {{projectId}}\n用途: 角色状态卡\n\n字段说明:\n- {{name}} [文本] 角色名称\n- {{level}} [数字] 角色等级\n- {{hp}} [数字] 当前生命值\n- {{max_hp}} [数字] 最大生命值',
                  style: TextStyle(
                    fontSize: AppTheme.captionSize,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('知道了'),
          ),
        ],
      ),
    );
  }
}

