import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import '../pages/create/services/material_service.dart';
import 'custom_toast.dart';

enum TextSelectSource {
  myMaterial,
  publicMaterial,
}

enum TextSelectType {
  setting,
  prefix,
  suffix,
}

class TextEditorPage extends StatefulWidget {
  final String title;
  final String initialText;
  final String hintText;
  final TextSelectType? selectType; // 可选，如果提供则显示素材库选择功能
  final int? maxLength;

  const TextEditorPage({
    super.key,
    required this.title,
    required this.initialText,
    required this.hintText,
    this.selectType,
    this.maxLength,
  });

  @override
  State<TextEditorPage> createState() => _TextEditorPageState();
}

class _TextEditorPageState extends State<TextEditorPage> {
  late TextEditingController _textController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // 替换相关
  bool _isReplacing = false;
  List<Map<String, dynamic>> _replaceMatches = [];
  Set<int> _selectedMatches = {};
  bool _caseSensitive = false;

  // 撤销功能相关
  List<String> _textHistory = [];
  int _currentHistoryIndex = -1;
  bool _isUndoing = false;
  Timer? _debounceTimer;
  String _lastText = '';
  DateTime _lastInputTime = DateTime.now();


  
  // 素材库相关
  final MaterialService _materialService = MaterialService();
  bool _showMaterialPanel = false;
  TextSelectSource _currentSource = TextSelectSource.myMaterial;
  List<Map<String, dynamic>> _materials = [];
  bool _isLoadingMaterials = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);

    // 初始化撤销历史
    _addToHistory(widget.initialText);
    _lastText = widget.initialText;

    // 监听文本变化
    _textController.addListener(_onTextChanged);

    if (widget.selectType != null) {
      _loadMaterials();
    }
  }

  // 撤销功能相关方法
  void _onTextChanged() {
    if (_isUndoing) return;

    final currentText = _textController.text;
    final now = DateTime.now();

    // 取消之前的防抖定时器
    _debounceTimer?.cancel();

    // 如果距离上次输入超过2秒，或者文本变化很大，立即保存
    final timeDiff = now.difference(_lastInputTime).inMilliseconds;
    final textDiff = _calculateTextDifference(_lastText, currentText);

    if (timeDiff > 2000 || textDiff > 10) {
      _saveToHistory(currentText);
    } else {
      // 否则设置防抖定时器，1秒后保存
      _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
        _saveToHistory(currentText);
      });
    }

    _lastInputTime = now;
  }

  int _calculateTextDifference(String oldText, String newText) {
    // 简单的文本差异计算：字符数差异 + 编辑距离的简化版本
    final lengthDiff = (oldText.length - newText.length).abs();

    // 如果长度差异很大，直接返回
    if (lengthDiff > 10) return lengthDiff;

    // 计算不同字符的数量
    int diffCount = 0;
    final minLength = oldText.length < newText.length ? oldText.length : newText.length;

    for (int i = 0; i < minLength; i++) {
      if (oldText[i] != newText[i]) {
        diffCount++;
      }
    }

    return diffCount + lengthDiff;
  }

  void _saveToHistory(String text) {
    if (text != _lastText) {
      _addToHistory(text);
      _lastText = text;
    }
  }

  void _addToHistory(String text) {
    // 如果当前不在历史记录的末尾，删除后面的记录
    if (_currentHistoryIndex < _textHistory.length - 1) {
      _textHistory = _textHistory.sublist(0, _currentHistoryIndex + 1);
    }

    // 避免重复添加相同的文本
    if (_textHistory.isEmpty || _textHistory.last != text) {
      _textHistory.add(text);
      _currentHistoryIndex = _textHistory.length - 1;

      // 限制历史记录数量，避免内存过多占用
      if (_textHistory.length > 50) {
        _textHistory.removeAt(0);
        _currentHistoryIndex--;
      }
    }
  }

  void _undo() {
    if (_canUndo()) {
      _currentHistoryIndex--;
      _isUndoing = true;
      _textController.text = _textHistory[_currentHistoryIndex];
      _lastText = _textHistory[_currentHistoryIndex];
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
      _isUndoing = false;
      setState(() {});
    }
  }

  bool _canUndo() {
    return _currentHistoryIndex > 0;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _searchController.dispose();
    _replaceController.dispose();
    _textFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 加载素材库数据
  Future<void> _loadMaterials() async {
    if (widget.selectType == null) return;
    
    setState(() => _isLoadingMaterials = true);
    
    try {
      final response = _currentSource == TextSelectSource.myMaterial
          ? await _materialService.getMaterials(
              page: 1,
              pageSize: 50,
              type: _getMaterialType(),
            )
          : await _materialService.getPublicMaterials(
              page: 1,
              pageSize: 50,
              type: _getMaterialType(),
            );
      
      if (mounted) {
        setState(() {
          _materials = List<Map<String, dynamic>>.from(response['items']);
        });
      }
    } catch (e) {
      _showToast('加载素材失败: $e', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoadingMaterials = false);
      }
    }
  }

  String _getMaterialType() {
    if (widget.selectType == null) return 'template';
    return switch (widget.selectType!) {
      TextSelectType.setting => 'template',
      TextSelectType.prefix => 'prefix',
      TextSelectType.suffix => 'suffix',
    };
  }

  // 查找替换匹配项
  void _findReplaceMatches() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _replaceMatches.clear();
        _selectedMatches.clear();
      });
      return;
    }

    final text = _textController.text;
    final matches = <Map<String, dynamic>>[];

    if (_caseSensitive) {
      int index = text.indexOf(query);
      while (index != -1) {
        matches.add(_createMatchInfo(text, index, query.length));
        index = text.indexOf(query, index + 1);
      }
    } else {
      final lowerText = text.toLowerCase();
      final lowerQuery = query.toLowerCase();
      int index = lowerText.indexOf(lowerQuery);
      while (index != -1) {
        matches.add(_createMatchInfo(text, index, query.length));
        index = lowerText.indexOf(lowerQuery, index + 1);
      }
    }

    setState(() {
      _replaceMatches = matches;
      _selectedMatches.clear();
    });
  }

  // 创建匹配项信息，包含前后文本
  Map<String, dynamic> _createMatchInfo(String text, int startIndex, int length) {
    const contextLength = 20; // 前后文本长度

    final beforeStart = (startIndex - contextLength).clamp(0, text.length);
    final afterEnd = (startIndex + length + contextLength).clamp(0, text.length);

    return {
      'index': startIndex,
      'length': length,
      'match': text.substring(startIndex, startIndex + length),
      'before': text.substring(beforeStart, startIndex),
      'after': text.substring(startIndex + length, afterEnd),
      'fullContext': text.substring(beforeStart, afterEnd),
    };
  }



  // 替换选中的匹配项
  void _replaceSelected() {
    if (_selectedMatches.isEmpty || _replaceController.text.isEmpty) return;

    // 在替换前保存当前文本到历史记录
    _saveToHistory(_textController.text);

    final replaceText = _replaceController.text;
    String text = _textController.text;

    // 从后往前替换，避免索引变化
    final sortedIndices = _selectedMatches.toList()..sort((a, b) => b.compareTo(a));

    for (final index in sortedIndices) {
      if (index < _replaceMatches.length) {
        final match = _replaceMatches[index];
        final startIndex = match['index'] as int;
        final length = match['length'] as int;

        text = text.replaceRange(startIndex, startIndex + length, replaceText);
      }
    }

    _textController.text = text;

    // 清空输入框
    _searchController.clear();
    _replaceController.clear();

    // 替换后也保存到历史记录
    _saveToHistory(_textController.text);

    // 重新查找
    _findReplaceMatches();

    _showToast('已替换 ${sortedIndices.length} 个匹配项', type: ToastType.success);
  }





  void _showToast(String message, {ToastType type = ToastType.info}) {
    if (!mounted) return;
    CustomToast.show(context, message: message, type: type);
  }

  // 构建顶部工具栏
  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.border.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor.withOpacity(0.05),
                    blurRadius: 4.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.textPrimary,
                size: 18.sp,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(width: 16.w),
                // 字数统计
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppTheme.border.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_textController.text.length}${widget.maxLength != null ? '/${widget.maxLength}' : ''} 字',
                    style: TextStyle(
                      color: widget.maxLength != null && _textController.text.length > widget.maxLength!
                          ? Colors.red
                          : AppTheme.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 保存按钮
          GestureDetector(
            onTap: () => Navigator.of(context).pop(_textController.text),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppTheme.buttonGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.save,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMaterialList() {
    if (_isLoadingMaterials) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (_materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 48.sp,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: 8.h),
            Text(
              '暂无素材',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _materials.length,
      itemBuilder: (context, index) {
        final material = _materials[index];
        return _buildMaterialItem(material);
      },
    );
  }

  Widget _buildMaterialItem(Map<String, dynamic> material) {
    return InkWell(
      onTap: () {
        final content = material['metadata'] ?? '';
        final currentText = _textController.text;

        // 在当前光标位置插入内容
        final selection = _textController.selection;
        final newText = currentText.replaceRange(
          selection.start,
          selection.end,
          content,
        );

        _textController.text = newText;
        _textController.selection = TextSelection.collapsed(
          offset: selection.start + content.length as int,
        );

        _showToast('已插入素材内容', type: ToastType.success);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: AppTheme.border.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 素材图标
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Icon(
                Icons.description_outlined,
                size: 16.sp,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material['description'] ?? '无描述',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '@${material['author_name'] ?? '未知作者'}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // 添加按钮
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Icon(
                Icons.add,
                size: 14.sp,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建文本编辑器
  Widget _buildTextEditor() {
    return TextField(
      controller: _textController,
      focusNode: _textFocusNode,
      scrollController: _scrollController,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        fillColor: Colors.transparent,
        hintStyle: TextStyle(
          color: AppTheme.textSecondary.withOpacity(0.5),
          fontSize: 16.sp,
        ),
      ),
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16.sp,
        height: 1.5,
      ),
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      maxLength: widget.maxLength,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
        return null;
      },
      onChanged: (value) {
        setState(() {});
        if (_isReplacing) {
          _findReplaceMatches();
        }
      },
    );
  }



  // 构建底部功能面板
  Widget _buildBottomFunctionPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          top: BorderSide(
            color: AppTheme.border.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 功能按钮行
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                // 撤销按钮
                _buildCompactFunctionButton(
                  icon: Icons.undo,
                  label: '撤销',
                  isActive: false,
                  onTap: _undo,
                  isEnabled: _canUndo(),
                ),
                SizedBox(width: 8.w),
                // 替换按钮
                _buildCompactFunctionButton(
                  icon: Icons.find_replace,
                  label: '替换',
                  isActive: _isReplacing,
                  onTap: () => setState(() {
                    if (_isReplacing) {
                      _isReplacing = false;
                    } else {
                      _isReplacing = true;
                      _showMaterialPanel = false;
                    }
                  }),
                ),
                if (widget.selectType != null) ...[
                  SizedBox(width: 8.w),
                  // 素材库按钮
                  _buildCompactFunctionButton(
                    icon: Icons.library_books,
                    label: '素材库',
                    isActive: _showMaterialPanel,
                    onTap: () => setState(() {
                      if (_showMaterialPanel) {
                        _showMaterialPanel = false;
                      } else {
                        _showMaterialPanel = true;
                        _isReplacing = false;
                      }
                    }),
                  ),
                ],
              ],
            ),
          ),
          // 展开的功能区域
          if (_isReplacing) _buildCompactReplacePanel(),
          if (_showMaterialPanel && widget.selectType != null) _buildCompactMaterialPanel(),
        ],
      ),
    );
  }


  // 构建紧凑功能按钮
  Widget _buildCompactFunctionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    VoidCallback? onTap,
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(6.r),
          border: !isActive ? Border.all(color: AppTheme.border.withOpacity(0.3)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: isActive
                  ? Colors.white
                  : isEnabled
                      ? AppTheme.textSecondary
                      : AppTheme.textSecondary.withOpacity(0.5),
            ),
            SizedBox(width: 3.w),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : isEnabled
                        ? AppTheme.textSecondary
                        : AppTheme.textSecondary.withOpacity(0.5),
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建紧凑替换面板
  Widget _buildCompactReplacePanel() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.border.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 输入区域
          Row(
            children: [
              // 查找输入框
              Expanded(
                child: Container(
                  height: 32.h,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '查找...',
                      prefixIcon: Icon(Icons.search, size: 16.sp),
                      filled: true,
                      fillColor: AppTheme.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      hintStyle: TextStyle(fontSize: 12.sp),
                    ),
                    style: TextStyle(fontSize: 12.sp),
                    onChanged: (value) => _findReplaceMatches(),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // 替换输入框
              Expanded(
                child: Container(
                  height: 32.h,
                  child: TextField(
                    controller: _replaceController,
                    decoration: InputDecoration(
                      hintText: '替换为...',
                      prefixIcon: Icon(Icons.find_replace, size: 16.sp),
                      filled: true,
                      fillColor: AppTheme.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      hintStyle: TextStyle(fontSize: 12.sp),
                    ),
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
              ),
            ],
          ),
          if (_replaceMatches.isNotEmpty) ...[
            SizedBox(height: 8.h),
            // 匹配信息行
            Row(
              children: [
                Text(
                  '找到 ${_replaceMatches.length} 个匹配项',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10.sp,
                  ),
                ),
                if (_selectedMatches.isNotEmpty) ...[
                  Text(
                    ' (已选中 ${_selectedMatches.length} 个)',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 6.h),
            // 操作按钮行
            Row(
              children: [
                // 全选按钮
                _buildCompactActionButton(
                  label: _selectedMatches.length == _replaceMatches.length ? '取消全选' : '全选',
                  onTap: _toggleSelectAll,
                  isPrimary: false,
                ),
                SizedBox(width: 8.w),
                // 大小写敏感
                _buildCompactActionButton(
                  label: _caseSensitive ? 'Aa' : 'aa',
                  onTap: () => setState(() {
                    _caseSensitive = !_caseSensitive;
                    _findReplaceMatches();
                  }),
                  isPrimary: false,
                ),
                const Spacer(),
                // 替换选中
                _buildCompactActionButton(
                  label: '替换选中',
                  onTap: _selectedMatches.isNotEmpty && _replaceController.text.isNotEmpty ? _replaceSelected : null,
                  isPrimary: true,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // 匹配列表
            Container(
              height: 100.h,
              child: ListView.builder(
                itemCount: _replaceMatches.length,
                itemBuilder: (context, index) => _buildCompactReplaceItem(index),
              ),
            ),
          ],
        ],
      ),
    );
  }


  // 构建悬浮素材库面板
  Widget _buildFloatingMaterialPanel() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.border.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 素材库头部
          Row(
            children: [
              Text(
                '素材库',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              // 源选择器
              Row(
                children: [
                  _buildCompactSourceButton(
                    title: '我的',
                    source: TextSelectSource.myMaterial,
                  ),
                  SizedBox(width: 6.w),
                  _buildCompactSourceButton(
                    title: '公开',
                    source: TextSelectSource.publicMaterial,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // 素材列表
          Container(
            height: 100.h,
            child: _buildMaterialList(),
          ),
        ],
      ),
    );
  }

  // 构建紧凑操作按钮
  Widget _buildCompactActionButton({
    required String label,
    required VoidCallback? onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: onTap != null
              ? (isPrimary ? AppTheme.primaryColor : AppTheme.cardBackground)
              : AppTheme.textSecondary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4.r),
          border: !isPrimary && onTap != null
              ? Border.all(color: AppTheme.border.withOpacity(0.3))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onTap != null
                ? (isPrimary ? Colors.white : AppTheme.textPrimary)
                : AppTheme.textSecondary,
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 全选/取消全选
  void _toggleSelectAll() {
    setState(() {
      if (_selectedMatches.length == _replaceMatches.length) {
        _selectedMatches.clear();
      } else {
        _selectedMatches = Set.from(List.generate(_replaceMatches.length, (index) => index));
      }
    });
  }

  // 构建紧凑替换项
  Widget _buildCompactReplaceItem(int index) {
    final match = _replaceMatches[index];
    final isSelected = _selectedMatches.contains(index);

    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : AppTheme.border.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 复选框
          GestureDetector(
            onTap: () => setState(() {
              if (isSelected) {
                _selectedMatches.remove(index);
              } else {
                _selectedMatches.add(index);
              }
            }),
            child: Container(
              width: 16.w,
              height: 16.w,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(3.r),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.border,
                  width: 1,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 10.sp, color: Colors.white)
                  : null,
            ),
          ),
          SizedBox(width: 6.w),
          // 匹配内容
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  // 前文
                  TextSpan(
                    text: match['before'],
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                  // 匹配文本
                  TextSpan(
                    text: match['match'],
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      backgroundColor: Colors.yellow.withOpacity(0.3),
                    ),
                  ),
                  // 后文
                  TextSpan(
                    text: match['after'],
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 构建紧凑素材库面板
  Widget _buildCompactMaterialPanel() {
    return _buildFloatingMaterialPanel();
  }

  // 构建紧凑源按钮
  Widget _buildCompactSourceButton({
    required String title,
    required TextSelectSource source,
  }) {
    final bool isSelected = _currentSource == source;
    return GestureDetector(
      onTap: () {
        if (_currentSource != source) {
          setState(() => _currentSource = source);
          _loadMaterials();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.border.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            // 主要文本编辑区域
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.w),
                child: _buildTextEditor(),
              ),
            ),
            // 底部功能面板
            _buildBottomFunctionPanel(),
          ],
        ),
      ),
    );
  }
}
