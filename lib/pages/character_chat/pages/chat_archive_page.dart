import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'dart:typed_data';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import '../services/character_service.dart';
import 'package:shimmer/shimmer.dart';

class ChatArchivePage extends StatefulWidget {
  final String sessionId;
  final Uint8List? backgroundImage;
  final double backgroundOpacity;

  const ChatArchivePage({
    super.key,
    required this.sessionId,
    this.backgroundImage,
    this.backgroundOpacity = 0.5,
  });

  @override
  State<ChatArchivePage> createState() => _ChatArchivePageState();
}

class _ChatArchivePageState extends State<ChatArchivePage>
    with SingleTickerProviderStateMixin {
  final CharacterService _characterService = CharacterService();
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _saveSlots = [];
  bool _archiveActivated = false;

  // 添加动画控制器
  late AnimationController _refreshAnimationController;

  @override
  void initState() {
    super.initState();
    // 初始化刷新按钮动画控制器
    _refreshAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _loadSaveSlots();
  }

  @override
  void dispose() {
    // 释放动画控制器
    _refreshAnimationController.dispose();
    super.dispose();
  }

  // 简单的加载指示器，使用纯文本+shimmer效果
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: AppTheme.textSecondary.withOpacity(0.7),
            highlightColor: AppTheme.textPrimary,
            child: Text(
              '正在加载存档...',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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

    // 启动刷新动画
    _refreshAnimationController.repeat();

    try {
      final saveSlots = await _characterService.getSessionSaveSlots(
        int.parse(widget.sessionId),
      );

      if (mounted) {
        setState(() {
          _saveSlots = saveSlots;
          _isRefreshing = false;
        });
        // 成功刷新后停止动画
        _refreshAnimationController.stop();
        _refreshAnimationController.reset();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        // 出错时也停止动画
        _refreshAnimationController.stop();
        _refreshAnimationController.reset();
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
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            isSnapshot ? '创建存档快照' : '创建对话存档',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
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
                              : AppTheme.cardBackground,
                          border: Border.all(
                            color: !isSnapshot
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            '新建存档',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: !isSnapshot
                                  ? Colors.white
                                  : AppTheme.textPrimary,
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
                              : AppTheme.cardBackground,
                          border: Border.all(
                            color: isSnapshot
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            '创建快照',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isSnapshot
                                  ? Colors.white
                                  : AppTheme.textPrimary,
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
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '存档名称',
                  hintText: '输入存档名称',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
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
              child: Text(
                '创建',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
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
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          '重命名存档',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '存档名称',
                hintText: '输入新的存档名称',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
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
            child: Text(
              '确定',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(String saveSlotId, String saveName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          '删除存档',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        content: Text(
          '确定要删除存档"$saveName"吗？此操作不可恢复。',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              _deleteSaveSlot(saveSlotId);
              Navigator.pop(context);
            },
            child: Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
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
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          '存档系统说明',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
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
            child: Text(
              '了解了',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
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
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          description,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppTheme.textSecondary,
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
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppTheme.textSecondary,
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
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          title: Text(
            '对话存档',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppTheme.textPrimary,
              size: 20.sp,
            ),
            onPressed: () => Navigator.of(context).pop(_archiveActivated),
          ),
          actions: [
            // 帮助按钮
            IconButton(
              icon: Icon(Icons.help_outline, color: AppTheme.textPrimary),
              onPressed: () => _showHelpDialog(),
              tooltip: '存档帮助',
            ),
            // 刷新按钮
            IconButton(
              icon: RotationTransition(
                turns: _refreshAnimationController,
                child: Icon(Icons.refresh, color: AppTheme.textPrimary),
              ),
              onPressed: _refreshSaveSlots,
              tooltip: '刷新存档列表',
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingIndicator()
            : _saveSlots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.archive_outlined,
                          size: 64.sp,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '暂无存档',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          onPressed: _showCreateSaveSlotDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                          ),
                          child: Text('创建存档'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _saveSlots.length,
                    padding: EdgeInsets.all(16.w),
                    physics: AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final saveSlot = _saveSlots[index];
                      final bool isActive = saveSlot['active'] ?? false;
                      final bool isSnapshot = saveSlot['isSnapshot'] ?? false;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border(
                              left: BorderSide(
                                color: isActive
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Row(
                                  children: [
                                    // 存档类型图标
                                    Container(
                                      padding: EdgeInsets.all(6.w),
                                      decoration: BoxDecoration(
                                        color: (isSnapshot
                                                ? Colors.amber
                                                : AppTheme.primaryColor)
                                            .withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isSnapshot
                                            ? Icons.photo_camera
                                            : Icons.save,
                                        size: 16.sp,
                                        color: isSnapshot
                                            ? Colors.amber
                                            : AppTheme.primaryColor,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),

                                    // 存档名称和标签
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  saveSlot['saveName'] ??
                                                      '未命名存档',
                                                  style: TextStyle(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              // 移除"当前"标记
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            isSnapshot ? '对话快照' : '对话存档',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 操作菜单
                                    PopupMenuButton(
                                      icon: Icon(Icons.more_horiz,
                                          color: AppTheme.textSecondary),
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
                              ),

                              Divider(height: 1),

                              // 信息栏
                              Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 消息和Token统计
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.chat_bubble_outline,
                                              size: 14.sp,
                                              color: AppTheme.textSecondary,
                                            ),
                                            SizedBox(width: 4.w),
                                            Text(
                                              '${saveSlot['totalCount'] ?? 0} 条消息',
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.token,
                                              size: 14.sp,
                                              color: AppTheme.textSecondary,
                                            ),
                                            SizedBox(width: 4.w),
                                            Text(
                                              '${saveSlot['totalTokens'] ?? 0} tokens',
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 8.h),

                                    // 创建和更新时间
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14.sp,
                                          color: AppTheme.textSecondary,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          '创建: ',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          _formatDateTime(
                                              saveSlot['createdAt'] ?? ''),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.update,
                                          size: 14.sp,
                                          color: AppTheme.textSecondary,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          '更新: ',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          _formatDateTime(
                                              saveSlot['lastUpdated'] ?? ''),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
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
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateSaveSlotDialog,
          backgroundColor: AppTheme.primaryColor,
          child: Icon(Icons.add),
          tooltip: '创建存档/快照',
        ),
      ),
    );
  }
}
