import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
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
  final Uint8List? backgroundImage; // 添加背景图像参数
  final double backgroundOpacity; // 添加背景不透明度参数

  const CharacterPanelPage({
    super.key,
    required this.characterData,
    this.backgroundImage, // 可选参数，允许不传递背景图
    this.backgroundOpacity = 0.5, // 默认不透明度
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
  String _uiSettings = 'markdown';

  // 为分类添加对应的颜色
  final List<Color> _pageColors = [
    Colors.blue.shade400,
    Colors.purple.shade400,
    Colors.green.shade400,
    Colors.orange.shade400,
  ];

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

      _uiSettings = data['ui_settings'] ?? 'markdown';
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

      // 设置刷新状态标志
      setState(() {
        _isSaving = false;
        _isRefreshing = true;
      });

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
        baseColor: Colors.white,
        highlightColor: Colors.white.withOpacity(0.3),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 5,
                offset: Offset(0, 1),
              ),
            ],
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
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ),
        // 标题 - 修改颜色为白色渐变
        Text(
          '角色信息',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 5,
                offset: Offset(0, 1),
              )
            ],
          ),
        ),
        // 保存按钮 - 改为纯图标按钮
        _isSaving
            ? Container(
                padding: EdgeInsets.all(8.w),
                child: SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildPageSelector() {
    return SizedBox(
      height: 36.h, // 更小的高度
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pageNames.length,
        itemBuilder: (context, index) {
          final isSelected = _currentPageIndex == index;
          final color = _pageColors[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentPageIndex = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 10.w), // 更小的内边距
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          color.withOpacity(0.7),
                          color.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r), // 更小的圆角
                border: Border.all(
                  color: isSelected ? color : Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _pageIcons[index],
                    color: isSelected ? Colors.white : color.withOpacity(0.8),
                    size: 15.sp, // 更小的图标
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _pageNames[index],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.9),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12.sp, // 更小的字体
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60.sp,
                ),
                SizedBox(height: 16.h),
                Text(
                  '加载失败',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _error ?? '未知错误',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: _loadSessionData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  ),
                  child: Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // 背景透明
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景层
          if (widget.backgroundImage != null)
            Image.memory(
              widget.backgroundImage!,
              fit: BoxFit.cover,
            ),
          // 背景叠加层
          Container(color: Colors.black.withOpacity(widget.backgroundOpacity)),

          // 状态栏空间
          SafeArea(
            child: _error != null
                ? _buildErrorView()
                : _isLoading || _isRefreshing
                    ? _buildLoadingText(
                        _isRefreshing ? "正在刷新数据..." : "正在加载角色信息...")
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
        ],
      ),
    );
  }
}
