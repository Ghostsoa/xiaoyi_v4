import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/character_service.dart';
import '../../../services/file_service.dart';
import 'dart:typed_data';
import 'dart:ui'; // Added for ImageFilter
import 'dart:async'; // Added for Timer
import 'package:shimmer/shimmer.dart';
import 'character_chat_page.dart';
import '../../../theme/app_theme.dart';

class CharacterInitPage extends StatefulWidget {
  final Map<String, dynamic> characterData;

  const CharacterInitPage({
    super.key,
    required this.characterData,
  });

  @override
  State<CharacterInitPage> createState() => _CharacterInitPageState();
}

class _CharacterInitPageState extends State<CharacterInitPage>
    with SingleTickerProviderStateMixin {
  final CharacterService _characterService = CharacterService();
  final FileService _fileService = FileService();
  final PageController _pageController = PageController();
  final Map<String, String> _initFieldValues = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _initFields;
  List<MapEntry<String, dynamic>> _fieldsList = [];
  final List<MapEntry<String, dynamic>> _interactiveFields = [];

  // 加载提示语
  final List<String> _loadingTips = [
    "正在初始化对话...",
    "正在生成角色记忆...",
    "正在加载人格设定...",
    "正在设置交互参数...",
    "即将与角色相遇...",
    "正在构建对话场景...",
    "正在调整AI模型...",
    "马上就好...",
  ];
  int _currentTipIndex = 0;
  Timer? _tipTimer;

  // 缓存封面图片
  Uint8List? _cachedCoverImage;
  bool _isLoadingCover = false;

  @override
  void initState() {
    super.initState();
    _initFields = widget.characterData['init_fields'] as Map<String, dynamic>?;
    if (_initFields != null) {
      _fieldsList = _initFields!.entries.toList();

      // 预处理随机字段并筛选出需要交互的字段
      for (var field in _fieldsList) {
        if (field.value['type'] == 'random') {
          // 处理随机选择
          final List<String> options =
              List<String>.from(field.value['options'] ?? []);
          final selectedOption =
              options[DateTime.now().microsecond % options.length];
          _initFieldValues[field.key] = selectedOption;
        } else {
          // 收集需要用户交互的字段
          _interactiveFields.add(field);
          if (field.value['type'] == 'user_input') {
            _controllers[field.key] = TextEditingController();
            _focusNodes[field.key] = FocusNode();
          }
        }
      }
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _loadCoverImage();

    // 如果没有待初始化字段，直接自动初始化
    if (_initFields == null || _interactiveFields.isEmpty) {
      // 使用微任务确保在构建完成后执行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _createSession();
      });
    }
  }

  // 开始轮播提示语
  void _startTipRotation() {
    // 如果已经有计时器，先取消
    _tipTimer?.cancel();

    // 创建新计时器，每3秒切换一次提示语
    _tipTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _isLoading) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _loadingTips.length;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadCoverImage() async {
    if (widget.characterData['cover_uri'] == null ||
        _isLoadingCover ||
        _cachedCoverImage != null) {
      return;
    }

    _isLoadingCover = true;
    try {
      final result =
          await _fileService.getFile(widget.characterData['cover_uri']);
      if (mounted) {
        setState(() {
          _cachedCoverImage = result.data;
          _isLoadingCover = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCover = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _tipTimer?.cancel();
    // 释放所有控制器和焦点节点
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _createSession() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _currentTipIndex = 0;
    });

    // 开始轮播提示语
    _startTipRotation();

    try {
      final result = await _characterService.createCharacterSession(
        widget.characterData['item_id'] as int,
        _initFields == null || _interactiveFields.isEmpty
            ? {}
            : _initFieldValues,
      );

      if (mounted) {
        // 预加载背景图
        final sessionData = result['data'] as Map<String, dynamic>;
        if (sessionData['background_uri'] != null) {
          try {
            await _fileService.getFile(sessionData['background_uri']);
          } catch (e) {
            // 背景图加载失败不阻止页面跳转
            debugPrint('背景图加载失败: $e');
          }
        }

        // 跳转到聊天页面
        if (result['code'] == 0) {
          _tipTimer?.cancel();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CharacterChatPage(
                sessionData: sessionData,
                characterData: sessionData, // 直接使用服务端返回的完整会话数据
              ),
            ),
          );
        } else {
          throw result['msg'] ?? '创建会话失败';
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
        _tipTimer?.cancel();
      }
    }
  }

  Widget _buildInitFieldPage(MapEntry<String, dynamic> field) {
    final String fieldKey = field.key;
    final dynamic fieldValue = field.value;

    if (fieldValue['type'] == 'choice') {
      return _buildChoiceField(fieldKey, fieldValue);
    } else {
      return _buildInputField(fieldKey, fieldValue);
    }
  }

  Widget _buildChoiceField(String key, Map<String, dynamic> field) {
    final List<String> options = List<String>.from(field['options'] ?? []);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '请选择$key',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 32.h),
            ...options.map((option) => Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _initFieldValues[key] = option;
                              _nextPage();
                            },
                            splashColor: Colors.white.withOpacity(0.1),
                            highlightColor: Colors.white.withOpacity(0.2),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 20.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                              ),
                              child: Center(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String key, Map<String, dynamic> field) {
    final controller = _controllers[key] ?? TextEditingController();
    final focusNode = _focusNodes[key] ?? FocusNode();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '请输入$key',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 32.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                    decoration: InputDecoration(
                      hintText: '请输入$key',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      filled: false,
                      contentPadding: EdgeInsets.all(20.w),
                    ),
                    maxLines: null,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _initFieldValues[key] = value.trim();
                        _nextPage();
                      }
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 32.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (controller.text.trim().isNotEmpty) {
                        _initFieldValues[key] = controller.text.trim();
                        _nextPage();
                      }
                    },
                    splashColor: Colors.white.withOpacity(0.1),
                    highlightColor: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 16.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '确认并继续',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48.w,
                      color: Colors.amber[300],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      '初始化失败',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[300],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.amber[200],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.6),
                              width: 1.5,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            '返回',
                            style: TextStyle(
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        ElevatedButton(
                          onPressed: _createSession,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            backgroundColor: Colors.white.withOpacity(0.3),
                          ),
                          child: Text(
                            '重试',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingTips() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Shimmer.fromColors(
        key: ValueKey<int>(_currentTipIndex),
        baseColor: Colors.white,
        highlightColor: Colors.white.withOpacity(0.5),
        child: Text(
          _loadingTips[_currentTipIndex],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    _animationController.reset();
    if (_currentPage < _interactiveFields.length - 1) {
      _pageController
          .nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        final nextField = _interactiveFields[_currentPage + 1];
        if (nextField.value['type'] == 'user_input') {
          _focusNodes[nextField.key]?.requestFocus();
        }
      });
      setState(() => _currentPage++);
      _animationController.forward();
    } else {
      _createSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // 背景图片
          if (_cachedCoverImage != null)
            Positioned.fill(
              child: Image.memory(
                _cachedCoverImage!,
                fit: BoxFit.cover,
              ),
            ),
          // 背景渐变遮罩
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
          // 内容
          if (_hasError)
            _buildErrorView()
          else if (_initFields == null || _interactiveFields.isEmpty)
            Container() // 不显示任何内容，因为会显示加载指示器
          else
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _interactiveFields.length,
              itemBuilder: (context, index) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24.w,
                    right: 24.w,
                    top: MediaQuery.of(context).padding.top + 120.h,
                    bottom: 16.h,
                  ),
                  child: _buildInitFieldPage(_interactiveFields[index]),
                );
              },
            ),
          if (_isLoading && !_hasError)
            Center(
              child: _buildLoadingTips(),
            ),
        ],
      ),
    );
  }
}
