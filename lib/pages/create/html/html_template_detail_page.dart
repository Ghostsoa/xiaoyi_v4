import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../services/html_template_service.dart';
import '../../../widgets/custom_toast.dart';
import 'html_template_preview_page.dart';

class HtmlTemplateDetailPage extends StatefulWidget {
  final Map<String, dynamic> project;
  final bool isOwner; // 是否是项目所有者

  const HtmlTemplateDetailPage({
    super.key,
    required this.project,
    this.isOwner = true,
  });

  @override
  State<HtmlTemplateDetailPage> createState() => _HtmlTemplateDetailPageState();
}

class _HtmlTemplateDetailPageState extends State<HtmlTemplateDetailPage> {
  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary;
    final background = AppTheme.background;

    final taskStatus = widget.project['task_status'] ?? 1;
    final status = widget.project['status'] ?? 1;
    final version = widget.project['version'] ?? 1;
    final aiOptimized = widget.project['ai_optimized'] ?? false;

    Color taskStatusColor = Colors.grey;
    switch (taskStatus) {
      case 1:
        taskStatusColor = Colors.green;
        break;
      case 2:
        taskStatusColor = Colors.orange;
        break;
      case 3:
        taskStatusColor = Colors.blue;
        break;
      case 4:
        taskStatusColor = Colors.red;
        break;
      case 5:
        taskStatusColor = Colors.amber;
        break;
    }

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
          'HTML模板详情',
          style: TextStyle(
            fontSize: AppTheme.titleSize,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 项目名称
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.project['project_name'] ?? '未命名项目',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // 标签行
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      _buildChip(
                        HtmlTemplateService.getStatusText(status),
                        status == 1 ? Colors.grey : Colors.green,
                      ),
                      _buildChip(
                        HtmlTemplateService.getTaskStatusText(taskStatus),
                        taskStatusColor,
                      ),
                      _buildChip(
                        HtmlTemplateService.getVersionText(version),
                        version == 1 ? Colors.orange : Colors.blue,
                      ),
                      if (aiOptimized)
                        _buildChip('AI优化', Colors.purple),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  // 元信息
                  Row(
                    children: [
                      Icon(Icons.person, size: 14.sp, color: AppTheme.textSecondary),
                      SizedBox(width: 4.w),
                      Text(
                        widget.project['username'] ?? '未知用户',
                        style: TextStyle(
                          fontSize: AppTheme.smallSize,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Icon(Icons.access_time, size: 14.sp, color: AppTheme.textSecondary),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          _formatDate(widget.project['created_at']),
                          style: TextStyle(
                            fontSize: AppTheme.smallSize,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // 渲染预览按钮
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: ElevatedButton.icon(
                onPressed: _openPreview,
                icon: Icon(Icons.preview, size: 20.sp),
                label: Text(
                  '渲染预览',
                  style: TextStyle(
                    fontSize: AppTheme.bodySize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // HTML模板
            _buildSection(
              title: 'HTML模板',
              content: widget.project['html_template'] ?? '',
              icon: Icons.code,
              iconColor: Colors.blue,
            ),

            SizedBox(height: 16.h),

            // 示例数据
            _buildSection(
              title: '示例数据',
              content: widget.project['example_data'] ?? '',
              icon: Icons.data_object,
              iconColor: Colors.green,
            ),

            SizedBox(height: 16.h),

            // 提示词指令
            _buildSection(
              title: '提示词指令',
              content: widget.project['prompt_instruction'] ?? '',
              icon: Icons.description,
              iconColor: Colors.orange,
            ),

            SizedBox(height: 80.h), // 为底部按钮留出空间
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.border.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18.sp, color: iconColor),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTheme.bodySize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Spacer(),
                // 复制按钮
                InkWell(
                  onTap: () => _copyToClipboard(content, title),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy,
                          size: 14.sp,
                          color: AppTheme.primaryColor,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '复制',
                          style: TextStyle(
                            fontSize: AppTheme.smallSize,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 内容区域
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: 100.h,
              maxHeight: 400.h,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(12.w),
              child: SelectableText(
                content.isEmpty ? '（暂无内容）' : content,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: content.isEmpty 
                      ? AppTheme.textSecondary.withOpacity(0.5)
                      : AppTheme.textPrimary,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTheme.smallSize,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '未知时间';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.toString();
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    CustomToast.show(
      context,
      message: '$label已复制',
      type: ToastType.success,
    );
  }

  void _openPreview() {
    final htmlTemplate = widget.project['html_template'] ?? '';
    final exampleData = widget.project['example_data'] ?? '';
    final projectName = widget.project['project_name'] ?? '未命名项目';

    // 验证数据
    if (htmlTemplate.isEmpty) {
      CustomToast.show(
        context,
        message: 'HTML模板为空，无法渲染',
        type: ToastType.error,
      );
      return;
    }

    if (exampleData.isEmpty) {
      CustomToast.show(
        context,
        message: '示例数据为空，无法渲染',
        type: ToastType.error,
      );
      return;
    }

    // 打开预览页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HtmlTemplatePreviewPage(
          htmlTemplate: htmlTemplate,
          exampleData: exampleData,
          projectName: projectName,
        ),
      ),
    );
  }
}

