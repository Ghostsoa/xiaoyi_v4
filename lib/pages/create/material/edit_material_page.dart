import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/material_service.dart';
import '../../../services/file_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';

class EditMaterialPage extends StatefulWidget {
  final Map<String, dynamic>? material;
  final String? initialType;

  const EditMaterialPage({
    super.key,
    this.material,
    this.initialType,
  });

  @override
  State<EditMaterialPage> createState() => _EditMaterialPageState();
}

class _EditMaterialPageState extends State<EditMaterialPage> {
  final MaterialService _service = MaterialService();
  final FileService _fileService = FileService();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  String _type = 'template';
  String _status = 'private';
  File? _selectedImage;
  String? _uploadedImageUri;

  @override
  void initState() {
    super.initState();
    if (widget.material != null) {
      _descriptionController.text = widget.material!['description'];
      _contentController.text = widget.material!['metadata'] ?? '';
      _type = widget.material!['type'];
      _status = widget.material!['status'];
      if (_type == 'image') {
        _uploadedImageUri = widget.material!['metadata'];
      }
    } else if (widget.initialType != null) {
      _type = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _uploadedImageUri = null; // 清除之前上传的图片URI
        });

        // 立即上传图片
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        _showToast('选择图片失败: $e', ToastType.error);
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);

    try {
      final uri = await _fileService.uploadFile(_selectedImage!, 'material');
      setState(() {
        _uploadedImageUri = uri;
      });
    } catch (e) {
      if (mounted) {
        _showToast('上传图片失败，请检查网络或文件大小', ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    if (_descriptionController.text.trim().isEmpty) {
      _showToast('请输入描述', ToastType.warning);
      return;
    }

    if (_type == 'image' && _uploadedImageUri == null) {
      _showToast('请选择并上传图片', ToastType.warning);
      return;
    }

    if (_type != 'image' && _contentController.text.trim().isEmpty) {
      _showToast('请输入内容', ToastType.warning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'description': _descriptionController.text,
        'type': _type,
        'status': _status,
        'metadata':
            _type == 'image' ? _uploadedImageUri : _contentController.text,
      };

      if (widget.material != null) {
        await _service.updateMaterial(widget.material!['id'], data);
      } else {
        await _service.createMaterial(data);
      }

      if (mounted) {
        _showToast('保存成功', ToastType.success);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showToast('保存失败: ${e.toString()}', ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showToast(String message, ToastType type) {
    if (!mounted) return;
    CustomToast.show(
      context,
      message: message,
      type: type,
    );
  }

  Widget _buildContentSection() {
    if (_type == 'image') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '图片',
            style: TextStyle(
              fontSize: AppTheme.bodySize,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: _isLoading ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: 200.h,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: _selectedImage != null || _uploadedImageUri != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      child: _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              '/files?uri=$_uploadedImageUri',
                              fit: BoxFit.cover,
                            ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48.sp,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '点击选择图片',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.captionSize,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            maxLines: 10,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.bodySize,
            ),
            decoration: InputDecoration(
              hintText: '请输入素材内容',
              hintStyle: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.bodySize,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                borderSide: BorderSide(color: AppTheme.border.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                borderSide: BorderSide(color: AppTheme.border.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
              filled: true,
              fillColor: AppTheme.cardBackground,
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 优化后的顶部导航栏
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.shadowColor.withOpacity(0.1),
                              blurRadius: 8.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close,
                          color: AppTheme.textPrimary,
                          size: 18.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.material != null ? '编辑素材' : '创建素材',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            widget.material != null ? '修改素材信息' : '添加新的创作素材',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.w,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                            ),
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _save,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppTheme.buttonGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 8.r,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: Text(
                            '保存',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // 内容区域
            Expanded(
              child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.material == null) ...[
                Text(
                  '类型',
                  style: TextStyle(
                    fontSize: AppTheme.bodySize,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    color: AppTheme.cardBackground,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _type,
                      isExpanded: true,
                      dropdownColor: AppTheme.cardBackground,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppTheme.bodySize,
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.textSecondary,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'image',
                          child: Text(
                            '图片',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.bodySize,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'template',
                          child: Text(
                            '模板',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.bodySize,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'prefix',
                          child: Text(
                            '前缀词',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.bodySize,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'suffix',
                          child: Text(
                            '后缀词',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.bodySize,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _type = value);
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
              ],
              Text(
                '描述',
                style: TextStyle(
                  fontSize: AppTheme.bodySize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _descriptionController,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.bodySize,
                ),
                decoration: InputDecoration(
                  hintText: '请输入素材描述',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.bodySize,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    borderSide:
                        BorderSide(color: AppTheme.border.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    borderSide:
                        BorderSide(color: AppTheme.border.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                ),
              ),
              SizedBox(height: 24.h),
              _buildContentSection(),
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
                  border: Border.all(color: AppTheme.border.withOpacity(0.3)),
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
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.bodySize,
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
                            color: AppTheme.textPrimary,
                            fontSize: AppTheme.bodySize,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'published',
                        child: Text(
                          '公开',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: AppTheme.bodySize,
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
      ],
    ),
    ),
    );
  }
}
