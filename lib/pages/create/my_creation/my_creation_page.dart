import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/app_theme.dart';
import '../services/characte_service.dart';
import '../../../services/file_service.dart';
import '../../../widgets/custom_toast.dart';
import '../character/create_character_page.dart';
import '../../../pages/character_chat/pages/character_init_page.dart';

class MyCreationPage extends StatefulWidget {
  const MyCreationPage({super.key});

  @override
  State<MyCreationPage> createState() => _MyCreationPageState();
}

class _MyCreationPageState extends State<MyCreationPage> {
  int _selectedIndex = 0; // 0: 角色卡, 1: 小说
  String _status = 'published'; // published: 公开, private: 私密
  final _characterService = CharacterService();

  bool _isLoading = false;
  List<Map<String, dynamic>> _characterList = [];
  int _total = 0;
  final int _currentPage = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_selectedIndex == 1) return; // 暂时不处理小说列表

    setState(() => _isLoading = true);

    try {
      final response = await _characterService.getCharacterList(
        page: _currentPage,
        pageSize: _pageSize,
        status: _status,
      );

      if (response['code'] == 0) {
        setState(() {
          _characterList =
              List<Map<String, dynamic>>.from(response['data']['items']);
          _total = response['data']['total'];
        });
      } else {
        _showToast('加载失败：${response['message']}', type: ToastType.error);
      }
    } catch (e) {
      _showToast('加载失败：$e', type: ToastType.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {ToastType type = ToastType.info}) {
    if (!mounted) return;
    CustomToast.show(context, message: message, type: type);
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary;
    final background = AppTheme.background;
    final primaryColor = AppTheme.primaryColor;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
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
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: textPrimary,
                        size: 18.sp,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '我的创建',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 32.w),
                ],
              ),
            ),

            // 切换按钮和状态过滤
            Container(
              margin: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧类型切换
                  Row(
                    children: [
                      _buildSwitchButton('角色卡', 0, primaryColor, textPrimary),
                      SizedBox(width: 24.w),
                      _buildSwitchButton('小说', 1, primaryColor, textPrimary),
                    ],
                  ),

                  // 右侧状态过滤
                  Row(
                    children: [
                      _buildStatusButton(
                          '公开', 'published', primaryColor, textPrimary),
                      SizedBox(width: 16.w),
                      _buildStatusButton(
                          '私密', 'private', primaryColor, textPrimary),
                    ],
                  ),
                ],
              ),
            ),

            // 内容区域
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedIndex == 0
                      ? _buildCharacterList()
                      : _buildNovelList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchButton(
      String text, int index, Color primaryColor, Color textPrimary) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        _loadData();
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? primaryColor : textPrimary.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildStatusButton(
      String text, String status, Color primaryColor, Color textPrimary) {
    final isSelected = _status == status;
    return GestureDetector(
      onTap: () {
        setState(() => _status = status);
        _loadData();
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? primaryColor : textPrimary.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildCharacterList() {
    if (_characterList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 48.sp,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              '暂无角色卡',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      itemCount: _characterList.length,
      itemBuilder: (context, index) {
        final character = _characterList[index];
        return Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppTheme.border.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面图片
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: character['coverUri'] != null
                    ? FutureBuilder(
                        future: FileService().getFile(character['coverUri']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildShimmerImage();
                          }
                          if (!snapshot.hasData || snapshot.hasError) {
                            return Container(
                              width: 96.h,
                              height: 96.h,
                              color: AppTheme.cardBackground,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: AppTheme.textSecondary.withOpacity(0.5),
                              ),
                            );
                          }
                          return Image.memory(
                            snapshot.data!.data,
                            width: 96.h,
                            height: 96.h,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Container(
                        width: 96.h,
                        height: 96.h,
                        color: AppTheme.cardBackground,
                        child: Icon(
                          Icons.image_outlined,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                      ),
              ),

              SizedBox(width: 12.w),

              // 内容区域
              Expanded(
                child: SizedBox(
                  height: 96.h,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 第一行：名字和按钮
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              character['name'] ?? '',
                              style: TextStyle(
                                fontSize: 15.sp, // 稍微减小字体
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 编辑和删除按钮
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CreateCharacterPage(
                                        character: character,
                                        isEdit: true,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 16.sp,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              // 添加对话按钮
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CharacterInitPage(
                                        characterData: {
                                          'id': character['id'],
                                          'item_id': character['id'],
                                          'cover_uri': character['coverUri'],
                                          'init_fields':
                                              character['initFields'],
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Icon(
                                    Icons.chat_outlined,
                                    size: 16.sp,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              GestureDetector(
                                onTap: () {
                                  _showDeleteConfirmDialog(character);
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 16.sp,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),

                      // 第二行：简介
                      Expanded(
                        child: Text(
                          character['description'] ?? '',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppTheme.textPrimary.withOpacity(0.8),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // 第三行：标签
                      if (character['tags'] != null &&
                          (character['tags'] as List).isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          (character['tags'] as List)
                              .map((tag) => '#$tag')
                              .join(' '),
                          style: TextStyle(
                            fontSize: 11.sp, // 减小字体
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      SizedBox(height: 2.h),
                      // 第四行：作者和时间
                      Text(
                        '@${character['authorName'] ?? ''} · ${_formatTime(character['createdAt'])}',
                        style: TextStyle(
                          fontSize: 11.sp, // 减小字体
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerImage() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 96.h,
        height: 96.h,
        color: Colors.white,
      ),
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final time = DateTime.parse(timeStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}年前';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}月前';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildNovelList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 48.sp,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            '暂无小说',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(Map<String, dynamic> character) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('确认删除'),
          content: Text('确定要删除角色"${character['name']}"吗？此操作不可恢复。'),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                '删除',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteCharacter(character['id'].toString());
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCharacter(String id) async {
    setState(() => _isLoading = true);

    try {
      final response = await _characterService.deleteCharacter(id);
      if (response['code'] == 0) {
        _showToast('删除成功', type: ToastType.success);
        _loadData(); // 重新加载列表
      } else {
        _showToast('删除失败: ${response['message']}', type: ToastType.error);
      }
    } catch (e) {
      _showToast('删除失败: $e', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
