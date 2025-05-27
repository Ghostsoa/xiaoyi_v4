import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_theme.dart';
import 'services/author_service.dart';
import 'world/my_world_book_page.dart';
import 'world/public_world_book_page.dart';
import 'guide/creation_guide_page.dart';
import 'guide/declaration_page.dart';
import 'material/my_material_page.dart';
import 'material/public_material_page.dart';
import 'character/create_character_page.dart';
import 'my_creation/my_creation_page.dart';
import 'draft/draft_page.dart';
import 'novel/create_novel_page.dart';

class CreateCenterPage extends StatefulWidget {
  const CreateCenterPage({super.key});

  @override
  State<CreateCenterPage> createState() => _CreateCenterPageState();
}

class _CreateCenterPageState extends State<CreateCenterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AuthorService _authorService = AuthorService();

  // 创作数据统计
  Map<String, int> _statistics = {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _showRefreshSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _authorService.getAuthorStats();
      if (mounted) {
        setState(() {
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // TODO: 处理错误
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryColor;
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;
    final background = AppTheme.background;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 页面标题和返回按钮
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: textPrimary,
                        size: 20.sp,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '创作中心',
                          style: TextStyle(
                            fontSize: AppTheme.titleSize,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20.sp), // 为了保持标题居中
                  ],
                ),
              ),
            ),

            // 统计概览
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '创作概览',
                          style: TextStyle(
                            fontSize: AppTheme.bodySize,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: _isRefreshing
                              ? null
                              : () async {
                                  setState(() => _isRefreshing = true);
                                  await _loadStatistics();
                                  setState(() {
                                    _isRefreshing = false;
                                    _showRefreshSuccess = true;
                                  });
                                  Future.delayed(const Duration(seconds: 2),
                                      () {
                                    if (mounted) {
                                      setState(
                                          () => _showRefreshSuccess = false);
                                    }
                                  });
                                },
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              if (_isRefreshing)
                                SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.w,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        primaryColor),
                                  ),
                                )
                              else if (_showRefreshSuccess)
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 16.sp,
                                  color: Colors.green,
                                )
                              else
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 16.sp,
                                  color: AppTheme.primaryColor,
                                ),
                              SizedBox(width: 4.w),
                              Text(
                                _isRefreshing
                                    ? '刷新中'
                                    : _showRefreshSuccess
                                        ? '刷新完成'
                                        : '刷新',
                                style: TextStyle(
                                  fontSize: AppTheme.captionSize,
                                  color: _showRefreshSuccess
                                      ? Colors.green
                                      : textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Wrap(
                      spacing: 24.w,
                      runSpacing: 16.h,
                      children: (_statistics.isEmpty
                              ? List.filled(7, 0).asMap().map(
                                    (i, _) => MapEntry(
                                        [
                                          '角色',
                                          '小说',
                                          '世界书',
                                          '模板',
                                          '词条',
                                          '获赞',
                                          '对话'
                                        ][i],
                                        0),
                                  )
                              : _statistics)
                          .entries
                          .map((entry) => SizedBox(
                                width: 60.w,
                                child: _buildStatItem(
                                  entry.key,
                                  entry.value,
                                  textPrimary,
                                  textSecondary,
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            // 创作指南
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreationGuidePage(),
                      ),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '创作指南',
                          style: TextStyle(
                            fontSize: AppTheme.captionSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 必读声明
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeclarationPage(),
                      ),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '必读声明',
                          style: TextStyle(
                            fontSize: AppTheme.captionSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 分割线
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 32.h),
                child: Divider(
                    height: 1.h, color: AppTheme.border.withOpacity(0.3)),
              ),
            ),

            // 创建角色和小说
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '选择一个开始创建',
                      style: TextStyle(
                        fontSize: AppTheme.bodySize,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateCharacterPage(),
                                ),
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_add,
                                  color: Colors.blue,
                                  size: 24.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '角色',
                                  style: TextStyle(
                                    fontSize: AppTheme.captionSize,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 1.w,
                          height: 24.h,
                          color: textSecondary.withOpacity(0.1),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreateNovelPage(),
                                ),
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.book,
                                  color: Colors.orange,
                                  size: 24.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '小说',
                                  style: TextStyle(
                                    fontSize: AppTheme.captionSize,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 分割线
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 32.h),
                child:
                    Divider(height: 1.h, color: textSecondary.withOpacity(0.1)),
              ),
            ),

            // 我的创建和草稿箱
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyCreationPage(),
                            ),
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          children: [
                            Icon(
                              Icons.grid_view,
                              color: Colors.purple,
                              size: 28.sp,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '我的创建',
                              style: TextStyle(
                                fontSize: AppTheme.captionSize,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '角色卡、小说',
                              style: TextStyle(
                                fontSize: AppTheme.smallSize,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1.w,
                      height: 40.h,
                      color: textSecondary.withOpacity(0.1),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DraftPage(),
                            ),
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          children: [
                            Icon(
                              Icons.edit_note,
                              color: Colors.green,
                              size: 28.sp,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '草稿箱',
                              style: TextStyle(
                                fontSize: AppTheme.captionSize,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '未完成的创作',
                              style: TextStyle(
                                fontSize: AppTheme.smallSize,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 分割线
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 32.h),
                child:
                    Divider(height: 1.h, color: textSecondary.withOpacity(0.1)),
              ),
            ),

            // 素材库
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 0),
                child: Text(
                  '素材库',
                  style: TextStyle(
                    fontSize: AppTheme.bodySize,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ),

            // 公共素材库
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PublicMaterialPage(),
                    ),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_shared,
                        color: Colors.blue,
                        size: 24.sp,
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '公共素材库',
                              style: TextStyle(
                                fontSize: AppTheme.captionSize,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '浏览公共创作素材',
                              style: TextStyle(
                                fontSize: AppTheme.smallSize,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: textSecondary.withOpacity(0.5),
                        size: 16.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 我的素材库
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyMaterialPage(),
                    ),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder,
                        color: Colors.cyan,
                        size: 24.sp,
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '我的素材库',
                              style: TextStyle(
                                fontSize: AppTheme.captionSize,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '管理你的创作素材',
                              style: TextStyle(
                                fontSize: AppTheme.smallSize,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: textSecondary.withOpacity(0.5),
                        size: 16.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 世界书标题
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 0),
                child: Text(
                  '世界书',
                  style: TextStyle(
                    fontSize: AppTheme.bodySize,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ),

            // 公共世界书
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PublicWorldBookPage()),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.public,
                        color: Colors.indigo,
                        size: 24.sp,
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '公共世界书',
                              style: TextStyle(
                                fontSize: AppTheme.captionSize,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '浏览公共世界观设定',
                              style: TextStyle(
                                fontSize: AppTheme.smallSize,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: textSecondary.withOpacity(0.5),
                        size: 16.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 我的世界书
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MyWorldBookPage()),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.public,
                        color: Colors.teal,
                        size: 24.sp,
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '我的世界书',
                              style: TextStyle(
                                fontSize: AppTheme.captionSize,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '创建你的世界观设定',
                              style: TextStyle(
                                fontSize: AppTheme.smallSize,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: textSecondary.withOpacity(0.5),
                        size: 16.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    int count,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          title,
          style: TextStyle(
            fontSize: AppTheme.smallSize,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}

class CreateSection {
  final String title;
  final IconData icon;
  final List<SectionItem> items;

  CreateSection({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class SectionItem {
  final String title;
  final IconData icon;

  SectionItem({
    required this.title,
    required this.icon,
  });
}

class RecentItem {
  final String title;
  final String type;
  final String lastEdit;
  final IconData icon;

  RecentItem({
    required this.title,
    required this.type,
    required this.lastEdit,
    required this.icon,
  });
}

class DraftItem {
  final String title;
  final String type;
  final String updateTime;
  final IconData icon;
  final double progress;

  DraftItem({
    required this.title,
    required this.type,
    required this.updateTime,
    required this.icon,
    required this.progress,
  });
}
