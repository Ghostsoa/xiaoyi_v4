import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';

typedef FetchInspiration = Future<List<String>> Function();
typedef FetchMemories = Future<Map<String, dynamic>> Function({String? cursor, int limit});
typedef CreateMemory = Future<void> Function({required String saveSlotId, required String title, required String content});
typedef UpdateMemory = Future<void> Function({required String saveSlotId, required String memoryId, String? title, String? content});
typedef DeleteMemory = Future<void> Function({required String saveSlotId, required String memoryId});
typedef InsertMemoryRelative = Future<void> Function({required String anchorMemoryId, required String position, required String title, required String content});

class ChatInputArea extends StatefulWidget {
  final TextEditingController messageController;
  final FocusNode focusNode;

  final bool isLocalMode;
  final bool isSending;
  final bool isResetting;
  final bool isSearchMode;
  final String currentInputText;
  final List<Map<String, dynamic>> searchResults;
  final void Function(String msgId) onTapSearchResult;

  final VoidCallback onMenuToggle; // parent can ignore if not needed
  final VoidCallback onSendTap;
  final VoidCallback onStopGenerationTap;
  final VoidCallback onToggleSearchMode;
  final ValueChanged<String>? onInlineSearch;

  final VoidCallback onOpenCharacterPanel;
  final VoidCallback onOpenChatSettings;
  final Future<void> Function() onResetSession;
  final VoidCallback onOpenArchive;

  final FetchInspiration fetchInspirationSuggestions;
  final FetchMemories fetchMemories;
  final CreateMemory createMemory;
  final UpdateMemory updateMemory;
  final DeleteMemory deleteMemory;
  final InsertMemoryRelative insertMemoryRelative;

  const ChatInputArea({
    super.key,
    required this.messageController,
    required this.focusNode,
    required this.isLocalMode,
    required this.isSending,
    required this.isResetting,
    required this.isSearchMode,
    required this.currentInputText,
    required this.searchResults,
    required this.onTapSearchResult,
    required this.onMenuToggle,
    required this.onSendTap,
    required this.onStopGenerationTap,
    required this.onToggleSearchMode,
    required this.onInlineSearch,
    required this.onOpenCharacterPanel,
    required this.onOpenChatSettings,
    required this.onResetSession,
    required this.onOpenArchive,
    required this.fetchInspirationSuggestions,
    required this.fetchMemories,
    required this.createMemory,
    required this.updateMemory,
    required this.deleteMemory,
    required this.insertMemoryRelative,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

enum _AssistPanelType { none, phrases, inspirations, search }

class _ChatInputAreaState extends State<ChatInputArea>
    with TickerProviderStateMixin {
  // input focus helpers
  bool _isInputFocused = false;

  // unified assist panel
  _AssistPanelType _panelType = _AssistPanelType.none;
  bool _isLoadingInspiration = false;
  List<String> _inspirationSuggestions = [];

  // quick phrases & memories
  List<Map<String, String>> _phrases = [];
  final TextEditingController _phraseNameController = TextEditingController();
  final TextEditingController _phraseContentController = TextEditingController();

  bool _isMemoriesTab = false;
  bool _isLoadingMemories = false;
  List<Map<String, dynamic>> _memories = [];
  String _nextCursor = '';
  String _currentSaveSlotId = '';

  // inline phrase create
  bool _showPhraseCreator = false;
  final TextEditingController _newPhraseNameController = TextEditingController();
  final TextEditingController _newPhraseContentController = TextEditingController();
  final FocusNode _newPhraseNameFocusNode = FocusNode();
  final FocusNode _newPhraseContentFocusNode = FocusNode();

  // inline memory edit/insert
  String? _editingMemoryId;
  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editContentController = TextEditingController();
  final FocusNode _editTitleFocusNode = FocusNode();
  final FocusNode _editContentFocusNode = FocusNode();
  String? _insertingMemoryId;
  String _insertingPosition = 'before';
  final TextEditingController _insertTitleController = TextEditingController();
  final TextEditingController _insertContentController = TextEditingController();
  final FocusNode _insertTitleFocusNode = FocusNode();
  final FocusNode _insertContentFocusNode = FocusNode();
  bool _showMemoryCreator = false;
  final TextEditingController _createTitleController = TextEditingController();
  final TextEditingController _createContentController = TextEditingController();
  final FocusNode _createTitleFocusNode = FocusNode();
  final FocusNode _createContentFocusNode = FocusNode();

  // menu expand
  bool _isMenuExpanded = false;
  late final AnimationController _menuAnimationController;
  late final Animation<double> _menuHeightAnimation;

  // bubble fade when focused
  late final AnimationController _bubbleAnimationController;
  late final Animation<double> _bubbleOpacityAnimation;

  // inspiration fade
  late final AnimationController _assistPanelAnimationController;
  late final Animation<double> _assistPanelOpacityAnimation;

  // expanded memory state
  final Set<String> _expandedMemoryIds = {};

  @override
  void initState() {
    super.initState();

    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _menuHeightAnimation = Tween<double>(begin: 0, end: 80).animate(
      CurvedAnimation(parent: _menuAnimationController, curve: Curves.easeInOut),
    );

    _bubbleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bubbleOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bubbleAnimationController, curve: Curves.easeOut),
    );

    _assistPanelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _assistPanelOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _assistPanelAnimationController, curve: Curves.easeOut),
    );

