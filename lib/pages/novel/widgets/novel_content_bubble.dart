import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_theme.dart';

// 小说内容气泡组件 - 现已移除气泡效果
class NovelContentBubble extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> paragraphs;
  final String createdAt;
  final String msgId;
  final bool isGenerating;

  // 编辑相关回调
  final Function(String msgId, String content)? onEdit;
  final Function(bool isEditing)? onEditingStateChanged;

  // 新增样式参数
  final double contentFontSize;
  final double titleFontSize;
  final Color backgroundColor;
  final Color textColor;

  const NovelContentBubble({
    super.key,
    required this.title,
    required this.paragraphs,
    this.msgId = '',
    this.createdAt = '',
    this.isGenerating = false,
    this.onEdit,
    this.onEditingStateChanged,
    this.contentFontSize = 20.0,
    this.titleFontSize = 25.0,
    this.backgroundColor = const Color(0xFF121212),
    this.textColor = Colors.white,
  });

  @override
  State<NovelContentBubble> createState() => _NovelContentBubbleState();
}

class _NovelContentBubbleState extends State<NovelContentBubble> {
  bool _isEditing = false;
  late TextEditingController _editingController;

  @override
  void initState() {
    super.initState();
    // 初始化编辑控制器
    _editingController = TextEditingController();
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.onEdit != null && !widget.isGenerating
          ? _handleEditToggle
          : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h), // 减小下方间距
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 章节标题
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // 居中显示标题
                children: [
                  SizedBox(width: 30.w),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center, // 文本居中
                      style: TextStyle(
                        fontSize: widget.titleFontSize.sp, // 使用设置的标题字体大小
                        fontWeight: FontWeight.bold,
                        color: widget.textColor, // 使用设置的文字颜色
                      ),
                    ),
                  ),
                  if (widget.isGenerating)
                    Shimmer.fromColors(
                      baseColor: AppTheme.primaryColor.withOpacity(0.6),
                      highlightColor: Colors.white,
                      child: Icon(
                        Icons.auto_stories,
                        size: 20.sp, // 调整图标尺寸与内容一致
                        color: widget.textColor.withOpacity(0.7), // 使用设置的文字颜色
                      ),
                    )
                  else
                    SizedBox(width: 30.w),
                ],
              ),
            ),

            // 章节内容段落
            _isEditing
                ? _buildEditingArea()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.paragraphs
                        .map((paragraph) => _buildParagraph(paragraph))
                        .toList(),
                  ),

            // 添加分隔线
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Divider(
                color: widget.textColor.withOpacity(0.5), // 使用文本颜色的半透明效果
                thickness: 1.0, // 稍微减小厚度
                height: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建编辑区域
  Widget _buildEditingArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _editingController,
          style: TextStyle(
            fontSize: widget.contentFontSize.sp,
            color: widget.textColor,
            height: 1.5,
          ),
          maxLines: null,
          decoration: InputDecoration(
            border: InputBorder.none,
            fillColor: Colors.transparent,
            filled: true,
            hintText: '编辑章节内容...',
            hintStyle: TextStyle(
              color: widget.textColor.withOpacity(0.5),
            ),
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _handleCancel,
              style: TextButton.styleFrom(
                minimumSize: Size(80.w, 36.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                backgroundColor: Colors.transparent,
              ),
              child: Text(
                '取消',
                style: TextStyle(
                  color: widget.textColor.withOpacity(0.8),
                  fontSize: 14.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            TextButton(
              onPressed: _handleSave,
              style: TextButton.styleFrom(
                minimumSize: Size(80.w, 36.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                backgroundColor: Colors.transparent,
              ),
              child: Text(
                '保存',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 处理编辑切换
  void _handleEditToggle() {
    if (_isEditing) {
      // 如果是编辑状态就保存
      _handleSave();
    } else {
      // 进入编辑状态，填充文本
      final String content = _getContentFromParagraphs();
      _editingController.text = content;
      setState(() {
        _isEditing = true;
      });
      // 通知父组件编辑状态变化
      widget.onEditingStateChanged?.call(true);
    }
  }

  // 处理取消编辑
  void _handleCancel() {
    setState(() {
      _isEditing = false;
    });
    // 通知父组件编辑状态变化
    widget.onEditingStateChanged?.call(false);
  }

  // 处理保存内容
  void _handleSave() {
    if (widget.onEdit != null && widget.msgId.isNotEmpty) {
      widget.onEdit!(widget.msgId, _editingController.text);
    }
    setState(() {
      _isEditing = false;
    });
    // 通知父组件编辑状态变化
    widget.onEditingStateChanged?.call(false);
  }

  // 从段落中提取内容文本
  String _getContentFromParagraphs() {
    final StringBuffer buffer = StringBuffer();
    for (final paragraph in widget.paragraphs) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
        buffer.writeln();
      }
      buffer.write(paragraph['content']);
    }
    return buffer.toString();
  }

  // 构建段落内容
  Widget _buildParagraph(Map<String, dynamic> paragraph) {
    final bool isCharacterSpeech = paragraph['type'] == 'character_speech';

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h), // 减小段落间距
      child: isCharacterSpeech
          ? _buildCharacterSpeech(paragraph)
          : _buildNarratorText(paragraph),
    );
  }

  // 构建叙述文本
  Widget _buildNarratorText(Map<String, dynamic> paragraph) {
    return Text(
      paragraph['content'],
      style: TextStyle(
        fontSize: widget.contentFontSize.sp, // 使用设置的内容字体大小
        color: widget.textColor, // 使用设置的文字颜色
        height: 1.5, // 调整行高
      ),
    );
  }

  // 构建对话文本
  Widget _buildCharacterSpeech(Map<String, dynamic> paragraph) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (paragraph['character_name'] != null)
          Padding(
            padding: EdgeInsets.only(bottom: 2.h), // 减小角色名称与对话间距
            child: Text(
              paragraph['character_name'],
              style: TextStyle(
                fontSize: (widget.contentFontSize - 6).sp, // 角色名称字体略小于内容
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        Text(
          paragraph['content'],
          style: TextStyle(
            fontSize: widget.contentFontSize.sp, // 使用设置的内容字体大小
            color: widget.textColor, // 使用设置的文字颜色
            fontStyle: FontStyle.italic, // 对话文本使用斜体以区分
          ),
        ),
      ],
    );
  }
}
