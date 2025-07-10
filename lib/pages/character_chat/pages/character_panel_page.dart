import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/file_service.dart';
import '../services/character_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';
import '../widgets/character_panel/basic_info_card.dart';
import '../widgets/character_panel/setting_card.dart';
import '../widgets/character_panel/model_config_card.dart';
import '../widgets/character_panel/interaction_card.dart';

class CharacterPanelPage extends StatefulWidget {
  final Map<String, dynamic> characterData;

  const CharacterPanelPage({
    super.key,
    required this.characterData,
  });

  @override
  State<CharacterPanelPage> createState() => _CharacterPanelPageState();
}

class _CharacterPanelPageState extends State<CharacterPanelPage> {
  final FileService _fileService = FileService();
  final CharacterService _characterService = CharacterService();

  Uint8List? _coverImage;
  bool _isLoadingCover = false;
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _sessionData = {};
  final Map<String, dynamic> _editedData = {};
  String? _error;
  int _currentPageIndex = 0;
  String _enhanceMode = 'disabled';

  final _settingController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _topPController = TextEditingController();
  final _topKController = TextEditingController();
  final _maxTokensController = TextEditingController();
  final _memoryTurnsController = TextEditingController();
  final _searchDepthController = TextEditingController();
  final _greetingController = TextEditingController();
  final _prefixController = TextEditingController();
  final _suffixController = TextEditingController();
  final _userSettingController = TextEditingController();
  String _uiSettings = 'markdown';

