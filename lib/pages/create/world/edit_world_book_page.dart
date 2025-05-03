import 'package:flutter/material.dart';
import '../services/world_book_service.dart';
import '../../../theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditWorldBookPage extends StatefulWidget {
  final Map<String, dynamic>? worldBook;

  const EditWorldBookPage({super.key, this.worldBook});

  @override
  State<EditWorldBookPage> createState() => _EditWorldBookPageState();
}

class _EditWorldBookPageState extends State<EditWorldBookPage> {
  final WorldBookService _service = WorldBookService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();
  final FocusNode _keywordFocusNode = FocusNode();
  List<String> _keywords = [];
  String _status = 'private';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.worldBook != null) {
      _titleController.text = widget.worldBook!['title'];
      _contentController.text = widget.worldBook!['content'] ?? '';
      _keywords = List<String>.from(widget.worldBook!['keywords']);
      _status = widget.worldBook!['status'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _keywordController.dispose();
    _keywordFocusNode.dispose();
    super.dispose();
  }

  void _addKeyword(String keyword) {
    if (!_keywords.contains(keyword)) {
      setState(() {
        _keywords.add(keyword);
      });
    }
  }

  void _removeKeyword(String keyword) {
    setState(() {
      _keywords.remove(keyword);
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题')),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容')),
      );
      return;
    }

    // 如果输入框还有未添加的关键词，自动添加
    final lastKeyword = _keywordController.text.trim();
    if (lastKeyword.isNotEmpty) {
      _addKeyword(lastKeyword);
      _keywordController.clear();
    }

    setState(() => _isLoading = true);

    try {
      if (widget.worldBook != null) {
        await _service.updateWorldBook(
          widget.worldBook!['id'].toString(),
          title: _titleController.text,
          content: _contentController.text,
          keywords: _keywords,
          status: _status,
          context: context,
        );
      } else {
        await _service.createWorldBook(
          title: _titleController.text,
          content: _contentController.text,
          keywords: _keywords,
          status: _status,
          context: context,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.worldBook != null ? '编辑世界书' : '创建世界书',
          style: TextStyle(
            fontSize: AppTheme.titleSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            Center(
              child: SizedBox(
                width: 24.w,
                height: 24.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                '保存',
                style: TextStyle(
                  fontSize: AppTheme.bodySize,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          SizedBox(width: 16.w),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '标题',
                style: TextStyle(
                  fontSize: AppTheme.bodySize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: '请输入世界书标题',
                  hintStyle: TextStyle(
                    fontSize: AppTheme.bodySize,
                    color: AppTheme.textHint,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                style: TextStyle(
                  fontSize: AppTheme.bodySize,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                '内容',
                style: TextStyle(
                  fontSize: AppTheme.bodySize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '请输入世界书内容',
                  hintStyle: TextStyle(
                    fontSize: AppTheme.bodySize,
                    color: AppTheme.textHint,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                style: TextStyle(
                  fontSize: AppTheme.bodySize,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                '关键词',
                style: TextStyle(
                  fontSize: AppTheme.bodySize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _keywordController,
                          focusNode: _keywordFocusNode,
                          decoration: InputDecoration(
                            hintText: '请输入关键词',
                            hintStyle: TextStyle(
                              fontSize: AppTheme.bodySize,
                              color: AppTheme.textHint,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSmall),
                              borderSide: BorderSide(color: AppTheme.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSmall),
                              borderSide: BorderSide(color: AppTheme.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSmall),
                              borderSide:
                                  BorderSide(color: AppTheme.primaryColor),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: AppTheme.bodySize,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      FilledButton(
                        onPressed: () {
                          final keyword = _keywordController.text.trim();
                          if (keyword.isNotEmpty) {
                            _addKeyword(keyword);
                            _keywordController.clear();
                            _keywordFocusNode.requestFocus();
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                        child: Text(
                          '添加',
                          style: TextStyle(
                            fontSize: AppTheme.bodySize,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_keywords.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 12.h),
                      child: Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: _keywords.map((keyword) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusXSmall),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  keyword,
                                  style: TextStyle(
                                    fontSize: AppTheme.smallSize,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                GestureDetector(
                                  onTap: () => _removeKeyword(keyword),
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: EdgeInsets.all(2.w),
                                    child: Icon(
                                      Icons.close,
                                      size: 14.sp,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 24.h),
              Text(
                '状态',
                style: TextStyle(
                  fontSize: AppTheme.bodySize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  color: AppTheme.cardBackground,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _status,
                    isExpanded: true,
                    dropdownColor: AppTheme.cardBackground,
                    style: TextStyle(
                      fontSize: AppTheme.bodySize,
                      color: AppTheme.textPrimary,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: AppTheme.textSecondary,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'private',
                        child: Text(
                          '私密',
                          style: TextStyle(
                            fontSize: AppTheme.bodySize,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'published',
                        child: Text(
                          '公开',
                          style: TextStyle(
                            fontSize: AppTheme.bodySize,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _status = value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