    // focus listener to toggle bubbles
    widget.focusNode.addListener(_onFocusChange);
    // load phrases
    _loadPhrases();
  }

  @override
  void didUpdateWidget(covariant ChatInputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSearchMode && _panelType != _AssistPanelType.search) {
      _panelType = _AssistPanelType.search;
      _assistPanelAnimationController
        ..reset()
        ..forward();
    } else if (!widget.isSearchMode && _panelType == _AssistPanelType.search) {
      _hideAssistPanel();
    }
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    _bubbleAnimationController.dispose();
    _assistPanelAnimationController.dispose();
    _phraseNameController.dispose();
    _phraseContentController.dispose();
    _newPhraseNameController.dispose();
    _newPhraseContentController.dispose();
    _editTitleController.dispose();
    _editContentController.dispose();
    _insertTitleController.dispose();
    _insertContentController.dispose();
    _createTitleController.dispose();
    _createContentController.dispose();
    _editTitleFocusNode.dispose();
    _editContentFocusNode.dispose();
    _insertTitleFocusNode.dispose();
    _insertContentFocusNode.dispose();
    _createTitleFocusNode.dispose();
    _createContentFocusNode.dispose();
    _newPhraseNameFocusNode.dispose();
    _newPhraseContentFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // 如果内联编辑器有焦点，完全忽略主输入框的焦点变化
    if (_hasInlineEditorFocus()) {
      return;
    }
    
    setState(() {
      _isInputFocused = widget.focusNode.hasFocus;
      if (_isInputFocused) {
        _bubbleAnimationController.forward();
      } else {
        _bubbleAnimationController.reverse();
      }
    });
  }

  bool _hasInlineEditorFocus() {
    return _editTitleFocusNode.hasFocus ||
           _editContentFocusNode.hasFocus ||
           _insertTitleFocusNode.hasFocus ||
           _insertContentFocusNode.hasFocus ||
           _createTitleFocusNode.hasFocus ||
           _createContentFocusNode.hasFocus ||
           _newPhraseNameFocusNode.hasFocus ||
           _newPhraseContentFocusNode.hasFocus;
  }

  // 当显示内联编辑器时，强制主输入框失焦
  void _forceMainInputUnfocus() {
    if (widget.focusNode.hasFocus) {
      widget.focusNode.unfocus();
    }
  }

  // assist panel controls
  void _showPhrasesPanel() {
    setState(() {
      _panelType = _AssistPanelType.phrases;
      _isMemoriesTab = false;
      _inspirationSuggestions.clear();
    });
    _assistPanelAnimationController
      ..reset()
      ..forward();
  }

  Future<void> _showInspirationPanel() async {
    if (_isLoadingInspiration) return;
    setState(() {
      _panelType = _AssistPanelType.inspirations;
      _isLoadingInspiration = true;
      _inspirationSuggestions.clear();
    });
    _assistPanelAnimationController
      ..reset()
      ..forward();
    try {
      final suggestions = await widget.fetchInspirationSuggestions();
      if (!mounted) return;
      setState(() {
        _inspirationSuggestions = suggestions;
      });
    } catch (e) {
      if (!mounted) return;
      CustomToast.show(context, message: '获取灵感失败', type: ToastType.error);
      _hideAssistPanel();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInspiration = false;
        });
      }
    }
  }

  void _hideAssistPanel() {
    setState(() {
      _panelType = _AssistPanelType.none;
      _isLoadingInspiration = false;
      _inspirationSuggestions.clear();
      _isMemoriesTab = false;
      _showPhraseCreator = false;
      _showMemoryCreator = false;
      _editingMemoryId = null;
      _insertingMemoryId = null;
      _expandedMemoryIds.clear(); // 清理展开的记忆状态
    });
    _assistPanelAnimationController.reset();
  }

  Future<void> _loadMemories({String? cursor, int limit = 20, bool append = false}) async {
    if (_isLoadingMemories) return;
    setState(() {
      _isLoadingMemories = true;
    });
    try {
      final data = await widget.fetchMemories(cursor: cursor, limit: limit);
      final List<dynamic> list = data['list'] ?? [];
      final List<Map<String, dynamic>> normalized = list
          .map((e) => {
                'memoryId': (e['memoryId'] ?? '').toString(),
                'title': (e['title'] ?? '').toString(),
                'content': (e['content'] ?? '').toString(),
              })
          .toList();
      setState(() {
        if (append) {
          _memories.addAll(normalized);
        } else {
          _memories = normalized;
        }
        _nextCursor = (data['next_cursor'] ?? '').toString();
        _currentSaveSlotId = (data['saveSlotId'] ?? '').toString();
      });
    } catch (e) {
      CustomToast.show(context, message: '获取记忆失败: $e', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMemories = false;
        });
      }
    }
  }

  // phrases persistence
  Future<void> _loadPhrases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phrasesJson = prefs.getString('common_phrases') ?? '[]';
      final List<dynamic> list = jsonDecode(phrasesJson);
      setState(() {
        _phrases = list
            .map((e) => {
                  'id': (e['id'] ?? '').toString(),
                  'name': (e['name'] ?? '').toString(),
                  'content': (e['content'] ?? '').toString(),
                })
            .toList();
      });
    } catch (_) {
      setState(() {
        _phrases = [];
      });
    }
  }

  Future<void> _savePhrases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('common_phrases', jsonEncode(_phrases));
    } catch (e) {
      if (!mounted) return;
      CustomToast.show(context, message: '保存失败: $e', type: ToastType.error);
    }
  }

  Future<void> _addPhrase(String name, String content) async {
    if (name.trim().isEmpty || content.trim().isEmpty) {
      CustomToast.show(context, message: '名称和内容不能为空', type: ToastType.error);
      return;
    }
    setState(() {
      _phrases.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name.trim(),
        'content': content.trim(),
      });
    });
    await _savePhrases();
    if (!mounted) return;
    CustomToast.show(context, message: '添加成功', type: ToastType.success);
  }

  Future<void> _addPhraseInline(String name, String content) async {
    await _addPhrase(name, content);
    setState(() {
      _showPhraseCreator = false;
      _newPhraseNameController.clear();
      _newPhraseContentController.clear();
    });
  }

  Future<void> _deletePhrase(String id) async {
    setState(() {
      _phrases.removeWhere((p) => p['id'] == id);
    });
    await _savePhrases();
  }

  // legacy dialog creator removed; using inline creator now

  // input helpers
  void _insertBrackets() {
    final controller = widget.messageController;
    final selection = controller.selection;
    final text = controller.text;
    if (selection.start != selection.end) {
      final selectedText = text.substring(selection.start, selection.end);
      controller.text = text.replaceRange(selection.start, selection.end, '($selectedText)');
      controller.selection = TextSelection.collapsed(offset: selection.end + 2);
    } else {
      controller.text = text.replaceRange(selection.start, selection.end, '()');
      controller.selection = TextSelection.collapsed(offset: selection.start + 1);
    }
  }

  void _insertQuotes() {
    final controller = widget.messageController;
    final selection = controller.selection;
    final text = controller.text;
    if (selection.start != selection.end) {
      final selectedText = text.substring(selection.start, selection.end);
      controller.text = text.replaceRange(selection.start, selection.end, '"$selectedText"');
      controller.selection = TextSelection.collapsed(offset: selection.end + 2);
    } else {
      controller.text = text.replaceRange(selection.start, selection.end, '“”');
      controller.selection = TextSelection.collapsed(offset: selection.start + 1);
    }
  }

  void _clearInput() {
    widget.messageController.clear();
  }

  Widget _buildFunctionBubble({
    Widget? icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Container(
      child: Material(
        color: isHighlighted ? AppTheme.primaryColor : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  icon,
                  SizedBox(width: 4.w),
                ],
                Text(
                  label,
                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssistPanel() {
    if (_panelType == _AssistPanelType.none) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _assistPanelOpacityAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _panelType == _AssistPanelType.phrases
                      ? Icons.history
                      : _panelType == _AssistPanelType.inspirations
                          ? Icons.lightbulb
                          : Icons.search,
                  color: _panelType == _AssistPanelType.phrases
                      ? Colors.white
                      : _panelType == _AssistPanelType.inspirations
                          ? Colors.amber
                          : AppTheme.primaryColor,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  _panelType == _AssistPanelType.phrases
                      ? '快捷语 & 记忆'
                      : _panelType == _AssistPanelType.inspirations
                          ? (_isLoadingInspiration ? '灵感涌现中...' : '灵感建议')
                          : '搜索结果 (${widget.searchResults.length})',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _panelType == _AssistPanelType.search
                        ? widget.onToggleSearchMode
                        : _hideAssistPanel,
                    borderRadius: BorderRadius.circular(12.r),
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Icon(Icons.close, color: Colors.white, size: 16.sp),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            if (_panelType == _AssistPanelType.phrases)
              _isMemoriesTab ? _buildMemoriesPanel() : _buildPhrasesPanel()
            else if (_panelType == _AssistPanelType.inspirations)
              _buildInspirationList()
            else
              _buildSearchList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhrasesPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // tabs
        Row(
          children: [
            _buildTabChip(active: !_isMemoriesTab, label: '快捷语', onTap: () {
              setState(() => _isMemoriesTab = false);
            }),
            SizedBox(width: 8.w),
            _buildTabChip(active: _isMemoriesTab, label: '记忆库', onTap: () async {
              setState(() => _isMemoriesTab = true);
              // 每次切换都重新加载，确保数据实时性
              await _loadMemories(cursor: null, limit: 20, append: false);
            }),
            const Spacer(),
            // 快捷语创建按钮移到右上角
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showPhraseCreator = true;
                  });
                  // 延迟聚焦，确保UI完全构建后再聚焦
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      _newPhraseNameFocusNode.requestFocus();
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 14.sp),
                      SizedBox(width: 4.w),
                      Text('新增快捷语', style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        // inline creator for phrases
        if (_showPhraseCreator) _buildPhraseCreatorInline(),
        _buildPhrasesList(),
      ],
    );
  }

  Widget _buildTabChip({required bool active, required String label, required VoidCallback onTap}) {
    return Material(
      color: active ? AppTheme.primaryColor : Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          child: Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildPhrasesList() {
    if (_phrases.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Center(
          child: Text(
            '暂无快捷语',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12.sp),
          ),
        ),
      );
    }
    return Container(
      constraints: BoxConstraints(maxHeight: 150.h),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _phrases.length > 10 ? 10 : _phrases.length,
        itemBuilder: (context, index) {
          final phrase = _phrases[index];
          return Container(
            margin: EdgeInsets.only(bottom: 4.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: InkWell(
              onTap: () {
                final controller = widget.messageController;
                final selection = controller.selection;
                final text = controller.text;
                final content = phrase['content'] ?? '';
                final start = selection.start;
                final end = selection.end;
                if (start < 0 || end < 0) {
                  controller.text = text + content;
                  controller.selection = TextSelection.collapsed(offset: controller.text.length);
                } else {
                  controller.text = text.replaceRange(start, end, content);
                  controller.selection = TextSelection.collapsed(offset: start + content.length);
                }
              },
              borderRadius: BorderRadius.circular(4.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        phrase['name'] ?? '',
                        style: TextStyle(color: Colors.white, fontSize: 12.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Material(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12.r),
                      child: InkWell(
                        onTap: () => _deletePhrase(phrase['id'] ?? ''),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline, color: Colors.white, size: 12.sp),
                              SizedBox(width: 4.w),
                              Text('删除', style: TextStyle(color: Colors.white, fontSize: 10.sp)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhraseCreatorInline() {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _newPhraseNameController,
            focusNode: _newPhraseNameFocusNode,
            decoration: const InputDecoration(labelText: '备注', hintText: '输入一个简短的备注'),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _newPhraseContentController,
            focusNode: _newPhraseContentFocusNode,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '内容', hintText: '输入要保存的内容'),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  await _addPhraseInline(_newPhraseNameController.text, _newPhraseContentController.text);
                },
                child: const Text('保存'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showPhraseCreator = false;
                    _newPhraseNameController.clear();
                    _newPhraseContentController.clear();
                  });
                },
                child: const Text('取消'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemoriesPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header actions
        Row(
          children: [
            _buildTabChip(active: false, label: '快捷语', onTap: () {
              setState(() => _isMemoriesTab = false);
            }),
            SizedBox(width: 8.w),
            _buildTabChip(active: true, label: '记忆库', onTap: () {}),
            const Spacer(),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  if (_currentSaveSlotId.isEmpty) {
                    await _loadMemories(cursor: null, limit: 20, append: false);
                  }
                  setState(() {
                    _showMemoryCreator = true;
                  });
                  // 延迟聚焦，确保UI完全构建后再聚焦
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      _createTitleFocusNode.requestFocus();
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 14.sp),
                      SizedBox(width: 4.w),
                      Text('新增记忆', style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        if (_showMemoryCreator) _buildMemoryCreatorInline(),
        if (_isLoadingMemories)
          Center(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.amber,
              period: const Duration(milliseconds: 1500),
              child: Text(
                '记忆加载中...',
                style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
            ),
          )
        else if (_memories.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Center(
              child: Text('暂无记忆', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12.sp)),
            ),
          )
        else
          Container(
            constraints: BoxConstraints(maxHeight: 200.h),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _memories.length + (_nextCursor.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _memories.length) {
                  return Center(
                    child: TextButton(
                      onPressed: () => _loadMemories(cursor: _nextCursor, limit: 20, append: true),
                      child: Text('加载更多', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12.sp)),
                    ),
                  );
                }
                final mem = _memories[index];
                final title = (mem['title'] as String? ?? '').trim();
                final content = (mem['content'] as String? ?? '').trim();
                final memoryId = (mem['memoryId'] as String? ?? '').trim();
                final isExpanded = _expandedMemoryIds.contains(memoryId);
                return Container(
                  margin: EdgeInsets.only(bottom: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                  ),
                  child: InkWell(
                    onTap: () {
                      // 切换展开/折叠状态
                      setState(() {
                        if (_expandedMemoryIds.contains(memoryId)) {
                          _expandedMemoryIds.remove(memoryId);
                        } else {
                          _expandedMemoryIds.add(memoryId);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding: EdgeInsets.all(10.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title.isEmpty ? '(无标题)' : title,
                                  style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // inline action chips instead of popup menu
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildMiniAction(label: '前插', onTap: () {
                                    setState(() {
                                      _insertingMemoryId = memoryId;
                                      _insertingPosition = 'before';
                                      _insertTitleController.clear();
                                      _insertContentController.clear();
                                    });
                                    // 延迟聚焦，确保UI完全构建后再聚焦
                                    Future.delayed(const Duration(milliseconds: 100), () {
                                      if (mounted) {
                                        _insertTitleFocusNode.requestFocus();
                                      }
                                    });
                                  }),
                                  SizedBox(width: 6.w),
                                  _buildMiniAction(label: '后插', onTap: () {
                                    setState(() {
                                      _insertingMemoryId = memoryId;
                                      _insertingPosition = 'after';
                                      _insertTitleController.clear();
                                      _insertContentController.clear();
                                    });
                                    // 延迟聚焦，确保UI完全构建后再聚焦
                                    Future.delayed(const Duration(milliseconds: 100), () {
                                      if (mounted) {
                                        _insertTitleFocusNode.requestFocus();
                                      }
                                    });
                                  }),
                                  SizedBox(width: 6.w),
                                  _buildMiniAction(label: '编辑', onTap: () {
                                    setState(() {
                                      _editingMemoryId = memoryId;
                                      _editTitleController.text = title;
                                      _editContentController.text = content;
                                    });
                                    // 延迟聚焦，确保UI完全构建后再聚焦
                                    Future.delayed(const Duration(milliseconds: 100), () {
                                      if (mounted) {
                                        _editTitleFocusNode.requestFocus();
                                      }
                                    });
                                  }),
                                  SizedBox(width: 6.w),
                                  _buildMiniAction(label: '删除', onTap: () {
                                    _deleteMemoryDirect(memoryId);
                                  }, danger: true),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          if (_editingMemoryId == memoryId)
                            _buildMemoryEditorInline(memoryId),
                          if (_insertingMemoryId == memoryId)
                            _buildMemoryInsertInline(memoryId),
                          Text(
                            content.isEmpty ? '(无内容)' : content,
                            style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 12.sp, height: 1.4),
                            maxLines: isExpanded ? null : 2,
                            overflow: isExpanded ? null : TextOverflow.ellipsis,
                          ),
                          if (!isExpanded && content.length > 100)
                            Padding(
                              padding: EdgeInsets.only(top: 4.h),
                              child: Text(
                                '点击展开查看更多...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 10.sp,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMemoryCreatorInline() {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: '标题'),
            controller: _createTitleController,
            focusNode: _createTitleFocusNode,
            maxLength: 200,
          ),
          SizedBox(height: 6.h),
          TextField(
            decoration: const InputDecoration(labelText: '内容'),
            controller: _createContentController,
            focusNode: _createContentFocusNode,
            maxLines: 6,
            maxLength: 20000,
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  if (_currentSaveSlotId.isEmpty) {
                    await _loadMemories(cursor: null, limit: 20, append: false);
                    if (_currentSaveSlotId.isEmpty) {
                      CustomToast.show(context, message: '无法确定存档ID', type: ToastType.error);
                      return;
                    }
                  }
                  try {
                    await widget.createMemory(
                      saveSlotId: _currentSaveSlotId,
                      title: _createTitleController.text.trim(),
                      content: _createContentController.text.trim(),
                    );
                    CustomToast.show(context, message: '创建成功', type: ToastType.success);
                    setState(() => _showMemoryCreator = false);
                    _createTitleController.clear();
                    _createContentController.clear();
                    await _loadMemories(cursor: null, limit: 20, append: false);
                  } catch (e) {
                    CustomToast.show(context, message: '$e', type: ToastType.error);
                  }
                },
                child: const Text('保存'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _showMemoryCreator = false);
                  _createTitleController.clear();
                  _createContentController.clear();
                },
                child: const Text('取消', style: TextStyle(decoration: TextDecoration.none)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAction({required String label, required VoidCallback onTap, bool danger = false}) {
    return Material(
      color: (danger ? Colors.red : AppTheme.primaryColor).withOpacity(0.25),
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          child: Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryEditorInline(String memoryId) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: '标题'),
            controller: _editTitleController,
            focusNode: _editTitleFocusNode,
            maxLength: 200,
          ),
          SizedBox(height: 6.h),
          TextField(
            decoration: const InputDecoration(labelText: '内容'),
            controller: _editContentController,
            focusNode: _editContentFocusNode,
            maxLines: 6,
            maxLength: 20000,
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  try {
                    await widget.updateMemory(
                      saveSlotId: _currentSaveSlotId,
                      memoryId: memoryId,
                      title: _editTitleController.text.trim(),
                      content: _editContentController.text.trim(),
                    );
                    CustomToast.show(context, message: '更新成功', type: ToastType.success);
                    setState(() => _editingMemoryId = null);
                    await _loadMemories(cursor: null, limit: 20, append: false);
                  } catch (e) {
                    CustomToast.show(context, message: '$e', type: ToastType.error);
                  }
                },
                child: const Text('保存'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _editingMemoryId = null);
                },
                child: const Text('取消'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryInsertInline(String anchorId) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('将在${_insertingPosition == 'before' ? '前' : '后'}插入', style: TextStyle(color: Colors.white, fontSize: 12.sp)),
          SizedBox(height: 6.h),
          TextField(
            decoration: const InputDecoration(labelText: '标题'),
            controller: _insertTitleController,
            focusNode: _insertTitleFocusNode,
            maxLength: 200,
          ),
          SizedBox(height: 6.h),
          TextField(
            decoration: const InputDecoration(labelText: '内容'),
            controller: _insertContentController,
            focusNode: _insertContentFocusNode,
            maxLines: 6,
            maxLength: 20000,
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  try {
                    await widget.insertMemoryRelative(
                      anchorMemoryId: anchorId,
                      position: _insertingPosition,
                      title: _insertTitleController.text.trim(),
                      content: _insertContentController.text.trim(),
                    );
                    CustomToast.show(context, message: '插入成功', type: ToastType.success);
                    setState(() {
                      _insertingMemoryId = null;
                    });
                    await _loadMemories(cursor: null, limit: 20, append: false);
                  } catch (e) {
                    CustomToast.show(context, message: '$e', type: ToastType.error);
                  }
                },
                child: const Text('保存'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _insertingMemoryId = null);
                },
                child: const Text('取消'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMemoryDirect(String memoryId) async {
    if (_currentSaveSlotId.isEmpty) return;
    try {
      await widget.deleteMemory(saveSlotId: _currentSaveSlotId, memoryId: memoryId);
      CustomToast.show(context, message: '删除成功', type: ToastType.success);
      await _loadMemories(cursor: null, limit: 20, append: false);
    } catch (e) {
      CustomToast.show(context, message: '$e', type: ToastType.error);
    }
  }

  // removed legacy dialog-based relative insert (using inline editor instead)

  Widget _buildInspirationList() {
    if (_isLoadingInspiration) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Center(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.amber,
            period: const Duration(milliseconds: 1500),
            child: Text(
              '灵感涌现中...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }
    if (_inspirationSuggestions.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Center(
          child: Text(
            '暂无灵感建议',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12.sp),
          ),
        ),
      );
    }
    return Container(
      constraints: BoxConstraints(maxHeight: 200.h),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _inspirationSuggestions.length,
        itemBuilder: (context, index) {
          final content = _inspirationSuggestions[index];
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.amber.withOpacity(0.6), width: 1),
            ),
            child: InkWell(
              onTap: () {
                widget.messageController.text = content;
                widget.messageController.selection =
                    TextSelection.fromPosition(TextPosition(offset: content.length));
                _hideAssistPanel();
              },
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.all(12.w),
                child: Text(
                  content,
                  style: TextStyle(color: Colors.white, fontSize: 13.sp, height: 1.4),
                  maxLines: null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchList() {
    final results = widget.searchResults;
    if (results.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Center(
          child: Text(
            '未找到相关消息',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12.sp),
          ),
        ),
      );
    }
    return Container(
      constraints: BoxConstraints(maxHeight: 200.h),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: results.length,
        itemBuilder: (context, index) {
          final item = results[index];
          final content = (item['content'] as String? ?? '').trim();
          final isUser = item['isUser'] as bool? ?? false;
          final msgId = (item['msgId'] as String? ?? '').trim();
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: (isUser ? AppTheme.primaryColor : Colors.grey).withOpacity(0.4),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () => widget.onTapSearchResult(msgId),
              borderRadius: BorderRadius.circular(8.r),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: (isUser ? AppTheme.primaryColor : Colors.grey).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            isUser ? '用户' : '模型',
                            style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      content,
                      style: TextStyle(color: Colors.white, fontSize: 13.sp, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSearch = widget.isSearchMode;
    final hasText = widget.currentInputText.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isInputFocused)
          FadeTransition(
            opacity: _bubbleOpacityAnimation,
            child: _panelType != _AssistPanelType.none
                ? _buildAssistPanel()
                : Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (widget.isLocalMode)
                          _buildFunctionBubble(
                            icon: Icon(isSearch ? Icons.close : Icons.search,
                                color: Colors.white, size: 14.sp),
                            label: isSearch ? '取消' : '搜索',
                            onTap: widget.onToggleSearchMode,
                            isHighlighted: isSearch,
                          ),
                        _buildFunctionBubble(icon: null, label: '()', onTap: _insertBrackets),
                        _buildFunctionBubble(icon: null, label: '""', onTap: _insertQuotes),
                        _buildFunctionBubble(
                          icon: Icon(Icons.backspace_outlined, color: Colors.white, size: 14.sp),
                          label: '清空输入框',
                          onTap: _clearInput,
                        ),
                        _buildFunctionBubble(
                          icon: Icon(Icons.history, color: Colors.white, size: 14.sp),
                          label: '快捷语 & 记忆',
                          onTap: _showPhrasesPanel,
                        ),
                        // 移除独立的快捷语创建按钮，现在在面板内部
                      ],
                    ),
                  ),
          ),

        // input row
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              // hamburger
              Container(
                width: 36.w,
                height: 36.w,
                margin: EdgeInsets.only(right: 8.w),
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMenuExpanded = !_isMenuExpanded;
                      if (_isMenuExpanded) {
                        _menuAnimationController.forward();
                      } else {
                        _menuAnimationController.reverse();
                      }
                    });
                    widget.onMenuToggle();
                  },
                  child: AnimatedIcon(
                    icon: AnimatedIcons.menu_close,
                    progress: _menuAnimationController,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
              ),
              // text field
              Expanded(
                child: Container(
                  constraints: BoxConstraints(minHeight: 36.h, maxHeight: 120.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Focus(
                    canRequestFocus: !_hasInlineEditorFocus(),
                    child: TextField(
                      controller: widget.messageController,
                      focusNode: widget.focusNode,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 14.sp),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: isSearch ? '输入关键词搜索...' : '发送消息...',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: isSearch ? widget.onInlineSearch : null,
                    ),
                  ),
                ),
              ),
              // send / inspiration / stop / search button
              Container(
                width: 36.w,
                height: 36.w,
                margin: EdgeInsets.only(left: 8.w),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isSearch
                        ? () {
                            final keyword = widget.messageController.text.trim();
                            if (keyword.isNotEmpty) {
                              widget.onInlineSearch?.call(keyword);
                            }
                          }
                        : widget.isSending
                            ? widget.onStopGenerationTap
                            : hasText
                                ? widget.onSendTap
                                : _showInspirationPanel,
                    borderRadius: BorderRadius.circular(18.r),
                    child: Icon(
                      isSearch
                          ? Icons.search
                          : widget.isSending
                              ? Icons.stop_rounded
                              : hasText
                                  ? Icons.send
                                  : Icons.lightbulb,
                      color: isSearch
                          ? AppTheme.primaryColor
                          : widget.isSending
                              ? Colors.red.withOpacity(0.8)
                              : hasText
                                  ? AppTheme.primaryColor
                                  : Colors.amber,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // expanded menu grid
        if (_isMenuExpanded)
          AnimatedBuilder(
            animation: _menuAnimationController,
            builder: (context, child) {
              return SizedBox(height: _menuHeightAnimation.value, child: child);
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                ),
              ),
              child: GridView.count(
                crossAxisCount: 4,
                padding: EdgeInsets.symmetric(vertical: 4.h),
                mainAxisSpacing: 2.h,
                crossAxisSpacing: 2.w,
                childAspectRatio: 0.9,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildExpandedFunctionButton(
                    icon: Icons.person,
                    label: '角色',
                    onTap: widget.onOpenCharacterPanel,
                  ),
                  _buildExpandedFunctionButton(
                    icon: Icons.palette,
                    label: '界面',
                    onTap: widget.onOpenChatSettings,
                  ),
                  _buildExpandedFunctionButton(
                    icon: Icons.restart_alt,
                    label: '重置',
                    onTap: () async {
                      await widget.onResetSession();
                    },
                    isLoading: widget.isResetting,
                  ),
                  _buildExpandedFunctionButton(
                    icon: Icons.archive,
                    label: '存档',
                    onTap: widget.onOpenArchive,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExpandedFunctionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                color: isLoading ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              alignment: Alignment.center,
              child: isLoading
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 22.sp),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(color: isLoading ? Colors.white.withOpacity(0.6) : Colors.white, fontSize: 11.sp),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


