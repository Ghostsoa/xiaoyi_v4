import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/character_service.dart';
import '../../../services/file_service.dart';
import 'dart:typed_data';
import '../pages/character_chat_page.dart';
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
  Map<String, dynamic>? _initFields;
  List<MapEntry<String, dynamic>> _fieldsList = [];
  final List<MapEntry<String, dynamic>> _interactiveFields = [];

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

    setState(() => _isLoading = true);
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
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CharacterChatPage(
                sessionData: sessionData,
                characterData: widget.characterData,
              ),
            ),
          );
        } else {
          throw result['msg'] ?? '创建会话失败';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
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
            SizedBox(height: 8.h),
            Text(
              '选择一个最适合的选项',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 32.h),
            ...options.map((option) => Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        _initFieldValues[key] = option;
                        _nextPage();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 20.h,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Container(
                        decoration: AppTheme.buttonDecoration,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 20.h,
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
            SizedBox(height: 8.h),
            Text(
              '让角色更有个性',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 32.h),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                style: TextStyle(
                  color: Colors.white,
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
                  filled: true,
                  fillColor: AppTheme.cardBackground,
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
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  _initFieldValues[key] = controller.text.trim();
                  _nextPage();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 32.w,
                  vertical: 16.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Container(
                decoration: AppTheme.buttonDecoration,
                padding: EdgeInsets.symmetric(
                  horizontal: 32.w,
                  vertical: 16.h,
                ),
                child: Center(
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
          ],
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
          if (_initFields == null || _interactiveFields.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '准备好开始了吗？',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 32.h),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _createSession,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 20.h,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Container(
                          decoration: AppTheme.buttonDecoration,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 20.h,
                          ),
                          child: Center(
                            child: Text(
                              '开始对话',
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
                  ],
                ),
              ),
            )
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
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      SizedBox(height: 16.h),
                      Text(
                        '正在初始化对话...',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
