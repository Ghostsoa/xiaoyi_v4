import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import '../services/character_service.dart';
import 'package:shimmer/shimmer.dart';

class ChatArchivePage extends StatefulWidget {
  final String sessionId;

  const ChatArchivePage({
    super.key,
    required this.sessionId,
  });

  @override
  State<ChatArchivePage> createState() => _ChatArchivePageState();
}

class _ChatArchivePageState extends State<ChatArchivePage> {
  final CharacterService _characterService = CharacterService();
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _saveSlots = [];
  bool _archiveActivated = false;

  @override
  void initState() {
    super.initState();
    _loadSaveSlots();
  }

  // 构建骨架屏卡片
  Widget _buildSkeletonCard() {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      color: AppTheme.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 标题骨架
                Expanded(
                  child: _ShimmerBox(
                    height: 20.h,
                    width: double.infinity,
                    borderRadius: 4.r,
                  ),
                ),
                SizedBox(width: 12.w),
                // 菜单骨架
                _ShimmerBox(
                  height: 24.w,
                  width: 24.w,
                  isCircle: true,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Divider(
              color: AppTheme.textPrimary.withOpacity(0.1),
              height: 16.h,
              thickness: 1,
            ),
            SizedBox(height: 4.h),
            // 消息数和Token数骨架
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ShimmerBox(
                  width: 80.w,
                  height: 16.h,
                  borderRadius: 4.r,
                ),
                _ShimmerBox(
                  width: 80.w,
                  height: 16.h,
                  borderRadius: 4.r,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // 时间信息骨架
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ShimmerBox(
                      width: 14.w,
                      height: 14.h,
                      isCircle: true,
                    ),
                    SizedBox(width: 4.w),
                    _ShimmerBox(
                      width: 150.w,
                      height: 14.h,
                      borderRadius: 4.r,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _ShimmerBox(
                      width: 14.w,
                      height: 14.h,
                      isCircle: true,
                    ),
                    SizedBox(width: 4.w),
                    _ShimmerBox(
                      width: 150.w,
                      height: 14.h,
                      borderRadius: 4.r,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 单独的骨架元素组件，带有自己的流光效果
  Widget _ShimmerBox({
    required double width,
    required double height,
    double? borderRadius,
    bool isCircle = false,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius:
              !isCircle ? BorderRadius.circular(borderRadius ?? 0) : null,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }

  // 构建骨架屏加载视图
  Widget _buildSkeletonLoading() {
    return ListView.builder(
      itemCount: 5,
      padding: EdgeInsets.all(16.w),
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Future<void> _loadSaveSlots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final saveSlots = await _characterService.getSessionSaveSlots(
        int.parse(widget.sessionId),
      );

      if (mounted) {
        setState(() {
          _saveSlots = saveSlots;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomToast.show(context, message: '加载存档失败: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _refreshSaveSlots() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final saveSlots = await _characterService.getSessionSaveSlots(
        int.parse(widget.sessionId),
      );

      if (mounted) {
        setState(() {
          _saveSlots = saveSlots;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        CustomToast.show(context, message: '刷新存档失败: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _createSaveSlot(String name) async {
    try {
      final newSaveSlot = await _characterService.createSaveSlot(
        int.parse(widget.sessionId),
        name,
      );

      if (mounted) {
        setState(() {
          _saveSlots = [newSaveSlot, ..._saveSlots];
        });
        CustomToast.show(context, message: '创建存档成功', type: ToastType.success);
      }

      _refreshSaveSlots();
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '创建存档失败: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _duplicateSaveSlot(String name) async {
    try {
      final newSaveSlot = await _characterService.duplicateSaveSlot(
        int.parse(widget.sessionId),
        name,
      );

      if (mounted) {
        setState(() {
          _saveSlots = [newSaveSlot, ..._saveSlots];
        });
        CustomToast.show(context, message: '创建存档快照成功', type: ToastType.success);
      }

      _refreshSaveSlots();
    } catch (e) {
      if (mounted) {
        CustomToast.show(context,
            message: '创建存档快照失败: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _activateSaveSlot(String saveSlotId) async {
    try {
      await _characterService.activateSaveSlot(
        int.parse(widget.sessionId),
        saveSlotId,
      );

      if (mounted) {
        setState(() {
          for (var slot in _saveSlots) {
            slot['active'] = slot['id'] == saveSlotId;
          }
          _archiveActivated = true;
        });
        CustomToast.show(context, message: '激活存档成功', type: ToastType.success);
      }

      _refreshSaveSlots();
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '激活存档失败: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _renameSaveSlot(String saveSlotId, String newName) async {
    try {
      await _characterService.renameSaveSlot(
        int.parse(widget.sessionId),
        saveSlotId,
        newName,
      );

      if (mounted) {
        setState(() {
          for (var slot in _saveSlots) {
            if (slot['id'] == saveSlotId) {
              slot['saveName'] = newName;
              break;
            }
          }
        });
        CustomToast.show(context, message: '重命名存档成功', type: ToastType.success);
      }

      _refreshSaveSlots();
    } catch (e) {
      if (mounted) {
        CustomToast.show(context,
            message: '重命名存档失败: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _deleteSaveSlot(String saveSlotId) async {
    try {
      await _characterService.deleteSaveSlot(
        int.parse(widget.sessionId),
        saveSlotId,
      );

      if (mounted) {
        setState(() {
          _saveSlots.removeWhere((slot) => slot['id'] == saveSlotId);
        });
        CustomToast.show(context, message: '删除存档成功', type: ToastType.success);
      }

      _refreshSaveSlots();
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '删除存档失败: $e', type: ToastType.error);
      }
    }
  }

  void _showCreateSaveSlotDialog() {
    final nameController = TextEditingController();
    bool isSnapshot = false; // 默认创建新存档而不是快照

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isSnapshot ? '创建存档快照' : '创建对话存档'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 选择创建类型
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isSnapshot = false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: !isSnapshot
                              ? AppTheme.primaryColor
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            '新建存档',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color:
                                  !isSnapshot ? Colors.white : Colors.black87,
                              fontWeight: !isSnapshot
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isSnapshot = true),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: isSnapshot
                              ? AppTheme.primaryColor
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            '创建快照',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isSnapshot ? Colors.white : Colors.black87,
                              fontWeight: isSnapshot
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 说明文字
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                child: Text(
                  isSnapshot ? '快照会保存当前对话状态，可以随时回到这一时刻。' : '新建存档会创建一个全新的对话记录。',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '存档名称',
                  hintText: '输入存档名称',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  CustomToast.show(context,
                      message: '请输入存档名称', type: ToastType.warning);
                  return;
                }

                if (isSnapshot) {
                  _duplicateSaveSlot(nameController.text.trim());
                } else {
                  _createSaveSlot(nameController.text.trim());
                }

                Navigator.pop(context);
              },
              child: Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameSaveSlotDialog(String saveSlotId, String currentName) {
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('重命名存档'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '存档名称',
                hintText: '输入新的存档名称',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                CustomToast.show(context,
                    message: '请输入存档名称', type: ToastType.warning);
                return;
              }
              _renameSaveSlot(saveSlotId, nameController.text.trim());
              Navigator.pop(context);
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(String saveSlotId, String saveName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除存档'),
        content: Text('确定要删除存档"$saveName"吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _deleteSaveSlot(saveSlotId);
              Navigator.pop(context);
            },
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      // 解析UTC时间
      final dateTime = DateTime.parse(dateTimeStr);
      // 添加+8小时的时区调整
      final beijingTime = dateTime.add(const Duration(hours: 8));

      final year = beijingTime.year.toString();
      final month = beijingTime.month.toString().padLeft(2, '0');
      final day = beijingTime.day.toString().padLeft(2, '0');
      final hour = beijingTime.hour.toString().padLeft(2, '0');
      final minute = beijingTime.minute.toString().padLeft(2, '0');
      return '$year-$month-$day $hour:$minute';
    } catch (e) {
      return dateTimeStr;
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('存档系统说明'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                '存档类型',
                '本系统支持两种存档类型：',
              ),
              SizedBox(height: 8.h),
              _buildHelpItem(
                Icons.save,
                '全新存档',
                '创建全新的对话记录，重新开始，与其他存档互不影响。',
              ),
              SizedBox(height: 8.h),
              _buildHelpItem(
                Icons.photo_camera,
                '对话快照',
                '保存当前对话状态的快照，可以随时回到这一时刻继续对话，类似游戏中的存档点。',
              ),
              SizedBox(height: 16.h),
              _buildHelpSection(
                '存档操作',
                '您可以对存档进行以下操作：',
              ),
              SizedBox(height: 8.h),
              _buildHelpItem(
                Icons.check,
                '激活',
                '切换到选定的存档或快照继续对话。',
              ),
              SizedBox(height: 8.h),
              _buildHelpItem(
                Icons.edit,
                '重命名',
                '修改存档的名称。',
              ),
              SizedBox(height: 8.h),
              _buildHelpItem(
                Icons.delete,
                '删除',
                '永久删除存档（无法撤销）。',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('了解了'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          description,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.sp, color: AppTheme.primaryColor),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_archiveActivated);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('对话存档'),
          actions: [
            IconButton(
              icon: Icon(Icons.help_outline),
              onPressed: () => _showHelpDialog(),
              tooltip: '存档帮助',
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _refreshSaveSlots,
              tooltip: '刷新存档列表',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateSaveSlotDialog,
          tooltip: '创建存档/快照',
          child: Icon(Icons.add),
        ),
        body: _isLoading
            ? _buildSkeletonLoading()
            : _saveSlots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.archive_outlined,
                          size: 64.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '暂无存档',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          onPressed: _showCreateSaveSlotDialog,
                          child: Text('创建存档'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshSaveSlots,
                    child: ListView.builder(
                      itemCount: _saveSlots.length,
                      padding: EdgeInsets.all(16.w),
                      physics: AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final saveSlot = _saveSlots[index];
                        final bool isActive = saveSlot['active'] ?? false;
                        final bool isSnapshot = saveSlot['isSnapshot'] ?? false;

                        return Card(
                          margin: EdgeInsets.only(bottom: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            side: isActive
                                ? BorderSide(
                                    color: AppTheme.primaryColor, width: 2)
                                : BorderSide.none,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isActive)
                                      Tooltip(
                                        message: '当前激活的存档',
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                            vertical: 2.h,
                                          ),
                                          margin: EdgeInsets.only(right: 8.w),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(4.r),
                                          ),
                                          child: Text(
                                            '当前',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                    // 显示存档类型图标
                                    Tooltip(
                                      message: isSnapshot ? '对话快照' : '完整存档',
                                      child: Icon(
                                        isSnapshot
                                            ? Icons.photo_camera
                                            : Icons.save,
                                        size: 16.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        saveSlot['saveName'] ?? '未命名存档',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton(
                                      icon: Icon(Icons.more_vert),
                                      itemBuilder: (context) => [
                                        if (!isActive)
                                          PopupMenuItem(
                                            value: 'activate',
                                            child: Row(
                                              children: [
                                                Icon(Icons.check, size: 18.sp),
                                                SizedBox(width: 8.w),
                                                Text('激活'),
                                              ],
                                            ),
                                          ),
                                        PopupMenuItem(
                                          value: 'rename',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 18.sp),
                                              SizedBox(width: 8.w),
                                              Text('重命名'),
                                            ],
                                          ),
                                        ),
                                        if (!isActive)
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete,
                                                    size: 18.sp,
                                                    color: Colors.red),
                                                SizedBox(width: 8.w),
                                                Text('删除',
                                                    style: TextStyle(
                                                        color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                      ],
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'activate':
                                            _activateSaveSlot(saveSlot['id']);
                                            break;
                                          case 'rename':
                                            _showRenameSaveSlotDialog(
                                              saveSlot['id'],
                                              saveSlot['saveName'] ?? '',
                                            );
                                            break;
                                          case 'delete':
                                            _showDeleteConfirmDialog(
                                              saveSlot['id'],
                                              saveSlot['saveName'] ?? '未命名存档',
                                            );
                                            break;
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Divider(),
                                SizedBox(height: 4.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '消息数: ${saveSlot['totalCount'] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'Token: ${saveSlot['totalTokens'] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 14.sp, color: Colors.grey),
                                        SizedBox(width: 4.w),
                                        Text(
                                          '创建时间: ',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          _formatDateTime(
                                              saveSlot['createdAt'] ?? ''),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Row(
                                      children: [
                                        Icon(Icons.update,
                                            size: 14.sp, color: Colors.grey),
                                        SizedBox(width: 4.w),
                                        Text(
                                          '更新时间: ',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          _formatDateTime(
                                              saveSlot['lastUpdated'] ?? ''),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
