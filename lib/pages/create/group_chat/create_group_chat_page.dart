import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
import '../../../theme/app_theme.dart';
import '../../../services/group_chat_service.dart';
import '../../../widgets/custom_toast.dart';
import 'modules/basic_info_module.dart';
import 'modules/master_settings_module.dart';
import 'modules/roles_module.dart';

class CreateGroupChatPage extends StatefulWidget {
  final Map<String, dynamic>? groupChat;
  final bool isEdit;

  const CreateGroupChatPage({
    super.key,
    this.groupChat,
    this.isEdit = false,
  });

  @override
  State<CreateGroupChatPage> createState() => _CreateGroupChatPageState();
}

class _CreateGroupChatPageState extends State<CreateGroupChatPage> {
  final _formKey = GlobalKey<FormState>();
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

  // 主控设定
  final _masterSettingController = TextEditingController();
  String _masterModel = 'gemini-2.0-flash';
  String? _coreControllerModel;
  final _userRoleSettingController = TextEditingController();
  final _greetingController = TextEditingController();

  // 角色列表
  List<Map<String, dynamic>> _roles = [];

  // 群聊状态
  String _status = 'draft'; // draft, published, private

  final List<String> _pageNames = ['基础信息', '主控设定', '角色管理'];





  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.groupChat != null) {
      _loadGroupChatData();
    }
  }

  void _loadGroupChatData() {
    final data = widget.groupChat!;
    _nameController.text = data['name'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _tagsController.text = (data['tags'] as List?)?.join(', ') ?? '';
    _coverUri = data['coverUri'];
    _backgroundUri = data['backgroundUri'];
    _masterSettingController.text = data['masterSetting'] ?? '';
    _masterModel = data['masterModel'] ?? 'gemini-2.0-flash';
    _coreControllerModel = data['coreControllerModel'];
    _userRoleSettingController.text = data['userRoleSetting'] ?? '';
    _greetingController.text = data['greeting'] ?? '';
    _roles = List<Map<String, dynamic>>.from(data['roles'] ?? []);
    _status = data['status'] ?? 'draft';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _masterSettingController.dispose();
    _userRoleSettingController.dispose();
    _greetingController.dispose();
    super.dispose();
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
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
                          widget.isEdit ? '编辑群聊' : '创建群聊',
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
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _saveGroupChat,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppTheme.buttonGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              transform: const GradientRotation(0.4),
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Text(
                            widget.isEdit ? '保存' : '创建',
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
              
              // 分页导航
              Container(
                margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  children: List.generate(
                    _pageNames.length,
                    (index) => _buildNavigationButton(index),
                  ),
                ),
              ),
              
              // 页面内容
              Expanded(
                child: _buildPageContent(),
              ),
            ],
          ),
        ),
      ),
    );
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
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    Widget content;
    switch (_currentPage) {
      case 0:
        content = BasicInfoModule(
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
          status: _status,
          onStatusChanged: (value) => setState(() => _status = value),
        );
        break;
      case 1:
        content = MasterSettingsModule(
          masterSettingController: _masterSettingController,
          masterModel: _masterModel,
          coreControllerModel: _coreControllerModel,
          userRoleSettingController: _userRoleSettingController,
          greetingController: _greetingController,
          onMasterModelChanged: (model) {
            setState(() {
              _masterModel = model;
            });
          },
          onCoreControllerModelChanged: (model) {
            setState(() {
              _coreControllerModel = model;
            });
          },
        );
        break;
      case 2:
        content = RolesModule(
          roles: _roles,
          onRolesChanged: (roles) {
            setState(() {
              _roles = roles;
            });
          },
          imageCache: _imageCache,
        );
        break;
      default:
        content = Container();
    }

    // 所有页面都使用统一的滚动处理
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: content,
    );
  }

  bool _validateForm() {
    // 验证基础信息
    if (_nameController.text.trim().isEmpty) {
      CustomToast.show(context, message: '请输入群聊名称', type: ToastType.error);
      return false;
    }
    
    // 验证主控设定
    if (_masterModel.isEmpty) {
      CustomToast.show(context, message: '请选择主控模型', type: ToastType.error);
      return false;
    }
    
    // 验证角色
    if (_roles.isEmpty) {
      CustomToast.show(context, message: '至少需要添加一个角色', type: ToastType.error);
      return false;
    }
    
    for (final role in _roles) {
      if (role['name'] == null || role['name'].toString().trim().isEmpty) {
        CustomToast.show(context, message: '所有角色都需要设置名称', type: ToastType.error);
        return false;
      }
      if (role['setting'] == null || role['setting'].toString().trim().isEmpty) {
        CustomToast.show(context, message: '所有角色都需要设置角色设定', type: ToastType.error);
        return false;
      }
      if (role['modelName'] == null || role['modelName'].toString().trim().isEmpty) {
        CustomToast.show(context, message: '所有角色都需要选择模型', type: ToastType.error);
        return false;
      }
    }
    
    return true;
  }

  Future<void> _saveGroupChat() async {
    if (!_validateForm()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // 准备群聊数据
      final groupChatData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'tags': _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'coverUri': _coverUri,
        'backgroundUri': _backgroundUri,
        'masterSetting': _masterSettingController.text.trim(),
        'masterModel': _masterModel,
        'coreControllerModel': _coreControllerModel,
        'userRoleSetting': _userRoleSettingController.text.trim(),
        'greeting': _greetingController.text.trim(),
        'roles': _roles,
        'status': _status,
      };

      final service = GroupChatService();
      if (widget.isEdit) {
        await service.updateGroupChat(widget.groupChat!['id'], groupChatData);
      } else {
        await service.createGroupChat(groupChatData);
      }

      if (mounted) {
        CustomToast.show(
          context,
          message: widget.isEdit ? '群聊已更新' : '群聊创建成功',
          type: ToastType.success,
        );

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
