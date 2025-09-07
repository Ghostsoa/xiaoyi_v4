import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import '../../material/select_image_page.dart';
import '../../../../widgets/custom_toast.dart';
import '../../../../services/file_service.dart';

class NovelBasicInfoModule extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final List<String> selectedTags;
  final String coverUri;
  final String selectedStatus;
  final Function(List<String>) onTagsChanged;
  final Function(String) onCoverUriChanged;
  final Function(String) onStatusChanged;

  const NovelBasicInfoModule({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.selectedTags,
    required this.coverUri,
    required this.selectedStatus,
    required this.onTagsChanged,
    required this.onCoverUriChanged,
    required this.onStatusChanged,
  });

  @override
  State<NovelBasicInfoModule> createState() => _NovelBasicInfoModuleState();
}

class _NovelBasicInfoModuleState extends State<NovelBasicInfoModule> {
  final List<String> _statusOptions = ['draft', 'published', 'private'];
  final List<String> _genreTags = [
    '奇幻',
    '科幻',
    '武侠',
    '言情',
    '悬疑',
    '历史',
    '现代',
    '都市',
    '校园',
    '游戏',
    '轻小说',
    '其他'
  ];
  final _fileService = FileService();
  final TextEditingController _customTagController = TextEditingController();
  final FocusNode _customTagFocusNode = FocusNode();

  @override
  void dispose() {
    _customTagController.dispose();
    _customTagFocusNode.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    final newTags = List<String>.from(widget.selectedTags);
    if (newTags.contains(tag)) {
      newTags.remove(tag);
    } else {
      newTags.add(tag);
    }
    widget.onTagsChanged(newTags);
  }

  void _addCustomTag(String tag) {
    if (tag.isEmpty) return;

    final trimmedTag = tag.trim();
    if (trimmedTag.length < 2 || trimmedTag.length > 4) {
      _showToast('标签长度需要在2-4个字之间', type: ToastType.warning);
      return;
    }

    if (widget.selectedTags.contains(trimmedTag)) {
      _showToast('标签已存在', type: ToastType.warning);
      return;
    }

    final newTags = List<String>.from(widget.selectedTags);
    newTags.add(trimmedTag);
    widget.onTagsChanged(newTags);
    _customTagController.clear();
  }

  void _removeTag(String tag) {
    final newTags = List<String>.from(widget.selectedTags);
    newTags.remove(tag);
    widget.onTagsChanged(newTags);
  }

  void _showToast(String message, {ToastType type = ToastType.info}) {
    if (!mounted) return;
    CustomToast.show(context, message: message, type: type);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 16.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppTheme.titleSize,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
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
                size: 24.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTags() {
    if (widget.selectedTags.isEmpty) {
      return SizedBox(height: 8.h);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: widget.selectedTags.map((tag) {
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

  Widget _buildStatusButton(String value, String label, IconData icon) {
    final bool isSelected = widget.selectedStatus == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onStatusChanged(value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.border,
            ),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: AppTheme.bodySize,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('基本信息'),

        // 小说标题
        Text(
          '小说标题',
          style: TextStyle(
            fontSize: AppTheme.bodySize,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: AppTheme.captionSize,
              color: textSecondary,
            ),
            children: [
              const TextSpan(text: '为小说取一个'),
              TextSpan(
                text: '吸引人的标题',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '，这将决定读者的'),
              TextSpan(
                text: '第一印象',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: widget.titleController,
          decoration: InputDecoration(
            hintText: '请输入小说标题',
            hintStyle: TextStyle(
              fontSize: AppTheme.captionSize,
              color: textSecondary.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppTheme.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入小说标题';
            }
            return null;
          },
        ),
        SizedBox(height: 24.h),

        // 小说封面
        Text(
          '小说封面',
          style: TextStyle(
            fontSize: AppTheme.bodySize,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: AppTheme.captionSize,
              color: textSecondary,
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
              const TextSpan(text: '中选择一张能'),
              TextSpan(
                text: '体现小说主题',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '的图片'),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        _buildImageSelector(
          uri: widget.coverUri,
          onUriChanged: widget.onCoverUriChanged,
        ),
        SizedBox(height: 24.h),

        // 小说简介
        Text(
          '小说简介',
          style: TextStyle(
            fontSize: AppTheme.bodySize,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: AppTheme.captionSize,
              color: textSecondary,
            ),
            children: [
              const TextSpan(text: '简明扼要地介绍'),
              TextSpan(
                text: '故事背景',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '和'),
              TextSpan(
                text: '核心看点',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '，让读者产生'),
              TextSpan(
                text: '阅读兴趣',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: widget.descriptionController,
          minLines: 3,
          maxLines: null,
          decoration: InputDecoration(
            hintText: '请输入小说简介',
            hintStyle: TextStyle(
              fontSize: AppTheme.captionSize,
              color: textSecondary.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppTheme.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入小说简介';
            }
            return null;
          },
        ),
        SizedBox(height: 24.h),

        // 小说标签
        Text(
          '小说标签',
          style: TextStyle(
            fontSize: AppTheme.bodySize,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: AppTheme.captionSize,
              color: textSecondary,
            ),
            children: [
              const TextSpan(text: '添加'),
              TextSpan(
                text: '2-4个字',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '的标签，帮助读者'),
              TextSpan(
                text: '快速了解',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '小说'),
              TextSpan(
                text: '类型',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '和'),
              TextSpan(
                text: '特点',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '推荐至少添加这些中的一个：',
              style: TextStyle(
                fontSize: AppTheme.captionSize,
                color: textSecondary,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(color: Colors.pink.withOpacity(0.3)),
                  ),
                  child: Text(
                    '女性向',
                    style: TextStyle(
                      color: Colors.pink,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    '男性向',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    '全性向',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
            color: textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _genreTags.map((tag) {
            final isSelected = widget.selectedTags.contains(tag);
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
                    color: isSelected ? Colors.white : textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 24.h),

        // 小说状态
        Text(
          '小说状态',
          style: TextStyle(
            fontSize: AppTheme.bodySize,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: AppTheme.captionSize,
              color: textSecondary,
            ),
            children: [
              const TextSpan(text: '选择小说的'),
              TextSpan(
                text: '发布状态',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '，'),
              TextSpan(
                text: '私有',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '状态下仅自己可见，'),
              TextSpan(
                text: '已发布',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '则公开可见'),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            _buildStatusButton('draft', '草稿', Icons.edit_outlined),
            SizedBox(width: 8.w),
            _buildStatusButton('published', '已发布', Icons.public),
            SizedBox(width: 8.w),
            _buildStatusButton('private', '私有', Icons.lock_outline),
          ],
        ),
      ],
    );
  }

  Widget _buildImageSelector({
    required String uri,
    required Function(String) onUriChanged,
  }) {
    final double containerHeight = 160.h;

    if (uri.isNotEmpty) {
      return Container(
        width: double.infinity,
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
                future: _fileService.getFile(uri).then((file) {
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
                  _showToast('已移除封面图片');
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
      width: double.infinity,
      height: containerHeight,
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SelectImagePage(
                type: ImageSelectType.cover,
                source: ImageSelectSource.myMaterial,
              ),
            ),
          );
          if (result != null && mounted) {
            onUriChanged(result);
            _showToast(
              '已选择封面图片',
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
                Icons.image,
                size: 32.sp,
                color: Colors.white,
              ),
              SizedBox(height: 8.h),
              Text(
                '选择封面',
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
}
