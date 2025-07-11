import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xiaoyi_v4/pages/message/widgets/character_session_list.dart';
import 'package:xiaoyi_v4/pages/message/widgets/novel_session_list.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_toast.dart';
import 'notifications_page.dart';
import 'message_service.dart';

class MessagePage extends StatefulWidget {
  final int unreadCount;

  const MessagePage({
    super.key,
    this.unreadCount = 0,
  });

  @override
  State<MessagePage> createState() => MessagePageState();
}

class MessagePageState extends State<MessagePage> with WidgetsBindingObserver {
  final MessageService _messageService = MessageService();

  final GlobalKey<CharacterSessionListState> _characterListKey =
      GlobalKey<CharacterSessionListState>();
  final GlobalKey<NovelSessionListState> _novelListKey =
      GlobalKey<NovelSessionListState>();

  late int _unreadCount;
  bool _isCharacterMode = true;
  bool _isMultiSelectMode = false;
  final Set<int> _selectedIds = <int>{};

  @override
  void initState() {
    super.initState();
    _unreadCount = widget.unreadCount;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Add refresh method to fix the error in MainPage
  void refresh() {
    if (_isCharacterMode) {
      _characterListKey.currentState?.onRefresh();
    } else {
      _novelListKey.currentState?.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 6.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '消息',
                    style: AppTheme.headingStyle,
                  ),
                  Row(
                    children: [
                      if (!_isMultiSelectMode) ...[
                        _buildIconButton(
                          icon: Icons.notifications_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsPage(),
                              ),
                            );
                          },
                          showBadge: _unreadCount > 0,
                          badgeCount: _unreadCount,
                        ),
                        SizedBox(width: 8.w),
                        _buildIconButton(
                          icon: Icons.delete_outline,
                          onTap: () {
                            setState(() {
                              _isMultiSelectMode = true;
                              _selectedIds.clear();
                            });
                          },
                        ),
                      ] else ...[
                        TextButton(
                          onPressed: _deleteSelectedSessions,
                          child: Text(
                            '删除',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isMultiSelectMode = false;
                              _selectedIds.clear();
                            });
                          },
                          child: Text(
                            '取消',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 8.h),
              child: Row(
                children: [
                  _buildCategoryButton(
                    title: '角色',
                    isSelected: _isCharacterMode,
                    onTap: () {
                      if (!_isCharacterMode) {
                        setState(() {
                          _isCharacterMode = true;
                          _isMultiSelectMode = false;
                          _selectedIds.clear();
                        });
                      }
                    },
                  ),
                  SizedBox(width: 8.w),
                  _buildCategoryButton(
                    title: '小说',
                    isSelected: !_isCharacterMode,
                    onTap: () {
                      if (_isCharacterMode) {
                        setState(() {
                          _isCharacterMode = false;
                          _isMultiSelectMode = false;
                          _selectedIds.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 16.h),
              child: Text(
                '最近的对话',
                style: AppTheme.secondaryStyle,
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _isCharacterMode ? 0 : 1,
                children: [
                  CharacterSessionList(
                    key: _characterListKey,
                    isMultiSelectMode: _isMultiSelectMode,
                    selectedIds: _selectedIds,
                    onSelectionChanged: (sessionId) {
                      setState(() {
                        if (_selectedIds.contains(sessionId)) {
                          _selectedIds.remove(sessionId);
                        } else {
                          _selectedIds.add(sessionId);
                        }
                      });
                    },
                    onShowMenu: (context, session) {
                      _showSessionMenu(context, session);
                    },
                  ),
                  NovelSessionList(
                    key: _novelListKey,
                    isMultiSelectMode: _isMultiSelectMode,
                    selectedIds: _selectedIds,
                    onSelectionChanged: (sessionId) {
                      setState(() {
                        if (_selectedIds.contains(sessionId)) {
                          _selectedIds.remove(sessionId);
                        } else {
                          _selectedIds.add(sessionId);
                        }
                      });
                    },
                    onShowMenu: (context, session) {
                      _showSessionMenu(context, session);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppTheme.cardBackground.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Icon(
                icon,
                color: AppTheme.textPrimary,
                size: 20.sp,
              ),
            ),
          ),
          if (showBadge)
            Positioned(
              right: -4.w,
              top: -4.h,
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                ),
                constraints: BoxConstraints(
                  minWidth: 16.w,
                  minHeight: 16.w,
                ),
                child: Center(
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
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

  Widget _buildCategoryButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: AppTheme.buttonGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: const GradientRotation(0.4),
                )
              : null,
          color: isSelected ? null : AppTheme.cardBackground.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.buttonGradient.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.border.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSelectedSessions() async {
    if (_selectedIds.isEmpty) return;

    CustomToast.show(
      context,
      message: '正在删除...',
      type: ToastType.info,
      duration: const Duration(seconds: 10),
    );

    try {
      final List<int> sessionIdList = _selectedIds.toList();

      final Map<String, dynamic> result = _isCharacterMode
          ? await _messageService.batchDeleteCharacterSessions(sessionIdList)
          : await _messageService.batchDeleteNovelSessions(sessionIdList);

      if (_isCharacterMode) {
        _characterListKey.currentState?.onRefresh();
      } else {
        _novelListKey.currentState?.onRefresh();
      }

      setState(() {
        _isMultiSelectMode = false;
        _selectedIds.clear();
      });

      CustomToast.dismiss();

      if (mounted) {
        CustomToast.show(
          context,
          message: result['msg'],
          type: result['success'] ? ToastType.success : ToastType.error,
        );
      }
    } catch (e) {
      CustomToast.dismiss();
      if (mounted) {
        CustomToast.show(
          context,
          message: '删除失败: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _showSessionMenu(BuildContext context, Map<String, dynamic> session,
      [Offset? position]) {
    final int sessionId = session['id'] as int;
    final String sessionName = _isCharacterMode
        ? (session['name'] ?? '未命名会话')
        : (session['title'] ?? '未命名小说');

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect positionRect = position != null
        ? RelativeRect.fromRect(
            Rect.fromPoints(position, position),
            Offset.zero & overlay.size,
          )
        : RelativeRect.fromLTRB(overlay.size.width / 3, overlay.size.height / 3,
            overlay.size.width / 3, overlay.size.height / 3);

    showMenu(
      context: context,
      position: positionRect,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      constraints: BoxConstraints(
        minWidth: 120.w,
        maxWidth: 180.w,
      ),
      items: [
        PopupMenuItem(
          value: 'rename',
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          height: 40.h,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_outlined,
                size: 16.sp,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 8.w),
              Text(
                '重命名',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          height: 40.h,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline,
                size: 16.sp,
                color: Colors.red,
              ),
              SizedBox(width: 8.w),
              Text(
                '删除',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'rename') {
        _showRenameDialog(sessionId, sessionName);
      } else if (value == 'delete') {
        _showDeleteConfirmDialog(sessionId);
      }
    });
  }

  void _showRenameDialog(int sessionId, String currentName) {
    final TextEditingController controller =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Text(
            '重命名',
            style: AppTheme.titleStyle,
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: '请输入新名称',
              hintStyle:
                  TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '取消',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  _renameSession(sessionId, newName);
                }
                Navigator.of(context).pop();
              },
              child: Text(
                '确定',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _renameSession(int sessionId, String newName) async {
    try {
      final result = _isCharacterMode
          ? await _messageService.renameSession(sessionId, newName)
          : await _messageService.renameNovelSession(sessionId, newName);

      if (result['success'] == true) {
        CustomToast.show(context, message: '重命名成功', type: ToastType.success);
        if (_isCharacterMode) {
          _characterListKey.currentState?.onRefresh();
        } else {
          _novelListKey.currentState?.onRefresh();
        }
      } else {
        CustomToast.show(context,
            message: result['msg'] ?? '重命名失败', type: ToastType.error);
      }
    } catch (e) {
      CustomToast.show(context, message: '重命名失败: $e', type: ToastType.error);
    }
  }

  void _showDeleteConfirmDialog(int sessionId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Text(
            '确认删除',
            style: AppTheme.titleStyle,
          ),
          content: Text(
            '确定要删除这个会话吗？此操作不可恢复。',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '取消',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSingleSession(sessionId);
              },
              child: Text(
                '删除',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSingleSession(int sessionId) async {
    try {
      CustomToast.show(
        context,
        message: '正在删除...',
        type: ToastType.info,
        duration: const Duration(seconds: 3),
      );

      final Map<String, dynamic> result = _isCharacterMode
          ? await _messageService.batchDeleteCharacterSessions([sessionId])
          : await _messageService.batchDeleteNovelSessions([sessionId]);

      if (_isCharacterMode) {
        _characterListKey.currentState?.onRefresh();
      } else {
        _novelListKey.currentState?.onRefresh();
      }

      if (mounted) {
        CustomToast.show(
          context,
          message: result['msg'],
          type: result['success'] ? ToastType.success : ToastType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '删除失败: $e',
          type: ToastType.error,
        );
      }
    }
  }
}
