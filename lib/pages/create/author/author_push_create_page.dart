import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import '../services/author_service.dart';
import '../../../dao/user_dao.dart';
import 'select_item_page.dart';

class AuthorPushCreatePage extends StatefulWidget {
  final Map<String, dynamic>? existingUpdate; // 如果是编辑模式，则传入现有推送

  const AuthorPushCreatePage({
    super.key,
    this.existingUpdate,
  });

  @override
  State<AuthorPushCreatePage> createState() => _AuthorPushCreatePageState();
}

class _AuthorPushCreatePageState extends State<AuthorPushCreatePage> {
  final AuthorService _authorService = AuthorService();
  final UserDao _userDao = UserDao();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // 设定字数限制
  final int _titleMaxLength = 30;
  final int _descriptionMaxLength = 200;

  String _updateType = 'new'; // 默认为新内容更新
  bool _isLoading = false;
  int? _authorId;

  // 临时模拟的作品数据，实际开发中应当通过选择页面获取
  int? _selectedItemId;
  String _selectedItemType = 'character_card';
  String _selectedItemName = '未选择作品';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();

    // 如果是编辑模式，加载现有数据
    if (widget.existingUpdate != null) {
      _titleController.text = widget.existingUpdate!['title'] ?? '';
      _descriptionController.text = widget.existingUpdate!['description'] ?? '';
      _updateType = widget.existingUpdate!['update_type'] ?? 'new';
      _selectedItemId = widget.existingUpdate!['item_id'];
      _selectedItemType =
          widget.existingUpdate!['item_type'] ?? 'character_card';
      _selectedItemName = '已选择作品ID: ${_selectedItemId ?? "未知"}';
    }

    // 添加监听，以便更新剩余字数提示
    _titleController.addListener(_onTitleChanged);
    _descriptionController.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _descriptionController.removeListener(_onDescriptionChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 标题字数变化监听
  void _onTitleChanged() {
    setState(() {});
  }

  // 描述字数变化监听
  void _onDescriptionChanged() {
    setState(() {});
  }

  Future<void> _loadUserInfo() async {
    try {
      final userId = await _userDao.getUserId();
      if (userId != null && mounted) {
        setState(() {
          _authorId = userId;
        });
      }
    } catch (e) {
      CustomToast.show(
        context,
        message: '无法加载用户信息',
        type: ToastType.error,
      );
    }
  }

  // 模拟选择作品
  void _showSelectItemDialog() {
    // 跳转到作品选择页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectItemPage(),
      ),
    ).then((selectedItem) {
      // 如果用户选择了作品，则更新状态
      if (selectedItem != null && mounted) {
        setState(() {
          _selectedItemId = selectedItem['id'];
          _selectedItemType = selectedItem['item_type'] ?? 'character_card';
          _selectedItemName = selectedItem['title'] ?? '未知作品';
        });
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedItemId == null) {
      CustomToast.show(
        context,
        message: '请选择要推送的作品',
        type: ToastType.warning,
      );
      return;
    }

    if (_authorId == null) {
      CustomToast.show(
        context,
        message: '无法获取用户ID',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.existingUpdate != null) {
        // 更新已有推送
        await _authorService.updateUpdate(
          updateId: widget.existingUpdate!['id'],
          title: _titleController.text,
          description: _descriptionController.text,
          updateType: _updateType,
        );
        CustomToast.show(
          context,
          message: '更新成功',
          type: ToastType.success,
        );
      } else {
        // 创建新推送
        await _authorService.createUpdate(
          authorId: _authorId!,
          itemId: _selectedItemId!,
          itemType: _selectedItemType,
          title: _titleController.text,
          description: _descriptionController.text,
          updateType: _updateType,
        );
        CustomToast.show(
          context,
          message: '发布成功',
          type: ToastType.success,
        );
      }
      // 返回上一页
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '操作失败: ${e.toString()}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          widget.existingUpdate != null ? '编辑推送' : '发布更新推送',
          style: AppTheme.titleStyle,
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 发布须知
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.cardBackground.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.primaryColor,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          '发布须知',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // 发布流程
                    _buildInfoItem(
                      icon: Icons.publish_rounded,
                      title: '发布流程',
                      content: '内容发布 -> 内容审核 -> 推送给粉丝',
                    ),

                    // 发布费用
                    _buildInfoItem(
                      icon: Icons.monetization_on_rounded,
                      title: '发布费用',
                      content: '每次发布将消耗 5 小懿币，审核不通过不予退还。',
                    ),

                    // 审核周期
                    _buildInfoItem(
                      icon: Icons.timer_rounded,
                      title: '审核周期',
                      content: '我们将在 5 分钟左右完成审核，请耐心等待。',
                    ),

                    SizedBox(height: 12.h),
                    Divider(color: AppTheme.border.withOpacity(0.2)),
                    SizedBox(height: 12.h),

                    // 违规内容警告
                    Text(
                      '严禁发布以下内容:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '• 危害国家安全、泄露国家秘密、颠覆国家政权、破坏国家统一的内容\n'
                      '• 广告、营销、引流或任何商业推广内容\n'
                      '• 色情、暴力、赌博、恐怖主义等违法内容\n'
                      '• 虚假信息、谣言或具有误导性的内容\n'
                      '• 侵犯他人知识产权、隐私权等合法权益的内容',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red.shade400,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '违反上述规定的账号将被处理，情节严重者将被永久封禁。',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // 选择作品
              Card(
                color: AppTheme.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: 0,
                child: InkWell(
                  onTap: _showSelectItemDialog,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '选择要推送的作品',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedItemName,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: _selectedItemId != null
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16.sp,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // 推送类型
              Card(
                color: AppTheme.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '更新类型',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'new',
                            groupValue: _updateType,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (value) {
                              setState(() {
                                _updateType = value!;
                              });
                            },
                          ),
                          Text(
                            '新内容',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Radio<String>(
                            value: 'update',
                            groupValue: _updateType,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (value) {
                              setState(() {
                                _updateType = value!;
                              });
                            },
                          ),
                          Text(
                            '更新内容',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // 标题输入
              Card(
                color: AppTheme.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '推送标题',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          // 显示剩余字数
                          Text(
                            '${_titleController.text.length}/$_titleMaxLength',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color:
                                  _titleController.text.length > _titleMaxLength
                                      ? Colors.red
                                      : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: '请输入推送标题',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.5),
                            fontSize: 14.sp,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: AppTheme.border.withOpacity(0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: AppTheme.border.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textPrimary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入推送标题';
                          }
                          if (value.length > _titleMaxLength) {
                            return '标题不能超过$_titleMaxLength个字符';
                          }
                          return null;
                        },
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // 描述输入
              Card(
                color: AppTheme.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '推送描述',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          // 显示剩余字数
                          Text(
                            '${_descriptionController.text.length}/$_descriptionMaxLength',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: _descriptionController.text.length >
                                      _descriptionMaxLength
                                  ? Colors.red
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: '请输入推送描述内容',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.5),
                            fontSize: 14.sp,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: AppTheme.border.withOpacity(0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: AppTheme.border.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textPrimary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入推送描述';
                          }
                          if (value.length > _descriptionMaxLength) {
                            return '描述不能超过$_descriptionMaxLength个字符';
                          }
                          return null;
                        },
                        maxLines: 5,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '简要描述本次更新内容，让粉丝了解您的新动态',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppTheme.primaryColor.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : Text(
                          widget.existingUpdate != null ? '保存修改' : '发布推送',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
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

  // 构建信息项的小组件
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.textSecondary,
            size: 18.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