  final List<String> _pageNames = [
    '基本信息',
    '设定',
    'AI模型',
    '交互设置',
  ];

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  @override
  void dispose() {
    _settingController.dispose();
    _temperatureController.dispose();
    _topPController.dispose();
    _topKController.dispose();
    _maxTokensController.dispose();
    _memoryTurnsController.dispose();
    _searchDepthController.dispose();
    _greetingController.dispose();
    _prefixController.dispose();
    _suffixController.dispose();
    _userSettingController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _characterService
          .getCharacterSession(widget.characterData['id']);
      if (!mounted) return;

      setState(() {
        _sessionData = data;
        _isLoading = false;
        _enhanceMode = data['enhance_mode'] ?? 'disabled';
      });

      // 加载封面图
      if (data['coverUri'] != null) {
        _loadCoverImage(data['coverUri']);
      }

      // 初始化编辑器的值
      _settingController.text = data['setting'] ?? '';
      _temperatureController.text = (data['temperature'] ?? 0.7).toString();
      _topPController.text = (data['top_p'] ?? 0.9).toString();
      _topKController.text = (data['top_k'] ?? 40).toString();
      _maxTokensController.text = (data['max_tokens'] ?? 2000).toString();
      _memoryTurnsController.text = (data['memory_turns'] ?? 10).toString();
      _searchDepthController.text = (data['search_depth'] ?? 5).toString();
      _greetingController.text = data['greeting'] ?? '';
      _prefixController.text = data['prefix'] ?? '';
      _suffixController.text = data['suffix'] ?? '';
      _userSettingController.text = data['user_setting'] ?? '';

      _uiSettings = data['ui_settings'] ?? 'markdown';
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCoverImage(String coverUri) async {
    if (_isLoadingCover || _coverImage != null) return;

    _isLoadingCover = true;
    try {
      final result = await _fileService.getFile(coverUri);
      if (mounted) {
        setState(() {
          _coverImage = result.data;
          _isLoadingCover = false;
        });
      }
    } catch (e) {
      debugPrint('封面图加载失败: $e');
      if (mounted) {
        setState(() => _isLoadingCover = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      // 在提交前，确保所有字段的当前值都被添加到_editedData中
      _editedData['setting'] = _settingController.text;
      _editedData['temperature'] =
          double.tryParse(_temperatureController.text) ?? 0.7;
      _editedData['top_p'] = double.tryParse(_topPController.text) ?? 0.9;
      _editedData['top_k'] = int.tryParse(_topKController.text) ?? 40;
      _editedData['max_tokens'] =
          int.tryParse(_maxTokensController.text) ?? 2000;
      _editedData['memory_turns'] =
          int.tryParse(_memoryTurnsController.text) ?? 10;
      _editedData['search_depth'] =
          int.tryParse(_searchDepthController.text) ?? 5;
      _editedData['greeting'] = _greetingController.text;
      _editedData['prefix'] = _prefixController.text;
      _editedData['suffix'] = _suffixController.text;
      _editedData['user_setting'] = _userSettingController.text;
      _editedData['ui_settings'] = _uiSettings;

      // 添加缺少的设定字段
      _editedData['world_background'] = _sessionData['world_background'] ?? '';
      _editedData['rules'] = _sessionData['rules'] ?? '';
      _editedData['positive_dialog_examples'] =
          _sessionData['positive_dialog_examples'] ?? '';
      _editedData['negative_dialog_examples'] =
          _sessionData['negative_dialog_examples'] ?? '';
      _editedData['supplement_setting'] =
          _sessionData['supplement_setting'] ?? '';

      // 添加其他可能需要的字段
      _editedData['enhance_mode'] = _enhanceMode;

      // 如果没有选择新模型，才使用原有模型
      if (!_editedData.containsKey('model_name')) {
        _editedData['model_name'] = _sessionData['model_name'];
      }

      await _characterService.updateCharacterSession(
        widget.characterData['id'],
        _editedData,
      );

      if (!mounted) return;

      CustomToast.show(
        context,
        message: '保存成功',
        type: ToastType.success,
      );

      // 重新加载数据
      await _loadSessionData();

      // 清空编辑数据
      _editedData.clear();
    } catch (e) {
      if (!mounted) return;
      CustomToast.show(
        context,
        message: e.toString(),
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _updateField(String field, dynamic value) {
    setState(() {
      _editedData[field] = value;

      // 为了实时更新UI状态
      if (field == 'enhance_mode') {
        _enhanceMode = value;
      }
    });
  }

  Widget _buildShimmerCard({
    required String title,
    required int itemCount,
  }) {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            ...List.generate(
              itemCount,
              (index) => Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.textPrimary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[800]!,
                  highlightColor: Colors.grey[600]!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: double.infinity,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: [
        _buildPageSelector(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _buildShimmerCard(title: '基本信息', itemCount: 6),
          ),
        ),
      ],
    );
  }

  Widget _buildPageSelector() {
    return Container(
      height: 40.h,
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pageNames.length, (index) {
          final isSelected = _currentPageIndex == index;
          return TextButton(
            onPressed: () {
              setState(() {
                _currentPageIndex = index;
              });
            },
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                  EdgeInsets.symmetric(horizontal: 8.w)),
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              shadowColor: WidgetStateProperty.all(Colors.transparent),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: WidgetStateProperty.all(TextStyle(
                decoration: TextDecoration.none,
              )),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 8.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color:
                        isSelected ? AppTheme.primaryColor : Colors.transparent,
                    width: 2.0,
                  ),
                ),
              ),
              child: Text(
                _pageNames[index],
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  fontSize: 15.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentPageIndex) {
      case 0:
        return BasicInfoCard(sessionData: _sessionData);
      case 1:
        return SettingCard(
          sessionData: _sessionData,
          onUpdateField: _updateField,
          settingController: _settingController,
          userSettingController: _userSettingController,
        );
      case 2:
        return ModelConfigCard(
          sessionData: _sessionData,
          editedData: _editedData,
          onUpdateField: _updateField,
          temperatureController: _temperatureController,
          topPController: _topPController,
          topKController: _topKController,
          maxTokensController: _maxTokensController,
          memoryTurnsController: _memoryTurnsController,
          searchDepthController: _searchDepthController,
        );
      case 3:
        return InteractionCard(
          sessionData: _sessionData,
          onUpdateField: _updateField,
          greetingController: _greetingController,
          prefixController: _prefixController,
          suffixController: _suffixController,
          uiSettings: _uiSettings,
          onUiSettingsChanged: (value) {
            setState(() {
              _uiSettings = value;
              _updateField('ui_settings', value);
            });
          },
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '角色信息',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '加载失败',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: _loadSessionData,
                child: Text(
                  '重试',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        shadowColor: Colors.transparent,
        title: Text(
          '角色信息',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                      ),
                    )
                  : Text(
                      '保存',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingContent()
          : Column(
              children: [
                _buildPageSelector(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _buildCurrentPage(),
                  ),
                ),
              ],
            ),
    );
  }
}
