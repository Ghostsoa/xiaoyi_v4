import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'dart:typed_data';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import '../../../widgets/cache_pull_dialog.dart';
import '../../../widgets/confirmation_dialog.dart';
import '../services/character_service.dart';
import '../../../services/message_cache_service.dart';
import '../../../services/session_data_service.dart';
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
  final MessageCacheService _messageCacheService = MessageCacheService();
  final SessionDataService _sessionDataService = SessionDataService();
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _saveSlots = [];
  bool _archiveActivated = false;

  // 记录进入时的激活存档ID，用于退出时比较
  String? _initialActiveArchiveId;
  String? _currentActiveArchiveId;

  // 记录是否拉取过缓存，用于退出时判断是否需要重载
  bool _hasPulledCache = false;

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
    _initializeAndLoadSaveSlots();
  }

  /// 初始化并加载存档列表（包含同步检查）
  Future<void> _initializeAndLoadSaveSlots() async {
    // 1. 先获取本地的激活存档ID
    await _getLocalActiveArchiveId();

    // 2. 加载存档列表
    await _loadSaveSlots();

    // 3. 检查服务器激活ID与本地是否一致
    await _syncActiveArchiveId();
  }

  /// 获取本地的激活存档ID
  Future<void> _getLocalActiveArchiveId() async {
    try {
      await _sessionDataService.initDatabase();

      final sessionId = int.parse(widget.sessionId);
      final sessionResponse = await _sessionDataService.getLocalCharacterSessions(
        page: 1,
        pageSize: 1000
      );

      final session = sessionResponse.sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => throw '会话不存在',
      );

      _initialActiveArchiveId = session.activeArchiveId;
      _currentActiveArchiveId = session.activeArchiveId;

      debugPrint('[ChatArchivePage] 进入时本地激活存档ID: $_initialActiveArchiveId');
    } catch (e) {
      debugPrint('[ChatArchivePage] 获取本地激活存档ID失败: $e');
    }
  }

  /// 同步激活存档ID（检查服务器与本地是否一致）
  Future<void> _syncActiveArchiveId() async {
    try {
      // 从存档列表中找到服务器激活的存档
      final serverActiveSlot = _saveSlots.firstWhere(
        (slot) => slot['active'] == true,
        orElse: () => <String, dynamic>{},
      );

      final serverActiveArchiveId = serverActiveSlot['id'] as String?;

      debugPrint('[ChatArchivePage] 服务器激活存档ID: $serverActiveArchiveId');
      debugPrint('[ChatArchivePage] 本地激活存档ID: $_currentActiveArchiveId');

      // 如果服务器激活ID与本地不一致，更新本地
      if (serverActiveArchiveId != _currentActiveArchiveId) {
        debugPrint('[ChatArchivePage] 检测到激活存档不一致，更新本地记录');

        if (serverActiveArchiveId != null) {
          await _updateSessionActiveArchive(serverActiveArchiveId);
          _currentActiveArchiveId = serverActiveArchiveId;
          _archiveActivated = true; // 标记为已激活，退出时需要刷新
        }
      }
    } catch (e) {
      debugPrint('[ChatArchivePage] 同步激活存档ID失败: $e');
    }
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

      // 检查每个存档是否有本地缓存
      await _checkCacheForSaveSlots(saveSlots);

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

  /// 检查存档是否有本地缓存
  Future<void> _checkCacheForSaveSlots(List<Map<String, dynamic>> saveSlots) async {
    try {
      await _messageCacheService.initDatabase();

      for (var slot in saveSlots) {
        final archiveId = slot['id'] as String;
        final hasCache = await _messageCacheService.hasArchiveCache(
          sessionId: int.parse(widget.sessionId),
          archiveId: archiveId,
        );

        // 添加缓存标识
        slot['hasCache'] = hasCache;
      }
    } catch (e) {
      debugPrint('[ChatArchivePage] 检查缓存失败: $e');
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

      // 🔥 关键修复：重新检查缓存状态，避免缓存标记丢失
      await _checkCacheForSaveSlots(saveSlots);

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
      // 1. 激活存档
      await _characterService.activateSaveSlot(
        int.parse(widget.sessionId),
        saveSlotId,
      );

      // 2. 立即更新会话的激活存档ID
      await _updateSessionActiveArchive(saveSlotId);

      // 3. 更新当前激活存档ID
      _currentActiveArchiveId = saveSlotId;

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

  /// 更新会话的激活存档ID
  Future<void> _updateSessionActiveArchive(String archiveId) async {
    try {
      await _sessionDataService.initDatabase();

      final sessionId = int.parse(widget.sessionId);

      // 获取当前会话数据
      final sessionResponse = await _sessionDataService.getLocalCharacterSessions(
        page: 1,
        pageSize: 1000
      );

      final session = sessionResponse.sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => throw '会话不存在',
      );

      // 更新激活存档ID
      final updatedSession = session.copyWith(
        activeArchiveId: archiveId,
        lastSyncTime: DateTime.now(),
      );

      await _sessionDataService.updateCharacterSession(updatedSession);

      debugPrint('[ChatArchivePage] ✅ 激活存档时已更新会话激活存档ID: $archiveId');
    } catch (e) {
      debugPrint('[ChatArchivePage] ❌ 更新会话激活存档ID失败: $e');
    }
  }



  /// 显示拉取缓存对话框（只拉取当前激活的存档）
  void _showPullCacheDialog() {
    // 找到当前激活的存档
    final activeSlot = _saveSlots.firstWhere(
      (slot) => slot['active'] == true,
      orElse: () => throw '没有激活的存档',
    );

    final activeArchiveId = activeSlot['id'] as String;
    final hasCache = activeSlot['hasCache'] == true;

    if (hasCache) {
      // 如果已有缓存，显示覆盖确认对话框
      _showOverwriteConfirmDialog(activeArchiveId);
    } else {
      // 没有缓存，直接拉取
      _startPullCache(activeArchiveId);
    }
  }

  /// 显示覆盖确认对话框
  void _showOverwriteConfirmDialog(String archiveId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('覆盖本地缓存'),
        content: Text('该存档已有本地缓存，是否要覆盖？\n\n覆盖后将重新从服务器拉取最新数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startPullCache(archiveId);
            },
            child: Text('覆盖'),
          ),
        ],
      ),
    );
  }

  /// 开始拉取缓存
  void _startPullCache(String archiveId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CachePullDialog(
        sessionId: int.parse(widget.sessionId),
        archiveId: archiveId,
        onCompleted: () {
          // 标记已拉取过缓存
          _hasPulledCache = true;
          // 重新检查缓存状态
          _checkCacheForSaveSlots(_saveSlots).then((_) {
            if (mounted) {
              setState(() {});
            }
          });
          CustomToast.show(context, message: '缓存拉取完成', type: ToastType.success);
        },
      ),
    );
  }

  /// 显示清空缓存确认对话框
  Future<void> _showClearCacheConfirmDialog(String archiveId, String archiveName) async {
    final bool? confirmed = await ConfirmationDialog.show(
      context: context,
      title: '清空本地缓存',
      content: '确定要清空存档"$archiveName"的本地缓存吗？\n\n清空后该存档将恢复为在线模式，需要重新拉取缓存才能使用本地模式。',
      confirmText: '清空',
      cancelText: '取消',
      isDangerous: false,
    );

    if (confirmed == true) {
      _clearArchiveCache(archiveId, archiveName);
    }
  }

  /// 清空指定存档的本地缓存
  Future<void> _clearArchiveCache(String archiveId, String archiveName) async {
    try {
      await _messageCacheService.initDatabase();

      // 清空指定存档的缓存数据
      await _messageCacheService.clearArchiveCache(
        sessionId: int.parse(widget.sessionId),
        archiveId: archiveId,
      );

      // 重新检查缓存状态，更新UI
      await _checkCacheForSaveSlots(_saveSlots);

      if (mounted) {
        setState(() {});
        CustomToast.show(
          context,
          message: '已清空存档"$archiveName"的本地缓存',
          type: ToastType.success
        );
      }

      debugPrint('[ChatArchivePage] ✅ 已清空存档缓存: $archiveId');
    } catch (e) {
      debugPrint('[ChatArchivePage] ❌ 清空存档缓存失败: $e');

      if (mounted) {
        CustomToast.show(
          context,
          message: '清空缓存失败: $e',
          type: ToastType.error
        );
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

      // 删除成功后，立即清理该存档的本地缓存数据
      await _clearArchiveCacheAfterDelete(saveSlotId);

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

  /// 删除存档后清理本地缓存
  Future<void> _clearArchiveCacheAfterDelete(String saveSlotId) async {
    try {
      await _messageCacheService.initDatabase();

      // 只删除特定存档的缓存数据，不影响其他存档
      await _messageCacheService.clearArchiveCache(
        sessionId: int.parse(widget.sessionId),
        archiveId: saveSlotId,
      );

      debugPrint('[ChatArchivePage] ✅ 已清理删除存档的本地缓存: $saveSlotId');
    } catch (e) {
      debugPrint('[ChatArchivePage] ❌ 清理删除存档的本地缓存失败: $e');
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

  Future<void> _showDeleteConfirmDialog(String saveSlotId, String saveName) async {
    final bool? confirmed = await ConfirmationDialog.show(
      context: context,
      title: '删除存档',
      content: '确定要删除存档"$saveName"吗？此操作不可恢复。',
      confirmText: '删除',
      cancelText: '取消',
      isDangerous: true,
    );

    if (confirmed == true) {
      _deleteSaveSlot(saveSlotId);
    }
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
        // 检查激活存档ID是否发生变化
        final bool archiveIdChanged = _initialActiveArchiveId != _currentActiveArchiveId;

        debugPrint('[ChatArchivePage] 退出存档页面');
        debugPrint('[ChatArchivePage] 进入时激活存档ID: $_initialActiveArchiveId');
        debugPrint('[ChatArchivePage] 退出时激活存档ID: $_currentActiveArchiveId');
        debugPrint('[ChatArchivePage] 激活存档ID是否变化: $archiveIdChanged');
        debugPrint('[ChatArchivePage] 是否拉取过缓存: $_hasPulledCache');

        // 如果激活存档ID发生变化或拉取过缓存，需要通知对话界面重新加载
        final bool needRefresh = archiveIdChanged || _archiveActivated || _hasPulledCache;
        Navigator.of(context).pop(needRefresh);
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
                                              // 缓存标识
                                              if (saveSlot['hasCache'] == true) ...[
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 6.w,
                                                    vertical: 2.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(4.r),
                                                    border: Border.all(
                                                      color: Colors.green,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    Icons.storage,
                                                    size: 12.sp,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
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
                                        if (isActive)
                                          PopupMenuItem(
                                            value: 'pull_cache',
                                            child: Row(
                                              children: [
                                                Icon(Icons.download, size: 18.sp, color: AppTheme.primaryColor),
                                                SizedBox(width: 8.w),
                                                Text('拉取缓存', style: TextStyle(color: AppTheme.primaryColor)),
                                              ],
                                            ),
                                          ),
                                        // 清空缓存选项（只有有缓存的存档才显示）
                                        if (saveSlot['hasCache'] == true)
                                          PopupMenuItem(
                                            value: 'clear_cache',
                                            child: Row(
                                              children: [
                                                Icon(Icons.clear_all, size: 18.sp, color: Colors.orange),
                                                SizedBox(width: 8.w),
                                                Text('清空缓存', style: TextStyle(color: Colors.orange)),
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
                                          case 'pull_cache':
                                            _showPullCacheDialog();
                                            break;
                                          case 'clear_cache':
                                            _showClearCacheConfirmDialog(
                                              saveSlot['id'],
                                              saveSlot['saveName'] ?? '未命名存档',
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
