import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import 'user_management_service.dart';
import '../../../widgets/custom_toast.dart';
import '../../../pages/admin/user_management/user_asset_records_page.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = '全部';
  String _selectedRole = '全部';
  int _currentPage = 1;
  final int _pageSize = 10;
  int _totalUsers = 0;
  bool _isLoading = false;
  List<dynamic> _users = [];
  final ScrollController _horizontalScrollController = ScrollController();

  // 记录操作中的用户ID
  final Map<int, Map<String, bool>> _loadingStates = {};

  final UserManagementService _userService = UserManagementService();

  // 增加资产操作状态控制
  bool _isAddingCoin = false;
  bool _isDeductingCoin = false;
  bool _isAddingExp = false;
  bool _isAddingPlayTime = false;

  // 增加资产操作控制器
  final TextEditingController _coinAmountController = TextEditingController();
  final TextEditingController _coinDescriptionController =
      TextEditingController();

  final TextEditingController _deductCoinAmountController =
      TextEditingController();
  final TextEditingController _deductCoinDescriptionController =
      TextEditingController();

  final TextEditingController _expAmountController = TextEditingController();
  final TextEditingController _expDescriptionController =
      TextEditingController();

  final TextEditingController _playTimeHoursController =
      TextEditingController();
  final TextEditingController _playTimeDescriptionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();

    // 新增资产控制器释放
    _coinAmountController.dispose();
    _coinDescriptionController.dispose();
    _deductCoinAmountController.dispose();
    _deductCoinDescriptionController.dispose();
    _expAmountController.dispose();
    _expDescriptionController.dispose();
    _playTimeHoursController.dispose();
    _playTimeDescriptionController.dispose();

    super.dispose();
  }

  // 加载用户列表
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 将中文状态转换为API需要的值
      String? statusValue;
      if (_selectedStatus == '正常') {
        statusValue = '0';
      } else if (_selectedStatus == '禁用') {
        statusValue = '1';
      }

      // 将中文角色转换为API需要的值
      String? roleValue;
      if (_selectedRole == '普通用户') {
        roleValue = '0';
      } else if (_selectedRole == '运营人员') {
        roleValue = '1';
      } else if (_selectedRole == '管理员') {
        roleValue = '2';
      }

      final result = await _userService.getUserList(
        page: _currentPage,
        pageSize: _pageSize,
        status: statusValue,
        role: roleValue,
        keyword:
            _searchController.text.isNotEmpty ? _searchController.text : null,
      );

      setState(() {
        _users = result['data']['users'];
        _totalUsers = result['data']['total'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorToast('加载用户列表失败: $e');
    }
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

  // 设置用户操作状态
  void _setUserActionLoading(int userId, String action, bool isLoading) {
    setState(() {
      if (!_loadingStates.containsKey(userId)) {
        _loadingStates[userId] = {};
      }
      _loadingStates[userId]![action] = isLoading;
    });
  }

  // 获取用户操作状态
  bool _isUserActionLoading(int userId, String action) {
    return _loadingStates[userId]?[action] ?? false;
  }

  // 启用或禁用用户
  Future<void> _toggleUserStatus(int userId, bool isCurrentlyEnabled) async {
    final actionName = isCurrentlyEnabled ? 'disable' : 'enable';

    try {
      _setUserActionLoading(userId, actionName, true);

      if (isCurrentlyEnabled) {
        await _userService.disableUser(userId);
        _showSuccessToast('用户已禁用');
      } else {
        await _userService.enableUser(userId);
        _showSuccessToast('用户已启用');
      }

      _loadUsers();
    } catch (e) {
      _showErrorToast('操作失败: $e');
    } finally {
      _setUserActionLoading(userId, actionName, false);
    }
  }

  // 强制用户下线
  Future<void> _forceLogout(int userId) async {
    try {
      _setUserActionLoading(userId, 'logout', true);

      await _userService.forceLogout(userId);
      _showSuccessToast('已强制用户下线');
    } catch (e) {
      _showErrorToast('强制下线失败: $e');
    } finally {
      _setUserActionLoading(userId, 'logout', false);
    }
  }

  // 修改用户角色
  Future<void> _changeUserRole(int userId, int newRole) async {
    try {
      _setUserActionLoading(userId, 'role', true);

      await _userService.setUserRole(userId, newRole);
      _showSuccessToast('用户角色已更新');
      _loadUsers();
    } catch (e) {
      _showErrorToast('修改角色失败: $e');
    } finally {
      _setUserActionLoading(userId, 'role', false);
    }
  }

  // 获取角色名称
  String _getRoleName(int role) {
    switch (role) {
      case 0:
        return '普通用户';
      case 1:
        return '运营人员';
      case 2:
        return '管理员';
      default:
        return '未知';
    }
  }

  // 获取状态名称
  String _getStatusName(int status) {
    switch (status) {
      case 0:
        return '正常';
      case 1:
        return '禁用';
      default:
        return '未知';
    }
  }

  // 增加用户小懿币
  Future<void> _addUserCoin(int userId, String username) async {
    if (_coinAmountController.text.isEmpty ||
        _coinDescriptionController.text.isEmpty) {
      _showErrorToast('请填写必填字段');
      return;
    }

    final int amount;
    try {
      amount = int.parse(_coinAmountController.text);
      if (amount <= 0) {
        _showErrorToast('金额必须大于0');
        return;
      }
    } catch (e) {
      _showErrorToast('请输入有效的数字');
      return;
    }

    setState(() {
      _isAddingCoin = true;
    });

    try {
      final result = await _userService.addUserCoin(
        userId,
        amount: amount,
        description: _coinDescriptionController.text,
      );

      _showSuccessToast('成功增加 $amount 小懿币，当前余额: ${result['data']['balance']}');
      _clearCoinForm();
      Navigator.pop(context); // 关闭弹窗
    } catch (e) {
      _showErrorToast('操作失败: $e');
    } finally {
      setState(() {
        _isAddingCoin = false;
      });
    }
  }

  // 扣除用户小懿币
  Future<void> _deductUserCoin(int userId, String username) async {
    if (_deductCoinAmountController.text.isEmpty ||
        _deductCoinDescriptionController.text.isEmpty) {
      _showErrorToast('请填写必填字段');
      return;
    }

    final int amount;
    try {
      amount = int.parse(_deductCoinAmountController.text);
      if (amount <= 0) {
        _showErrorToast('金额必须大于0');
        return;
      }
    } catch (e) {
      _showErrorToast('请输入有效的数字');
      return;
    }

    setState(() {
      _isDeductingCoin = true;
    });

    try {
      final result = await _userService.deductUserCoin(
        userId,
        amount: amount,
        description: _deductCoinDescriptionController.text,
      );

      _showSuccessToast('成功扣除 $amount 小懿币，当前余额: ${result['data']['balance']}');
      _clearDeductCoinForm();
      Navigator.pop(context); // 关闭弹窗
    } catch (e) {
      _showErrorToast('操作失败: $e');
    } finally {
      setState(() {
        _isDeductingCoin = false;
      });
    }
  }

  // 增加用户经验值
  Future<void> _addUserExperience(int userId, String username) async {
    if (_expAmountController.text.isEmpty ||
        _expDescriptionController.text.isEmpty) {
      _showErrorToast('请填写必填字段');
      return;
    }

    final int amount;
    try {
      amount = int.parse(_expAmountController.text);
      if (amount <= 0) {
        _showErrorToast('经验值必须大于0');
        return;
      }
    } catch (e) {
      _showErrorToast('请输入有效的数字');
      return;
    }

    setState(() {
      _isAddingExp = true;
    });

    try {
      final result = await _userService.addUserExperience(
        userId,
        amount: amount,
        description: _expDescriptionController.text,
      );

      _showSuccessToast('成功增加 $amount 经验值，当前总经验: ${result['data']['balance']}');
      _clearExpForm();
      Navigator.pop(context); // 关闭弹窗
    } catch (e) {
      _showErrorToast('操作失败: $e');
    } finally {
      setState(() {
        _isAddingExp = false;
      });
    }
  }

  // 增加用户畅玩时长
  Future<void> _addUserPlayTime(int userId, String username) async {
    if (_playTimeHoursController.text.isEmpty ||
        _playTimeDescriptionController.text.isEmpty) {
      _showErrorToast('请填写必填字段');
      return;
    }

    final int hours;
    try {
      hours = int.parse(_playTimeHoursController.text);
      if (hours <= 0) {
        _showErrorToast('时长必须大于0');
        return;
      }
    } catch (e) {
      _showErrorToast('请输入有效的数字');
      return;
    }

    setState(() {
      _isAddingPlayTime = true;
    });

    try {
      final result = await _userService.addUserPlayTime(
        userId,
        hours: hours,
        description: _playTimeDescriptionController.text,
      );

      final DateTime expireAt =
          DateTime.parse(result['data']['play_time_expire_at']);
      _showSuccessToast(
          '成功增加 $hours 小时畅玩时长，有效期至: ${_formatDateTime(expireAt)}');
      _clearPlayTimeForm();
      Navigator.pop(context); // 关闭弹窗
    } catch (e) {
      _showErrorToast('操作失败: $e');
    } finally {
      setState(() {
        _isAddingPlayTime = false;
      });
    }
  }

  // 显示增加小懿币弹窗
  void _showAddCoinDialog(int userId, String username) {
    _clearCoinForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('增加小懿币 - $username'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _coinAmountController,
                labelText: '增加数量*',
                hintText: '请输入大于0的整数',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                controller: _coinDescriptionController,
                labelText: '变动描述*',
                hintText: '例如：管理员奖励',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed:
                _isAddingCoin ? null : () => _addUserCoin(userId, username),
            child: _isAddingCoin
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Text('确认'),
          ),
        ],
      ),
    );
  }

  // 显示扣除小懿币弹窗
  void _showDeductCoinDialog(int userId, String username) {
    _clearDeductCoinForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('扣除小懿币 - $username'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _deductCoinAmountController,
                labelText: '扣除数量*',
                hintText: '请输入大于0的整数',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                controller: _deductCoinDescriptionController,
                labelText: '变动描述*',
                hintText: '例如：管理员扣除',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: _isDeductingCoin
                ? null
                : () => _deductUserCoin(userId, username),
            child: _isDeductingCoin
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Text('确认'),
          ),
        ],
      ),
    );
  }

  // 显示增加经验值弹窗
  void _showAddExpDialog(int userId, String username) {
    _clearExpForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('增加经验值 - $username'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _expAmountController,
                labelText: '增加数量*',
                hintText: '请输入大于0的整数',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                controller: _expDescriptionController,
                labelText: '变动描述*',
                hintText: '例如：管理员奖励经验',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: _isAddingExp
                ? null
                : () => _addUserExperience(userId, username),
            child: _isAddingExp
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Text('确认'),
          ),
        ],
      ),
    );
  }

  // 显示增加畅玩时长弹窗
  void _showAddPlayTimeDialog(int userId, String username) {
    _clearPlayTimeForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('增加畅玩时长 - $username'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _playTimeHoursController,
                labelText: '增加小时数*',
                hintText: '请输入大于0的整数',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                controller: _playTimeDescriptionController,
                labelText: '变动描述*',
                hintText: '例如：管理员赠送畅玩时长',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: _isAddingPlayTime
                ? null
                : () => _addUserPlayTime(userId, username),
            child: _isAddingPlayTime
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Text('确认'),
          ),
        ],
      ),
    );
  }

  // 显示用户资产管理选项菜单
  void _showAssetManagementMenu(int userId, String username) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('资产管理 - $username'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showAddCoinDialog(userId, username);
            },
            child: ListTile(
              leading: Icon(Icons.add_circle, color: Colors.green),
              title: Text('增加小懿币'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showDeductCoinDialog(userId, username);
            },
            child: ListTile(
              leading: Icon(Icons.remove_circle, color: Colors.orange),
              title: Text('扣除小懿币'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showAddExpDialog(userId, username);
            },
            child: ListTile(
              leading: Icon(Icons.star, color: Colors.blue),
              title: Text('增加经验值'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showAddPlayTimeDialog(userId, username);
            },
            child: ListTile(
              leading: Icon(Icons.timer, color: Colors.purple),
              title: Text('增加畅玩时长'),
            ),
          ),
        ],
      ),
    );
  }

  // 辅助方法：清除表单
  void _clearCoinForm() {
    _coinAmountController.clear();
    _coinDescriptionController.clear();
  }

  void _clearDeductCoinForm() {
    _deductCoinAmountController.clear();
    _deductCoinDescriptionController.clear();
  }

  void _clearExpForm() {
    _expAmountController.clear();
    _expDescriptionController.clear();
  }

  void _clearPlayTimeForm() {
    _playTimeHoursController.clear();
    _playTimeDescriptionController.clear();
  }

  // 格式化日期时间（比原有的只有日期的格式化更详细）
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // 构建输入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;
    final primaryColor = AppTheme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontSize: 14.sp,
            color: textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: textSecondary,
              fontSize: 14.sp,
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4.r),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4.r),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4.r),
              borderSide: BorderSide(
                color: primaryColor.withOpacity(0.6),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryColor;
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;
    final surfaceColor = AppTheme.cardBackground;
    final background = AppTheme.background;

    return Scaffold(
      backgroundColor: background,
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜索区域 - 第一行
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索用户...',
                hintStyle: TextStyle(color: textSecondary),
                prefixIcon: Icon(Icons.search, color: textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    _loadUsers();
                  },
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.r),
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.r),
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.r),
                  borderSide: BorderSide(
                    color: primaryColor.withOpacity(0.6),
                    width: 1,
                  ),
                ),
              ),
              onSubmitted: (_) => _loadUsers(),
            ),
            SizedBox(height: 12.h),

            // 筛选区域 - 第二行
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedStatus,
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: textSecondary),
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        items: ['全部', '正常', '禁用'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedStatus = newValue;
                              _currentPage = 1;
                            });
                            _loadUsers();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedRole,
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: textSecondary),
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        items:
                            ['全部', '普通用户', '运营人员', '管理员'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedRole = newValue;
                              _currentPage = 1;
                            });
                            _loadUsers();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // 搜索按钮
                SizedBox(
                  height: 40.h,
                  child: TextButton(
                    onPressed: _isLoading ? null : _loadUsers,
                    style: TextButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      disabledBackgroundColor: primaryColor.withOpacity(0.6),
                      disabledForegroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('搜索'),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // 横向滚动表格
            Expanded(
              child: _isLoading && _users.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor))
                  : _users.isEmpty
                      ? Center(
                          child: Text(
                            '没有找到用户',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: textSecondary,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _horizontalScrollController,
                          child: SizedBox(
                            width: 860.w, // 适应操作列宽度调整
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 表头
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 80.w,
                                        child: Text(
                                          'ID',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120.w,
                                        child: Text(
                                          '用户名',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 180.w,
                                        child: Text(
                                          '邮箱',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100.w,
                                        child: Text(
                                          '角色',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 80.w,
                                        child: Text(
                                          '状态',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120.w,
                                        child: Text(
                                          '注册时间',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 180.w,
                                        child: Text(
                                          '操作',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: textPrimary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 表格内容
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _users.length,
                                    itemBuilder: (context, index) {
                                      final user = _users[index];
                                      final userId = user['id'] as int;
                                      final bool isEnabled =
                                          user['status'] == 0;
                                      final bool isDisableLoading =
                                          _isUserActionLoading(
                                              userId, 'disable');
                                      final bool isEnableLoading =
                                          _isUserActionLoading(
                                              userId, 'enable');
                                      final bool isLogoutLoading =
                                          _isUserActionLoading(
                                              userId, 'logout');
                                      final bool isRoleLoading =
                                          _isUserActionLoading(userId, 'role');

                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12.h),
                                        decoration: BoxDecoration(
                                          color: index % 2 == 0
                                              ? background
                                              : surfaceColor,
                                          border: Border(
                                            bottom: BorderSide(
                                              color:
                                                  Colors.grey.withOpacity(0.1),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 80.w,
                                              child: Text(
                                                '${user['id']}',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 120.w,
                                              child: Text(
                                                user['username'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 180.w,
                                              child: Text(
                                                user['email'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 100.w,
                                              child: Text(
                                                _getRoleName(user['role']),
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: _getRoleColor(
                                                      user['role']),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 80.w,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8.w,
                                                  vertical: 2.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                          user['status'])
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          2.r),
                                                ),
                                                child: Text(
                                                  _getStatusName(
                                                      user['status']),
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color: _getStatusColor(
                                                        user['status']),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 120.w,
                                              child: Text(
                                                _formatDate(user['created_at']),
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: textSecondary,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 180.w,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  // 启用/禁用按钮
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4.r),
                                                      onTap: (isDisableLoading ||
                                                              isEnableLoading)
                                                          ? null
                                                          : () =>
                                                              _toggleUserStatus(
                                                                  userId,
                                                                  isEnabled),
                                                      child: Container(
                                                        width: 40.w,
                                                        height: 40.h,
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      4.r),
                                                        ),
                                                        child: Center(
                                                          child: isDisableLoading ||
                                                                  isEnableLoading
                                                              ? SizedBox(
                                                                  width: 18.w,
                                                                  height: 18.h,
                                                                  child:
                                                                      CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    color: isEnabled
                                                                        ? Colors
                                                                            .red
                                                                        : Colors
                                                                            .green,
                                                                  ),
                                                                )
                                                              : Icon(
                                                                  isEnabled
                                                                      ? Icons
                                                                          .lock
                                                                      : Icons
                                                                          .lock_open,
                                                                  size: 20.sp,
                                                                  color: isEnabled
                                                                      ? Colors
                                                                          .red
                                                                      : Colors
                                                                          .green,
                                                                ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  // 强制下线按钮
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4.r),
                                                      onTap: isLogoutLoading
                                                          ? null
                                                          : () => _forceLogout(
                                                              userId),
                                                      child: Container(
                                                        width: 40.w,
                                                        height: 40.h,
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      4.r),
                                                        ),
                                                        child: Center(
                                                          child: isLogoutLoading
                                                              ? SizedBox(
                                                                  width: 18.w,
                                                                  height: 18.h,
                                                                  child:
                                                                      CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    color: Colors
                                                                        .orange,
                                                                  ),
                                                                )
                                                              : Icon(
                                                                  Icons
                                                                      .power_settings_new,
                                                                  size: 20.sp,
                                                                  color: Colors
                                                                      .orange,
                                                                ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  // 资产管理按钮
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4.r),
                                                      onTap: () =>
                                                          _showAssetManagementMenu(
                                                              userId,
                                                              user['username'] ??
                                                                  ''),
                                                      child: Container(
                                                        width: 40.w,
                                                        height: 40.h,
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      4.r),
                                                        ),
                                                        child: Center(
                                                          child: Icon(
                                                            Icons
                                                                .account_balance_wallet,
                                                            size: 20.sp,
                                                            color: Colors.teal,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  // 资产记录按钮
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4.r),
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                UserAssetRecordsPage(
                                                              userId: userId,
                                                              username: user[
                                                                      'username'] ??
                                                                  '',
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        width: 40.w,
                                                        height: 40.h,
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      4.r),
                                                        ),
                                                        child: Center(
                                                          child: Icon(
                                                            Icons.history,
                                                            size: 20.sp,
                                                            color: Colors.blue,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  // 角色设置按钮
                                                  PopupMenuButton<int>(
                                                    icon: isRoleLoading
                                                        ? SizedBox(
                                                            width: 18.w,
                                                            height: 18.h,
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  textPrimary,
                                                            ),
                                                          )
                                                        : Icon(
                                                            Icons.more_vert,
                                                            size: 20.sp,
                                                            color: textPrimary,
                                                          ),
                                                    tooltip: '更多操作',
                                                    enabled: !isRoleLoading,
                                                    itemBuilder: (context) => [
                                                      PopupMenuItem<int>(
                                                        value: 0,
                                                        child: Text('设为普通用户'),
                                                      ),
                                                      PopupMenuItem<int>(
                                                        value: 1,
                                                        child: Text('设为运营人员'),
                                                      ),
                                                      PopupMenuItem<int>(
                                                        value: 2,
                                                        child: Text('设为管理员'),
                                                      ),
                                                    ],
                                                    onSelected: (int value) =>
                                                        _changeUserRole(
                                                            userId, value),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),

            // 分页控制
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '共 $_totalUsers 条记录，每页 $_pageSize 条',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left),
                        onPressed: (_currentPage > 1 && !_isLoading)
                            ? () {
                                setState(() {
                                  _currentPage--;
                                });
                                _loadUsers();
                              }
                            : null,
                        color: _currentPage > 1 && !_isLoading
                            ? primaryColor
                            : Colors.grey.withOpacity(0.5),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 4.h),
                        child: Text(
                          '$_currentPage / ${(_totalUsers / _pageSize).ceil()}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right),
                        onPressed:
                            (_currentPage < (_totalUsers / _pageSize).ceil() &&
                                    !_isLoading)
                                ? () {
                                    setState(() {
                                      _currentPage++;
                                    });
                                    _loadUsers();
                                  }
                                : null,
                        color:
                            _currentPage < (_totalUsers / _pageSize).ceil() &&
                                    !_isLoading
                                ? primaryColor
                                : Colors.grey.withOpacity(0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 格式化日期
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  // 获取角色颜色
  Color _getRoleColor(int role) {
    switch (role) {
      case 2:
        return Colors.purple;
      case 1:
        return Colors.blue;
      case 0:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // 获取状态颜色
  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
