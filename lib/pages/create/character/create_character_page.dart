import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
import '../../../theme/app_theme.dart';
import '../services/characte_service.dart';
import '../../../services/file_service.dart';
import '../material/select_image_page.dart';
import '../material/select_text_page.dart';
import '../../../widgets/custom_toast.dart';
import '../world/select_world_book_page.dart';
import 'select_model_page.dart';

class CreateCharacterPage extends StatefulWidget {
  final Map<String, dynamic>? character;
  final bool isEdit;

  const CreateCharacterPage({
    super.key,
    this.character,
    this.isEdit = false,
  });

  @override
  State<CreateCharacterPage> createState() => _CreateCharacterPageState();
}

class _CreateCharacterPageState extends State<CreateCharacterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fileService = FileService();
  bool _isLoading = false;

  // 添加临时缓存变量
  Uint8List? _coverImageCache;
  Uint8List? _backgroundImageCache;

  // 基础信息
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  String? _coverUri;
  String? _backgroundUri;

  // 系统设定
  final _settingController = TextEditingController();
  final _greetingController = TextEditingController();
  final _prefixController = TextEditingController();
  final _suffixController = TextEditingController();
  bool _settingEditable = true;

  // 模型配置
  String _modelName = 'gemini-2.0-flash';
  double _temperature = 0.7;
  double _topP = 0.9;
  int _topK = 40;
  int _maxTokens = 2000;

  // 高级设定
  int _memoryTurns = 10;
  int _searchDepth = 5;
  Map<String, dynamic> _worldbookMap = {};
  String _status = 'draft';
  int _selectedWorldBookCount = 0;
  final List<Map<String, dynamic>> _selectedWorldBooks = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.character != null) {
      _initializeEditData();
    }
  }

  void _initializeEditData() {
    final character = widget.character!;
    _nameController.text = character['name'] ?? '';
    _descriptionController.text = character['description'] ?? '';
    _tagsController.text = character['tags']?.join(',') ?? '';
    _coverUri = character['coverUri'];
    _backgroundUri = character['backgroundUri'];
    _settingController.text = character['setting'] ?? '';
    _greetingController.text = character['greeting'] ?? '';
    _prefixController.text = character['prefix'] ?? '';
    _suffixController.text = character['suffix'] ?? '';
    _settingEditable = character['settingEditable'] ?? true;
    _modelName = character['modelName'] ?? 'gemini-2.0-flash';
    _temperature = (character['temperature'] ?? 0.7).toDouble();
    _topP = (character['topP'] ?? 0.9).toDouble();
    _topK = character['topK'] ?? 40;
    _maxTokens = character['maxTokens'] ?? 2000;
    _memoryTurns = character['memoryTurns'] ?? 10;
    _searchDepth = character['searchDepth'] ?? 5;
    _status = character['status'] ?? 'draft';

    // 处理世界书数据
    if (character['worldbookMap'] != null) {
      _worldbookMap = Map<String, dynamic>.from(character['worldbookMap']);

      // 根据worldbookMap中的ID获取已选中的世界书
      final Set<String> selectedIds = Set<String>.from(_worldbookMap.values);

      // 创建临时的世界书列表
      for (String id in selectedIds) {
        _selectedWorldBooks.add({
          'id': id,
          'keywords': _worldbookMap.entries
              .where((entry) => entry.value == id)
              .map((entry) => entry.key)
              .toList(),
        });
      }

      _selectedWorldBookCount = _selectedWorldBooks.length;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _settingController.dispose();
    _greetingController.dispose();
    _prefixController.dispose();
    _suffixController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final data = {
        "name": _nameController.text,
        "description": _descriptionController.text,
        "tags": tags,
        "coverUri": _coverUri,
        "backgroundUri": _backgroundUri,
        "setting": _settingController.text,
        "modelName": _modelName,
        "temperature": _temperature,
        "topP": _topP,
        "topK": _topK,
        "maxTokens": _maxTokens,
        "memoryTurns": _memoryTurns,
        "greeting": _greetingController.text,
        "prefix": _prefixController.text,
        "suffix": _suffixController.text,
        "searchDepth": _searchDepth,
        "worldbookMap": _worldbookMap,
        "settingEditable": _settingEditable,
        "status": _status
      };

      final response = widget.isEdit
          ? await CharacterService()
              .updateCharacter(widget.character!['id'].toString(), data)
          : await CharacterService().createCharacter(data);

      if (response['code'] == 0) {
        if (mounted) {
          _showToast(widget.isEdit ? '更新成功' : '创建成功', type: ToastType.success);
          Navigator.pop(context, true); // 返回true表示操作成功
        }
      } else {
        if (mounted) {
          _showToast('${widget.isEdit ? "更新" : "创建"}失败: ${response['message']}',
              type: ToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        _showToast('${widget.isEdit ? "更新" : "创建"}失败: $e',
            type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Divider(
        color: AppTheme.border,
        thickness: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 顶部标题栏
              Container(
                padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 8.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: AppTheme.textPrimary,
                          size: 18.sp,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.isEdit ? '编辑角色' : '创建角色',
                          style: AppTheme.titleStyle,
                        ),
                      ),
                    ),
                    if (_isLoading)
                      SizedBox(
                        width: 20.sp,
                        height: 20.sp,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.w,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _submitForm,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppTheme.buttonGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              transform: const GradientRotation(0.4),
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.buttonGradient.first
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.isEdit ? '更新' : '保存',
                            style: AppTheme.buttonTextStyle.copyWith(
                              fontSize: AppTheme.bodySize,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 内容区域
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(24.w),
                  children: [
                    // 基础信息
                    _buildSectionTitle('基础信息'),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '角色名称',
                        hintText: '请输入角色名称',
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
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
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: '角色简介',
                        hintText: '请输入角色简介',
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: AppTheme.bodyStyle,
                      minLines: 3,
                      maxLines: null,
                    ),
                    SizedBox(height: 16.h),
                    TextFormField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        labelText: '标签',
                        hintText: '请输入标签，用逗号分隔（每个标签至少2个字）',
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: AppTheme.bodyStyle,
                      minLines: 1,
                      maxLines: null,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null; // 标签是可选的
                        }

                        // 支持中文逗号和英文逗号
                        final tags = value
                            .split(RegExp(r'[,，]'))
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();

                        // 检查每个标签的长度
                        for (var tag in tags) {
                          if (tag.length < 2) {
                            return '每个标签至少需要2个字';
                          }
                        }

                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // 封面图片选择
                    Text(
                      '封面图片',
                      style: AppTheme.secondaryStyle,
                    ),
                    SizedBox(height: 8.h),
                    if (_coverUri != null)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppTheme.cardBackground.withOpacity(0.1),
                          ),
                        ),
                        child: Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: FutureBuilder(
                                  future: _coverImageCache != null
                                      ? Future.value(_coverImageCache)
                                      : _fileService
                                          .getFile(_coverUri!)
                                          .then((file) {
                                          _coverImageCache = file.data;
                                          return file.data;
                                        }),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData ||
                                        snapshot.hasError) {
                                      return Container(
                                        color: AppTheme.cardBackground
                                            .withOpacity(0.1),
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
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8.h,
                              right: 8.w,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _coverUri = null;
                                    _coverImageCache = null; // 清除缓存
                                  });
                                  _showToast('已移除封面图片');
                                },
                                child: Container(
                                  width: 32.w,
                                  height: 32.w,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBackground
                                        .withOpacity(0.5),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: AppTheme.error,
                                    size: 18.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SelectImagePage(
                                      source: ImageSelectSource.myMaterial,
                                      type: ImageSelectType.cover,
                                    ),
                                  ),
                                );
                                if (result != null && mounted) {
                                  setState(() => _coverUri = result);
                                  _showToast('已选择封面图片',
                                      type: ToastType.success);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
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
                                      color: AppTheme.buttonGradient.first
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.folder_outlined,
                                        size: 20.sp, color: Colors.white),
                                    SizedBox(width: 8.w),
                                    Text('我的素材库',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: AppTheme.bodySize,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SelectImagePage(
                                      source: ImageSelectSource.publicMaterial,
                                      type: ImageSelectType.cover,
                                    ),
                                  ),
                                );
                                if (result != null && mounted) {
                                  setState(() => _coverUri = result);
                                  _showToast('已选择封面图片',
                                      type: ToastType.success);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
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
                                      color: AppTheme.buttonGradient.first
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.folder_shared_outlined,
                                        size: 20.sp, color: Colors.white),
                                    SizedBox(width: 8.w),
                                    Text('公开素材库',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: AppTheme.bodySize,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 16.h),

                    // 背景图片选择
                    Text(
                      '背景图片',
                      style: AppTheme.secondaryStyle,
                    ),
                    SizedBox(height: 8.h),
                    if (_backgroundUri != null)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppTheme.cardBackground.withOpacity(0.1),
                          ),
                        ),
                        child: Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: FutureBuilder(
                                  future: _backgroundImageCache != null
                                      ? Future.value(_backgroundImageCache)
                                      : _fileService
                                          .getFile(_backgroundUri!)
                                          .then((file) {
                                          _backgroundImageCache = file.data;
                                          return file.data;
                                        }),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData ||
                                        snapshot.hasError) {
                                      return Container(
                                        color: AppTheme.cardBackground
                                            .withOpacity(0.1),
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
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8.h,
                              right: 8.w,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _backgroundUri = null;
                                    _backgroundImageCache = null; // 清除缓存
                                  });
                                  _showToast('已移除背景图片');
                                },
                                child: Container(
                                  width: 32.w,
                                  height: 32.w,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBackground
                                        .withOpacity(0.5),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: AppTheme.error,
                                    size: 18.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SelectImagePage(
                                      source: ImageSelectSource.myMaterial,
                                      type: ImageSelectType.background,
                                    ),
                                  ),
                                );
                                if (result != null && mounted) {
                                  setState(() => _backgroundUri = result);
                                  _showToast('已选择背景图片',
                                      type: ToastType.success);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
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
                                      color: AppTheme.buttonGradient.first
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.folder_outlined,
                                        size: 20.sp, color: Colors.white),
                                    SizedBox(width: 8.w),
                                    Text('我的素材库',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: AppTheme.bodySize,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SelectImagePage(
                                      source: ImageSelectSource.publicMaterial,
                                      type: ImageSelectType.background,
                                    ),
                                  ),
                                );
                                if (result != null && mounted) {
                                  setState(() => _backgroundUri = result);
                                  _showToast('已选择背景图片',
                                      type: ToastType.success);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
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
                                      color: AppTheme.buttonGradient.first
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.folder_shared_outlined,
                                        size: 20.sp, color: Colors.white),
                                    SizedBox(width: 8.w),
                                    Text('公开素材库',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: AppTheme.bodySize,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    _buildDivider(),

                    // 系统设定
                    _buildSectionTitle('系统设定'),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '角色设定',
                          style: AppTheme.secondaryStyle,
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SelectTextPage(
                                        source: TextSelectSource.myMaterial,
                                        type: TextSelectType.setting,
                                      ),
                                    ),
                                  );
                                  if (result != null && mounted) {
                                    setState(
                                        () => _settingController.text = result);
                                    _showToast('已导入角色设定',
                                        type: ToastType.success);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
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
                                        color: AppTheme.buttonGradient.first
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.folder_outlined,
                                          size: 20.sp, color: Colors.white),
                                      SizedBox(width: 8.w),
                                      Text('我的素材库',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: AppTheme.bodySize,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SelectTextPage(
                                        source: TextSelectSource.publicMaterial,
                                        type: TextSelectType.setting,
                                      ),
                                    ),
                                  );
                                  if (result != null && mounted) {
                                    setState(
                                        () => _settingController.text = result);
                                    _showToast('已导入角色设定',
                                        type: ToastType.success);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
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
                                        color: AppTheme.buttonGradient.first
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.folder_shared_outlined,
                                          size: 20.sp, color: Colors.white),
                                      SizedBox(width: 8.w),
                                      Text('公开素材库',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: AppTheme.bodySize,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _settingController,
                          decoration: InputDecoration(
                            hintText: '请输入角色设定，可使用{{变量}}',
                            filled: true,
                            fillColor: AppTheme.cardBackground,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          minLines: 3,
                          maxLines: null,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    TextFormField(
                      controller: _greetingController,
                      decoration: InputDecoration(
                        labelText: '开场白',
                        hintText: '请输入开场白',
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      minLines: 1,
                      maxLines: null,
                    ),
                    SizedBox(height: 16.h),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '前缀词',
                          style: AppTheme.secondaryStyle,
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SelectTextPage(
                                        source: TextSelectSource.myMaterial,
                                        type: TextSelectType.prefix,
                                      ),
                                    ),
                                  );
                                  if (result != null && mounted) {
                                    setState(
                                        () => _prefixController.text = result);
                                    _showToast('已导入前缀词',
                                        type: ToastType.success);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
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
                                        color: AppTheme.buttonGradient.first
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.folder_outlined,
                                          size: 20.sp, color: Colors.white),
                                      SizedBox(width: 8.w),
                                      Text('我的素材库',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: AppTheme.bodySize,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SelectTextPage(
                                        source: TextSelectSource.publicMaterial,
                                        type: TextSelectType.prefix,
                                      ),
                                    ),
                                  );
                                  if (result != null && mounted) {
                                    setState(
                                        () => _prefixController.text = result);
                                    _showToast('已导入前缀词',
                                        type: ToastType.success);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
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
                                        color: AppTheme.buttonGradient.first
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.folder_shared_outlined,
                                          size: 20.sp, color: Colors.white),
                                      SizedBox(width: 8.w),
                                      Text('公开素材库',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: AppTheme.bodySize,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _prefixController,
                          decoration: InputDecoration(
                            hintText: '可选，例如：Assistant:',
                            filled: true,
                            fillColor: AppTheme.cardBackground,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          minLines: 1,
                          maxLines: null,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '后缀词',
                          style: AppTheme.secondaryStyle,
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SelectTextPage(
                                        source: TextSelectSource.myMaterial,
                                        type: TextSelectType.suffix,
                                      ),
                                    ),
                                  );
                                  if (result != null && mounted) {
                                    setState(
                                        () => _suffixController.text = result);
                                    _showToast('已导入后缀词',
                                        type: ToastType.success);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
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
                                        color: AppTheme.buttonGradient.first
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.folder_outlined,
                                          size: 20.sp, color: Colors.white),
                                      SizedBox(width: 8.w),
                                      Text('我的素材库',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: AppTheme.bodySize,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SelectTextPage(
                                        source: TextSelectSource.publicMaterial,
                                        type: TextSelectType.suffix,
                                      ),
                                    ),
                                  );
                                  if (result != null && mounted) {
                                    setState(
                                        () => _suffixController.text = result);
                                    _showToast('已导入后缀词',
                                        type: ToastType.success);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
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
                                        color: AppTheme.buttonGradient.first
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.folder_shared_outlined,
                                          size: 20.sp, color: Colors.white),
                                      SizedBox(width: 8.w),
                                      Text('公开素材库',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: AppTheme.bodySize,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _suffixController,
                          decoration: InputDecoration(
                            hintText: '可选，例如：Human:',
                            filled: true,
                            fillColor: AppTheme.cardBackground,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          minLines: 1,
                          maxLines: null,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    SwitchListTile(
                      title: Text('允许修改设定', style: AppTheme.bodyStyle),
                      value: _settingEditable,
                      onChanged: (value) =>
                          setState(() => _settingEditable = value),
                      tileColor: AppTheme.cardBackground,
                      activeColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),

                    _buildDivider(),

                    // 模型配置
                    _buildSectionTitle('模型配置'),
                    ListTile(
                      title: Text(
                        '模型选择',
                        style: AppTheme.secondaryStyle,
                      ),
                      subtitle: Text(
                        _modelName,
                        style: AppTheme.bodyStyle,
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16.sp,
                        color: AppTheme.textSecondary,
                      ),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SelectModelPage(),
                          ),
                        );
                        if (result != null && mounted) {
                          setState(() => _modelName = result);
                        }
                      },
                    ),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '温度',
                                style: AppTheme.secondaryStyle,
                              ),
                              Text(
                                _temperature.toStringAsFixed(2),
                                style: AppTheme.bodyStyle,
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppTheme.primaryColor,
                              inactiveTrackColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              thumbColor: AppTheme.primaryColor,
                              overlayColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              trackHeight: 4.h,
                            ),
                            child: Slider(
                              value: _temperature,
                              min: 0.0,
                              max: 1.0,
                              divisions: 20,
                              onChanged: (value) {
                                setState(() => _temperature = value);
                              },
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Top P',
                                style: AppTheme.secondaryStyle,
                              ),
                              Text(
                                _topP.toStringAsFixed(2),
                                style: AppTheme.bodyStyle,
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppTheme.primaryColor,
                              inactiveTrackColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              thumbColor: AppTheme.primaryColor,
                              overlayColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              trackHeight: 4.h,
                            ),
                            child: Slider(
                              value: _topP,
                              min: 0.0,
                              max: 1.0,
                              divisions: 20,
                              onChanged: (value) {
                                setState(() => _topP = value);
                              },
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Top K',
                                style: AppTheme.secondaryStyle,
                              ),
                              Text(
                                _topK.toString(),
                                style: AppTheme.bodyStyle,
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppTheme.primaryColor,
                              inactiveTrackColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              thumbColor: AppTheme.primaryColor,
                              overlayColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              trackHeight: 4.h,
                            ),
                            child: Slider(
                              value: _topK.toDouble(),
                              min: 1,
                              max: 100,
                              divisions: 99,
                              onChanged: (value) {
                                setState(() => _topK = value.toInt());
                              },
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '最大Token',
                                style: AppTheme.secondaryStyle,
                              ),
                              Text(
                                _maxTokens.toString(),
                                style: AppTheme.bodyStyle,
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppTheme.primaryColor,
                              inactiveTrackColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              thumbColor: AppTheme.primaryColor,
                              overlayColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              trackHeight: 4.h,
                            ),
                            child: Slider(
                              value: _maxTokens.toDouble(),
                              min: 100,
                              max: 8196,
                              divisions: 81,
                              onChanged: (value) {
                                setState(() {
                                  _maxTokens = value.toInt();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildDivider(),

                    // 高级设定
                    _buildSectionTitle('高级设定'),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '记忆轮数',
                                style: AppTheme.secondaryStyle,
                              ),
                              Text(
                                _memoryTurns.toString(),
                                style: AppTheme.bodyStyle,
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppTheme.primaryColor,
                              inactiveTrackColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              thumbColor: AppTheme.primaryColor,
                              overlayColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              trackHeight: 4.h,
                            ),
                            child: Slider(
                              value: _memoryTurns.toDouble(),
                              min: 1,
                              max: 500,
                              divisions: 499,
                              onChanged: (value) {
                                setState(() => _memoryTurns = value.toInt());
                              },
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '搜索深度',
                                style: AppTheme.secondaryStyle,
                              ),
                              Text(
                                _searchDepth.toString(),
                                style: AppTheme.bodyStyle,
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppTheme.primaryColor,
                              inactiveTrackColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              thumbColor: AppTheme.primaryColor,
                              overlayColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              trackHeight: 4.h,
                            ),
                            child: Slider(
                              value: _searchDepth.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              onChanged: (value) {
                                setState(() => _searchDepth = value.toInt());
                              },
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            '世界书',
                            style: AppTheme.secondaryStyle,
                          ),
                          if (_selectedWorldBookCount > 0)
                            Padding(
                              padding: EdgeInsets.only(top: 4.h),
                              child: Text(
                                '已选择 $_selectedWorldBookCount 个世界书',
                                style: AppTheme.hintStyle,
                              ),
                            ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SelectWorldBookPage(
                                          source:
                                              WorldBookSelectSource.myWorldBook,
                                          initialSelected: _selectedWorldBooks,
                                        ),
                                      ),
                                    );
                                    if (result != null && mounted) {
                                      setState(() {
                                        // 清空之前的选择
                                        _worldbookMap.clear();
                                        _selectedWorldBooks.clear();

                                        // 保存新的选择
                                        _selectedWorldBooks.addAll(
                                            List<Map<String, dynamic>>.from(
                                                result));
                                        for (var worldBook in result) {
                                          final id = worldBook['id'].toString();
                                          final keywords = List<dynamic>.from(
                                              worldBook['keywords'] as List);

                                          for (var keyword in keywords) {
                                            _worldbookMap[keyword.toString()] =
                                                id;
                                          }
                                        }
                                        _selectedWorldBookCount = result.length;
                                      });
                                      _showToast('已选择 ${result.length} 个世界书');
                                    }
                                  },
                                  child: Container(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 12.h),
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
                                          color: AppTheme.buttonGradient.first
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.public,
                                            size: 20.sp, color: Colors.white),
                                        SizedBox(width: 8.w),
                                        Text('我的世界书',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: AppTheme.bodySize,
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SelectWorldBookPage(
                                          source: WorldBookSelectSource
                                              .publicWorldBook,
                                          initialSelected: _selectedWorldBooks,
                                        ),
                                      ),
                                    );
                                    if (result != null && mounted) {
                                      setState(() {
                                        // 清空之前的选择
                                        _worldbookMap.clear();
                                        _selectedWorldBooks.clear();

                                        // 保存新的选择
                                        _selectedWorldBooks.addAll(
                                            List<Map<String, dynamic>>.from(
                                                result));
                                        for (var worldBook in result) {
                                          final id = worldBook['id'].toString();
                                          final keywords = List<dynamic>.from(
                                              worldBook['keywords'] as List);

                                          for (var keyword in keywords) {
                                            _worldbookMap[keyword.toString()] =
                                                id;
                                          }
                                        }
                                        _selectedWorldBookCount = result.length;
                                      });
                                      _showToast('已选择 ${result.length} 个世界书');
                                    }
                                  },
                                  child: Container(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 12.h),
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
                                          color: AppTheme.buttonGradient.first
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.public,
                                            size: 20.sp, color: Colors.white),
                                        SizedBox(width: 8.w),
                                        Text('公开世界书',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: AppTheme.bodySize,
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: InputDecoration(
                              labelText: '发布状态',
                              filled: true,
                              fillColor: AppTheme.cardBackground,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            style: AppTheme.bodyStyle,
                            dropdownColor: AppTheme.cardBackground,
                            items: [
                              DropdownMenuItem(
                                value: 'draft',
                                child: Text('草稿', style: AppTheme.bodyStyle),
                              ),
                              DropdownMenuItem(
                                value: 'published',
                                child: Text('发布', style: AppTheme.bodyStyle),
                              ),
                              DropdownMenuItem(
                                value: 'private',
                                child: Text('私密', style: AppTheme.bodyStyle),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _status = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
