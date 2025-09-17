import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
import '../../../../theme/app_theme.dart';
import '../../../../services/file_service.dart';
import '../../material/select_image_page.dart';
import '../../../../widgets/custom_toast.dart';
import '../../services/characte_service.dart';
import 'markdown_preview_dialog.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../widgets/expandable_text_field.dart';

class BasicInfoModule extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController tagsController;
  final String? coverUri;
  final String? backgroundUri;
  final Function(String) onCoverUriChanged;
  final Function(String) onBackgroundUriChanged;
  final Map<String, Uint8List> imageCache;

  const BasicInfoModule({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.tagsController,
    required this.coverUri,
    required this.backgroundUri,
    required this.onCoverUriChanged,
    required this.onBackgroundUriChanged,
    required this.imageCache,
  });

  @override
  State<BasicInfoModule> createState() => _BasicInfoModuleState();
}

class _BasicInfoModuleState extends State<BasicInfoModule> {
  final _fileService = FileService();
  final TextEditingController _customTagController = TextEditingController();
  final FocusNode _customTagFocusNode = FocusNode();
  List<String> _tags = [];

  // 当前角色简介字数
  int _descriptionCount = 0;
  final int _maxDescriptionCount = 1500;

  // 格式化按钮状态
  bool _isFormatting = false;

  // 推荐标签
  final List<String> _genreTags = [
    '男性向',
    '女性向',
    '全性向',

  ];

  @override
  void initState() {
    super.initState();
    // 初始化已有的标签
    if (widget.tagsController.text.isNotEmpty) {
      _tags = widget.tagsController.text
          .split(RegExp(r'[,，]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // 添加角色简介字数变化监听
    widget.descriptionController.addListener(_updateDescriptionCount);

    // 添加标签输入框焦点监听
    _customTagFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _customTagController.dispose();
    _customTagFocusNode.dispose();
    // 移除监听器
    widget.descriptionController.removeListener(_updateDescriptionCount);
    super.dispose();
  }

  // 更新字数计数
  void _updateDescriptionCount() {
    setState(() {
      _descriptionCount = widget.descriptionController.text.length;
    });
  }


  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      widget.tagsController.text = _tags.join(',');
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
      widget.tagsController.text = _tags.join(',');
    });
  }

  void _addCustomTag(String tag) {
    if (tag.isEmpty) return;

    final trimmedTag = tag.trim();
    if (trimmedTag.length < 2 || trimmedTag.length > 4) {
      _showToast('标签长度需要在2-4个字之间', type: ToastType.warning);
      return;
    }

    if (_tags.contains(trimmedTag)) {
      _showToast('标签已存在', type: ToastType.warning);
      return;
    }

    setState(() {
      _tags.add(trimmedTag);
      widget.tagsController.text = _tags.join(',');
    });
    _customTagController.clear();
  }

