import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import 'modules/basic_info_module.dart';
import 'modules/story_settings_module.dart';
import 'modules/character_settings_module.dart';
import 'modules/model_config_module.dart';
import '../../../widgets/custom_toast.dart';
import '../services/novel_service.dart';

class CreateNovelPage extends StatefulWidget {
  final Map<String, dynamic>? novel;
  final bool isEdit;

  const CreateNovelPage({
    super.key,
    this.novel,
    this.isEdit = false,
  });

  @override
  State<CreateNovelPage> createState() => _CreateNovelPageState();
}

class _CreateNovelPageState extends State<CreateNovelPage> {
  final _formKey = GlobalKey<FormState>();
  final _novelService = NovelService();
  bool _isLoading = false;
  int _currentPage = 0;

  // 基本信息
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _selectedTags = [];
  String _coverUri = '';
  String _selectedStatus = 'draft';

  // 主要设定 (大纲和世界观)
  final _storyOutlineController = TextEditingController();
  final _worldSettingsController = TextEditingController();
  Map<String, dynamic> _worldbookMap = {};
  List<Map<String, dynamic>> _selectedWorldBooks = [];
  int _selectedWorldBookCount = 0;

  // 角色设定
  final _protagonistSetController = TextEditingController();
  final _npcSettingsController = TextEditingController();
  final _supplementarySetController = TextEditingController();

  // 模型配置
  String _modelName = 'default';

  final List<String> _pageNames = ['基础信息', '主要设定', '角色设定', '模型设定'];

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.novel != null) {
      _initializeEditData();
    }
  }

  void _initializeEditData() {
    final novel = widget.novel!;

    // 基本信息
    _titleController.text = novel['title'] ?? '';
    _descriptionController.text = novel['description'] ?? '';
    _selectedTags = List<String>.from(novel['tags'] ?? []);
    _coverUri = novel['coverUri'] ?? '';
    _selectedStatus = novel['status'] ?? 'draft';

    // 主要设定
    _storyOutlineController.text = novel['storyOutline'] ?? '';
    _worldSettingsController.text = novel['worldSettings'] ?? '';

    // 角色设定
    _protagonistSetController.text = novel['protagonistSet'] ?? '';
    _npcSettingsController.text = novel['npcSettings'] ?? '';
    _supplementarySetController.text = novel['supplementarySet'] ?? '';

    // 模型配置 - 只使用modelName
    _modelName = novel['modelName'] ?? 'default';

    // 世界书数据
    if (novel['worldbookMap'] != null) {
      _worldbookMap = Map<String, dynamic>.from(novel['worldbookMap']);

      // 根据worldbookMap中的ID获取已选中的世界书
      final Set<String> selectedIds = Set<String>.from(_worldbookMap.values);
      _selectedWorldBookCount = selectedIds.length;

      // 创建临时的世界书列表
      _selectedWorldBooks.clear();
      for (String id in selectedIds) {
        _selectedWorldBooks.add({
          'id': id,
          'keywords': _worldbookMap.entries
              .where((entry) => entry.value == id)
              .map((entry) => entry.key)
              .toList(),
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _storyOutlineController.dispose();
    _worldSettingsController.dispose();
    _protagonistSetController.dispose();
    _npcSettingsController.dispose();
    _supplementarySetController.dispose();
    super.dispose();
  }

  void _showToast(String message, {ToastType type = ToastType.info}) {
    if (!mounted) return;
    CustomToast.show(context, message: message, type: type);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 构建请求参数 - 确保与JSON结构完全一致
      final Map<String, dynamic> requestBody = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'coverUri': _coverUri,
        'tags': _selectedTags,
        'status': _selectedStatus,
        'modelName': _modelName,
        'storyOutline': _storyOutlineController.text,
        'worldSettings': _worldSettingsController.text,
        'protagonistSet': _protagonistSetController.text,
        'npcSettings': _npcSettingsController.text,
        'supplementarySet': _supplementarySetController.text,
        'worldbookMap': _worldbookMap,
      };

      // 使用NovelService调用API
      final Map<String, dynamic> responseData = widget.isEdit
          ? await _novelService.updateNovel(
              widget.novel!['id'].toString(), requestBody)
          : await _novelService.createNovel(requestBody);

      if (responseData['code'] == 0) {
        if (mounted) {
          _showToast(responseData['message'].toString(),
              type: ToastType.success);
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(responseData['message'].toString());
      }
    } catch (e) {
      // 错误处理
      if (mounted) {
        _showToast('${widget.isEdit ? "更新" : "创建"}失败: ${e.toString()}',
            type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildNavigationButton(int index) {
    final isSelected = _currentPage == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentPage = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            _pageNames[index],
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_currentPage) {
      case 0:
        return NovelBasicInfoModule(
          titleController: _titleController,
          descriptionController: _descriptionController,
          selectedTags: _selectedTags,
          coverUri: _coverUri,
          selectedStatus: _selectedStatus,
          onTagsChanged: (tags) {
            setState(() => _selectedTags = tags);
          },
          onCoverUriChanged: (uri) {
            setState(() => _coverUri = uri);
          },
          onStatusChanged: (status) {
            setState(() => _selectedStatus = status);
          },
        );
      case 1:
        return NovelStorySettingsModule(
          storyOutlineController: _storyOutlineController,
          worldSettingsController: _worldSettingsController,
          selectedWorldBooks: _selectedWorldBooks,
          onWorldBooksChanged: (worldBooks) {
            setState(() {
              _selectedWorldBooks = worldBooks;
              _selectedWorldBookCount = worldBooks.length;
            });
          },
          onWorldbookMapChanged: (map) {
            setState(() => _worldbookMap = map);
          },
        );
      case 2:
        return NovelCharacterSettingsModule(
          protagonistSetController: _protagonistSetController,
          npcSettingsController: _npcSettingsController,
          supplementarySetController: _supplementarySetController,
        );
      case 3:
        return NovelModelConfigModule(
          modelName: _modelName,
          onModelNameChanged: (modelName) {
            setState(() => _modelName = modelName);
          },
        );
      default:
        return const SizedBox();
    }
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
                      onTap: () => Navigator.of(context).pop(true),
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
                          widget.isEdit ? '编辑小说' : '创建小说',
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppTheme.bodySize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 导航按钮
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                child: Row(
                  children: List.generate(
                    _pageNames.length,
                    (index) => _buildNavigationButton(index),
                  ),
                ),
              ),

              // 内容区域
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.w),
                  child: _buildPageContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
