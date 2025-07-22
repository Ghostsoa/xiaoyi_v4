import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'dart:typed_data'; // Added for Uint8List
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import '../../../services/file_service.dart';
import '../services/home_service.dart';

class ReportItemPage extends StatefulWidget {
  final String itemId;
  final String itemTitle;

  const ReportItemPage({
    Key? key,
    required this.itemId,
    required this.itemTitle,
  }) : super(key: key);

  @override
  State<ReportItemPage> createState() => _ReportItemPageState();
}

class _ReportItemPageState extends State<ReportItemPage> {
  final HomeService _homeService = HomeService();
  final FileService _fileService = FileService();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  int _selectedReportType = 1; // 默认选择违规内容
  List<String> _evidenceUris = []; // 存储证据图片URI
  bool _isSubmitting = false;
  bool _isUploadingImage = false;

  final List<Map<String, dynamic>> _reportTypes = [
    {
      'id': 1,
      'name': '违规内容',
      'icon': Icons.block,
      'description':
          '指角色卡的公开部分（封面、背景、标题、简介、公开设定）中包含色情、暴力、政治敏感、赌博、毒品、血腥或引人不适的内容。'
    },
    {
      'id': 2,
      'name': '侵权',
      'icon': Icons.copyright,
      'description': '未经原作者授权，直接搬运、转载其他平台的原创作品。擦边的设定或相似的创意不属于侵权范围。'
    },
    {
      'id': 3,
      'name': '抄袭',
      'icon': Icons.content_copy,
      'description': '直接复制或高度模仿平台内其他作者的原创角色设定、简介或核心创意。'
    },
    {
      'id': 4,
      'name': '色情',
      'icon': Icons.visibility_off,
      'description':
          '指在公开部分（封面、背景等）出现完全裸露且未做任何遮挡的性器官（如男性下体、女性胸部及下体），或对性行为的露骨文字描述。注意：类似比基尼等服装的性感艺术表现形式，其界定标准由官方掌握。'
    },
    {
      'id': 5,
      'name': '暴力',
      'icon': Icons.dangerous,
      'description': '指在公开部分（封面、背景、简介等）包含对真实人物或群体的暴力威胁、血腥场面或虐待行为的详细描述。'
    },
    {
      'id': 6,
      'name': '其他',
      'icon': Icons.more_horiz,
      'description': '其他未在上述分类中提及的违规行为。'
    },
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    if (_isUploadingImage) return;

    // 限制最多上传3张图片
    if (_evidenceUris.length >= 3) {
      CustomToast.show(
        context,
        message: '最多上传3张图片',
        type: ToastType.warning,
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // 压缩图片质量，减少上传大小
      );

      if (image == null) return; // 用户取消选择

      setState(() => _isUploadingImage = true);

      // 上传图片，使用"report_evidence"作为图片类型
      final String uri =
          await _fileService.uploadFile(File(image.path), "report_evidence");

      if (mounted) {
        setState(() {
          _evidenceUris.add(uri);
          _isUploadingImage = false;
        });

        CustomToast.show(
          context,
          message: '图片上传成功',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        CustomToast.show(
          context,
          message: '图片上传失败: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _evidenceUris.removeAt(index);
    });

    CustomToast.show(
      context,
      message: '已移除图片',
      type: ToastType.info,
    );
  }

  Future<void> _submitReport() async {
    if (_contentController.text.trim().isEmpty) {
      CustomToast.show(
        context,
        message: '请填写举报内容描述',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await _homeService.reportItem(
        widget.itemId,
        _selectedReportType,
        _contentController.text.trim(),
        _evidenceUris,
      );

      if (mounted) {
        if (response['code'] == 0) {
          CustomToast.show(
            context,
            message: response['msg'] ?? '举报提交成功，感谢您的反馈',
            type: ToastType.success,
          );
          // 返回上一页
          Navigator.pop(context);
        } else {
          CustomToast.show(
            context,
            message: response['msg'] ?? '举报提交失败',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '举报提交失败: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildReportTypeItem({
    required int id,
    required String name,
    required IconData icon,
    String description = '',
  }) {
    bool isSelected = id == _selectedReportType;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedReportType = id);
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(
          vertical: 12.h,
          horizontal: 12.w,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Colors.red.shade400,
                    Colors.red.shade300,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isSelected ? Colors.red.shade400 : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20.sp,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
                SizedBox(width: 8.w),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.only(left: 28.w),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isSelected
                        ? Colors.white.withOpacity(0.8)
                        : AppTheme.textSecondary.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('内容举报'),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 举报内容标题信息
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '举报内容',
                    style: AppTheme.titleStyle,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16.sp,
                        color: AppTheme.textSecondary,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          widget.itemTitle,
                          style: AppTheme.bodyStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // 举报警告
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
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
                      '请注意：滥用举报功能、提交虚假或恶意举报，将会根据情节严重程度受到警告或封号处理。',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // 官方解释权提示
            Container(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.gavel_rounded,
                    color: AppTheme.primaryColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      '所有举报类型的最终解释权及定性权归平台所有。',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // 举报类型选择
            Text(
              '选择举报类型',
              style: AppTheme.titleStyle,
            ),
            SizedBox(height: 12.h),

            // 使用Column替代Wrap
            Column(
              children: _reportTypes.map((type) {
                return _buildReportTypeItem(
                  id: type['id'],
                  name: type['name'],
                  icon: type['icon'],
                  description: type['description'] ?? '',
                );
              }).toList(),
            ),

            SizedBox(height: 24.h),

            // 举报内容描述
            Text(
              '举报详细描述',
              style: AppTheme.titleStyle,
            ),
            SizedBox(height: 12.h),

            // 使用标准TextField替代CustomTextField
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: '请详细描述您举报的原因...',
                hintStyle: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.7),
                  fontSize: 14.sp,
                ),
                filled: true,
                fillColor: AppTheme.cardBackground,
                contentPadding: EdgeInsets.all(16.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: Colors.red.shade400,
                  ),
                ),
              ),
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14.sp,
              ),
              maxLines: 10,
              minLines: 5,
            ),

            SizedBox(height: 24.h),

            // 上传证据图片区域
            Text(
              '上传证据图片 (选填)',
              style: AppTheme.titleStyle,
            ),
            SizedBox(height: 12.h),

            Text(
              '您可以上传截图等作为举报证据',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14.sp,
              ),
            ),

            SizedBox(height: 12.h),

            // 已上传图片列表
            if (_evidenceUris.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                height: 100.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _evidenceUris.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: 10.w),
                      child: Stack(
                        children: [
                          FutureBuilder<Response>(
                            future: _fileService.getFile(_evidenceUris[index]),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container(
                                  width: 100.w,
                                  height: 100.h,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBackground,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                        color: Colors.grey.withOpacity(0.2)),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      color: Colors.red.shade300,
                                    ),
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return Container(
                                  width: 100.w,
                                  height: 100.h,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBackground,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                        color: Colors.grey.withOpacity(0.2)),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.error_outline,
                                        color: Colors.red),
                                  ),
                                );
                              } else if (snapshot.hasData &&
                                  snapshot.data != null) {
                                return Container(
                                  width: 100.w,
                                  height: 100.h,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBackground,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                        color: Colors.grey.withOpacity(0.2)),
                                    image: DecorationImage(
                                      image: MemoryImage(
                                          snapshot.data!.data as Uint8List),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              } else {
                                return Container(
                                  width: 100.w,
                                  height: 100.h,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBackground,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                        color: Colors.grey.withOpacity(0.2)),
                                  ),
                                  child: Center(child: Text('无图片')),
                                );
                              }
                            },
                          ),
                          Positioned(
                            top: 5.h,
                            right: 5.w,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: EdgeInsets.all(5.w),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // 图片上传功能区域
            InkWell(
              onTap: _isUploadingImage || _evidenceUris.length >= 3
                  ? null
                  : _pickAndUploadImage,
              child: Container(
                height: 100.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isUploadingImage)
                        SizedBox(
                          width: 30.w,
                          height: 30.h,
                          child: CircularProgressIndicator(
                            color: Colors.red.shade400,
                            strokeWidth: 2.w,
                          ),
                        )
                      else
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 36.sp,
                          color: _evidenceUris.length >= 3
                              ? Colors.grey
                              : AppTheme.textSecondary,
                        ),
                      SizedBox(height: 8.h),
                      Text(
                        _isUploadingImage
                            ? '上传中...'
                            : (_evidenceUris.length >= 3
                                ? '已达上限(3张)'
                                : '点击上传图片(${_evidenceUris.length}/3)'),
                        style: TextStyle(
                          color: _evidenceUris.length >= 3
                              ? Colors.grey
                              : AppTheme.textSecondary,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 40.h),

            // 使用标准ElevatedButton替代CustomButton
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReport,
                icon: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  _isSubmitting ? '提交中...' : '提交举报',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade500,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                  shadowColor: Colors.red.shade300.withOpacity(0.5),
                ),
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
