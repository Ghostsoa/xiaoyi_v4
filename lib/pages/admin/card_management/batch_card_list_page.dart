import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import 'card_management_service.dart';

class BatchCardListPage extends StatefulWidget {
  final int batchId;
  final String batchNo;

  const BatchCardListPage(
      {super.key, required this.batchId, required this.batchNo});

  @override
  State<BatchCardListPage> createState() => _BatchCardListPageState();
}

class _BatchCardListPageState extends State<BatchCardListPage> {
  final CardManagementService _cardService = CardManagementService();

  // 搜索筛选条件
  String? _selectedCardType; // 从批次信息获取或允许再筛选
  int? _selectedStatus; // 0:未使用, 1:已使用, 2:已禁用
  final TextEditingController _cardSecretController = TextEditingController();

  // 列表数据
  List<dynamic> _cards = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalItems = 0;
  int _totalPages = 1;
  final int _pageSize = 10;

  // 批量操作变量
  List<int> _selectedCardIds = [];
  bool _isBatchProcessing = false;

  @override
  void initState() {
    super.initState();
    // TODO: 如果需要，可以从批次详情接口获取批次信息，例如默认的卡密类型
    _loadCards();
  }

  @override
  void dispose() {
    _cardSecretController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final result = await _cardService.getCardList(
        batchId: widget.batchId,
        cardType: _selectedCardType,
        status: _selectedStatus,
        cardSecret: _cardSecretController.text.trim(),
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (result['code'] == 0) {
        final data = result['data'];
        setState(() {
          _cards = data['cards'] ?? [];
          _totalItems = data['total'] ?? 0;
          _totalPages = (data['total'] / _pageSize).ceil();
          if (_totalPages == 0) _totalPages = 1;
        });
      } else {
        _showErrorToast('获取卡密列表失败: ${result['message']}');
      }
    } catch (e) {
      _showErrorToast('加载卡密列表失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disableCard(int cardId) async {
    try {
      await _cardService.disableCard(cardId);
      _showSuccessToast('卡密已禁用');
      _loadCards();
    } catch (e) {
      _showErrorToast('禁用卡密失败: $e');
    }
  }

  Future<void> _enableCard(int cardId) async {
    try {
      await _cardService.enableCard(cardId);
      _showSuccessToast('卡密已启用');
      _loadCards();
    } catch (e) {
      _showErrorToast('启用卡密失败: $e');
    }
  }

  Future<void> _deleteCard(int cardId) async {
    final bool confirm = await _showConfirmDialog('确认删除', '确定要删除该卡密吗？此操作不可撤销。');
    if (!confirm) return;
    try {
      await _cardService.deleteCard(cardId);
      _showSuccessToast('卡密已删除');
      _loadCards();
    } catch (e) {
      _showErrorToast('删除卡密失败: $e');
    }
  }

  Future<void> _batchDisableCards() async {
    if (_selectedCardIds.isEmpty) {
      _showErrorToast('请先选择要操作的卡密');
      return;
    }
    setState(() => _isBatchProcessing = true);
    try {
      final result = await _cardService.batchDisableCards(_selectedCardIds);
      _showSuccessToast('成功禁用 ${result['data']?['disabled_count'] ?? 0} 张卡密');
      _clearSelection();
      _loadCards();
    } catch (e) {
      _showErrorToast('批量禁用失败: $e');
    } finally {
      setState(() => _isBatchProcessing = false);
    }
  }

  Future<void> _batchEnableCards() async {
    if (_selectedCardIds.isEmpty) {
      _showErrorToast('请先选择要操作的卡密');
      return;
    }
    setState(() => _isBatchProcessing = true);
    try {
      final result = await _cardService.batchEnableCards(_selectedCardIds);
      _showSuccessToast('成功启用 ${result['data']?['enabled_count'] ?? 0} 张卡密');
      _clearSelection();
      _loadCards();
    } catch (e) {
      _showErrorToast('批量启用失败: $e');
    } finally {
      setState(() => _isBatchProcessing = false);
    }
  }

  Future<void> _batchDeleteCards() async {
    if (_selectedCardIds.isEmpty) {
      _showErrorToast('请先选择要删除的卡密');
      return;
    }
    final bool confirm = await _showConfirmDialog(
        '确认批量删除', '确定要删除选中的 ${_selectedCardIds.length} 张卡密吗？此操作不可撤销。');
    if (!confirm) return;

    setState(() => _isBatchProcessing = true);
    try {
      final result = await _cardService.batchDeleteCards(_selectedCardIds);
      _showSuccessToast('成功删除 ${result['data']?['deleted_count'] ?? 0} 张卡密');
      _clearSelection();
      _loadCards();
    } catch (e) {
      _showErrorToast('批量删除失败: $e');
    } finally {
      setState(() => _isBatchProcessing = false);
    }
  }

  Future<void> _exportUnusedCardsInThisBatch() async {
    setState(() => _isLoading = true);
    try {
      final result =
          await _cardService.exportUnusedCardsInBatch(widget.batchId);
      final batchInfo = result['data']?['batch'];
      final unusedCards = result['data']?['unused_cards'] as List?;

      if (unusedCards == null || unusedCards.isEmpty) {
        _showErrorToast('该批次没有未使用的卡密可导出');
        return;
      }

      StringBuffer content = StringBuffer();
      content.writeln('批次号: ${batchInfo?['batch_no']}');
      content.writeln(
          '类型: ${batchInfo?['card_type'] == 'coin' ? '小懿币卡' : '畅玩时长卡'}');
      content.writeln('面额: ${batchInfo?['amount']}');
      content.writeln('导出时间: ${result['data']?['export_time']}');
      content.writeln('共 ${unusedCards.length} 张未使用卡密:');
      content.writeln('-------------------------------------');
      for (var card in unusedCards) {
        content.writeln(card['card_secret']);
      }
      content.writeln('-------------------------------------');

      await Clipboard.setData(ClipboardData(text: content.toString()));
      _showSuccessToast(
          '已复制 ${unusedCards.length} 张属于批次 ${widget.batchNo} 的未使用卡密到剪贴板');
    } catch (e) {
      _showErrorToast('导出失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUnusedCardsInThisBatch() async {
    final bool confirm = await _showConfirmDialog(
        '确认操作', '确定要删除批次 ${widget.batchNo} 下所有未使用的卡密吗？',
        deleteActionText: '删除未使用');
    if (!confirm) return;
    setState(() => _isBatchProcessing = true);
    try {
      final result =
          await _cardService.deleteUnusedCardsInBatch(widget.batchId);
      final count = result['data']?['deleted_count'] ?? 0;
      _showSuccessToast('成功删除 $count 张未使用的卡密');
      _loadCards(); // Refresh card list
    } catch (e) {
      _showErrorToast('删除未使用卡密失败: $e');
    } finally {
      setState(() => _isBatchProcessing = false);
    }
  }

  void _clearSelection() => setState(() => _selectedCardIds = []);

  void _toggleCardSelection(int cardId) {
    setState(() {
      if (_selectedCardIds.contains(cardId)) {
        _selectedCardIds.remove(cardId);
      } else {
        _selectedCardIds.add(cardId);
      }
    });
  }

  // 全选/取消全选
  void _toggleSelectAll() {
    setState(() {
      if (_selectedCardIds.length == _cards.length) {
        // 如果已经全选了，则取消全选
        _selectedCardIds = [];
      } else {
        // 否则全选
        _selectedCardIds =
            _cards.map<int>((card) => card['id'] as int).toList();
      }
    });
  }

  Future<bool> _showConfirmDialog(String title, String content,
      {String deleteActionText = '删除'}) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消')),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(deleteActionText)),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryLight;
    final background = AppTheme.background;
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;
    final surfaceColor = AppTheme.cardBackground;

    return Scaffold(
      appBar: AppBar(
        title: Text('批次: ${widget.batchNo} - 卡密列表'),
        backgroundColor: background,
        elevation: 0.5,
      ),
      backgroundColor: background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterArea(primaryColor, textSecondary),
          _buildBatchActions(primaryColor),
          _buildListHeaderAndCounter(textPrimary, textSecondary, primaryColor),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cards.isEmpty
                    ? Center(
                        child: Text('该批次下暂无卡密数据',
                            style: TextStyle(
                                fontSize: 14.sp, color: textSecondary)))
                    : _buildTableCardListView(
                        surfaceColor, textPrimary, textSecondary),
          ),
          if (_totalPages > 1)
            _buildPaginationControls(textPrimary, textSecondary, primaryColor),
        ],
      ),
    );
  }

