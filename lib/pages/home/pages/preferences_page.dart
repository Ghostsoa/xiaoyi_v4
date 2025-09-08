import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_theme.dart';
import '../services/home_service.dart';
import '../../../widgets/custom_toast.dart';

class PreferenceModel {
  List<String> likedTags;
  List<String> dislikedTags;
  List<String> likedAuthors;
  List<String> dislikedAuthors;
  List<String> likedKeywords;
  List<String> dislikedKeywords;
  int preferenceStrength;
  int applyToHall;
  List<String> preferredCategories;

  PreferenceModel({
    this.likedTags = const [],
    this.dislikedTags = const [],
    this.likedAuthors = const [],
    this.dislikedAuthors = const [],
    this.likedKeywords = const [],
    this.dislikedKeywords = const [],
    this.preferenceStrength = 1,
    this.applyToHall = 1,
    this.preferredCategories = const ['all'],
  });

  factory PreferenceModel.fromJson(Map<String, dynamic> json) {
    // 处理 preferred_category 字段，支持字符串和数组两种格式
    List<String> categories = ['all'];
    if (json['preferred_category'] != null) {
      if (json['preferred_category'] is List) {
        categories = List<String>.from(json['preferred_category']);
      } else if (json['preferred_category'] is String) {
        categories = [json['preferred_category']];
      }
    }

    return PreferenceModel(
      likedTags: List<String>.from(json['liked_tags'] ?? []),
      dislikedTags: List<String>.from(json['disliked_tags'] ?? []),
      likedAuthors: List<String>.from(json['liked_authors'] ?? []),
      dislikedAuthors: List<String>.from(json['disliked_authors'] ?? []),
      likedKeywords: List<String>.from(json['liked_keywords'] ?? []),
      dislikedKeywords: List<String>.from(json['disliked_keywords'] ?? []),
      preferenceStrength: json['preference_strength'] ?? 1,
      applyToHall: json['apply_to_hall'] ?? 1,
      preferredCategories: categories,
    );
  }
}

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final HomeService _homeService = HomeService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  PreferenceModel _preferences = PreferenceModel();
  PreferenceModel _originalPreferences = PreferenceModel();

  // 标签相关控制器
  final TextEditingController _likedTagController = TextEditingController();
  final TextEditingController _dislikedTagController = TextEditingController();

  // 作者相关控制器
  final TextEditingController _likedAuthorController = TextEditingController();
  final TextEditingController _dislikedAuthorController =
      TextEditingController();

  // 作者搜索结果
  List<String> _authorSearchResults = [];
  bool _isSearchingAuthors = false;
  Timer? _authorSearchDebounce;

  // 关键词相关控制器
  final TextEditingController _likedKeywordController = TextEditingController();
  final TextEditingController _dislikedKeywordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();

    // 添加作者搜索监听
    _likedAuthorController.addListener(_onLikedAuthorChanged);
    _dislikedAuthorController.addListener(_onDislikedAuthorChanged);
  }

  @override
  void dispose() {
    _likedTagController.dispose();
    _dislikedTagController.dispose();

    _likedAuthorController.removeListener(_onLikedAuthorChanged);
    _dislikedAuthorController.removeListener(_onDislikedAuthorChanged);
    _authorSearchDebounce?.cancel();
    _likedAuthorController.dispose();
    _dislikedAuthorController.dispose();

    _likedKeywordController.dispose();
    _dislikedKeywordController.dispose();
    super.dispose();
  }

  void _onLikedAuthorChanged() {
    _debounceAuthorSearch(_likedAuthorController.text, isLiked: true);
  }

  void _onDislikedAuthorChanged() {
    _debounceAuthorSearch(_dislikedAuthorController.text, isLiked: false);
  }

  void _debounceAuthorSearch(String keyword, {required bool isLiked}) {
    if (_authorSearchDebounce?.isActive ?? false) {
      _authorSearchDebounce!.cancel();
    }
    _authorSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (keyword.isNotEmpty) {
        _searchAuthors(keyword);
      } else {
        setState(() {
          _authorSearchResults = [];
          _isSearchingAuthors = false;
        });
      }
    });
  }

  Future<void> _searchAuthors(String keyword) async {
    if (keyword.isEmpty) return;

    setState(() {
      _isSearchingAuthors = true;
    });

    try {
      final result = await _homeService.searchUsernames(keyword);
      if (mounted) {
        if (result['code'] == 0 && result['data'] != null) {
          setState(() {
            _authorSearchResults = List<String>.from(result['data']);
            _isSearchingAuthors = false;
          });
        } else {
          setState(() {
            _authorSearchResults = [];
            _isSearchingAuthors = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _authorSearchResults = [];
          _isSearchingAuthors = false;
        });
      }
    }
  }

  void _selectAuthorFromSearch(String author, {bool isLiked = true}) {
    if (author.isEmpty) return;

    setState(() {
      _authorSearchResults = [];
      if (isLiked) {
        _likedAuthorController.text = author;
      } else {
        _dislikedAuthorController.text = author;
      }
    });
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final result = await _homeService.getUserPreferences();
      if (mounted) {
        if (result['code'] == 0 && result['data'] != null) {
          // 成功
          setState(() {
            _preferences = PreferenceModel.fromJson(result['data']);
            _originalPreferences = PreferenceModel.fromJson(result['data']);
            _isLoading = false;
          });
        } else {
          // 加载失败
          setState(() => _isLoading = false);

          CustomToast.show(
            context,
            message: result['msg'] ?? '加载偏好设置失败',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '加载偏好设置失败，请稍后再试',
          type: ToastType.error,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePreferences() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final result = await _homeService.updateUserPreferences(
        likedTags: _preferences.likedTags,
        dislikedTags: _preferences.dislikedTags,
        likedAuthors: _preferences.likedAuthors,
        dislikedAuthors: _preferences.dislikedAuthors,
        likedKeywords: _preferences.likedKeywords,
        dislikedKeywords: _preferences.dislikedKeywords,
        preferenceStrength: _preferences.preferenceStrength,
        applyToHall: _preferences.applyToHall,
        preferredCategories: _preferences.preferredCategories,
      );

      if (mounted) {
        if (result['code'] == 0) {
          // 成功
          setState(() {
            if (result['data'] != null) {
              _preferences = PreferenceModel.fromJson(result['data']);
              _originalPreferences = PreferenceModel.fromJson(result['data']);
            }
            _isSaving = false;
            _isEditing = false;
          });

          CustomToast.show(
            context,
            message: result['msg'] ?? '保存成功',
            type: ToastType.success,
          );
        } else {
          // 失败
          setState(() => _isSaving = false);

          CustomToast.show(
            context,
            message: result['msg'] ?? '保存失败',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '保存失败，请稍后再试',
          type: ToastType.error,
        );
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _resetPreferences() async {
    if (_isSaving) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('确认重置', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('确定要重置所有偏好设置吗？此操作不可撤销。',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      final result = await _homeService.resetUserPreferences();

      if (mounted) {
        if (result['code'] == 0) {
          // 成功
          setState(() {
            if (result['data'] != null) {
              _preferences = PreferenceModel.fromJson(result['data']);
              _originalPreferences = PreferenceModel.fromJson(result['data']);
            }
            _isSaving = false;
            _isEditing = false;
          });

          CustomToast.show(
            context,
            message: result['msg'] ?? '重置成功',
            type: ToastType.success,
          );
        } else {
          // 失败
          setState(() => _isSaving = false);

          CustomToast.show(
            context,
            message: result['msg'] ?? '重置失败',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '重置失败，请稍后再试',
          type: ToastType.error,
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _addTag(String tag, {bool isLiked = true}) {
    if (tag.trim().isEmpty) return;

    setState(() {
      _isEditing = true;
      if (isLiked) {
        if (!_preferences.likedTags.contains(tag)) {
          _preferences.likedTags.add(tag);
          // 从不喜欢的标签中移除
          _preferences.dislikedTags.remove(tag);
        }
        _likedTagController.clear();
      } else {
        if (!_preferences.dislikedTags.contains(tag)) {
          _preferences.dislikedTags.add(tag);
          // 从喜欢的标签中移除
          _preferences.likedTags.remove(tag);
        }
        _dislikedTagController.clear();
      }
    });
  }

  void _addAuthor(String author, {bool isLiked = true}) {
    if (author.trim().isEmpty) return;

    setState(() {
      _isEditing = true;
      if (isLiked) {
        if (!_preferences.likedAuthors.contains(author)) {
          _preferences.likedAuthors.add(author);
          // 从不喜欢的作者中移除
          _preferences.dislikedAuthors.remove(author);
        }
        _likedAuthorController.clear();
      } else {
        if (!_preferences.dislikedAuthors.contains(author)) {
          _preferences.dislikedAuthors.add(author);
          // 从喜欢的作者中移除
          _preferences.likedAuthors.remove(author);
        }
        _dislikedAuthorController.clear();
      }
    });
  }

  void _addKeyword(String keyword, {bool isLiked = true}) {
    if (keyword.trim().isEmpty) return;

    setState(() {
      _isEditing = true;
      if (isLiked) {
        if (!_preferences.likedKeywords.contains(keyword)) {
          _preferences.likedKeywords.add(keyword);
          // 从不喜欢的关键词中移除
          _preferences.dislikedKeywords.remove(keyword);
        }
        _likedKeywordController.clear();
      } else {
        if (!_preferences.dislikedKeywords.contains(keyword)) {
          _preferences.dislikedKeywords.add(keyword);
          // 从喜欢的关键词中移除
          _preferences.likedKeywords.remove(keyword);
        }
        _dislikedKeywordController.clear();
      }
    });
  }

  void _removeTag(String tag, {bool isLiked = true}) {
    setState(() {
      _isEditing = true;
      if (isLiked) {
        _preferences.likedTags.remove(tag);
      } else {
        _preferences.dislikedTags.remove(tag);
      }
    });
  }

  void _removeAuthor(String author, {bool isLiked = true}) {
    setState(() {
      _isEditing = true;
      if (isLiked) {
        _preferences.likedAuthors.remove(author);
      } else {
        _preferences.dislikedAuthors.remove(author);
      }
    });
  }

  void _removeKeyword(String keyword, {bool isLiked = true}) {
    setState(() {
      _isEditing = true;
      if (isLiked) {
        _preferences.likedKeywords.remove(keyword);
      } else {
        _preferences.dislikedKeywords.remove(keyword);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? _buildLoadingShimmer()
          : Stack(
              children: [
                // 主内容
                CustomScrollView(
                  physics: BouncingScrollPhysics(),
                  slivers: [
                    // 返回按钮和标题
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 50.h, 16.w, 16.h),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: AppTheme.isLightTheme
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: AppTheme.textPrimary,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Text(
                              '偏好设置',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                      ),
                    ),

                    // 分区偏好设置
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Card(
                          color: AppTheme.cardBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 0,
                          margin: EdgeInsets.only(bottom: 16.h),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '分区偏好',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: AppTheme.primaryColor,
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          '更改后，刷新大厅生效。偏好设置不会影响热门排行榜。',
                                          style: TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  '选择您偏好的内容分区',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                _buildCategoryButtons(),
                                SizedBox(height: 12.h),
                                _buildCategoryDescriptions(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 设置是否应用于大厅
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Card(
                          color: AppTheme.cardBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 0,
                          margin: EdgeInsets.only(bottom: 16.h),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '应用设置',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '将偏好设置应用于大厅列表',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 16.sp,
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: _preferences.applyToHall == 1,
                                      onChanged: (value) {
                                        setState(() {
                                          _isEditing = true;
                                          _preferences.applyToHall =
                                              value ? 1 : 2;
                                        });
                                      },
                                      activeColor: AppTheme.primaryColor,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  '说明：开启后，系统将根据您的"不喜欢"设置过滤大厅内容。注意：偏好设置会应用于推荐算法，但不会影响榜单。',
                                  style: TextStyle(
                                    color:
                                        AppTheme.textSecondary.withValues(alpha: 0.7),
                                    fontSize: 12.sp,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  '偏好强度',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: _preferences.preferenceStrength
                                            .toDouble().clamp(1.0, 3.0),
                                        min: 1.0,
                                        max: 3.0,
                                        divisions: 2,
                                        activeColor: AppTheme.primaryColor,
                                        inactiveColor: AppTheme.primaryColor
                                            .withValues(alpha: 0.3),
                                        label: _getPreferenceStrengthLabel(
                                            _preferences.preferenceStrength),
                                        onChanged: (value) {
                                          setState(() {
                                            _isEditing = true;
                                            _preferences.preferenceStrength =
                                                value.toInt();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '弱',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    Text(
                                      '中',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    Text(
                                      '强',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  '偏好强度说明：\n· 在推荐算法中，弱、中、强三个强度级别分别对应不同的过滤力度\n· 在大厅列表中，弱和中的效果相同（降低优先级），强则完全排除不喜欢的内容',
                                  style: TextStyle(
                                    color:
                                        AppTheme.textSecondary.withValues(alpha: 0.7),
                                    fontSize: 12.sp,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 标签偏好
                    _buildPreferenceSection(
                      title: '标签偏好',
                      likedItems: _preferences.likedTags,
                      dislikedItems: _preferences.dislikedTags,
                      likedController: _likedTagController,
                      dislikedController: _dislikedTagController,
                      addItem: _addTag,
                      removeItem: _removeTag,
                      likedHint: '添加喜欢的标签',
                      dislikedHint: '添加不喜欢的标签',
                      emptyLikedText: '尚未添加喜欢的标签',
                      emptyDislikedText: '尚未添加不喜欢的标签',
                    ),

                    // 作者偏好
                    _buildPreferenceSection(
                      title: '作者偏好',
                      likedItems: _preferences.likedAuthors,
                      dislikedItems: _preferences.dislikedAuthors,
                      likedController: _likedAuthorController,
                      dislikedController: _dislikedAuthorController,
                      addItem: _addAuthor,
                      removeItem: _removeAuthor,
                      likedHint: '添加喜欢的作者',
                      dislikedHint: '添加不喜欢的作者',
                      emptyLikedText: '尚未添加喜欢的作者',
                      emptyDislikedText: '尚未添加不喜欢的作者',
                    ),

                    // 关键词偏好
                    _buildPreferenceSection(
                      title: '关键词偏好',
                      likedItems: _preferences.likedKeywords,
                      dislikedItems: _preferences.dislikedKeywords,
                      likedController: _likedKeywordController,
                      dislikedController: _dislikedKeywordController,
                      addItem: _addKeyword,
                      removeItem: _removeKeyword,
                      likedHint: '添加喜欢的关键词',
                      dislikedHint: '添加不喜欢的关键词',
                      emptyLikedText: '尚未添加喜欢的关键词',
                      emptyDislikedText: '尚未添加不喜欢的关键词',
                    ),

                    // 重置按钮
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: OutlinedButton(
                          onPressed: _resetPreferences,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            '重置所有偏好设置',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 底部间距
                    SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                  ],
                ),

                // 返回确认提示
                if (_isEditing)
                  WillPopScope(
                    onWillPop: () async {
                      final bool? result = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.cardBackground,
                          title: Text('未保存的更改',
                              style: TextStyle(color: AppTheme.textPrimary)),
                          content: Text('您有未保存的更改，确定要放弃吗？',
                              style: TextStyle(color: AppTheme.textSecondary)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('放弃',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      return result ?? false;
                    },
                    child: Container(),
                  ),

                // 添加底部固定的保存按钮
                if (_isEditing)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppTheme.background.withOpacity(0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _savePreferences,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 24.w,
                                height: 24.w,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                '保存更新',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildLoadingShimmer() {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        // 返回按钮和标题
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 50.h, 16.w, 16.h),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Shimmer.fromColors(
                  baseColor: AppTheme.textPrimary,
                  highlightColor: AppTheme.textSecondary,
                  child: Text(
                    '正在加载偏好设置...',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 加载提示文本
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: Shimmer.fromColors(
                baseColor: AppTheme.textPrimary,
                highlightColor: AppTheme.textSecondary,
                child: Text(
                  '加载中，请稍候...',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18.sp,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchShimmer() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Shimmer.fromColors(
        baseColor: AppTheme.textPrimary,
        highlightColor: AppTheme.textSecondary,
        child: Text(
          '搜索中...',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  String _getPreferenceStrengthLabel(int value) {
    switch (value) {
      case 1:
        return '弱';
      case 2:
        return '中';
      case 3:
        return '强';
      default:
        return '中';
    }
  }

  Widget _buildCategoryButtons() {
    final categories = [
      {
        'value': 'all',
        'label': '所有',
        'icon': Icons.apps_rounded,
        'gradient': [Color(0xFF667eea), Color(0xFF764ba2)],
        'description': '全部内容'
      },
      {
        'value': 'general',
        'label': '全性向',
        'icon': Icons.diversity_3_rounded,
        'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)],
        'description': '通用内容'
      },
      {
        'value': 'female',
        'label': '女性向',
        'icon': Icons.female_rounded,
        'gradient': [Color(0xFFf093fb), Color(0xFFf5576c)],
        'description': '女性用户'
      },
      {
        'value': 'male',
        'label': '男性向',
        'icon': Icons.male_rounded,
        'gradient': [Color(0xFF4facfe), Color(0xFF00f2fe)],
        'description': '男性用户'
      },
    ];

    return Column(
      children: [
        // 所有分区选项 - 每个都占一行
        ...categories.map((category) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildCompactCategoryCard(category),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCompactCategoryCard(Map<String, dynamic> category) {
    final isSelected = _preferences.preferredCategories.contains(category['value']);
    final categoryValue = category['value'];

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isEditing = true;

            if (categoryValue == 'all') {
              // 选择"全部"，清空其他选择
              _preferences.preferredCategories = ['all'];
            } else {
              // 选择其他分区
              List<String> newCategories = List.from(_preferences.preferredCategories);

              // 移除"全部"选项
              newCategories.remove('all');

              if (isSelected) {
                // 如果已选中，则取消选择
                newCategories.remove(categoryValue);
                // 如果没有任何选择，默认选择"全部"
                if (newCategories.isEmpty) {
                  newCategories = ['all'];
                }
              } else {
                // 如果未选中，则添加选择
                newCategories.add(categoryValue);
              }

              _preferences.preferredCategories = newCategories;
            }
          });
        },
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: category['gradient'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.3)
                  : AppTheme.textSecondary.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: category['gradient'][0].withValues(alpha: 0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isSelected ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  category['icon'],
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      category['description'],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppTheme.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.textSecondary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isSelected ? Icons.check_rounded : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  size: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildCategoryDescriptions() {
    final descriptions = {
      'all': '显示所有分区的内容',
      'general': '不区分性别，例如模拟器的卡',
      'female': '面向女性用户的内容',
      'male': '面向男性用户的内容',
    };

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.isLightTheme
            ? Colors.grey.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '分区说明：',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          ...descriptions.entries.map((entry) {
            final categoryLabels = {
              'all': '所有',
              'general': '全性向',
              'female': '女性向',
              'male': '男性向',
            };

            return Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ${categoryLabels[entry.key]}：',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPreferenceSection({
    required String title,
    required List<String> likedItems,
    required List<String> dislikedItems,
    required TextEditingController likedController,
    required TextEditingController dislikedController,
    required void Function(String, {bool isLiked}) addItem,
    required void Function(String, {bool isLiked}) removeItem,
    required String likedHint,
    required String dislikedHint,
    required String emptyLikedText,
    required String emptyDislikedText,
  }) {
    final bool isAuthorSection = title == '作者偏好';

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Card(
          color: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
          margin: EdgeInsets.only(bottom: 16.h),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),

                // 喜欢的项目
                Row(
                  children: [
                    Icon(Icons.thumb_up, color: Colors.green, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(
                      '喜欢',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: likedController,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: likedHint,
                    hintStyle: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: AppTheme.isLightTheme
                        ? Colors.grey.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add, color: AppTheme.primaryColor),
                      onPressed: () =>
                          addItem(likedController.text, isLiked: true),
                    ),
                  ),
                  onSubmitted: (value) => addItem(value, isLiked: true),
                ),
                // 作者搜索结果显示 - 喜欢部分
                if (isAuthorSection &&
                    _authorSearchResults.isNotEmpty &&
                    likedController.text.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 4.h),
                    decoration: BoxDecoration(
                      color: AppTheme.isLightTheme
                          ? Colors.grey.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      children: _authorSearchResults
                          .map((author) => ListTile(
                                dense: true,
                                title: Text(
                                  author,
                                  style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14.sp),
                                ),
                                onTap: () {
                                  _selectAuthorFromSearch(author,
                                      isLiked: true);
                                  addItem(author, isLiked: true);
                                },
                              ))
                          .toList(),
                    ),
                  ),
                if (isAuthorSection &&
                    _isSearchingAuthors &&
                    likedController.text.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: _buildSearchShimmer(),
                  ),
                SizedBox(height: 8.h),
                likedItems.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Text(
                          emptyLikedText,
                          style: TextStyle(
                            color: AppTheme.textSecondary.withValues(alpha: 0.7),
                            fontSize: 14.sp,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: likedItems
                            .map((item) => _buildChip(
                                  item,
                                  Colors.green,
                                  onDeleted: () =>
                                      removeItem(item, isLiked: true),
                                ))
                            .toList(),
                      ),
                SizedBox(height: 8.h),
                Text(
                  '注意：喜欢的内容仅用于推荐，不会影响过滤。',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                    fontSize: 12.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 24.h),

                // 不喜欢的项目
                Row(
                  children: [
                    Icon(Icons.thumb_down, color: Colors.red, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(
                      '不喜欢',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: dislikedController,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: dislikedHint,
                    hintStyle: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: AppTheme.isLightTheme
                        ? Colors.grey.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add, color: AppTheme.primaryColor),
                      onPressed: () =>
                          addItem(dislikedController.text, isLiked: false),
                    ),
                  ),
                  onSubmitted: (value) => addItem(value, isLiked: false),
                ),
                // 作者搜索结果显示 - 不喜欢部分
                if (isAuthorSection &&
                    _authorSearchResults.isNotEmpty &&
                    dislikedController.text.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 4.h),
                    decoration: BoxDecoration(
                      color: AppTheme.isLightTheme
                          ? Colors.grey.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      children: _authorSearchResults
                          .map((author) => ListTile(
                                dense: true,
                                title: Text(
                                  author,
                                  style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14.sp),
                                ),
                                onTap: () {
                                  _selectAuthorFromSearch(author,
                                      isLiked: false);
                                  addItem(author, isLiked: false);
                                },
                              ))
                          .toList(),
                    ),
                  ),
                if (isAuthorSection &&
                    _isSearchingAuthors &&
                    dislikedController.text.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: _buildSearchShimmer(),
                  ),
                SizedBox(height: 8.h),
                dislikedItems.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Text(
                          emptyDislikedText,
                          style: TextStyle(
                            color: AppTheme.textSecondary.withValues(alpha: 0.7),
                            fontSize: 14.sp,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: dislikedItems
                            .map((item) => _buildChip(
                                  item,
                                  Colors.red,
                                  onDeleted: () =>
                                      removeItem(item, isLiked: false),
                                ))
                            .toList(),
                      ),
                SizedBox(height: 8.h),
                Text(
                  '注意：不喜欢的内容将根据偏好强度进行过滤。',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                    fontSize: 12.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color,
      {required VoidCallback onDeleted}) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.7),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      deleteIcon: Icon(Icons.close, size: 16.sp, color: Colors.white),
      onDeleted: onDeleted,
    );
  }
}
