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
import '../../widgets/custom_toast.dart';

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
  Map<String, num> _statistics = {};
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
                              ? List.filled(8, 0).asMap().map(
                                    (i, _) => MapEntry(
                                        [
                                          '角色',
                                          '小说',
                                          '世界书',
                                          '模板',
                                          '词条',
                                          '获赞',
                                          '对话',
                                          '待领时长'
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
    num count,
    Color textPrimary,
    Color textSecondary,
  ) {
    // 格式化数字显示：保留2位小数，>=100时显示整数
    String formattedCount;
    if (title == '待领时长') {
      if (count >= 100) {
        formattedCount = count.round().toString();
      } else {
        // 强制显示2位小数，确保即使是13.62这样的数值也能正确显示
        formattedCount = count.toStringAsFixed(2);
      }
    } else {
      formattedCount = count.toString();
    }

    return GestureDetector(
      onTap: title == '待领时长' && count > 0
          ? () => _showClaimDurationDialog(count)
          : null,
      child: Column(
        children: [
          Text(
            formattedCount,
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
      ),
    );
  }

  // 显示领取时长弹窗
  void _showClaimDurationDialog(num hours) {
    if (hours <= 0) return; // 如果没有可领取时长，不显示弹窗

    final double maxHours = hours.toDouble();

    // 显示一个固定选项的弹窗
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.primaryColor),
              SizedBox(width: 8.w),
              Expanded(child: Text('领取可用时长')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.sp),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.sp),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: AppTheme.primaryColor),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '您当前有 ${hours.toStringAsFixed(2)} 小时待领时长',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                '请选择要领取的时长：',
                style: TextStyle(
                  fontSize: AppTheme.captionSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(bottom: 8.h, left: 8.w, right: 8.w),
              child: Column(
                children: [
                  // 领取10小时
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: maxHours >= 10.0
                          ? () => _claimAndCloseDialog(10.0)
                          : null,
                      icon: Icon(Icons.access_time, size: 18.sp),
                      label: Text('领取 10.00 小时'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.sp),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        disabledBackgroundColor: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // 领取24小时 (1天)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: maxHours >= 24.0
                          ? () => _claimAndCloseDialog(24.0)
                          : null,
                      icon: Icon(Icons.av_timer, size: 18.sp),
                      label: Text('领取 24.00 小时 (1天)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.sp),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        disabledBackgroundColor: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // 领取168小时 (7天)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: maxHours >= 168.0
                          ? () => _claimAndCloseDialog(168.0)
                          : null,
                      icon: Icon(Icons.date_range, size: 18.sp),
                      label: Text('领取 168.00 小时 (7天)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.sp),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        disabledBackgroundColor: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // 领取全部 (仅当时长>10小时时可用)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: maxHours > 10.0
                          ? () => _claimAndCloseDialog(null)
                          : null,
                      icon: Icon(Icons.done_all, size: 18.sp),
                      label: Text('领取全部 (${hours.toStringAsFixed(2)}小时)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.sp),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        disabledBackgroundColor:
                            AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // 取消按钮
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.cancel_outlined,
                          color: AppTheme.textSecondary, size: 18.sp),
                      label: Text('取消',
                          style: TextStyle(color: AppTheme.textSecondary)),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.sp),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        );
      },
    );
  }

  // 领取并关闭弹窗
  Future<void> _claimAndCloseDialog(double? hours) async {
    // 先关闭弹窗
    Navigator.of(context).pop();

    try {
      // 请求API
      await _authorService.claimDuration(hours: hours);

      // 刷新统计信息
      await _loadStatistics();

      // 显示成功消息
      CustomToast.show(
        context,
        message: '领取成功',
        type: ToastType.success,
      );
    } catch (e) {
      // 显示错误消息
      CustomToast.show(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        type: ToastType.error,
      );
    }
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
