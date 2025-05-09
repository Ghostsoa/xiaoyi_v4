import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
import '../../../theme/app_theme.dart';
import '../services/characte_service.dart';
import '../../../services/file_service.dart';
import '../../../widgets/custom_toast.dart';
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
  final _statusBarController = TextEditingController();
  bool _settingEditable = true;
  String _uiSettings = 'markdown';

  // 模型配置
  String _modelName = 'gemini-2.0-flash';
  double _temperature = 0.7;
  double _topP = 0.9;
  int _topK = 40;
  int _maxTokens = 2000;
  bool _streamMode = true;

  // 高级设定
  int _memoryTurns = 100;
  int _searchDepth = 5;
  bool _permanentMemory = false;
  Map<String, dynamic> _worldbookMap = {};
  String _status = 'draft';
  int _selectedWorldBookCount = 0;
  final List<Map<String, dynamic>> _selectedWorldBooks = [];

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
    _statusBarController.text =
        character['statusBar'] ?? 'HP: 100 | MP: 50 | 好感度: 80';
    _settingEditable = character['settingEditable'] ?? true;
    _uiSettings = character['uiSettings'] ?? 'markdown';
    _modelName = character['modelName'] ?? 'gemini-2.0-flash';
    _temperature = (character['temperature'] ?? 0.7).toDouble();
    _topP = (character['topP'] ?? 0.9).toDouble();
    _topK = character['topK'] ?? 40;
    _maxTokens = character['maxTokens'] ?? 2000;
    _streamMode = character['streamMode'] ?? true;
    _memoryTurns = character['memoryTurns'] ?? 100;
    _searchDepth = character['searchDepth'] ?? 5;
    _permanentMemory = character['permanentMemory'] ?? false;
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
    _userSettingController.dispose();
    _statusBarController.dispose();
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
        "streamMode": _streamMode,
        "memoryTurns": _memoryTurns,
        "permanentMemory": _permanentMemory,
        "greeting": _greetingController.text,
        "prefix": _prefixController.text,
        "suffix": _suffixController.text,
        "userSetting": _userSettingController.text,
        "statusBar": _statusBarController.text,
        "uiSettings": _uiSettings,
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
          Navigator.pop(context, true);
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
          statusBarController: _statusBarController,
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
          streamMode: _streamMode,
          onModelNameChanged: (value) => setState(() => _modelName = value),
          onTemperatureChanged: (value) => setState(() => _temperature = value),
          onTopPChanged: (value) => setState(() => _topP = value),
          onTopKChanged: (value) => setState(() => _topK = value),
          onMaxTokensChanged: (value) => setState(() => _maxTokens = value),
          onStreamModeChanged: (value) => setState(() => _streamMode = value),
        );
      case 3:
        return AdvancedSettingsModule(
          memoryTurns: _memoryTurns,
          searchDepth: _searchDepth,
          status: _status,
          uiSettings: _uiSettings,
          permanentMemory: _permanentMemory,
          selectedWorldBooks: _selectedWorldBooks,
          prefixController: _prefixController,
          suffixController: _suffixController,
          onMemoryTurnsChanged: (value) => setState(() => _memoryTurns = value),
          onSearchDepthChanged: (value) => setState(() => _searchDepth = value),
          onStatusChanged: (value) => setState(() => _status = value),
          onUiSettingsChanged: (value) => setState(() => _uiSettings = value),
          onPermanentMemoryChanged: (value) =>
              setState(() => _permanentMemory = value),
          onWorldBooksChanged: (value) => setState(() => _selectedWorldBooks
            ..clear()
            ..addAll(value)),
          onWorldbookMapChanged: (value) =>
              setState(() => _worldbookMap = value),
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
