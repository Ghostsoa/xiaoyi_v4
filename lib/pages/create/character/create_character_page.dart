import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
import '../../../theme/app_theme.dart';
import '../services/characte_service.dart';
import '../../../services/file_service.dart';
import '../../../widgets/custom_toast.dart';
import '../../home/pages/item_detail_page.dart';
import 'modules/basic_info_module.dart';
import 'modules/system_settings_module.dart';
import 'modules/model_config_module.dart';
import 'modules/advanced_settings_module.dart';

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
  int _currentPage = 0;

  // 图片缓存Map
  final Map<String, Uint8List> _imageCache = {};

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
  final _userSettingController = TextEditingController();
  final _worldBackgroundController = TextEditingController();
  final _rulesController = TextEditingController();
  final _positiveDialogExamplesController = TextEditingController();
  final _negativeDialogExamplesController = TextEditingController();
  final _supplementSettingController = TextEditingController();
  bool _settingEditable = false;
  String _uiSettings = 'markdown';

  // 模型配置
  String _modelName = 'gemini-2.0-flash';
  double _temperature = 0.7;
  double _topP = 0.9;
  int _topK = 40;
  int _maxTokens = 2000;

  // 高级设定
  int _memoryTurns = 100;
  int _searchDepth = 5;
  Map<String, dynamic> _worldbookMap = {};
  String _status = 'draft';
  int _selectedWorldBookCount = 0;
  final List<Map<String, dynamic>> _selectedWorldBooks = [];
  String _enhanceMode = 'disabled';
  final _resourceMappingController = TextEditingController();

  final List<String> _pageNames = ['基础信息', '系统设定', '模型配置', '高级设定'];

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
    _userSettingController.text =
        character['userSetting'] ?? '你应该尊重用户，并提供准确的信息。';
    _worldBackgroundController.text = character['worldBackground'] ?? '';
    _rulesController.text = character['rules'] ?? '';
    _positiveDialogExamplesController.text = character['positiveDialogExamples'] ?? '';
    _negativeDialogExamplesController.text = character['negativeDialogExamples'] ?? '';
    _supplementSettingController.text = character['supplementSetting'] ?? '';
    _settingEditable = character['settingEditable'] ?? true;
    _uiSettings = character['uiSettings'] ?? 'markdown';
    _modelName = character['modelName'] ?? 'gemini-2.0-flash';
    _temperature = (character['temperature'] ?? 0.7).toDouble();
    _topP = (character['topP'] ?? 0.9).toDouble();
    _topK = character['topK'] ?? 40;
    _maxTokens = character['maxTokens'] ?? 2000;
    _memoryTurns = character['memoryTurns'] ?? 100;
    _searchDepth = character['searchDepth'] ?? 5;
    _status = character['status'] ?? 'draft';
    _enhanceMode = character['enhanceMode'] ?? 'disabled';
    _resourceMappingController.text = character['resourceMapping'] ?? '';

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
    _userSettingController.dispose();
    _worldBackgroundController.dispose();
    _rulesController.dispose();
    _positiveDialogExamplesController.dispose();
    _negativeDialogExamplesController.dispose();
    _supplementSettingController.dispose();
    _resourceMappingController.dispose();
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
        "userSetting": _userSettingController.text,
        "worldBackground": _worldBackgroundController.text,
        "rules": _rulesController.text,
        "positiveDialogExamples": _positiveDialogExamplesController.text,
        "negativeDialogExamples": _negativeDialogExamplesController.text,
        "supplementSetting": _supplementSettingController.text,
        "uiSettings": _uiSettings,
        "searchDepth": _searchDepth,
        "worldbookMap": _worldbookMap,
        "settingEditable": _settingEditable,
        "status": _status,
        "enhanceMode": _enhanceMode,
        "resourceMapping": _resourceMappingController.text,
      };

      final response = widget.isEdit
          ? await CharacterService()
              .updateCharacter(widget.character!['id'].toString(), data)
          : await CharacterService().createCharacter(data);

      if (response['code'] == 0) {
        if (mounted) {
          _showToast(widget.isEdit ? '更新成功' : '创建成功', type: ToastType.success);

          if (widget.isEdit) {
            // 编辑模式：返回上一页并通知刷新
            Navigator.pop(context, true);
          } else {
            // 创建模式：返回上一页
            Navigator.pop(context, true);
          }
        }
      } else {
        if (mounted) {
          _showToast('${widget.isEdit ? "更新" : "创建"}失败: ${response['msg']}',
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


  /// 预览角色
  void _previewCharacter() {
    if (!widget.isEdit || widget.character == null) {
      _showToast('只有编辑模式下才能预览', type: ToastType.warning);
      return;
    }

    // 转换当前表单数据为预览格式（下划线命名）
    final previewData = _convertToPreviewFormat();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailPage(item: previewData),
      ),
    );
  }

  /// 将当前表单数据转换为预览格式（下划线命名，适配 ItemDetailPage）
  Map<String, dynamic> _convertToPreviewFormat() {
    return {
      'id': widget.character?['id'] ?? 0,
      'title': _nameController.text.isNotEmpty ? _nameController.text : '未命名角色',
      'description': _descriptionController.text,
      'cover_uri': _coverUri,
      'author_name': widget.character?['author_name'] ?? '未知作者',
      'author_id': widget.character?['author_id'] ?? 0,
      'item_type': 'character_card',
      'tags': _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'like_count': widget.character?['like_count'] ?? 0,
      'dialog_count': widget.character?['dialog_count'] ?? 0,
      'hot_score': widget.character?['hot_score'] ?? 0,
      'created_at': widget.character?['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(), // 使用当前时间作为更新时间
      'status': _status,
      // 添加其他可能需要的字段（保持下划线命名）
      'setting': _settingController.text,
      'greeting': _greetingController.text,
      'model_name': _modelName,
      'temperature': _temperature,
      'top_p': _topP,
      'top_k': _topK,
      'max_tokens': _maxTokens,
      'memory_turns': _memoryTurns,
      'search_depth': _searchDepth,
      'world_background': _worldBackgroundController.text,
      'rules': _rulesController.text,
      'positive_dialog_examples': _positiveDialogExamplesController.text,
      'negative_dialog_examples': _negativeDialogExamplesController.text,
      'ui_settings': _uiSettings,
      'setting_editable': _settingEditable,
      'enhance_mode': _enhanceMode,
    };
  }

  void _showToast(String message, {ToastType type = ToastType.info}) {
    if (!mounted) return;
    CustomToast.show(context, message: message, type: type);
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
        return BasicInfoModule(
          nameController: _nameController,
          descriptionController: _descriptionController,
          tagsController: _tagsController,
          coverUri: _coverUri,
          backgroundUri: _backgroundUri,
          onCoverUriChanged: (value) =>
              setState(() => _coverUri = value.isEmpty ? null : value),
          onBackgroundUriChanged: (value) =>
              setState(() => _backgroundUri = value.isEmpty ? null : value),
          imageCache: _imageCache,
        );
      case 1:
        return SystemSettingsModule(
          settingController: _settingController,
          greetingController: _greetingController,
          userSettingController: _userSettingController,
          worldBackgroundController: _worldBackgroundController,
          rulesController: _rulesController,
          positiveDialogExamplesController: _positiveDialogExamplesController,
          negativeDialogExamplesController: _negativeDialogExamplesController,
          supplementSettingController: _supplementSettingController,
          settingEditable: _settingEditable,
          onSettingEditableChanged: (value) =>
              setState(() => _settingEditable = value),
        );
      case 2:
        return ModelConfigModule(
          modelName: _modelName,
          temperature: _temperature,
          topP: _topP,
          topK: _topK,
          maxTokens: _maxTokens,
          onModelNameChanged: (value) => setState(() => _modelName = value),
          onTemperatureChanged: (value) => setState(() => _temperature = value),
          onTopPChanged: (value) => setState(() => _topP = value),
          onTopKChanged: (value) => setState(() => _topK = value),
          onMaxTokensChanged: (value) => setState(() => _maxTokens = value),
        );
      case 3:
        return AdvancedSettingsModule(
          memoryTurns: _memoryTurns,
          searchDepth: _searchDepth,
          status: _status,
          uiSettings: _uiSettings,
          selectedWorldBooks: _selectedWorldBooks,
          prefixController: _prefixController,
          suffixController: _suffixController,
          enhanceMode: _enhanceMode,
          resourceMappingController: _resourceMappingController,
          imageCache: _imageCache,
          onMemoryTurnsChanged: (value) => setState(() => _memoryTurns = value),
          onSearchDepthChanged: (value) => setState(() => _searchDepth = value),
          onStatusChanged: (value) => setState(() => _status = value),
          onUiSettingsChanged: (value) => setState(() => _uiSettings = value),
          onWorldBooksChanged: (value) => setState(() => _selectedWorldBooks
            ..clear()
            ..addAll(value)),
          onWorldbookMapChanged: (value) =>
              setState(() => _worldbookMap = value),
          onEnhanceModeChanged: (value) => setState(() => _enhanceMode = value),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 预览按钮（仅编辑模式显示）
                          if (widget.isEdit) ...[
                            GestureDetector(
                              onTap: _previewCharacter,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  border: Border.all(
                                    color: AppTheme.primaryColor,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      color: AppTheme.primaryColor,
                                      size: 16.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '预览',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: AppTheme.bodySize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],
                          // 更新/保存按钮
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