  Widget _buildTagInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签标题
        Text(
          '角色标签',
          style: TextStyle(
            fontSize: AppTheme.bodySize,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.sp,
            ),
            children: [
              const TextSpan(text: '为角色添加'),
              TextSpan(
                text: '性格标签',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '，帮助用户'),
              TextSpan(
                text: '快速了解',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '角色特点'),
            ],
          ),
        ),
        SizedBox(height: 8.h),

        // 自定义标签输入
        _buildCustomTagInput(),

        // 已选标签展示
        _buildSelectedTags(),
        // 推荐标签
        Text(
          '推荐标签',
          style: TextStyle(
            fontSize: AppTheme.captionSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _genreTags.map((tag) {
            final isSelected = _tags.contains(tag);
            return GestureDetector(
              onTap: () => _toggleTag(tag),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: AppTheme.smallSize,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }



  Widget _buildCustomTagInput() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _customTagController,
              focusNode: _customTagFocusNode,
              decoration: InputDecoration(
                hintText: '添加自定义标签 (2-4个字)',
                hintStyle: TextStyle(
                  fontSize: AppTheme.captionSize,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              onSubmitted: _addCustomTag,
              textInputAction: TextInputAction.done,
            ),
          ),
          GestureDetector(
            onTap: () => _addCustomTag(_customTagController.text),
            child: Container(
              padding: EdgeInsets.all(12.w),
              child: Icon(
                Icons.add_circle_outline,
                color: AppTheme.primaryColor,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTags() {
    if (_tags.isEmpty) {
      return SizedBox(height: 8.h);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: _tags.map((tag) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: AppTheme.smallSize,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 4.w),
                GestureDetector(
                  onTap: () => _removeTag(tag),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showToast(String message, {ToastType type = ToastType.info}) {
    if (!mounted) return;
    CustomToast.show(context, message: message, type: type);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h, bottom: 16.h),
      child: Text(
        title,
        style: AppTheme.titleStyle.copyWith(
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  // 构建Markdown美化按钮
  Widget _buildMarkdownButton() {
    return GestureDetector(
      onTap: _isFormatting ? null : () => _formatMarkdown(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppTheme.buttonGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isFormatting ? Icons.sync : Icons.format_paint,
              size: 16.sp,
              color: Colors.white,
            ),
            SizedBox(width: 4.w),
            if (_isFormatting)
              Shimmer.fromColors(
                baseColor: Colors.white.withOpacity(0.5),
                highlightColor: Colors.white,
                child: Text(
                  '美化中...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              Text(
                'Markdown美化',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('基础信息'),
        TextFormField(
          controller: widget.nameController,
          decoration: InputDecoration(
            labelText: '角色名称',
            hintText: '请输入角色名称',
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
            labelStyle: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14.sp,
            ),
            hintStyle: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          style: AppTheme.bodyStyle,
          minLines: 1,
          maxLines: null,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入角色名称';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        ExpandableTextField(
          title: '角色简介',
          controller: widget.descriptionController,
          hintText: '请输入角色简介',
          maxLength: _maxDescriptionCount,
          previewLines: 3,
          onChanged: () => setState(() {}), // 触发界面刷新
          extraButton: _buildMarkdownButton(),
        ),
        SizedBox(height: 16.h),
        _buildTagInput(),
        SizedBox(height: 16.h),

        // 图片选择部分 - 警告独立板块
        Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppTheme.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: AppTheme.error.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.report_gmailerrorred,
                color: AppTheme.error,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '重要提示：严禁使用真人图片，禁止侵犯肖像权。',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),

        Row(
          children: [
            // 封面图片
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('封面图片', style: AppTheme.secondaryStyle),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.help_outline,
                        size: 16.sp,
                        color: AppTheme.textSecondary,
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
                        const TextSpan(text: '从'),
                        TextSpan(
                          text: '素材库',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: '中选择'),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildImageSelector(
                    uri: widget.coverUri,
                    onUriChanged: widget.onCoverUriChanged,
                    type: ImageSelectType.cover,
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            // 背景图片
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('背景图片', style: AppTheme.secondaryStyle),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.help_outline,
                        size: 16.sp,
                        color: AppTheme.textSecondary,
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
                        const TextSpan(text: '从'),
                        TextSpan(
                          text: '素材库',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: '中选择'),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildImageSelector(
                    uri: widget.backgroundUri,
                    onUriChanged: widget.onBackgroundUriChanged,
                    type: ImageSelectType.background,
                  ),
                ],
              ),
            ),
          ],
        ),

        // 添加底部提示信息
        Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 14.sp,
                color: AppTheme.textSecondary,
              ),
              SizedBox(width: 4.w),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.sp,
                  ),
                  children: [
                    const TextSpan(text: '请先在'),
                    TextSpan(
                      text: '素材库',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '中'),
                    TextSpan(
                      text: '上传图片',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，再在此处选择使用'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSelector({
    required String? uri,
    required Function(String) onUriChanged,
    required ImageSelectType type,
  }) {
    final double containerHeight = 160.h;
    final double containerWidth = (1.sw - 64.w) / 2; // 考虑左右和中间间距

    if (uri != null) {
      return Container(
        width: containerWidth,
        height: containerHeight,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppTheme.cardBackground.withOpacity(0.1),
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: FutureBuilder(
                future: widget.imageCache[uri] != null
                    ? Future.value(widget.imageCache[uri])
                    : _fileService.getFile(uri).then((file) {
                        return file.data;
                      }),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.hasError) {
                    return Container(
                      color: AppTheme.cardBackground.withOpacity(0.1),
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 32.sp,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    );
                  }
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              ),
            ),
            Positioned(
              top: 8.h,
              right: 8.w,
              child: GestureDetector(
                onTap: () {
                  onUriChanged('');
                  _showToast(
                      '已移除${type == ImageSelectType.cover ? "封面" : "背景"}图片');
                },
                child: Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: AppTheme.error,
                    size: 14.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: containerWidth,
      height: containerHeight,
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SelectImagePage(
                type: type,
                source: ImageSelectSource.myMaterial,
              ),
            ),
          );
          if (result != null && mounted) {
            onUriChanged(result);
            _showToast(
              '已选择${type == ImageSelectType.cover ? "封面" : "背景"}图片',
              type: ToastType.success,
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppTheme.buttonGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: const GradientRotation(0.4),
            ),
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: AppTheme.buttonGradient.first.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == ImageSelectType.cover ? Icons.image : Icons.wallpaper,
                size: 32.sp,
                color: Colors.white,
              ),
              SizedBox(height: 8.h),
              Text(
                '选择${type == ImageSelectType.cover ? "封面" : "背景"}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _formatMarkdown(BuildContext context) async {
    final text = widget.descriptionController.text.trim();
    if (text.isEmpty) {
      _showToast('请先输入角色简介', type: ToastType.warning);
      return;
    }

    // 设置加载状态
    setState(() {
      _isFormatting = true;
    });

    try {
      final characterService = CharacterService();
      final response = await characterService.formatMarkdown(text);

      // 重置加载状态
      setState(() {
        _isFormatting = false;
      });

      if (response['code'] == 0) {
        final formattedMarkdown = response['data']['markdown'];

        // 显示预览对话框
        if (mounted && context.mounted) {
          showDialog(
            context: context,
            builder: (context) => MarkdownPreviewDialog(
              markdown: formattedMarkdown,
              onConfirm: (markdown) {
                widget.descriptionController.text = markdown;
                _showToast('已应用格式化内容', type: ToastType.success);
              },
            ),
          );
        }
      } else {
        // 显示服务器返回的具体错误信息
        final errorMsg = response['msg'] ?? '格式化出现错误，请重新尝试';
        _showToast(errorMsg, type: ToastType.error);
        debugPrint('Markdown格式化错误: ${response['msg']}');
      }
    } catch (e) {
      // 重置加载状态
      setState(() {
        _isFormatting = false;
      });

      // 显示用户友好的错误信息
      _showToast('格式化出现错误，请重新尝试', type: ToastType.error);
      // 记录详细错误信息，但不显示给用户
      debugPrint('Markdown格式化异常: $e');
    }
  }
}
