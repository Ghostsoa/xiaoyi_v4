import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/app_theme.dart';
import '../../world/select_world_book_page.dart';
import '../../../../widgets/custom_toast.dart';

class NovelStorySettingsModule extends StatefulWidget {
  final TextEditingController storyOutlineController;
  final TextEditingController worldSettingsController;
  final List<Map<String, dynamic>> selectedWorldBooks;
  final Function(List<Map<String, dynamic>>) onWorldBooksChanged;
  final Function(Map<String, dynamic>) onWorldbookMapChanged;

  const NovelStorySettingsModule({
    super.key,
    required this.storyOutlineController,
    required this.worldSettingsController,
    required this.selectedWorldBooks,
    required this.onWorldBooksChanged,
    required this.onWorldbookMapChanged,
  });

  @override
  State<NovelStorySettingsModule> createState() =>
      _NovelStorySettingsModuleState();
}

class _NovelStorySettingsModuleState extends State<NovelStorySettingsModule> {
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

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;

    // 计算所有世界书的关键词总数
    int totalKeywords = 0;
    for (var worldBook in widget.selectedWorldBooks) {
      if (worldBook['keywords'] != null) {
        totalKeywords += (worldBook['keywords'] as List).length;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('主要设定'),

        // 故事大纲
        Text(
          '故事大纲',
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
              const TextSpan(text: '简述小说的'),
              TextSpan(
                text: '主要情节',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '、'),
              TextSpan(
                text: '发展脉络',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '和'),
              TextSpan(
                text: '结局走向',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '，作为AI创作的'),
              TextSpan(
                text: '核心指导',
                style: TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: widget.storyOutlineController,
          minLines: 3,
          maxLines: null,
          decoration: InputDecoration(
            hintText: '请输入故事大纲',
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
        ),
        SizedBox(height: 24.h),

        // 世界观设定
        Text(
          '世界观设定',
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
              const TextSpan(text: '描述故事发生的'),
              TextSpan(
                text: '背景世界',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '，包括'),
              TextSpan(
                text: '时代背景',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '、'),
              TextSpan(
                text: '地理环境',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '、'),
              TextSpan(
                text: '社会规则',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '等'),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: widget.worldSettingsController,
          minLines: 3,
          maxLines: null,
          decoration: InputDecoration(
            hintText: '请输入世界观设定',
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
        ),
        SizedBox(height: 24.h),

        // 世界书选择
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '世界书',
              style: TextStyle(
                fontSize: AppTheme.bodySize,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            if (widget.selectedWorldBooks.isNotEmpty)
              Text(
                '已选择 ${widget.selectedWorldBooks.length} 个 · $totalKeywords 个关键词',
                style: TextStyle(
                  fontSize: AppTheme.smallSize,
                  color: textSecondary,
                ),
              ),
          ],
        ),
        SizedBox(height: 4.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: AppTheme.captionSize,
              color: textSecondary,
            ),
            children: [
              const TextSpan(text: '为小说添加'),
              TextSpan(
                text: '背景知识库',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '，当对话中出现'),
              TextSpan(
                text: '关键词',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '时会'),
              TextSpan(
                text: '自动调用',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '相关知识'),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SelectWorldBookPage(
                  source: WorldBookSelectSource.myWorldBook,
                  initialSelected: widget.selectedWorldBooks,
                ),
              ),
            );
            if (result != null && mounted) {
              final selectedBooks = List<Map<String, dynamic>>.from(result);
              widget.onWorldBooksChanged(selectedBooks);

              final Map<String, dynamic> worldbookMap = {};
              for (var worldBook in selectedBooks) {
                final id = worldBook['id'].toString();
                final keywords =
                    List<dynamic>.from(worldBook['keywords'] as List);
                for (var keyword in keywords) {
                  worldbookMap[keyword.toString()] = id;
                }
              }
              widget.onWorldbookMapChanged(worldbookMap);
              _showToast('已选择 ${selectedBooks.length} 个世界书',
                  type: ToastType.success);
            }
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.buttonGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                transform: const GradientRotation(0.4),
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.buttonGradient.first.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.public,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  widget.selectedWorldBooks.isEmpty ? '选择世界书' : '管理世界书',
                  style: TextStyle(
                    fontSize: AppTheme.bodySize,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
