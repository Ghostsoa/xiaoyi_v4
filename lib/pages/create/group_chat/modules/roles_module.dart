import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/custom_toast.dart';
import '../../material/select_image_page.dart';
import '../../../../services/file_service.dart';
import '../../character/select_model_page.dart';
import '../../../../widgets/expandable_text_field.dart';


class RolesModule extends StatefulWidget {
  final List<Map<String, dynamic>> roles;
  final bool useUnifiedModel;
  final Function(List<Map<String, dynamic>>) onRolesChanged;
  final Function(bool) onUnifiedModelChanged;
  final Function(int, String) onRoleModelChanged;
  final Map<String, Uint8List> imageCache;

  const RolesModule({
    super.key,
    required this.roles,
    required this.useUnifiedModel,
    required this.onRolesChanged,
    required this.onUnifiedModelChanged,
    required this.onRoleModelChanged,
    required this.imageCache,
  });

  @override
  State<RolesModule> createState() => _RolesModuleState();
}

class _RolesModuleState extends State<RolesModule> {
  final FileService _fileService = FileService();
  int _selectedRoleIndex = 0;

  // 为每个角色创建独立的控制器
  final Map<int, TextEditingController> _nameControllers = {};
  final Map<int, TextEditingController> _descriptionControllers = {};
  final Map<int, TextEditingController> _settingControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    for (int i = 0; i < widget.roles.length; i++) {
      final role = widget.roles[i];
      _nameControllers[i] = TextEditingController(text: role['name'] ?? '');
      _descriptionControllers[i] = TextEditingController(text: role['description'] ?? '');
      _settingControllers[i] = TextEditingController(text: role['setting'] ?? '');
    }
  }

  void _disposeControllers() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _descriptionControllers.values) {
      controller.dispose();
    }
    for (final controller in _settingControllers.values) {
      controller.dispose();
    }
    _nameControllers.clear();
    _descriptionControllers.clear();
    _settingControllers.clear();
  }

  void _ensureControllerExists(int index) {
    if (!_nameControllers.containsKey(index)) {
      final role = widget.roles[index];
      _nameControllers[index] = TextEditingController(text: role['name'] ?? '');
      _descriptionControllers[index] = TextEditingController(text: role['description'] ?? '');
      _settingControllers[index] = TextEditingController(text: role['setting'] ?? '');
    }
  }


  void _addRole() {
    // 限制最大角色数量为30个
    if (widget.roles.length >= 30) {
      CustomToast.show(
        context,
        message: '最多只能创建30个角色',
        type: ToastType.error,
      );
      return;
    }

    final newRole = {
      'name': '',
      'description': '',
      'setting': '',
      'avatarUri': null,
      'modelName': 'gemini-2.0-flash',
    };

    final updatedRoles = List<Map<String, dynamic>>.from(widget.roles);
    updatedRoles.add(newRole);

    // 为新角色创建控制器
    final newIndex = updatedRoles.length - 1;
    _nameControllers[newIndex] = TextEditingController(text: '');
    _descriptionControllers[newIndex] = TextEditingController(text: '');
    _settingControllers[newIndex] = TextEditingController(text: '');

    widget.onRolesChanged(updatedRoles);

    CustomToast.show(context, message: '已添加新角色', type: ToastType.success);
  }

  void _removeRole(int index) {
    if (widget.roles.length <= 1) {
      CustomToast.show(context, message: '至少需要保留一个角色', type: ToastType.error);
      return;
    }

    // 清理被删除角色的控制器
    _nameControllers[index]?.dispose();
    _descriptionControllers[index]?.dispose();
    _settingControllers[index]?.dispose();

    // 重新组织控制器映射
    final newNameControllers = <int, TextEditingController>{};
    final newDescriptionControllers = <int, TextEditingController>{};
    final newSettingControllers = <int, TextEditingController>{};

    for (int i = 0; i < widget.roles.length; i++) {
      if (i < index) {
        // 保持原有索引
        newNameControllers[i] = _nameControllers[i]!;
        newDescriptionControllers[i] = _descriptionControllers[i]!;
        newSettingControllers[i] = _settingControllers[i]!;
      } else if (i > index) {
        // 索引前移
        newNameControllers[i - 1] = _nameControllers[i]!;
        newDescriptionControllers[i - 1] = _descriptionControllers[i]!;
        newSettingControllers[i - 1] = _settingControllers[i]!;
      }
    }

    _nameControllers.clear();
    _descriptionControllers.clear();
    _settingControllers.clear();

    _nameControllers.addAll(newNameControllers);
    _descriptionControllers.addAll(newDescriptionControllers);
    _settingControllers.addAll(newSettingControllers);

    final updatedRoles = List<Map<String, dynamic>>.from(widget.roles);
    updatedRoles.removeAt(index);

    // 调整选中索引
    if (_selectedRoleIndex >= updatedRoles.length) {
      _selectedRoleIndex = updatedRoles.length - 1;
    }

    widget.onRolesChanged(updatedRoles);

    CustomToast.show(context, message: '角色已删除', type: ToastType.success);
  }

  void _updateRole(int index, String field, dynamic value) {
    // 如果是模型字段且开启了统一模型，使用专门的回调
    if (field == 'modelName') {
      widget.onRoleModelChanged(index, value);
      return;
    }

    // 检查角色名字是否重复
    if (field == 'name' && value != null && value.toString().trim().isNotEmpty) {
      final trimmedName = value.toString().trim();
      for (int i = 0; i < widget.roles.length; i++) {
        if (i != index && widget.roles[i]['name'] == trimmedName) {
          CustomToast.show(
            context,
            message: '角色名"$trimmedName"已存在，请使用不同的名字',
            type: ToastType.error,
          );
          // 恢复原来的名字
          _nameControllers[index]?.text = widget.roles[index]['name'] ?? '';
          return;
        }
      }
    }

    final updatedRoles = List<Map<String, dynamic>>.from(widget.roles);
    updatedRoles[index][field] = value;

    // 同步更新对应的控制器（避免循环更新）
    if (field == 'name' && _nameControllers[index]?.text != value) {
      _nameControllers[index]?.text = value ?? '';
    } else if (field == 'description' && _descriptionControllers[index]?.text != value) {
      _descriptionControllers[index]?.text = value ?? '';
    } else if (field == 'setting' && _settingControllers[index]?.text != value) {
      _settingControllers[index]?.text = value ?? '';
    }

    widget.onRolesChanged(updatedRoles);
  }

  Future<void> _pickAvatar(int index) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SelectImagePage(
            type: ImageSelectType.cover,
            source: ImageSelectSource.myMaterial,
          ),
        ),
      );

      if (result != null) {
        // 更新角色头像
        _updateRole(index, 'avatarUri', result);
        
        CustomToast.show(
          context,
          message: '已选择角色头像',
          type: ToastType.success,
        );
      }
    } catch (e) {
      CustomToast.show(
        context,
        message: '头像选择失败: ${e.toString()}',
        type: ToastType.error,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // 统一模型设置
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppTheme.border.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.model_training,
                  color: AppTheme.primaryColor,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '统一模型设置',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              '推荐开启',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppTheme.textSecondary,
                            height: 1.3,
                          ),
                          children: [
                            TextSpan(
                              text: '开启：',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: '一个模型可同时扮演多个角色，节省成本和时间\n'),
                            TextSpan(
                              text: '关闭：',
                              style: TextStyle(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: '每个角色独立请求，成本高、速度慢'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.useUnifiedModel,
                  onChanged: (value) {
                    widget.onUnifiedModelChanged(value);
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 16.h),
        
        // 添加角色按钮区域
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            children: [
              GestureDetector(
                onTap: _addRole,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppTheme.buttonGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: const GradientRotation(0.4),
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.buttonGradient.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '添加角色',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (widget.roles.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.group,
                        size: 16.sp,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '共${widget.roles.length}个角色',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        SizedBox(height: 16.h),
        
        // 横向角色列表
        if (widget.roles.isNotEmpty)
          Container(
            height: 90.h, // 增加高度避免溢出
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: widget.roles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final role = entry.value;
                  final isSelected = _selectedRoleIndex == index;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRoleIndex = index;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 12.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 防止溢出
                        children: [
                          Container(
                            width: 64.w,
                            height: 64.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32.r),
                              border: Border.all(
                                color: isSelected 
                                    ? AppTheme.primaryColor 
                                    : AppTheme.border,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32.r),
                              child: role['avatarUri'] != null
                                  ? _buildAvatar(role['avatarUri'])
                                  : Container(
                                      color: AppTheme.cardBackground,
                                      child: Icon(
                                        Icons.person,
                                        color: AppTheme.textSecondary,
                                        size: 24.sp,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          SizedBox(
                            width: 64.w,
                            child: Text(
                              role['name']?.toString().isNotEmpty == true 
                                  ? role['name'] 
                                  : '角色${index + 1}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: isSelected 
                                    ? AppTheme.primaryColor 
                                    : AppTheme.textSecondary,
                                fontWeight: isSelected 
                                    ? FontWeight.w600 
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        
        // 分隔线
        if (widget.roles.isNotEmpty)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            height: 1.h,
            color: AppTheme.border.withOpacity(0.3),
          ),
        
        // 角色详情
        if (widget.roles.isNotEmpty)
          _buildRoleDetail(widget.roles[_selectedRoleIndex], _selectedRoleIndex)
        else
          SizedBox(
            height: 200.h,
            child: _buildEmptyRoleHint(),
          ),
      ],
    );
  }

  Widget _buildRoleDetail(Map<String, dynamic> role, int index) {
    // 确保控制器存在
    _ensureControllerExists(index);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：角色标题和删除按钮
          Row(
            children: [
              Expanded(
                child: Text(
                  role['name']?.toString().isNotEmpty == true 
                      ? role['name'] 
                      : '角色 ${index + 1}',
                  style: AppTheme.titleStyle.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (widget.roles.length > 1)
                GestureDetector(
                  onTap: () => _removeRole(index),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20.sp,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 24.h),

          // 头像和名称
          Row(
            children: [
              GestureDetector(
                onTap: () => _pickAvatar(index),
                child: Container(
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
                    child: role['avatarUri'] != null
                        ? _buildAvatar(role['avatarUri'])
                        : Container(
                            color: AppTheme.cardBackground,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  color: AppTheme.textSecondary,
                                  size: 24.sp,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '选择头像',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('角色名称', style: AppTheme.secondaryStyle),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _nameControllers[index],
                      onChanged: (value) => _updateRole(index, 'name', value),
                      decoration: InputDecoration(
                        hintText: '请输入角色名称',
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14.sp,
                        ),
                      ),
                      style: AppTheme.bodyStyle,
                      maxLength: 10,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // 角色简介
          Text('角色简介', style: AppTheme.secondaryStyle),
          SizedBox(height: 4.h),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
              children: [
                const TextSpan(text: '不仅是给'),
                TextSpan(
                  text: '用户看',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '的，也会影响'),
                TextSpan(
                  text: '决策模型的决策',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          ExpandableTextField(
            title: '角色描述',
            controller: _descriptionControllers[index]!,
            hintText: '简单描述这个角色的特点...',
            maxLength: 1000,
            previewLines: 2,
            onChanged: () => _updateRole(index, 'description', _descriptionControllers[index]!.text),
          ),

          SizedBox(height: 24.h),

          // 角色设定
          ExpandableTextField(
            title: '角色设定',
            controller: _settingControllers[index]!,
            hintText: '详细描述角色的性格、背景、说话方式等...',
            maxLength: 5000,
            previewLines: 4,
            description: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12.sp,
                ),
                children: [
                  const TextSpan(text: '角色设定会'),
                  TextSpan(
                    text: '传递给生成模型',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: '，详细描述角色的'),
                  TextSpan(
                    text: '性格、背景、说话方式',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: '等'),
                ],
              ),
            ),
            onChanged: () => _updateRole(index, 'setting', _settingControllers[index]!.text),
          ),

          SizedBox(height: 24.h),

          // 角色模型选择
          Text('角色模型', style: AppTheme.secondaryStyle),
          SizedBox(height: 4.h),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.sp,
              ),
              children: [
                const TextSpan(text: '选择合适的'),
                TextSpan(
                  text: 'AI模型',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '来驱动角色对话'),
                if (widget.useUnifiedModel) ...[
                  const TextSpan(text: '\n'),
                  const TextSpan(text: '🔗 '),
                  TextSpan(
                    text: '统一模型模式：修改将影响所有角色',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 8.h),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.border.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      role['modelName'] ?? '点击选择模型',
                      style: TextStyle(
                        fontSize: AppTheme.captionSize,
                        color: role['modelName'] != null 
                            ? AppTheme.textPrimary 
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.textSecondary,
                    size: 16.sp,
                  ),
                ],
              ),
            ),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SelectModelPage(),
                ),
              );
              if (result != null && mounted) {
                _updateRole(index, 'modelName', result);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRoleHint() {
    return Center(
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
            '还没有角色',
            style: TextStyle(
              fontSize: AppTheme.captionSize,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '点击上方的 + 按钮添加第一个角色',
            style: TextStyle(
              fontSize: AppTheme.smallSize,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String uri) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30.r),
      child: widget.imageCache.containsKey(uri)
          ? Image.memory(
              widget.imageCache[uri]!,
              width: 60.w,
              height: 60.w,
              fit: BoxFit.cover,
            )
          : FutureBuilder<Uint8List?>(
              future: _loadImageFromUri(uri),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: 60.w,
                    height: 60.w,
                    color: AppTheme.background,
                    child: Center(
                      child: SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      ),
                    ),
                  );
                }
                
                if (snapshot.hasData && snapshot.data != null) {
                  // 缓存图片数据
                  widget.imageCache[uri] = snapshot.data!;
                  return Image.memory(
                    snapshot.data!,
                    width: 60.w,
                    height: 60.w,
                    fit: BoxFit.cover,
                  );
                }
                
                return Container(
                  width: 60.w,
                  height: 60.w,
                  color: AppTheme.background,
                  child: Icon(
                    Icons.broken_image,
                    color: AppTheme.textSecondary,
                    size: 24.sp,
                  ),
                );
              },
            ),
    );
  }

  Future<Uint8List?> _loadImageFromUri(String uri) async {
    try {
      final file = await _fileService.getFile(uri);
      return file.data;
    } catch (e) {
      return null;
    }
  }
}
