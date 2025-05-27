import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import '../services/novel_service.dart';
import '../../create/character/select_model_page.dart';

class NovelDetailPage extends StatefulWidget {
  final String sessionId;
  final Color textColor;
  final Color backgroundColor;

  const NovelDetailPage({
    super.key,
    required this.sessionId,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  State<NovelDetailPage> createState() => _NovelDetailPageState();
}

class _NovelDetailPageState extends State<NovelDetailPage> {
  final NovelService _novelService = NovelService();
  bool _isLoading = true;
  Map<String, dynamic> _novelDetail = {};
  String _errorMessage = '';

  // 编辑状态
  bool _isEditing = false;

  // 编辑值
  final TextEditingController _modelNameController = TextEditingController();
  final TextEditingController _protagonistSetController =
      TextEditingController();
  final TextEditingController _supplementarySetController =
      TextEditingController();

  // 表单验证key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadNovelDetail();
  }

  @override
  void dispose() {
    _modelNameController.dispose();
    _protagonistSetController.dispose();
    _supplementarySetController.dispose();
    super.dispose();
  }

  Future<void> _loadNovelDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _novelService.getNovelSession(widget.sessionId);

      if (response['code'] != 0) {
        throw response['message'] ?? '请求失败';
      }

      setState(() {
        _novelDetail = response['data'] ?? {};
        _isLoading = false;

        // 更新编辑控制器的值
        _modelNameController.text = _novelDetail['model_name'] ?? '';
        _protagonistSetController.text = _novelDetail['protagonist_set'] ?? '';
        _supplementarySetController.text =
            _novelDetail['supplementary_set'] ?? '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载小说详情失败: $e';
        _isLoading = false;
      });

      CustomToast.show(
        context,
        message: '加载小说详情失败',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48.sp,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          _errorMessage,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 16.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          onPressed: _loadNovelDetail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                          ),
                          child: Text(
                            '重新加载',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildNovelDetailContent(),
      ),
    );
  }

  Widget _buildNovelDetailContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 返回按钮和标题
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: widget.textColor),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                iconSize: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                '小说详情设置',
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              // 编辑/保存按钮
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.check : Icons.edit,
                  color: widget.textColor,
                ),
                onPressed: _isEditing ? _saveChanges : _startEditing,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                iconSize: 24.sp,
              ),
              if (_isEditing)
                IconButton(
                  icon: Icon(Icons.close, color: widget.textColor),
                  onPressed: _cancelEditing,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  iconSize: 24.sp,
                ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildHeaderSection(),
          SizedBox(height: 24.h),
          _buildDetailItem(
              '小说ID', _novelDetail['novel_id']?.toString() ?? '未知'),
          _buildDetailItem(
              '创建者ID', _novelDetail['user_id']?.toString() ?? '未知'),
          _buildDetailItem('作者名称', _novelDetail['author_name'] ?? '未知'),
          _buildDetailItem('AI模型', _novelDetail['model_name'] ?? '未知'),
          _buildDetailItem(
              '对话轮次', _novelDetail['total_turns']?.toString() ?? '0'),
          _buildDetailItem('创建时间', _formatDateTime(_novelDetail['created_at'])),
          _buildDetailItem('更新时间', _formatDateTime(_novelDetail['updated_at'])),
          if (_novelDetail['tags'] != null &&
              (_novelDetail['tags'] as List).isNotEmpty)
            _buildTagsSection(_novelDetail['tags'] as List),
          SizedBox(height: 24.h),
          _buildLongTextSection('主角设定', _novelDetail['protagonist_set']),
          _buildLongTextSection('补充设定', _novelDetail['supplementary_set']),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _novelDetail['title'] ?? '未命名小说',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: widget.textColor,
          ),
        ),
        SizedBox(height: 8.h),
        if (_novelDetail['description'] != null &&
            _novelDetail['description'].toString().isNotEmpty)
          Text(
            _novelDetail['description'],
            style: TextStyle(
              fontSize: 16.sp,
              color: widget.textColor.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        SizedBox(height: 16.h),
        Divider(color: widget.textColor.withOpacity(0.2)),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    // AI模型特殊处理，支持编辑
    if (label == 'AI模型' && _isEditing) {
      return Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100.w,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: widget.textColor.withOpacity(0.7),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: InkWell(
                onTap: _selectModel,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 12.h,
                    horizontal: 12.w,
                  ),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor.computeLuminance() > 0.5
                        ? Colors.black.withOpacity(0.05)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(
                      color: widget.textColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _modelNameController.text.isEmpty
                            ? '请选择模型'
                            : _modelNameController.text,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: _modelNameController.text.isEmpty
                              ? widget.textColor.withOpacity(0.5)
                              : widget.textColor,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16.sp,
                        color: widget.textColor.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: widget.textColor.withOpacity(0.7),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                color: widget.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(List tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          '标签',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: widget.textColor,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: (tags).map((tag) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                tag.toString(),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14.sp,
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildLongTextSection(String title, String? content) {
    if (content == null || content.isEmpty) {
      content = '';
    }

    // 获取对应的控制器
    TextEditingController? controller;
    if (title == '主角设定') {
      controller = _protagonistSetController;
    } else if (title == '补充设定') {
      controller = _supplementarySetController;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: widget.textColor,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: _isEditing ? EdgeInsets.zero : EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: widget.backgroundColor.computeLuminance() > 0.5
                ? Colors.black.withOpacity(0.05)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: widget.textColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: _isEditing && controller != null
              ? TextField(
                  controller: controller,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: widget.textColor.withOpacity(0.9),
                    height: 1.5,
                  ),
                  maxLines: null,
                  minLines: 3,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(12.w),
                    border: InputBorder.none,
                    hintText: '请输入${title}内容',
                    hintStyle: TextStyle(
                      color: widget.textColor.withOpacity(0.4),
                    ),
                  ),
                )
              : Text(
                  content,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: widget.textColor.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return '未知';
    }

    try {
      final dateTime =
          DateTime.parse(dateTimeString).add(const Duration(hours: 8));
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  // 开始编辑模式
  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  // 取消编辑
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      // 恢复原始值
      _modelNameController.text = _novelDetail['model_name'] ?? '';
      _protagonistSetController.text = _novelDetail['protagonist_set'] ?? '';
      _supplementarySetController.text =
          _novelDetail['supplementary_set'] ?? '';
    });
  }

  // 保存更改
  Future<void> _saveChanges() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 构建更新数据
      final Map<String, dynamic> updateData = {};

      if (_modelNameController.text != _novelDetail['model_name']) {
        updateData['model_name'] = _modelNameController.text;
      }

      if (_protagonistSetController.text != _novelDetail['protagonist_set']) {
        updateData['protagonist_set'] = _protagonistSetController.text;
      }

      if (_supplementarySetController.text !=
          _novelDetail['supplementary_set']) {
        updateData['supplementary_set'] = _supplementarySetController.text;
      }

      // 如果没有更改，直接退出编辑模式
      if (updateData.isEmpty) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
        return;
      }

      // 调用API保存更改
      final response = await _novelService.updateNovelSession(
        widget.sessionId,
        updateData,
      );

      if (response['code'] != 0) {
        throw response['message'] ?? '请求失败';
      }

      // 重新加载数据
      await _loadNovelDetail();

      // 退出编辑模式
      setState(() {
        _isEditing = false;
      });

      // 显示成功提示
      CustomToast.show(
        context,
        message: '保存成功',
        type: ToastType.success,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      CustomToast.show(
        context,
        message: '保存失败: $e',
        type: ToastType.error,
      );
    }
  }

  // 选择模型
  Future<void> _selectModel() async {
    final selectedModel = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectModelPage(),
      ),
    );

    if (selectedModel != null && mounted) {
      setState(() {
        _modelNameController.text = selectedModel;
      });
    }
  }
}
