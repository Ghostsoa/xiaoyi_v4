import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import 'notification_service.dart';

class CreateNotificationPage extends StatefulWidget {
  final Function? onNotificationCreated;

  const CreateNotificationPage({super.key, this.onNotificationCreated});

  @override
  State<CreateNotificationPage> createState() => _CreateNotificationPageState();
}

class _CreateNotificationPageState extends State<CreateNotificationPage> {
  final NotificationService _notificationService = NotificationService();

  // 创建通知表单控制器
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  String? _selectedType;
  int _selectedLevel = 0;
  bool _isBroadcast = true;
  final TextEditingController _targetUsersController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    _targetUsersController.dispose();
    super.dispose();
  }

  // 创建通知
  Future<void> _createNotification() async {
    // 表单验证
    if (_titleController.text.trim().isEmpty) {
      _showErrorToast('请输入通知标题');
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      _showErrorToast('请输入通知内容');
      return;
    }

    if (_selectedType == null) {
      _showErrorToast('请选择通知类型');
      return;
    }

    // 如果是定向通知，验证目标用户
    if (!_isBroadcast) {
      final targetText = _targetUsersController.text.trim();
      if (targetText.isEmpty) {
        _showErrorToast('请输入目标用户ID');
        return;
      }

      try {
        // 验证输入的是有效的用户ID列表
        final targetList =
            targetText.split(',').map((e) => int.parse(e.trim())).toList();
        if (targetList.isEmpty) {
          _showErrorToast('请输入有效的用户ID');
          return;
        }
      } catch (e) {
        _showErrorToast('用户ID格式不正确，请使用逗号分隔的数字ID');
        return;
      }
    }

    setState(() {
      _isCreating = true;
    });

    try {
      List<int>? targetUsers;
      if (!_isBroadcast) {
        // 解析目标用户ID
        targetUsers = _targetUsersController.text
            .split(',')
            .map((e) => int.parse(e.trim()))
            .toList();
      }

      await _notificationService.createNotification(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType!,
        level: _selectedLevel,
        isBroadcast: _isBroadcast,
        targetUsers: targetUsers,
        link: _linkController.text.trim().isNotEmpty
            ? _linkController.text.trim()
            : null,
      );

      _showSuccessToast('通知创建成功');

      // 如果提供了回调，调用回调
      if (widget.onNotificationCreated != null) {
        widget.onNotificationCreated!();
      }

      // 返回上一页
      Navigator.pop(context);
    } catch (e) {
      _showErrorToast('创建通知失败: $e');
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryLight;
    final background = AppTheme.background;
    final surfaceColor = AppTheme.cardBackground;
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        title: Text(
          '创建通知',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createNotification,
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              disabledForegroundColor: Colors.grey,
            ),
            child: _isCreating
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text('创建中...'),
                    ],
                  )
                : Text('发布', style: TextStyle(fontSize: 16.sp)),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 通知标题
              Container(
                margin: EdgeInsets.only(bottom: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '通知标题',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: '输入通知标题',
                        hintStyle:
                            TextStyle(color: textSecondary.withOpacity(0.5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                      ),
                      maxLength: 50,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // 通知内容
              Container(
                margin: EdgeInsets.only(bottom: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '通知内容',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        hintText: '输入通知内容',
                        hintStyle:
                            TextStyle(color: textSecondary.withOpacity(0.5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                      ),
                      maxLines: 8,
                      maxLength: 500,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // 通知类型
              Container(
                margin: EdgeInsets.only(bottom: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '通知类型',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: '选择通知类型',
                          hintStyle:
                              TextStyle(color: textSecondary.withOpacity(0.5)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                        value: _selectedType,
                        items: [
                          DropdownMenuItem(
                            value: 'system',
                            child: Text('系统通知',
                                style: TextStyle(color: textPrimary)),
                          ),
                          DropdownMenuItem(
                            value: 'activity',
                            child: Text('活动通知',
                                style: TextStyle(color: textPrimary)),
                          ),
                          DropdownMenuItem(
                            value: 'update',
                            child: Text('更新通知',
                                style: TextStyle(color: textPrimary)),
                          ),
                          DropdownMenuItem(
                            value: 'reminder',
                            child: Text('提醒通知',
                                style: TextStyle(color: textPrimary)),
                          ),
                          DropdownMenuItem(
                            value: 'promotion',
                            child: Text('促销通知',
                                style: TextStyle(color: textPrimary)),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                        dropdownColor: surfaceColor,
                        icon: Icon(Icons.arrow_drop_down, color: textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              // 通知级别
              Container(
                margin: EdgeInsets.only(bottom: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '通知级别',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 12.w,
                        children: [
                          _buildLevelChip(0, '普通', AppTheme.success),
                          _buildLevelChip(1, '重要', AppTheme.warning),
                          _buildLevelChip(2, '紧急', AppTheme.error),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 发送方式
              Container(
                margin: EdgeInsets.only(bottom: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '发送方式',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 12.w,
                        children: [
                          ChoiceChip(
                            label: Text('全部用户'),
                            selected: _isBroadcast,
                            selectedColor: primaryColor.withOpacity(0.15),
                            onSelected: (selected) {
                              setState(() {
                                _isBroadcast = selected;
                                if (!selected) {
                                  _isBroadcast = true;
                                }
                              });
                            },
                          ),
                          ChoiceChip(
                            label: Text('指定用户'),
                            selected: !_isBroadcast,
                            selectedColor: primaryColor.withOpacity(0.15),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _isBroadcast = false;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 目标用户输入框，仅当选择定向通知时显示
              if (!_isBroadcast)
                Container(
                  margin: EdgeInsets.only(bottom: 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '目标用户ID',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: _targetUsersController,
                        decoration: InputDecoration(
                          hintText: '多个ID用逗号分隔，如：1,2,3',
                          hintStyle:
                              TextStyle(color: textSecondary.withOpacity(0.5)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide:
                                BorderSide(color: Colors.grey.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide:
                                BorderSide(color: Colors.grey.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

              // 相关链接
              Container(
                margin: EdgeInsets.only(bottom: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '相关链接（可选）',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        hintText: '如: https://example.com/event',
                        hintStyle:
                            TextStyle(color: textSecondary.withOpacity(0.5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // 发布按钮
              Container(
                width: double.infinity,
                height: 50.h,
                margin: EdgeInsets.only(bottom: 32.h, top: 16.h),
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    disabledBackgroundColor: primaryColor.withOpacity(0.6),
                  ),
                  child: _isCreating
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16.r,
                              height: 16.r,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '发布中...',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '发布通知',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 通知级别选择器
  Widget _buildLevelChip(int level, String label, Color color) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedLevel == level,
      selectedColor: color.withOpacity(0.15),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedLevel = level;
          });
        }
      },
      labelStyle: TextStyle(
        color: _selectedLevel == level ? color : null,
      ),
    );
  }

  // 显示错误提示
  void _showErrorToast(String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.error,
    );
  }

  // 显示成功提示
  void _showSuccessToast(String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.success,
    );
  }
}
