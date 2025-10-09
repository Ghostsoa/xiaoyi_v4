import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../services/group_chat_session_service.dart';
import '../../../widgets/expandable_text_field.dart';
import '../../../widgets/text_editor_page.dart';
import '../../../widgets/custom_toast.dart';
import '../../../services/file_service.dart';
import '../../create/character/select_model_page.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';

class GroupChatPanelPage extends StatefulWidget {
  final Map<String, dynamic> groupChatData;

  const GroupChatPanelPage({
    super.key,
    required this.groupChatData,
  });

  @override
  State<GroupChatPanelPage> createState() => _GroupChatPanelPageState();
}

class _GroupChatPanelPageState extends State<GroupChatPanelPage> {
  final GroupChatSessionService _groupChatService = GroupChatSessionService();
  final FileService _fileService = FileService();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSyncing = false;
  String? _error;
  int _currentPageIndex = 0;
  int _selectedRoleIndex = 0;
  Map<String, dynamic> _sessionData = {};
  final Map<String, dynamic> _editedData = {};
  final Map<String, Uint8List> _avatarCache = {};
  
  // 群聊设置字段的控制器
  final _masterSettingController = TextEditingController();
  final _sharedContextController = TextEditingController();
  final _userRoleSettingController = TextEditingController();
  final _greetingController = TextEditingController();
  final _prefixController = TextEditingController();
  final _suffixController = TextEditingController();
  
  // 控制器模型的自定义模式
  bool _isCustomMasterModelMode = false;
  final _customMasterModelController = TextEditingController();
  
  // 群聊设置字段的非文本值
  int _memoryRounds = 10;
  String _unifiedModel = 'disabled';
  String _visibility = 'public';
  String _prefixSuffixEditable = 'private';
  int _maxRoleControlCount = 1;
  
  // 角色设定控制器
  final Map<int, TextEditingController> _roleSettingControllers = {};
  
  // 角色模型的自定义模式
  final Map<int, bool> _isCustomRoleModelMode = {};
  final Map<int, TextEditingController> _customRoleModelControllers = {};

  final List<String> _pageNames = [
    '基本信息',
    '群聊设置',
    '角色管理',
  ];

  final List<IconData> _pageIcons = [
    Icons.info_outline,
    Icons.chat_outlined,
    Icons.group_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _loadGroupChatData();
  }

  @override
  void dispose() {
    _masterSettingController.dispose();
    _customMasterModelController.dispose();
    _sharedContextController.dispose();
    _userRoleSettingController.dispose();
    _greetingController.dispose();
    _prefixController.dispose();
    _suffixController.dispose();
    
    // 释放角色设定控制器
    for (final controller in _roleSettingControllers.values) {
      controller.dispose();
    }
    _roleSettingControllers.clear();
    
    // 释放角色模型控制器
    for (final controller in _customRoleModelControllers.values) {
      controller.dispose();
    }
    _customRoleModelControllers.clear();
    
    super.dispose();
  }