  Widget _buildFilterArea(Color primaryColor, Color textSecondary) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cardSecretController,
                  decoration: InputDecoration(
                      labelText: '卡密搜索',
                      hintText: '输入卡密关键词',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.r)),
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 12.h)),
                  onSubmitted: (_) => _searchCards(),
                ),
              ),
              SizedBox(width: 12.w),
              ElevatedButton(
                  onPressed: _searchCards,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.w, vertical: 12.h),
                      minimumSize: Size(100.w, 56.h)),
                  child: const Text('搜索')),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              // TODO: Consider if CardType filter is needed here, as batch already has a type.
              // Potentially useful if a batch could somehow have mixed types (not per current API)
              Expanded(
                child: SizedBox(
                  height: 56.h,
                  child: DropdownButtonFormField<int?>(
                    isExpanded: true,
                    decoration: InputDecoration(
                        labelText: '卡密状态',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4.r)),
                        isDense: true),
                    value: _selectedStatus,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('全部状态')),
                      DropdownMenuItem(value: 0, child: Text('未使用')),
                      DropdownMenuItem(value: 1, child: Text('已使用')),
                      DropdownMenuItem(value: 2, child: Text('已禁用'))
                    ],
                    onChanged: (value) {
                      setState(() => _selectedStatus = value);
                      _searchCards();
                    },
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBatchActions(Color primaryColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.h),
      child: Wrap(
        spacing: 10.w,
        runSpacing: 8.h,
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.file_download_done, size: 18.sp),
            label: Text('导出本批次未使用', style: TextStyle(fontSize: 13.sp)),
            onPressed: _isLoading ? null : _exportUnusedCardsInThisBatch,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h)),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.delete_outline, size: 18.sp),
            label: Text('删除本批次未使用', style: TextStyle(fontSize: 13.sp)),
            onPressed: _isBatchProcessing || _isLoading
                ? null
                : _deleteUnusedCardsInThisBatch,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h)),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeaderAndCounter(
      Color textPrimary, Color textSecondary, Color primaryColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('卡密列表',
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: textPrimary)),
              SizedBox(width: 16.w),
              Text('共 $_totalItems 条记录',
                  style: TextStyle(fontSize: 14.sp, color: textSecondary)),
            ],
          ),
          if (_selectedCardIds.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Row(
                children: [
                  Text('已选择 ${_selectedCardIds.length} 项',
                      style: TextStyle(fontSize: 14.sp, color: primaryColor)),
                  SizedBox(width: 8.w),
                  IconButton(
                      icon: Icon(Icons.block, color: Colors.red, size: 20.r),
                      tooltip: '批量禁用',
                      onPressed:
                          _isBatchProcessing ? null : _batchDisableCards),
                  IconButton(
                      icon: Icon(Icons.check_circle,
                          color: Colors.green, size: 20.r),
                      tooltip: '批量启用',
                      onPressed: _isBatchProcessing ? null : _batchEnableCards),
                  IconButton(
                      icon: Icon(Icons.delete,
                          color: Colors.red.shade700, size: 20.r),
                      tooltip: '批量删除',
                      onPressed: _isBatchProcessing ? null : _batchDeleteCards),
                  IconButton(
                      icon: Icon(Icons.close, size: 20.r),
                      tooltip: '取消选择',
                      onPressed: _clearSelection),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 新的表格式布局，支持左右滑动
  Widget _buildTableCardListView(
      Color surfaceColor, Color textPrimary, Color textSecondary) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTableHeader(textPrimary, textSecondary),
            ...List.generate(_cards.length, (index) {
              final card = _cards[index];
              return _buildTableRow(
                  card, index, surfaceColor, textPrimary, textSecondary);
            }),
          ],
        ),
      ),
    );
  }

  // 表头
  Widget _buildTableHeader(Color textPrimary, Color textSecondary) {
    final headerColor = AppTheme.cardBackground.withOpacity(0.95);
    return Container(
      decoration: BoxDecoration(color: headerColor, boxShadow: [
        BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 2,
            offset: const Offset(0, 1))
      ]),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            // 多选框列
            SizedBox(
              width: 50.w,
              height: 48.h,
              child: Checkbox(
                value: _cards.isNotEmpty &&
                    _selectedCardIds.length == _cards.length,
                onChanged: (_) => _toggleSelectAll(),
              ),
            ),
            // 编号列
            _headerCell('ID', 70.w, textPrimary),
            // 卡密列
            _headerCell('卡密', 200.w, textPrimary, tooltip: '点击可复制卡密'),
            // 批次号列
            _headerCell('批次号', 150.w, textPrimary),
            // 卡密类型列
            _headerCell('卡密类型', 100.w, textPrimary),
            // 面额列
            _headerCell('面额', 80.w, textPrimary),
            // 状态列
            _headerCell('状态', 80.w, textPrimary),
            // 使用者ID列
            _headerCell('使用者ID', 100.w, textPrimary),
            // 创建时间列
            _headerCell('创建时间', 150.w, textPrimary),
            // 使用时间列
            _headerCell('使用时间', 150.w, textPrimary),
            // 操作列
            _headerCell('操作', 120.w, textPrimary),
          ],
        ),
      ),
    );
  }

  // 表头单元格
  Widget _headerCell(String title, double width, Color textColor,
      {String? tooltip}) {
    return Container(
      width: width,
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (tooltip != null) ...[
            SizedBox(width: 4.w),
            Tooltip(
              message: tooltip,
              child: Icon(Icons.info_outline,
                  size: 14.sp, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
    );
  }

  // 表格行
  Widget _buildTableRow(Map<String, dynamic> card, int index,
      Color surfaceColor, Color textPrimary, Color textSecondary) {
    // 处理卡密状态
    int statusCode = 0;
    if (card['status'] is int) {
      statusCode = card['status'];
    } else if (card['status'] is String) {
      statusCode = int.tryParse(card['status'].toString()) ?? 0;
    }

    String statusText;
    Color statusColor;
    switch (statusCode) {
      case 1:
        statusText = '已使用';
        statusColor = AppTheme.warning;
        break;
      case 2:
        statusText = '已禁用';
        statusColor = AppTheme.error;
        break;
      default:
        statusText = '未使用';
        statusColor = AppTheme.success;
        break;
    }

    final batchInfo = card['batch'] as Map<String, dynamic>?;
    final rowColor = index % 2 == 0
        ? surfaceColor.withOpacity(0.5)
        : surfaceColor.withOpacity(0.8);

    return Container(
      color: rowColor,
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            // 多选框列
            SizedBox(
              width: 50.w,
              height: 45.h,
              child: Checkbox(
                value: _selectedCardIds.contains(card['id']),
                onChanged: (value) => _toggleCardSelection(card['id']),
              ),
            ),
            // ID列
            _cellText(card['id']?.toString() ?? '-', 70.w, textPrimary),
            // 卡密列 (可点击复制)
            _buildCopyableCell(card['card_secret'] ?? '-', 200.w, textPrimary),
            // 批次号列
            _cellText(batchInfo?['batch_no'] ?? '-', 150.w, textSecondary,
                maxLines: 1),
            // 卡密类型列
            _cellText(
                batchInfo?['card_type'] == 'coin'
                    ? '小懿币卡'
                    : (batchInfo?['card_type'] == 'play_time' ? '畅玩时长卡' : '-'),
                100.w,
                textSecondary),
            // 面额列
            _cellText('${batchInfo?['amount'] ?? '-'}', 80.w, textSecondary),
            // 状态列
            Container(
              width: 80.w,
              height: 45.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              alignment: Alignment.centerLeft,
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ),
            // 使用者ID列
            _cellText(statusCode == 1 ? '${card['used_by'] ?? '-'}' : '-',
                100.w, textSecondary),
            // 创建时间列
            _cellText(_formatDateTime(card['created_at']?.toString()), 150.w,
                textSecondary),
            // 使用时间列
            _cellText(_formatDateTime(card['used_at']?.toString()), 150.w,
                textSecondary),
            // 操作列
            Container(
              width: 120.w,
              height: 45.h,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (statusCode == 0)
                    IconButton(
                      icon: Icon(Icons.block, color: Colors.red, size: 18.sp),
                      tooltip: '禁用',
                      onPressed: () => _disableCard(card['id']),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 36.w,
                        minHeight: 36.h,
                      ),
                    ),
                  if (statusCode == 2)
                    IconButton(
                      icon: Icon(Icons.check_circle,
                          color: Colors.green, size: 18.sp),
                      tooltip: '启用',
                      onPressed: () => _enableCard(card['id']),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 36.w,
                        minHeight: 36.h,
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.delete,
                        color: Colors.red.shade700, size: 18.sp),
                    tooltip: '删除',
                    onPressed: () => _deleteCard(card['id']),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 36.w,
                      minHeight: 36.h,
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

  // 普通文本单元格
  Widget _cellText(String text, double width, Color textColor,
      {int maxLines = 1}) {
    return Container(
      width: width,
      height: 45.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.sp,
          color: textColor,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: maxLines,
      ),
    );
  }

  // 可复制的单元格
  Widget _buildCopyableCell(String text, double width, Color textColor) {
    return Container(
      width: width,
      height: 45.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: text));
          _showSuccessToast('卡密已复制到剪贴板');
        },
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.copy, size: 14.sp, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(
      Color textPrimary, Color textSecondary, Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('共 $_totalItems 条记录，每页 $_pageSize 条',
              style: TextStyle(fontSize: 14.sp, color: textSecondary)),
          Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: (_currentPage > 1 && !_isLoading)
                      ? () {
                          setState(() => _currentPage--);
                          _loadCards();
                        }
                      : null,
                  color: _currentPage > 1 && !_isLoading
                      ? primaryColor
                      : Colors.grey.withOpacity(0.5)),
              Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  child: Text('$_currentPage / $_totalPages',
                      style: TextStyle(fontSize: 14.sp, color: textPrimary))),
              IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: (_currentPage < _totalPages && !_isLoading)
                      ? () {
                          setState(() => _currentPage++);
                          _loadCards();
                        }
                      : null,
                  color: _currentPage < _totalPages && !_isLoading
                      ? primaryColor
                      : Colors.grey.withOpacity(0.5)),
            ],
          ),
        ],
      ),
    );
  }

  void _searchCards() {
    _currentPage = 1;
    _loadCards();
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';
    try {
      final dateTime =
          DateTime.parse(dateTimeStr).add(const Duration(hours: 8));
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  void _showErrorToast(String message) =>
      CustomToast.show(context, message: message, type: ToastType.error);
  void _showSuccessToast(String message) =>
      CustomToast.show(context, message: message, type: ToastType.success);
}
