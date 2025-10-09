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
  bool _isSyncing = false;
  bool _isRefreshing = false; // 添加刷新状态标志
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
  // 添加其他设定字段的控制器
  final _worldBackgroundController = TextEditingController();
  final _rulesController = TextEditingController();
  final _positiveDialogController = TextEditingController();
  final _negativeDialogController = TextEditingController();
  final _supplementSettingController = TextEditingController();
  String _uiSettings = 'markdown';
  String _originalUiSettings = 'markdown'; // 保存原始的UI设置，用于检测变化

  final List<String> _pageNames = [
    '基本信息',
    '设定',
    'AI模型',
    '交互设置',
  ];

  final List<IconData> _pageIcons = [
    Icons.person_outline,
    Icons.description_outlined,
    Icons.smart_toy_outlined,
    Icons.settings_outlined,
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
    // 释放新添加的控制器
    _worldBackgroundController.dispose();
    _rulesController.dispose();
    _positiveDialogController.dispose();
    _negativeDialogController.dispose();
    _supplementSettingController.dispose();
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
        _isRefreshing = false; // 重置刷新状态
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
      // 初始化其他设定字段的控制器
      _worldBackgroundController.text = data['world_background'] ?? '';
      _rulesController.text = data['rules'] ?? '';
      _positiveDialogController.text = data['positive_dialog_examples'] ?? '';
      _negativeDialogController.text = data['negative_dialog_examples'] ?? '';
      _supplementSettingController.text = data['supplement_setting'] ?? '';

      _uiSettings = data['ui_settings'] ?? 'markdown';
      _originalUiSettings = _uiSettings; // 保存原始值
      
      // 确保 prefix_suffix_editable 字段被加载到 sessionData 中
      if (!_sessionData.containsKey('prefix_suffix_editable')) {
        _sessionData['prefix_suffix_editable'] = data['prefix_suffix_editable'] ?? false;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isRefreshing = false; // 重置刷新状态
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

      // 添加设定字段 - 使用控制器的当前值
      _editedData['world_background'] = _worldBackgroundController.text;
      _editedData['rules'] = _rulesController.text;
      _editedData['positive_dialog_examples'] = _positiveDialogController.text;
      _editedData['negative_dialog_examples'] = _negativeDialogController.text;
      _editedData['supplement_setting'] = _supplementSettingController.text;

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

      // 检查UI设置是否发生变化
      if (_originalUiSettings != _uiSettings) {
        // 显示需要刷新的提示弹窗
        _showRefreshDialog();
      } else {
        // 设置刷新状态标志
        setState(() {
          _isSaving = false;
        _isRefreshing = true;
        });
      }

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
      setState(() => _isSaving = false);
    }
  }

  // 显示需要刷新的提示弹窗
  void _showRefreshDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 不允许点击外部关闭
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('设置已更新'),
          content: const Text('界面渲染类型已更改，需要退出当前页面后重新进入才能生效。'),
          actions: [
            TextButton(
              onPressed: () {
                // 关闭弹窗
                Navigator.of(context).pop();
                // 连续返回2次页面，回到聊天列表，并传递刷新标志
                Navigator.of(context).pop(true); // 返回到聊天页面，传递刷新标志
                Navigator.of(context).pop(true); // 返回到聊天列表，传递刷新标志
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
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

  // 构建加载中的文本
  Widget _buildLoadingText(String text) {
    return Center(
      child: Shimmer.fromColors(
        baseColor: AppTheme.textPrimary,
        highlightColor: AppTheme.textSecondary.withOpacity(0.3),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 返回按钮 - 改为纯图标按钮
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.all(8.w),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.textPrimary,
                size: 20.sp,
              ),
            ),
          ),
        ),
        // 标题
        Text(
          '角色信息',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        // 右侧操作区：可选的同步按钮 + 保存按钮
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 如果存在 debug 字段且非空，则显示同步按钮
            if ((_sessionData['debug']?.toString().isNotEmpty ?? false))
              _isSyncing
                  ? Container(
                      padding: EdgeInsets.all(8.w),
                      child: SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.w,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor),
                        ),
                      ),
                    )
                  : Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _syncDebugSettings,
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          child: Icon(
                            Icons.cloud_sync_outlined,
                            color: AppTheme.primaryColor,
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),
            SizedBox(width: 4.w),
            _isSaving
                ? Container(
                    padding: EdgeInsets.all(8.w),
                    child: SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                      ),
                    ),
                  )
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _saveChanges,
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        child: Icon(
                          Icons.save,
                          color: AppTheme.primaryColor,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  Future<void> _syncDebugSettings() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      await _characterService.syncDebugSettings(widget.characterData['id']);
      if (!mounted) return;
      CustomToast.show(
        context,
        message: '同步成功',
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      CustomToast.show(
        context,
        message: e.toString(),
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Widget _buildPageSelector() {
    return SizedBox(
      height: 36.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pageNames.length,
        itemBuilder: (context, index) {
          final isSelected = _currentPageIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentPageIndex = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.2)
                    : AppTheme.cardBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.cardBackground,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _pageIcons[index],
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                    size: 15.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _pageNames[index],
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
          worldBackgroundController: _worldBackgroundController,
          rulesController: _rulesController,
          positiveDialogController: _positiveDialogController,
          negativeDialogController: _negativeDialogController,
          supplementSettingController: _supplementSettingController,
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

  Widget _buildErrorView() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.error,
              size: 60.sp,
            ),
            SizedBox(height: 16.h),
            Text(
              '加载失败',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _error ?? '未知错误',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadSessionData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error.withOpacity(0.7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              ),
              child: Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _error != null
            ? _buildErrorView()
            : _isLoading || _isRefreshing
                ? _buildLoadingText(_isRefreshing ? "正在刷新数据..." : "正在加载角色信息...")
                : Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        SizedBox(height: 12.h),
                        _buildPageSelector(),
                        SizedBox(height: 12.h),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(horizontal: 2.w),
                            physics: const BouncingScrollPhysics(),
                            child: _buildCurrentPage(),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
