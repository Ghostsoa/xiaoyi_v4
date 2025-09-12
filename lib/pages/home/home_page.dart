import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:typed_data';
import 'dart:async'; // 导入Timer
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/file_service.dart';
import 'services/home_service.dart';
import 'package:shimmer/shimmer.dart';


import 'pages/hot_items_page.dart';
import 'pages/item_detail_page.dart';
import 'pages/recommend_items_page.dart';
import 'pages/all_items_page.dart';
import 'pages/tag_items_page.dart';
import 'pages/favorites_page.dart';
import 'pages/preferences_page.dart';
import 'pages/author_updates_page.dart';
import 'pages/category_selection_page.dart';
import '../../widgets/draw_cards_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // 添加WidgetsBindingObserver
  final HomeService _homeService = HomeService();
  final FileService _fileService = FileService();
  final RefreshController _refreshController = RefreshController();

  // 添加定时器
  Timer? _pushCheckTimer;
  bool _isVisible = true; // 跟踪页面是否可见

  bool _isLoading = true;
  bool _showAllTags = false;

  // 独立加载状态跟踪
  bool _hotItemsLoading = true;
  bool _recommendItemsLoading = true;
  bool _hotTagsLoading = true;

  List<dynamic> _hotItems = [];
  List<dynamic> _recommendItems = [];
  List<String> _hotTags = [];

  // 图片缓存Map
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, bool> _loadingImages = {};
  bool _forceReload = false; // 是否强制重新加载图片

  // 新增最新发布相关变量
  List<dynamic> _latestItems = [];
  bool _isLoadingLatest = true;
  int _latestPage = 1;
  final int _latestPageSize = 10;
  bool _hasMoreLatest = true;

  int _authorUpdateCount = 0;

  @override
  void initState() {
    super.initState();

    // 异步独立加载各个部分，不等待
    _loadHotItems();
    _loadRecommendItems();
    _loadHotTags();
    _loadLatestItems(); // 加载最新发布
    _checkAuthorUpdates();

    // 初始化页面可见性监听
    WidgetsBinding.instance.addObserver(this);

    // 启动推送检查定时器
    _startPushCheckTimer();

    // 异步检查分区偏好设置
    _checkCategoryPreference();
  }

  @override
  void dispose() {
    // 取消定时器
    _pushCheckTimer?.cancel();
    // 移除页面可见性监听
    WidgetsBinding.instance.removeObserver(this);
    _refreshController.dispose();
    super.dispose();
  }

  // 处理应用生命周期状态变化
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用回到前台，立即检查一次推送并重启定时器
      _isVisible = true;
      _checkAuthorUpdates();
      _startPushCheckTimer();
    } else if (state == AppLifecycleState.paused) {
      // 应用进入后台，停止定时器
      _isVisible = false;
      _pushCheckTimer?.cancel();
    }
    super.didChangeAppLifecycleState(state);
  }

  // 启动推送检查定时器
  void _startPushCheckTimer() {
    // 取消现有定时器
    _pushCheckTimer?.cancel();

    // 创建新定时器，每10秒检查一次
    _pushCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isVisible && mounted) {
        _checkAuthorUpdates();
      }
    });
  }

  Future<void> _loadItemImage(String? coverUri,
      {bool forceReload = false}) async {
    if (coverUri == null ||
        _loadingImages[coverUri] == true ||
        (!forceReload && _imageCache.containsKey(coverUri))) {
      return;
    }

    _loadingImages[coverUri] = true;
    try {
      final result = await _fileService.getFile(coverUri);
      if (mounted) {
        setState(() {
          _imageCache[coverUri] = result.data;
          _loadingImages[coverUri] = false;
        });
      }
    } catch (e) {
      _loadingImages[coverUri] = false;
    }
  }

  // 加载热门内容
  Future<void> _loadHotItems() async {
    if (!mounted) return;

    try {
      final result = await _homeService.getHotItems();
      if (mounted && result['code'] == 0) {
        setState(() {
          _hotItems = result['data']['items'] ?? [];
          _hotItemsLoading = false;
        });

        // 预加载图片
        for (final item in _hotItems) {
          if (item['cover_uri'] != null) {
            _loadItemImage(item['cover_uri'], forceReload: _forceReload);
          }
          // 预加载群聊角色头像
          if (item['item_type'] == 'group_chat_card' && item['role_group'] != null) {
            final roles = item['role_group']['roles'] as List<dynamic>? ?? [];
            for (final role in roles) {
              if (role['avatarUri'] != null) {
                _loadItemImage(role['avatarUri'], forceReload: _forceReload);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('加载热门内容失败: $e');
      if (mounted) {
        setState(() {
          _hotItemsLoading = false;
        });
      }
    }
  }

  // 加载推荐内容
  Future<void> _loadRecommendItems() async {
    if (!mounted) return;

    try {
      final result = await _homeService.getRecommendItems();
      if (mounted && result['code'] == 0) {
        setState(() {
          _recommendItems = result['data']['items'] ?? [];
          _recommendItemsLoading = false;
        });

        // 预加载图片
        for (final item in _recommendItems) {
          if (item['cover_uri'] != null) {
            _loadItemImage(item['cover_uri'], forceReload: _forceReload);
          }
          // 预加载群聊角色头像
          if (item['item_type'] == 'group_chat_card' && item['role_group'] != null) {
            final roles = item['role_group']['roles'] as List<dynamic>? ?? [];
            for (final role in roles) {
              if (role['avatarUri'] != null) {
                _loadItemImage(role['avatarUri'], forceReload: _forceReload);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('加载推荐内容失败: $e');
      if (mounted) {
        setState(() {
          _recommendItemsLoading = false;
        });
      }
    }
  }

  // 加载热门标签
  Future<void> _loadHotTags() async {
    if (!mounted) return;

    try {
      final result = await _homeService.getHotTags();
      if (mounted && result['code'] == 0) {
        setState(() {
          _hotTags = List<String>.from(result['data'] ?? []);
          _hotTagsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载热门标签失败: $e');
      if (mounted) {
        setState(() {
          _hotTagsLoading = false;
        });
      }
    }
  }

  // 保留原来的_loadData方法用于刷新
  Future<void> _loadData() async {
    if (!mounted) return;

    if (!_isLoading) {
      setState(() {
        _isLoading = true;
        // 重置加载状态
        _hotItemsLoading = true;
        _recommendItemsLoading = true;
        _hotTagsLoading = true;
      });
    }

    try {
      // 并行加载数据
      final results = await Future.wait([
        _homeService.getHotItems(),
        _homeService.getRecommendItems(),
        _homeService.getHotTags(),
      ]);

      if (mounted) {
        setState(() {
          _hotItems = results[0]['data']['items'] ?? [];
          _recommendItems = results[1]['data']['items'] ?? [];
          _hotTags = List<String>.from(results[2]['data'] ?? []);
          _isLoading = false;
          // 更新加载状态标志
          _hotItemsLoading = false;
          _recommendItemsLoading = false;
          _hotTagsLoading = false;
        });

        // 预加载所有图片
        for (final item in [..._hotItems, ..._recommendItems]) {
          if (item['cover_uri'] != null) {
            _loadItemImage(item['cover_uri'], forceReload: _forceReload);
          }
          // 预加载群聊角色头像
          if (item['item_type'] == 'group_chat_card' && item['role_group'] != null) {
            final roles = item['role_group']['roles'] as List<dynamic>? ?? [];
            for (final role in roles) {
              if (role['avatarUri'] != null) {
                _loadItemImage(role['avatarUri'], forceReload: _forceReload);
              }
            }
          }
        }
        // 重置强制重新加载标志
        _forceReload = false;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // 不显示任何错误提示，用户可以下拉刷新重试
      }
    }
  }

  void _onRefresh() async {
    setState(() {
      _forceReload = true; // 下拉刷新时强制重新加载图片
    });
    try {
      // 同时刷新所有内容
      await Future.wait([
        _loadData(),
        _loadLatestItems(refresh: true),
        _checkAuthorUpdates()
      ]);

      if (mounted) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      if (mounted) {
        _refreshController.refreshFailed();
        // 错误通过刷新控制器的状态显示，不额外显示toast
      }
    }
  }

  // 添加refresh方法供外部调用，实现静默刷新
  void refresh() {
    if (mounted) {
      // 静默加载数据，不更新加载状态
      _loadSilently();
    }
  }

  // 静默加载数据，不显示加载状态
  Future<void> _loadSilently() async {
    if (!mounted) return;

    try {
      // 并行加载数据
      final results = await Future.wait([
        _homeService.getHotItems(),
        _homeService.getRecommendItems(),
        _homeService.getHotTags(),
        _homeService.getAllItems(
          page: 1,
          pageSize: _latestPageSize,
          sortBy: 'new', // 按最新排序
        ),
      ]);

      if (mounted) {
        final newHotItems = results[0]['data']['items'] ?? [];
        final newRecommendItems = results[1]['data']['items'] ?? [];
        final newHotTags = List<String>.from(results[2]['data'] ?? []);
        final newLatestItems = results[3]['data']['items'] ?? [];

        // 检查数据是否发生变化
        bool dataChanged = false;

        if (_hotItems.length != newHotItems.length ||
            _recommendItems.length != newRecommendItems.length ||
            _hotTags.length != newHotTags.length ||
            _latestItems.length != newLatestItems.length) {
          dataChanged = true;
        }

        // 如果数据发生变化，更新UI
        if (dataChanged) {
          setState(() {
            _hotItems = newHotItems;
            _recommendItems = newRecommendItems;
            _hotTags = newHotTags;
            _latestItems = newLatestItems;
            _latestPage = 1; // 重置最新发布页码
            _hasMoreLatest = newLatestItems.length >= _latestPageSize;
          });

          // 预加载新图片
          for (final item in [
            ...newHotItems,
            ...newRecommendItems,
            ...newLatestItems
          ]) {
            if (item['cover_uri'] != null) {
              _loadItemImage(item['cover_uri'], forceReload: false);
            }
            // 预加载群聊角色头像
            if (item['item_type'] == 'group_chat_card' && item['role_group'] != null) {
              final roles = item['role_group']['roles'] as List<dynamic>? ?? [];
              for (final role in roles) {
                if (role['avatarUri'] != null) {
                  _loadItemImage(role['avatarUri'], forceReload: false);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('静默刷新数据失败: $e');
      // 静默刷新出错时不显示错误提示
    }
  }

  // 加载最新发布内容
  Future<void> _loadLatestItems({bool refresh = false}) async {
    if (!mounted) return;

    if (refresh) {
      setState(() {
        _latestPage = 1;
        _hasMoreLatest = true;
      });
    }

    if (_latestPage == 1) {
      setState(() => _isLoadingLatest = true);
    }

    try {
      final result = await _homeService.getAllItems(
        page: _latestPage,
        pageSize: _latestPageSize,
        sortBy: 'new', // 按最新排序
      );

      if (mounted) {
        final newItems = result['data']['items'] ?? [];
        setState(() {
          if (_latestPage == 1) {
            _latestItems = newItems;
          } else {
            _latestItems.addAll(newItems);
          }
          _isLoadingLatest = false;
          _hasMoreLatest = newItems.length >= _latestPageSize;
        });

        // 预加载图片
        for (final item in newItems) {
          if (item['cover_uri'] != null) {
            _loadItemImage(item['cover_uri'], forceReload: _forceReload);
          }
          // 预加载群聊角色头像
          if (item['item_type'] == 'group_chat_card' && item['role_group'] != null) {
            final roles = item['role_group']['roles'] as List<dynamic>? ?? [];
            for (final role in roles) {
              if (role['avatarUri'] != null) {
                _loadItemImage(role['avatarUri'], forceReload: _forceReload);
              }
            }
          }
        }

        // 打印调试信息
        debugPrint('最新内容加载完成，共${_latestItems.length}项');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLatest = false);
        // 显示错误提示
        debugPrint('加载最新内容失败: $e');
      }
    }
  }

  // 加载更多最新内容
  Future<void> _loadMoreLatestItems() async {
    if (!_hasMoreLatest || _isLoadingLatest) return;

    _latestPage++;
    await _loadLatestItems();

    if (mounted) {
      if (_hasMoreLatest) {
        _refreshController.loadComplete();
      } else {
        _refreshController.loadNoData();
      }
    }
  }



  Future<void> _checkAuthorUpdates() async {
    if (!mounted) return;

    try {
      final count = await _homeService.getUnreadAuthorUpdatesCount();
      if (mounted) {
        setState(() {
          _authorUpdateCount = count;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('检查作者更新失败: $e');
      }
    }
  }

  /// 检查分区偏好设置
  Future<void> _checkCategoryPreference() async {
    try {
      // 先检查本地是否已经完成过分区选择
      final prefs = await SharedPreferences.getInstance();
      final bool categorySelectionCompleted = prefs.getBool('category_selection_completed') ?? false;

      if (categorySelectionCompleted) {
        // 已经选择过，直接返回
        return;
      }

      // 没有本地标记，请求后端检查当前分区设置
      final result = await _homeService.getUserPreferences();
      if (result['code'] == 0 && result['data'] != null) {
        final dynamic preferredCategoryData = result['data']['preferred_category'];

        // 处理 preferred_category 字段，支持字符串和数组两种格式
        List<String> preferredCategories = ['all'];
        if (preferredCategoryData != null) {
          if (preferredCategoryData is List) {
            preferredCategories = List<String>.from(preferredCategoryData);
          } else if (preferredCategoryData is String) {
            preferredCategories = [preferredCategoryData];
          }
        }

        // 如果分区为空或者只包含"all"，才跳转到选择界面
        if (preferredCategories.isEmpty ||
            (preferredCategories.length == 1 && preferredCategories.first == 'all')) {
          if (mounted) {
            final selectionResult = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategorySelectionPage(),
              ),
            );

            // 如果用户完成了选择，刷新大厅数据
            if (selectionResult == true) {
              _onRefresh();
            }
          }
        } else {
          // 后端已有具体分区设置，直接保存本地标记，不跳转
          await prefs.setBool('category_selection_completed', true);
        }
      }
    } catch (e) {
      // 检查失败，静默处理
      debugPrint('检查分区偏好失败: $e');
    }
  }



  /// 显示抽卡弹窗
  void _showDrawCardsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DrawCardsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          enablePullDown: true,
          header: CustomHeader(
            builder: (BuildContext context, RefreshStatus? mode) {
              Widget body;
              if (mode == RefreshStatus.idle) {
                body = Text('下拉刷新',
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp));
              } else if (mode == RefreshStatus.refreshing) {
                body = Shimmer.fromColors(
                  baseColor: Colors.white70,
                  highlightColor: Colors.white,
                  child: Text(
                    '正在刷新...',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                );
              } else if (mode == RefreshStatus.failed) {
                body = Text('刷新失败',
                    style: TextStyle(color: Colors.amber, fontSize: 14.sp));
              } else if (mode == RefreshStatus.canRefresh) {
                body = Text('松开刷新',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp));
              } else {
                body = Text('刷新完成',
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp));
              }
              return SizedBox(
                height: 55.0,
                child: Center(child: body),
              );
            },
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 顶部按钮区域（三个按钮并排）
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左侧按钮区域
                      Expanded(
                        flex: 2, // 占据四分之二(即二分之一)的空间
                        child: SizedBox(
                          height: 120.h,
                          child: Column(
                            children: [
                              // 随机抽卡按钮 (占据2/3高度)
                              SizedBox(
                                height: 76.h,
                                child: GestureDetector(
                                  onTap: () {
                                    _showDrawCardsDialog();
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF6A5ACD), // 星光紫
                                          Color(0xFF9370DB), // 中等兰花紫
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF6A5ACD).withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.all(16.w),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.casino,
                                          color: Colors.white,
                                          size: 24.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          '随机抽卡',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 8.h),

                              // 发现更多按钮 (占据1/3高度)
                              SizedBox(
                                height: 36.h,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AllItemsPage(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: AppTheme.primaryGradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryGradient.first
                                              .withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '浏览全部AI角色',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.white,
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
                      ),
                      SizedBox(width: 12.w),
                      // 右侧两个按钮的容器
                      Expanded(
                        flex: 1, // 占据四分之一的空间
                        child: Column(
                          children: [
                            // 收藏按钮
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const FavoritesPage(),
                                  ),
                                );
                              },
                              child: Container(
                                height: 54.h,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber.shade700,
                                      Colors.amber.shade500
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: Colors.white,
                                      size: 22.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      '收藏',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            // 偏好按钮
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PreferencesPage(),
                                  ),
                                );
                              },
                              child: Container(
                                height: 54.h,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blueAccent.shade700,
                                      Colors.blueAccent.shade400
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      color: Colors.white,
                                      size: 22.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      '偏好',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 今日热门
              SliverToBoxAdapter(
                child: _buildItemSectionSimple(
                  '今日热门',
                  '今日最受欢迎的AI角色',
                  _hotItems,
                  AppTheme.textPrimary,
                  AppTheme.textSecondary,
                  AppTheme.primaryColor,
                  isHotSection: true,
                  isLoading: _hotItemsLoading,
                ),
              ),

              // 热门标签
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: AppTheme.accentGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Icon(
                                  Icons.tag_rounded,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                '热门标签',
                                style: AppTheme.gradientTextStyle(
                                  colors: AppTheme.accentGradient,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showAllTags = !_showAllTags;
                              });
                            },
                            child: Row(
                              children: [
                                Text(
                                  _showAllTags ? '收起' : '查看全部',
                                  style: AppTheme.gradientActionStyle,
                                ),
                                ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return LinearGradient(
                                      colors: AppTheme.primaryGradient,
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ).createShader(bounds);
                                  },
                                  child: Icon(
                                    _showAllTags
                                        ? Icons.keyboard_arrow_up
                                        : Icons.chevron_right_rounded,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '点击标签探索更多相关角色',
                        style: AppTheme.gradientTextStyle(
                          colors: [Colors.white60, Colors.white38],
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _hotTagsLoading
                          ? _buildTagsSkeleton()
                          : _showAllTags
                              ? _buildTagsWrapLayout()
                              : _buildTagsScrollLayout(),
                    ],
                  ),
                ),
              ),

              // 每日推荐
              SliverToBoxAdapter(
                child: _buildItemSectionSimple(
                  '每日推荐',
                  '根据您的兴趣智能推荐的角色',
                  _recommendItems,
                  AppTheme.textPrimary,
                  AppTheme.textSecondary,
                  AppTheme.primaryColor,
                  isHotSection: false,
                  isLoading: _recommendItemsLoading,
                ),
              ),

              // 最新发布标题 (固定标题)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 50.h, // 减小高度
                  maxHeight: 50.h, // 减小高度
                  child: Container(
                    color: AppTheme.background,
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h), // 减小上边距
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: AppTheme.accentGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Icon(
                                Icons.new_releases_rounded,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '最新发布',
                              style: AppTheme.gradientTextStyle(
                                colors: AppTheme.accentGradient,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AllItemsPage(),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                '查看全部分类',
                                style: AppTheme.gradientActionStyle,
                              ),
                              ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return LinearGradient(
                                    colors: AppTheme.primaryGradient,
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ).createShader(bounds);
                                },
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 最新发布内容
              _isLoadingLatest && _latestItems.isEmpty
                  ? SliverToBoxAdapter(
                      child: Container(
                        height: 300.h,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: _buildLatestSkeleton(),
                      ),
                    )
                  : SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // 到达底部时加载更多
                            if (index == _latestItems.length + 1 - 1 &&
                                _hasMoreLatest &&
                                !_isLoadingLatest) {
                              _loadMoreLatestItems();
                            }

                            // 在第0个位置插入关注作者更新通知卡片
                            if (index == 0) {
                              return _buildFollowingAuthorsCard();
                            }

                            // 调整索引以适应关注作者卡片
                            final itemIndex = index - 1;
                            if (itemIndex >= _latestItems.length) {
                              return const SizedBox();
                            }

                            final item = _latestItems[itemIndex];
                            return _buildLatestItemCard(item);
                          },
                          childCount:
                              _latestItems.length + 1, // +1 是为了添加关注作者更新通知卡片
                        ),
                      ),
                    ),

              // 添加底部加载更多指示器
              SliverToBoxAdapter(
                child: _isLoadingLatest && _latestItems.isNotEmpty
                    ? Container(
                        height: 60.h,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      )
                    : !_hasMoreLatest && _latestItems.isNotEmpty
                        ? Container(
                            height: 60.h,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            alignment: Alignment.center,
                            child: Text(
                              '-- 已经到底了 --',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14.sp,
                              ),
                            ),
                          )
                        : const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 简化版本的项目部分构建
  Widget _buildItemSectionSimple(
      String title,
      String subtitle,
      List<dynamic> items,
      Color textPrimary,
      Color textSecondary,
      Color primaryColor,
      {required bool isHotSection, required bool isLoading}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isHotSection
                            ? Icons.local_fire_department_rounded
                            : Icons.recommend_rounded,
                        color: isHotSection
                            ? Colors.redAccent
                            : Colors.orangeAccent,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        title,
                        style: AppTheme.gradientTextStyle(
                          colors: AppTheme.primaryGradient,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      if (isHotSection) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HotItemsPage(),
                          ),
                        );
                      } else if (title == '每日推荐') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecommendItemsPage(),
                          ),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          '查看全部',
                          style: AppTheme.gradientActionStyle,
                        ),
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              colors: AppTheme.primaryGradient,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds);
                          },
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: AppTheme.gradientTextStyle(
                  colors: [Colors.white60, Colors.white38],
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        isLoading
            ? _buildItemsSkeleton(isHotSection)
            : items.isEmpty
                ? _buildEmptyState(title, textSecondary)
                : SizedBox(
                    height: 180.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(left: 12.w),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildItemCard(
                          item,
                          textPrimary,
                          isHotItem: isHotSection,
                          index: index,
                        );
                      },
                    ),
                  ),
      ],
    );
  }

  Widget _buildItemsSkeleton(bool isHotSection) {
    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: 12.w),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            width: 120.w,
            margin: EdgeInsets.only(right: 12.w),
            child: Stack(
              children: [
                // 主卡片
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Shimmer.fromColors(
                    baseColor: AppTheme.cardBackground,
                    highlightColor: AppTheme.cardBackground.withOpacity(0.5),
                    child: Container(
                      width: 120.w,
                      height: 150.w,
                      color: AppTheme.cardBackground,
                    ),
                  ),
                ),
                // 标题渐变遮罩层
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(12.w, 32.h, 12.w, 12.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Shimmer.fromColors(
                      baseColor: AppTheme.cardBackground,
                      highlightColor: AppTheme.cardBackground.withOpacity(0.5),
                      child: Container(
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                  ),
                ),
                // 热门标签
                if (isHotSection && index < 3)
                  Positioned(
                    left: 8.w,
                    top: 8.h,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: [
                          const Color(0xFFFF6B6B),
                          const Color(0xFFFFAB4C),
                          const Color(0xFFFFD93D),
                        ][index]
                            .withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Shimmer.fromColors(
                        baseColor: AppTheme.cardBackground,
                        highlightColor:
                            AppTheme.cardBackground.withOpacity(0.5),
                        child: Container(
                          width: 32.w,
                          height: 12.h,
                          color: AppTheme.cardBackground,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, Color textSecondary) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(vertical: 24.h),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              title == '今日热门'
                  ? Icons.local_fire_department_outlined
                  : Icons.recommend_outlined,
              size: 32.sp,
              color: title == '今日热门'
                  ? Colors.redAccent.withOpacity(0.5)
                  : Colors.orangeAccent.withOpacity(0.5),
            ),
            SizedBox(height: 8.h),
            Text(
              '暂无${title.replaceAll('今日', '').replaceAll('每日', '')}内容',
              style: AppTheme.gradientTextStyle(
                colors: [Colors.white60, Colors.white38],
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, Color textPrimary,
      {bool isHotItem = false, int? index}) {
    final String? coverUri = item['cover_uri'];
    final bool isGroupChat = item['item_type'] == 'group_chat_card';
    final List<dynamic> roles = isGroupChat && item['role_group'] != null 
        ? (item['role_group']['roles'] as List<dynamic>? ?? [])
        : [];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailPage(item: item),
          ),
        );
      },
      child: Container(
        width: 120.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: coverUri != null
                  ? _buildCoverImage(coverUri, item['title'], roles: roles, isGroupChat: isGroupChat)
                  : _buildEmptyCover(item['title'], roles: roles, isGroupChat: isGroupChat),
            ),
            if (isHotItem && index != null && index < 3)
              Positioned(
                left: 8.w,
                top: 8.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: [
                      const Color(0xFFFF6B6B),
                      const Color(0xFFFFAB4C),
                      const Color(0xFFFFD93D),
                    ][index]
                        .withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'TOP ${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(String coverUri, String? title, {List<dynamic>? roles, bool isGroupChat = false}) {
    if (_imageCache.containsKey(coverUri)) {
      return Stack(
        children: [
          Image.memory(
            _imageCache[coverUri]!,
            width: 120.w,
            height: 150.w,
            fit: BoxFit.cover,
          ),
          _buildTitleOverlay(title),
          // 群聊卡片在右上角显示简化的角色头像
          if (isGroupChat && roles != null && roles.isNotEmpty)
            _buildSimpleRoleAvatars(roles),
        ],
      );
    }

    if (_loadingImages[coverUri] != true) {
      _loadItemImage(coverUri);
    }

    return Shimmer.fromColors(
      baseColor: AppTheme.cardBackground,
      highlightColor: AppTheme.cardBackground.withOpacity(0.5),
      child: Container(
        width: 120.w,
        height: 150.w,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  Widget _buildEmptyCover(String? title, {List<dynamic>? roles, bool isGroupChat = false}) {
    return Container(
      width: 120.w,
      height: 150.w,
      color: AppTheme.cardBackground,
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.image_outlined,
              color: AppTheme.textSecondary,
            ),
          ),
          _buildTitleOverlay(title, isDark: false),
          // 群聊卡片在右上角显示简化的角色头像
          if (isGroupChat && roles != null && roles.isNotEmpty)
            _buildSimpleRoleAvatars(roles),
        ],
      ),
    );
  }

  Widget _buildTitleOverlay(String? title, {bool isDark = true}) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 32.h, 12.w, 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Text(
          title ?? '',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // 构建简化版角色头像（用于今日热门和每日推荐）
  Widget _buildSimpleRoleAvatars(List<dynamic> roles) {
    if (roles.isEmpty) return const SizedBox();

    return Positioned(
      right: 8.w,
      top: 8.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 第一个角色头像（无边框）
            SizedBox(
              width: 16.w,
              height: 16.h,
              child: ClipOval(
                child: _buildRoleAvatar(roles[0]['avatarUri']),
              ),
            ),
            // 直接显示+N（如果有多个角色）
            if (roles.length > 1) ...[
              SizedBox(width: 4.w),
              Text(
                '+${roles.length - 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 构建群聊角色头像堆叠显示（用于最新发布）
  Widget _buildRoleAvatarsStack(List<dynamic> roles) {
    if (roles.isEmpty) return const SizedBox();

    const int maxVisibleAvatars = 3;
    final int visibleCount = roles.length > maxVisibleAvatars ? maxVisibleAvatars : roles.length;
    final int remainingCount = roles.length > maxVisibleAvatars ? roles.length - maxVisibleAvatars : 0;

    return Positioned(
      right: 8.w,
      bottom: 8.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 堆叠头像
            SizedBox(
              width: (visibleCount * 12.w) + 12.w, // 计算总宽度，考虑重叠
              height: 20.h,
              child: Stack(
                children: [
                  for (int i = 0; i < visibleCount; i++)
                    Positioned(
                      right: i * 12.w, // 每个头像向右偏移12w，创造重叠效果
                      child: SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: ClipOval(
                          child: _buildRoleAvatar(roles[i]['avatarUri']),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // 直接显示+N（如果有剩余角色）
            if (remainingCount > 0) ...[
              SizedBox(width: 4.w),
              Text(
                '+$remainingCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 构建单个角色头像
  Widget _buildRoleAvatar(String? avatarUri) {
    if (avatarUri == null) {
      return Container(
        color: AppTheme.cardBackground,
        child: Icon(
          Icons.person,
          color: AppTheme.textSecondary,
          size: 16.sp,
        ),
      );
    }

    if (_imageCache.containsKey(avatarUri)) {
      return Image.memory(
        _imageCache[avatarUri]!,
        fit: BoxFit.cover,
        width: 24.w,
        height: 24.h,
      );
    }

    // 如果图片未加载，先加载图片
    if (_loadingImages[avatarUri] != true) {
      _loadItemImage(avatarUri);
    }

    return Container(
      color: AppTheme.cardBackground,
      child: Icon(
        Icons.person,
        color: AppTheme.textSecondary,
        size: 16.sp,
      ),
    );
  }

  Widget _buildTagsScrollLayout() {
    return SizedBox(
      height: 36.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _hotTags.length,
        itemBuilder: (context, index) {
          final tag = _hotTags[index];
          // 为每个标签选择一个渐变色
          final List<Color> tagGradient = _getTagGradient(index);

          return TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutCubic,
            builder: (context, double value, child) {
              return Transform.translate(
                offset: Offset(20 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TagItemsPage(
                      tag: tag,
                    ),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.only(right: 10.w),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: tagGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: tagGradient.first.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTagsWrapLayout() {
    return Wrap(
      spacing: 10.w,
      runSpacing: 12.h,
      children: [
        ..._hotTags.asMap().entries.map((entry) {
          final index = entry.key;
          final tag = entry.value;
          final List<Color> tagGradient = _getTagGradient(index);

          return TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 30)),
            curve: Curves.easeOutCubic,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TagItemsPage(
                      tag: tag,
                    ),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tagGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: tagGradient.first.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // 为标签生成渐变色
  List<Color> _getTagGradient(int index) {
    // 定义几种渐变组合
    final gradients = [
      [
        const Color(0xFF4158D0),
        const Color(0xFF6B8DD6),
        const Color(0xFFC850C0)
      ], // 蓝紫
      [
        const Color(0xFFFF416C),
        const Color(0xFFFF5E62),
        const Color(0xFFFF7C48)
      ], // 红橙
      [
        const Color(0xFF43CEA2),
        const Color(0xFF54C8AC),
        const Color(0xFF28B485)
      ], // 绿
      [
        const Color(0xFF584BD2),
        const Color(0xFF896CDF),
        const Color(0xFFB892FF)
      ], // 紫色
      [
        const Color(0xFF4776E6),
        const Color(0xFF5886E7),
        const Color(0xFF8E54E9)
      ], // 蓝紫
      [
        const Color(0xFFFFB347),
        const Color(0xFFFFCC33),
        const Color(0xFFFFD700)
      ], // 金黄
    ];

    // 使用标签索引来选择渐变，确保同一标签始终获得相同的渐变
    int gradientIndex = index % gradients.length;
    return gradients[gradientIndex];
  }

  Widget _buildTagsSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardBackground,
      highlightColor: AppTheme.cardBackground.withOpacity(0.5),
      child: SizedBox(
        height: 36.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 8,
          itemBuilder: (context, index) {
            return Container(
              width: 70.w,
              height: 32.h,
              margin: EdgeInsets.only(right: 10.w),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(18.r),
              ),
            );
          },
        ),
      ),
    );
  }

  // 构建最新发布区域的骨架屏
  Widget _buildLatestSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardBackground,
      highlightColor: AppTheme.cardBackground.withOpacity(0.5),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12.r),
            ),
          );
        },
      ),
    );
  }

  

  // 构建关注作者更新通知卡片
  Widget _buildFollowingAuthorsCard() {
    return GestureDetector(
      onTap: () {
        // 处理点击事件，跳转到关注作者页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AuthorUpdatesPage(),
          ),
        );
        // 移除返回后刷新的逻辑，因为现在有定时器了
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppTheme.accentGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGradient.first.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 添加红点提醒
            if (_authorUpdateCount > 0)
              Positioned(
                top: 10.h,
                right: 10.w,
                child: Container(
                  width: 16.w,
                  height: 16.w,
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _authorUpdateCount > 9
                      ? Text(
                          '9+',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : (_authorUpdateCount > 1
                          ? Text(
                              '$_authorUpdateCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null),
                ),
              ),

            Positioned(
              right: -10,
              bottom: -10,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 80.sp,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                      // 添加红点指示器
                      if (_authorUpdateCount > 0)
                        Container(
                          margin: EdgeInsets.only(left: 5.w, bottom: 15.h),
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '作者动态推送',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _authorUpdateCount > 0
                        ? '$_authorUpdateCount条未读推送'
                        : '暂无未读推送',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14.sp,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Text(
                      '查看推送',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建最新内容卡片
  Widget _buildLatestItemCard(Map<String, dynamic> item) {
    final String? coverUri = item['cover_uri'];
    final bool isGroupChat = item['item_type'] == 'group_chat_card';
    final List<dynamic> roles = isGroupChat && item['role_group'] != null 
        ? (item['role_group']['roles'] as List<dynamic>? ?? [])
        : [];
    final DateTime createdAt =
        DateTime.parse(item['created_at'] ?? DateTime.now().toIso8601String());
    final Duration difference = DateTime.now().difference(createdAt);

    // 计算时间显示
    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes}分钟前';
    } else {
      timeAgo = '刚刚';
    }

    // 判断是否为当天发布
    final bool isNewToday = DateTime.now().day == createdAt.day &&
        DateTime.now().month == createdAt.month &&
        DateTime.now().year == createdAt.year;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailPage(item: item),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Stack(
            children: [
              // 封面图片作为整个卡片的背景
              Positioned.fill(
                child: coverUri != null
                    ? _buildLatestCoverImage(coverUri)
                    : Container(
                        color: AppTheme.cardBackground.withOpacity(0.5),
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: AppTheme.textSecondary,
                            size: 32.sp,
                          ),
                        ),
                      ),
              ),

              // 发布时间标签
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Colors.white,
                        size: 12.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 新发布标签 - 仅当天发布的内容显示
              if (isNewToday)
                Positioned(
                  top: 8.h,
                  left: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurpleAccent,
                          Colors.purpleAccent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurpleAccent.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fiber_new_rounded,
                          color: Colors.white,
                          size: 12.sp,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '新发布',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 内容部分 - 底部渐变背景
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 150.h, // 卡片底部区域高度
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.5, 1.0], // 从底部到中间有实色背景，中间往上渐变透明
                      colors: [
                        Colors.black.withOpacity(0.8), // 底部较深的背景色
                        Colors.black.withOpacity(0.6), // 中间区域半透明
                        Colors.transparent, // 顶部完全透明
                      ],
                    ),
                  ),
                ),
              ),

              // 内容文字区域
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['title'] ?? '未命名',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white, // 文字颜色改为白色以便在深色背景上显示
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      if (item['description'] != null)
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 36.h),
                          child: Text(
                            item['description'],
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white70, // 次要文字使用半透明白色
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 12.sp,
                            color: Colors.white70, // 图标使用半透明白色
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              '@${item['author_name'] ?? '未知作者'}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white70, // 作者名使用半透明白色
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 群聊卡片显示角色头像
              if (isGroupChat && roles.isNotEmpty)
                _buildRoleAvatarsStack(roles),
            ],
          ),
        ),
      ),
    );
  }

  // 为最新发布构建封面图片
  Widget _buildLatestCoverImage(String coverUri) {
    if (_imageCache.containsKey(coverUri)) {
      return Image.memory(
        _imageCache[coverUri]!,
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
      );
    }

    if (_loadingImages[coverUri] != true) {
      _loadItemImage(coverUri);
    }

    return Shimmer.fromColors(
      baseColor: AppTheme.cardBackground,
      highlightColor: AppTheme.cardBackground.withOpacity(0.5),
      child: Container(
        color: AppTheme.cardBackground,
      ),
    );
  }
}

// 固定标题委托类
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
