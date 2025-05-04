import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'character_service.dart';
import '../../../theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/file_service.dart';
import 'package:dio/dio.dart';

class CharacterManagementPage extends StatefulWidget {
  const CharacterManagementPage({super.key});

  @override
  State<CharacterManagementPage> createState() =>
      _CharacterManagementPageState();
}

class _CharacterManagementPageState extends State<CharacterManagementPage> {
  final CharacterService _characterService = CharacterService();
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _characters = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  CharacterStatus? _selectedStatus;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadCharacters(refresh: true);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    _currentPage = 1;
    await _loadCharacters(refresh: true);
    _refreshController.refreshCompleted();
  }

  Future<void> _onLoading() async {
    await _loadCharacters(refresh: false);
    _refreshController.loadComplete();
  }

  Future<void> _loadCharacters({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _characters = [];
      }
    });

    try {
      final response = await _characterService.getCharacters(
        page: _currentPage,
        pageSize: _pageSize,
        status: _selectedStatus,
        keyword: _searchKeyword,
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        final newItems = response.data['data']['items'] ?? [];
        final total = response.data['data']['total'] ?? 0;

        setState(() {
          if (refresh) {
            _characters = newItems;
          } else {
            _characters.addAll(newItems);
          }

          if (_characters.length >= total) {
            _refreshController.loadNoData();
          } else {
            _currentPage += 1;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：${response.data['msg'] ?? '未知错误'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败：$e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleCharacterStatus(int id, String currentStatus) async {
    final newStatus = currentStatus == 'private' ? 'published' : 'private';
    try {
      final response =
          await _characterService.updateCharacterStatus(id, newStatus);
      if (response.statusCode == 200 && response.data['code'] == 0) {
        setState(() {
          final index = _characters.indexWhere((item) => item['id'] == id);
          if (index != -1) {
            _characters[index]['status'] = newStatus;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('状态更新成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('状态更新失败：${response.data['msg'] ?? '未知错误'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('状态更新失败：$e')),
      );
    }
  }

  Future<void> _deleteCharacter(int id) async {
    try {
      final response = await _characterService.deleteCharacter(id);
      if (response.statusCode == 200 && response.data['code'] == 0) {
        setState(() {
          _characters.removeWhere((item) => item['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：${response.data['msg'] ?? '未知错误'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.background,
      child: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: SmartRefresher(
              controller: _refreshController,
              enablePullDown: true,
              enablePullUp: true,
              header: const WaterDropHeader(),
              footer: const ClassicFooter(),
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              child: _characters.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        '暂无数据',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: _characters.length,
                      itemBuilder: (context, index) {
                        final item = _characters[index];
                        return _buildCharacterCard(item);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索角色卡',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.r),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.r),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  _searchKeyword = value;
                  _loadCharacters(refresh: true);
                });
              },
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: DropdownButton<CharacterStatus>(
              value: _selectedStatus,
              hint:
                  Text('全部状态', style: TextStyle(color: AppTheme.textSecondary)),
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
              items: CharacterStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    CharacterService.getStatusName(status),
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (CharacterStatus? value) {
                setState(() {
                  _selectedStatus = value;
                  _loadCharacters(refresh: true);
                });
              },
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: () => _loadCharacters(refresh: true),
            tooltip: '刷新',
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard(Map<String, dynamic> character) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (character['coverUri'] != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: FutureBuilder<Response>(
                future: FileService().getFile(character['coverUri']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey[400],
                          size: 32.sp,
                        ),
                      ),
                    );
                  }
                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: MemoryImage(snapshot.data!.data),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            character['name'] ?? '',
                            style: TextStyle(
                              fontSize: AppTheme.titleSize,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '作者：${character['authorName'] ?? ''}',
                            style: TextStyle(
                              fontSize: AppTheme.captionSize,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _toggleCharacterStatus(
                        character['id'],
                        character['status'],
                      ),
                      child: Text(
                        CharacterService.getStatusName(
                            CharacterStatus.values.firstWhere(
                          (s) => s.name == character['status'],
                          orElse: () => CharacterStatus.private,
                        )),
                        style: TextStyle(
                          color: character['status'] == 'private'
                              ? AppTheme.textSecondary
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteCharacter(character['id']),
                    ),
                  ],
                ),
                if (character['description'] != null) ...[
                  SizedBox(height: 12.h),
                  Text(
                    character['description'],
                    style: TextStyle(
                      fontSize: AppTheme.bodySize,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (character['tags']?.isNotEmpty ?? false) ...[
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    children: (character['tags'] as List)
                        .map((tag) => Chip(
                              label: Text(
                                tag.toString(),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              backgroundColor: Colors.grey.withOpacity(0.1),
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