  Future<void> _loadGroupChatData() async {
    try {
      final sessionId = widget.groupChatData['id'] as int;
      final result = await _groupChatService.getGroupChatSessionDetail(sessionId);
      
      if (result['success'] == true) {
        setState(() {
          _sessionData = result['data'] ?? {};
          _isLoading = false;
        });
        _initializeControllers();
        _preloadAvatars();
      } else {
        setState(() {
          _error = result['msg'] ?? '加载群聊数据失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '加载群聊数据失败: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeControllers() {
    // 调试：检查会话数据的关键字段
    debugPrint('会话数据 - memory_rounds: ${_sessionData['memory_rounds']}, unified_model: ${_sessionData['unified_model']}, visibility: ${_sessionData['visibility']}, prefix: ${_sessionData['prefix']}, suffix: ${_sessionData['suffix']}');
    
    _masterSettingController.text = _sessionData['master_setting'] ?? '';
    _sharedContextController.text = _sessionData['shared_context'] ?? '';
    _userRoleSettingController.text = _sessionData['user_role_setting'] ?? '';
    _greetingController.text = _sessionData['greeting'] ?? '';
    _prefixController.text = _sessionData['prefix'] ?? '';
    _suffixController.text = _sessionData['suffix'] ?? '';
    _memoryRounds = _sessionData['memory_rounds'] ?? 10;
    _unifiedModel = _sessionData['unified_model'] ?? 'disabled';
    _visibility = _sessionData['visibility'] ?? 'public';
    _prefixSuffixEditable = _sessionData['prefix_suffix_editable'] ?? 'private';
    _maxRoleControlCount = _sessionData['max_role_control_count'] ?? 1;
    
    // 初始化角色设定控制器
    final roles = _sessionData['roles'] as List<dynamic>? ?? [];
    for (int i = 0; i < roles.length; i++) {
      final role = roles[i] as Map<String, dynamic>;
      _roleSettingControllers[i] = TextEditingController(text: role['setting'] ?? '');
      _roleSettingControllers[i]!.addListener(() {
        _updateRoleSetting(i, _roleSettingControllers[i]!.text);
      });
    }
    
    // 添加监听器
    _masterSettingController.addListener(() {
      _editedData['master_setting'] = _masterSettingController.text;
    });
    _sharedContextController.addListener(() {
      _editedData['shared_context'] = _sharedContextController.text;
    });
    _userRoleSettingController.addListener(() {
      _editedData['user_role_setting'] = _userRoleSettingController.text;
    });
    _greetingController.addListener(() {
      _editedData['greeting'] = _greetingController.text;
    });
    _prefixController.addListener(() {
      _editedData['prefix'] = _prefixController.text;
    });
    _suffixController.addListener(() {
      _editedData['suffix'] = _suffixController.text;
    });
  }

  void _updateRoleSetting(int roleIndex, String setting) {
    if (!_editedData.containsKey('roles')) {
      _editedData['roles'] = List<Map<String, dynamic>>.from(_sessionData['roles'] ?? []);
    }
    final roles = _editedData['roles'] as List<Map<String, dynamic>>;
    if (roleIndex < roles.length) {
      roles[roleIndex] = Map<String, dynamic>.from(roles[roleIndex]);
      roles[roleIndex]['setting'] = setting;
    }
  }

  /// 保存所有更改
  Future<void> _saveChanges() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final sessionId = widget.groupChatData['id'] as int;
      
      // 构建全量更新数据
      final updateData = {
        'name': _sessionData['name'],
        'description': _sessionData['description'],
        'tags': _sessionData['tags'] ?? [],
        'greeting': _greetingController.text,
        'master_model': _editedData.containsKey('master_model') 
            ? _editedData['master_model']
            : (_isCustomMasterModelMode 
                ? _customMasterModelController.text 
                : _sessionData['master_model']),
        'memory_rounds': _memoryRounds,
        'master_setting': _masterSettingController.text,
        'shared_context': _sharedContextController.text,
        'user_role_setting': _userRoleSettingController.text,
        'unified_model': _unifiedModel,
        'visibility': _visibility,
        'prefix_suffix_editable': _prefixSuffixEditable,
        'max_role_control_count': _maxRoleControlCount,
        'prefix': _prefixController.text,
        'suffix': _suffixController.text,
      };

      // 如果有角色修改，添加角色数据
      if (_editedData.containsKey('roles')) {
        updateData['roles'] = _editedData['roles'];
      } else {
        updateData['roles'] = _sessionData['roles'];
      }

      // 如果统一模型开启，强制统一所有角色的模型为第一个角色的模型
      if (_unifiedModel == 'enabled') {
        final roles = updateData['roles'] as List;
        if (roles.isNotEmpty) {
          final firstRoleModel = roles[0]['modelName'] ?? '';
          if (firstRoleModel.isNotEmpty) {
            debugPrint('[统一模型] 保存时强制统一所有角色模型为: $firstRoleModel');
            for (int i = 1; i < roles.length; i++) {
              if (roles[i] is Map<String, dynamic>) {
                final roleMap = Map<String, dynamic>.from(roles[i] as Map<String, dynamic>);
                roleMap['modelName'] = firstRoleModel;
                roles[i] = roleMap;
              }
            }
            updateData['roles'] = roles;
          }
        }
      }

      debugPrint('[GroupChatPanelPage] 准备保存数据: $updateData');

      final result = await _groupChatService.updateSession(sessionId, updateData);

      if (result['success'] == true) {
        // 更新成功，将 _editedData 的内容合并到 _sessionData 中
        setState(() {
          // 如果服务器返回了新数据，使用新数据
          if (result['data'] != null && (result['data'] as Map).isNotEmpty) {
            _sessionData = result['data'] as Map<String, dynamic>;
          } else {
            // 否则将保存的数据合并到 _sessionData
            _sessionData.addAll(updateData);
          }
          _editedData.clear();
        });

        if (mounted) {
          CustomToast.show(
            context,
            message: result['msg'] ?? '保存成功',
            type: ToastType.success,
          );
        }
      } else {
        throw Exception(result['msg'] ?? '保存失败');
      }
    } catch (e) {
      debugPrint('[GroupChatPanelPage] 保存失败: $e');
      if (mounted) {
        CustomToast.show(
          context,
          message: '保存失败: $e',
          type: ToastType.error,
          duration: Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 同步调试设置
  Future<void> _syncDebugSettings() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final sessionId = widget.groupChatData['id'] as int;
      await _groupChatService.syncDebugSettings(sessionId);
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
        message: '同步失败: $e',
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _preloadAvatars() async {
    final roles = _sessionData['roles'] as List<dynamic>? ?? [];
    for (int i = 0; i < roles.length; i++) {
      final role = roles[i] as Map<String, dynamic>;
      final avatarUri = role['avatarUri'];
      if (avatarUri != null && !_avatarCache.containsKey(avatarUri)) {
        try {
          final result = await _fileService.getFile(avatarUri);
          if (mounted) {
            _avatarCache[avatarUri] = result.data as Uint8List;
          }
        } catch (e) {
          debugPrint('头像预加载失败: $e');
        }
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _error != null
            ? _buildErrorView()
            : _isLoading
                ? _buildLoadingText("正在加载群聊信息...")
                : Column(
                    children: [
                      _buildHeader(),
                      SizedBox(height: 16.h),
                      _buildPageSelector(),
                      SizedBox(height: 16.h),
                      Expanded(
                        child: _buildCurrentPage(),
                      ),
                    ],
                  ),
      ),
    );
  }

  // 构建加载中的文本（带 shimmer 效果）
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
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48.sp,
          ),
          SizedBox(height: 16.h),
          Text(
            _error ?? '加载失败',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _isLoading = true;
              });
              _loadGroupChatData();
            },
            child: Text('重试'),
          ),
        ],
      ),
    );
  }


  Widget _buildCurrentPage() {
    switch (_currentPageIndex) {
      case 0:
        return _buildBasicInfoPage();
      case 1:
        return _buildChatSettingsPage();
      case 2:
        return _buildRoleManagementPage();
      default:
        return Container();
    }
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem('群聊名称', _sessionData['name'] ?? '未知', Icons.group),
          if (_sessionData['description'] != null && _sessionData['description'].toString().isNotEmpty)
            _buildInfoItem('群聊描述', _sessionData['description'], Icons.description),
          if (_sessionData['tags'] != null)
            _buildInfoItem(
              '标签',
              (_sessionData['tags'] as List<dynamic>?)
                      ?.map((tag) => '#$tag')
                      .join(' ') ?? '',
              Icons.tag,
            ),
          _buildInfoItem('作者', _sessionData['author_name'] ?? '未知', Icons.person_outline),
          _buildInfoItem('对话轮数', '${_sessionData['total_turns'] ?? 0}', Icons.chat_bubble_outline),
          _buildInfoItem('创建时间', _formatDateTime(_sessionData['created_at']), Icons.access_time),
          _buildInfoItem('更新时间', _formatDateTime(_sessionData['updated_at']), Icons.update),
        ],
      ),
    );
  }

  Widget _buildChatSettingsPage() {
    final bool isEditable = _visibility == 'public';
    final bool isPrefixSuffixEditable = _prefixSuffixEditable == 'public';
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户角色设定 - 始终可编辑
          _buildSettingField(
            '用户角色设定',
            _userRoleSettingController,
            icon: Icons.person,
            accentColor: AppTheme.success,
            description: '用户在群聊中的角色设定和身份背景',
          ),
          
          SizedBox(height: 16.h),
          
          // 控制器设置字段 - 根据可编辑状态判断
          if (!isEditable) ...[
            Text(
              '控制器设定',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            _buildNonEditableNotice(),
          ] else ...[
            _buildSettingField(
              '控制器设定',
              _masterSettingController,
              icon: Icons.psychology,
              accentColor: AppTheme.primaryColor,
              description: '控制整体对话流程和规则的设定',
            ),
            SizedBox(height: 12.h),
            _buildMasterModelSelector(),
            _buildSettingField(
              '共享上下文',
              _sharedContextController,
              icon: Icons.share,
              accentColor: AppTheme.accentPink,
              description: '所有角色共用的背景设定和上下文信息',
            ),
            _buildSettingField(
              '群聊开场白',
              _greetingController,
              icon: Icons.waving_hand,
              accentColor: AppTheme.warning,
              description: '群聊开始时的欢迎词和初始化信息',
            ),
            SizedBox(height: 12.h),
            _buildMemoryRoundsField(),
            // SizedBox(height: 12.h),
            // _buildMaxRoleControlCountField(), // 已隐藏
          ],
          
          SizedBox(height: 16.h),
          
          // 前后缀设定 - 始终显示，单独控制可见性
          Text(
            '前后缀设定',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          if (!isPrefixSuffixEditable) ...[
            _buildPrefixSuffixLockedNotice(),
          ] else ...[
            _buildSettingField(
              '前缀',
              _prefixController,
              icon: Icons.format_quote,
              accentColor: Colors.purple,
              description: '在AI回复前添加的固定内容',
            ),
            _buildSettingField(
              '后缀',
              _suffixController,
              icon: Icons.format_quote_outlined,
              accentColor: Colors.purple,
              description: '在AI回复后添加的固定内容',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleManagementPage() {
    final roles = _sessionData['roles'] as List<dynamic>? ?? [];
    final bool isEditable = _visibility == 'public';
    
    return Column(
      children: [
        // 统一模型开关
        if (isEditable) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: _buildUnifiedModelField(),
          ),
        ],
        
        if (roles.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_add,
                    size: 64.sp,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '暂无角色',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // 角色标签页
          Container(
            height: 50.h,
            decoration: BoxDecoration(
              color: AppTheme.cardBackground.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.textSecondary.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: roles.length,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemBuilder: (context, index) {
                final role = roles[index] as Map<String, dynamic>;
                final isSelected = _selectedRoleIndex == index;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRoleIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 8.w, top: 8.h),
                    child: Column(
                      children: [
                        Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.border.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: _buildRoleAvatar(role['avatarUri'], role['name']),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 角色详情
          Expanded(
            child: _buildRoleDetail(roles[_selectedRoleIndex] as Map<String, dynamic>, _selectedRoleIndex, isEditable),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(left: BorderSide(color: AppTheme.primaryColor, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '未知';
    try {
      return DateTime.parse(dateTimeStr).toLocal().toString().split('.')[0];
    } catch (e) {
      return '未知';
    }
  }

  // 构建不可编辑状态的提示
  Widget _buildNonEditableNotice() {
    final accentColor = AppTheme.primaryLight;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              Icons.lock_outline,
              color: accentColor,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '相关设定不可查看',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建前后缀不可编辑状态的提示
  Widget _buildPrefixSuffixLockedNotice() {
    final accentColor = Colors.purple;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              Icons.lock_outline,
              color: accentColor,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '前后缀设定不可查看',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建设定字段
  Widget _buildSettingField(
    String label,
    TextEditingController controller, {
    required IconData icon,
    required Color accentColor,
    String? description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ExpandableTextField(
        title: label,
        controller: controller,
        hintText: '点击这里编辑$label...',
        selectType: _getSelectType(label),
        previewLines: 4,
        helpIcon: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: 12.sp,
          ),
        ),
        description: description != null ? Text(
          description,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12.sp,
            fontStyle: FontStyle.italic,
          ),
        ) : null,
      ),
    );
  }


  TextSelectType? _getSelectType(String field) {
    switch (field) {
      case '控制器设定':
        return TextSelectType.setting;
      case '用户角色设定':
        return TextSelectType.setting;
      case '共享上下文':
        return TextSelectType.setting;
      default:
        return null;
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 返回按钮
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
            '群聊详情',
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
              // 保存按钮
              _isSaving
                  ? Container(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryColor,
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
      ),
    );
  }

  Widget _buildPageSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SizedBox(
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
      ),
    );
  }

  Widget _buildRoleDetail(Map<String, dynamic> role, int roleIndex, bool isEditable) {
    // 确保角色设定控制器存在
    if (!_roleSettingControllers.containsKey(roleIndex)) {
      _roleSettingControllers[roleIndex] = TextEditingController(text: role['setting'] ?? '');
      _roleSettingControllers[roleIndex]!.addListener(() {
        _updateRoleSetting(roleIndex, _roleSettingControllers[roleIndex]!.text);
      });
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 角色头像和基本信息
          Row(
            children: [
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40.r),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40.r),
                  child: _buildRoleAvatar(role['avatarUri'], role['name'], size: 80.w),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '角色名称',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      role['name'] ?? '未命名角色',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (role['description'] != null && role['description'].toString().isNotEmpty) ...[
                      Text(
                        '角色描述',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        role['description'],
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // 角色模型
          if (isEditable)
            _buildRoleModelSelector(roleIndex, role)
          else
            _buildInfoItem('角色模型', role['modelName'] ?? '未设置', Icons.smart_toy),

          SizedBox(height: 16.h),

          // 角色设定 - 可编辑
          if (isEditable) ...[
            Text(
              '角色设定',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '详细描述角色的性格、背景、说话方式等',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 12.h),
            ExpandableTextField(
              title: '角色设定',
              controller: _roleSettingControllers[roleIndex]!,
              hintText: '详细描述角色的性格、背景、说话方式等...',
              selectType: TextSelectType.setting,
              maxLength: 5000,
              previewLines: 4,
              helpIcon: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Icon(
                  Icons.psychology,
                  color: AppTheme.success,
                  size: 12.sp,
                ),
              ),
            ),
          ] else ...[
            // 不可编辑状态
            Text(
              '角色设定',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            _buildNonEditableNotice(),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleAvatar(String? avatarUri, String? roleName, {double? size}) {
    final double avatarSize = size ?? 32.w;
    
    if (avatarUri != null && _avatarCache.containsKey(avatarUri)) {
      return Image.memory(
        _avatarCache[avatarUri]!,
        width: avatarSize,
        height: avatarSize,
        fit: BoxFit.cover,
      );
    }
    
    if (avatarUri != null) {
      return FutureBuilder<Uint8List?>(
        future: _loadAvatar(avatarUri),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              width: avatarSize,
              height: avatarSize,
              fit: BoxFit.cover,
            );
          }
          return _buildAvatarPlaceholder(roleName, avatarSize);
        },
      );
    }
    
    return _buildAvatarPlaceholder(roleName, avatarSize);
  }

  Widget _buildAvatarPlaceholder(String? roleName, double size) {
    final String displayText = (roleName?.isNotEmpty == true)
        ? roleName!.substring(0, 1).toUpperCase()
        : '?';
    
    return Container(
      width: size,
      height: size,
      color: AppTheme.primaryColor.withOpacity(0.2),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _loadAvatar(String uri) async {
    if (_avatarCache.containsKey(uri)) {
      return _avatarCache[uri];
    }
    
    try {
      final result = await _fileService.getFile(uri);
      final imageData = result.data as Uint8List;
      _avatarCache[uri] = imageData;
      return imageData;
    } catch (e) {
      debugPrint('头像加载失败: $e');
      return null;
    }
  }

  Widget _buildMemoryRoundsField() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(left: BorderSide(color: Colors.blue, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.memory,
                  color: Colors.blue,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '记忆轮数',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'AI能够记忆的对话轮数（1-500轮）',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12.sp,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '当前: $_memoryRounds 轮',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.blue,
              inactiveTrackColor: AppTheme.border.withOpacity(0.3),
              thumbColor: Colors.blue,
              overlayColor: Colors.blue.withOpacity(0.2),
              trackHeight: 4.h,
            ),
            child: Slider(
              value: _memoryRounds.toDouble(),
              min: 1,
              max: 500,
              divisions: 499,
              onChanged: (value) {
                setState(() {
                  _memoryRounds = value.round();
                  _editedData['memory_rounds'] = _memoryRounds;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterModelSelector() {
    final accentColor = AppTheme.primaryLight;
    final currentModel = _editedData['master_model'] ?? _sessionData['master_model'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: accentColor,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                '控制器模型',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppTheme.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _isCustomMasterModelMode
                      ? TextField(
                          controller: _customMasterModelController,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: '输入自定义模型名称',
                            hintStyle: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14.sp,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              setState(() {
                                _isCustomMasterModelMode = false;
                                _editedData['master_model'] = value.trim();
                              });
                            }
                          },
                        )
                      : Text(
                          currentModel.isNotEmpty ? currentModel : '未设置',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                // 编辑按钮（自定义模型）
                IconButton(
                  icon: Icon(
                    _isCustomMasterModelMode ? Icons.check : Icons.edit,
                    size: 16.sp,
                    color: _isCustomMasterModelMode ? Colors.green : AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    if (_isCustomMasterModelMode) {
                      // 确认自定义输入
                      if (_customMasterModelController.text.trim().isNotEmpty) {
                        setState(() {
                          _isCustomMasterModelMode = false;
                          _editedData['master_model'] = _customMasterModelController.text.trim();
                        });
                      }
                    } else {
                      // 进入编辑模式
                      setState(() {
                        _isCustomMasterModelMode = true;
                        _customMasterModelController.text = currentModel;
                      });
                    }
                  },
                ),
                // 选择按钮（预设模型）
                IconButton(
                  icon: Icon(
                    _isCustomMasterModelMode ? Icons.close : Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: _isCustomMasterModelMode ? Colors.red : AppTheme.textSecondary,
                  ),
                  onPressed: () async {
                    if (_isCustomMasterModelMode) {
                      // 取消编辑
                      setState(() {
                        _isCustomMasterModelMode = false;
                      });
                    } else {
                      // 打开模型选择页面
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SelectModelPage(),
                        ),
                      );
                      if (result != null && mounted) {
                        setState(() {
                          _editedData['master_model'] = result;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedModelField() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.border.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.model_training,
            color: AppTheme.primaryColor,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '统一模型设置',
                  style: TextStyle(
                    fontSize: AppTheme.bodySize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '开启后所有角色将使用相同的AI模型',
                  style: TextStyle(
                    fontSize: AppTheme.smallSize,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _unifiedModel == 'enabled',
            onChanged: (value) {
              setState(() {
                _unifiedModel = value ? 'enabled' : 'disabled';
                _editedData['unified_model'] = _unifiedModel;
                
                // 如果开启统一模型，将所有角色的模型设置为第一个角色的模型
                if (value) {
                  final roles = _sessionData['roles'] as List<dynamic>? ?? [];
                  if (roles.isNotEmpty) {
                    final firstRoleModel = roles[0]['modelName'] ?? '';
                    if (firstRoleModel.isNotEmpty) {
                      // 确保 _editedData 中有 roles
                      if (!_editedData.containsKey('roles')) {
                        _editedData['roles'] = List<Map<String, dynamic>>.from(roles);
                      }
                      final editedRoles = _editedData['roles'] as List<Map<String, dynamic>>;
                      // 统一所有角色的模型
                      for (int i = 0; i < editedRoles.length; i++) {
                        editedRoles[i] = Map<String, dynamic>.from(editedRoles[i]);
                        editedRoles[i]['modelName'] = firstRoleModel;
                      }
                      debugPrint('[统一模型] 已将所有角色的模型统一为: $firstRoleModel');
                    }
                  }
                }
              });
            },
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  // 模型控制角色数量 - 已隐藏
  // Widget _buildMaxRoleControlCountField() {
  //   return Container(
  //     margin: EdgeInsets.only(bottom: 12.h),
  //     padding: EdgeInsets.all(16.w),
  //     decoration: BoxDecoration(
  //       color: AppTheme.cardBackground.withOpacity(0.5),
  //       borderRadius: BorderRadius.circular(8.r),
  //       border: Border(left: BorderSide(color: Colors.amber, width: 3)),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               padding: EdgeInsets.all(6.w),
  //               decoration: BoxDecoration(
  //                 color: Colors.amber.withOpacity(0.2),
  //                 borderRadius: BorderRadius.circular(6.r),
  //               ),
  //               child: Icon(
  //                 Icons.groups,
  //                 color: Colors.amber,
  //                 size: 18.sp,
  //               ),
  //             ),
  //             SizedBox(width: 12.w),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     '模型控制角色数量',
  //                     style: TextStyle(
  //                       color: AppTheme.textPrimary,
  //                       fontSize: 14.sp,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                   SizedBox(height: 4.h),
  //                   Text(
  //                     '设置单个模型最多可以控制的角色数量（1-5个）',
  //                     style: TextStyle(
  //                       color: AppTheme.textSecondary,
  //                       fontSize: 12.sp,
  //                       fontStyle: FontStyle.italic,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: 12.h),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: List.generate(5, (index) {
  //             final count = index + 1;
  //             final isSelected = _maxRoleControlCount == count;
  //             return GestureDetector(
  //               onTap: () {
  //                 setState(() {
  //                   _maxRoleControlCount = count;
  //                   _editedData['max_role_control_count'] = count;
  //                 });
  //               },
  //               child: Container(
  //                 width: 50.w,
  //                 height: 50.w,
  //                 decoration: BoxDecoration(
  //                   color: isSelected 
  //                       ? AppTheme.primaryColor.withOpacity(0.1)
  //                       : AppTheme.cardBackground,
  //                   borderRadius: BorderRadius.circular(12.r),
  //                   border: Border.all(
  //                     color: isSelected
  //                         ? AppTheme.primaryColor
  //                         : AppTheme.border.withOpacity(0.3),
  //                     width: isSelected ? 2 : 1,
  //                   ),
  //                 ),
  //                 child: Center(
  //                   child: Text(
  //                     count.toString(),
  //                     style: TextStyle(
  //                       fontSize: 18.sp,
  //                       fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
  //                       color: isSelected 
  //                           ? AppTheme.primaryColor 
  //                           : AppTheme.textSecondary,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             );
  //           }),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildRoleModelSelector(int roleIndex, Map<String, dynamic> role) {
    final accentColor = Colors.blue;
    // 优先从 _editedData 中读取最新的模型名称
    String currentModel = role['modelName'] ?? '';
    if (_editedData.containsKey('roles')) {
      final editedRoles = _editedData['roles'] as List;
      if (roleIndex < editedRoles.length) {
        final editedRole = editedRoles[roleIndex] as Map<String, dynamic>;
        currentModel = editedRole['modelName'] ?? currentModel;
      }
    }
    
    // 确保控制器和状态存在
    if (!_customRoleModelControllers.containsKey(roleIndex)) {
      _customRoleModelControllers[roleIndex] = TextEditingController();
      _isCustomRoleModelMode[roleIndex] = false;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: accentColor,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                '角色模型',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppTheme.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _isCustomRoleModelMode[roleIndex] == true
                      ? TextField(
                          controller: _customRoleModelControllers[roleIndex],
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: '输入自定义模型名称',
                            hintStyle: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14.sp,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              setState(() {
                                _isCustomRoleModelMode[roleIndex] = false;
                                _updateRoleModel(roleIndex, value.trim());
                              });
                            }
                          },
                        )
                      : Text(
                          currentModel.isNotEmpty ? currentModel : '未设置',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                // 编辑按钮（自定义模型）
                IconButton(
                  icon: Icon(
                    _isCustomRoleModelMode[roleIndex] == true ? Icons.check : Icons.edit,
                    size: 16.sp,
                    color: _isCustomRoleModelMode[roleIndex] == true ? Colors.green : AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    if (_isCustomRoleModelMode[roleIndex] == true) {
                      // 确认自定义输入
                      if (_customRoleModelControllers[roleIndex]!.text.trim().isNotEmpty) {
                        setState(() {
                          _isCustomRoleModelMode[roleIndex] = false;
                          _updateRoleModel(roleIndex, _customRoleModelControllers[roleIndex]!.text.trim());
                        });
                      }
                    } else {
                      // 进入编辑模式
                      setState(() {
                        _isCustomRoleModelMode[roleIndex] = true;
                        _customRoleModelControllers[roleIndex]!.text = currentModel;
                      });
                    }
                  },
                ),
                // 选择按钮（预设模型）
                IconButton(
                  icon: Icon(
                    _isCustomRoleModelMode[roleIndex] == true ? Icons.close : Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: _isCustomRoleModelMode[roleIndex] == true ? Colors.red : AppTheme.textSecondary,
                  ),
                  onPressed: () async {
                    if (_isCustomRoleModelMode[roleIndex] == true) {
                      // 取消编辑
                      setState(() {
                        _isCustomRoleModelMode[roleIndex] = false;
                      });
                    } else {
                      // 打开模型选择页面
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SelectModelPage(),
                        ),
                      );
                      if (result != null && mounted) {
                        setState(() {
                          _updateRoleModel(roleIndex, result);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateRoleModel(int roleIndex, String modelName) {
    if (!_editedData.containsKey('roles')) {
      _editedData['roles'] = List<Map<String, dynamic>>.from(_sessionData['roles'] ?? []);
    }
    final roles = _editedData['roles'] as List<Map<String, dynamic>>;
    if (roleIndex < roles.length) {
      roles[roleIndex] = Map<String, dynamic>.from(roles[roleIndex]);
      roles[roleIndex]['modelName'] = modelName;
      
      // 如果统一模型开启且修改的是第一个角色，同步到所有角色
      if (_unifiedModel == 'enabled' && roleIndex == 0) {
        debugPrint('[统一模型] 第一个角色模型改变为 $modelName，同步到所有角色');
        for (int i = 1; i < roles.length; i++) {
          roles[i] = Map<String, dynamic>.from(roles[i]);
          roles[i]['modelName'] = modelName;
        }
      }
    }
  }
}
