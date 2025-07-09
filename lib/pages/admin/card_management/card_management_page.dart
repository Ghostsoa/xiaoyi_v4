import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import 'card_management_service.dart';
import 'batch_card_list_page.dart'; // 假设新的卡密列表页面

class CardManagementPage extends StatefulWidget {
  const CardManagementPage({super.key});

  @override
  State<CardManagementPage> createState() => _CardManagementPageState();
}

class _CardManagementPageState extends State<CardManagementPage> {
  final CardManagementService _cardService = CardManagementService();

  // 搜索筛选条件
  String? _selectedCardType;
  int? _selectedStatus; // 0:激活, 1:禁用
  final TextEditingController _cardSecretController =
      TextEditingController(); // 改名为_cardSecretController，用于搜索卡密

  // 创建批次表单控制器 (如果创建功能在此页面)
  String? _createCardType;
  final TextEditingController _createAmountController = TextEditingController();
  final TextEditingController _createCountController =
      TextEditingController(text: '1');
  final TextEditingController _createRemarkController = TextEditingController();
  bool _isCreatingBatch = false;

  // 列表数据
  List<dynamic> _batches = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalItems = 0;
  int _totalPages = 1;
  final int _pageSize = 10;

  // 卡密搜索结果相关
  List<dynamic> _searchResultCards = [];
  bool _isShowingSearchResults = false; // 是否正在显示搜索结果
  bool _isSearching = false; // 是否正在搜索

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  @override
  void dispose() {
    _cardSecretController.dispose();
    _createAmountController.dispose();
    _createCountController.dispose();
    _createRemarkController.dispose();
    super.dispose();
  }

  // 查询卡密
  Future<void> _searchCardsByKeyword() async {
    final cardSecret = _cardSecretController.text.trim();
    if (cardSecret.isEmpty) {
      // 如果关键词为空，则回到批次列表
      setState(() {
        _isShowingSearchResults = false;
        _searchResultCards = [];
      });
      _loadBatches();
      return;
    }

    setState(() {
      _isSearching = true;
      _isShowingSearchResults = true;
    });

    try {
      final result = await _cardService.getCardList(
        cardSecret: cardSecret,
        cardType: _selectedCardType,
        status: _selectedStatus,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (result['code'] == 0) {
        final data = result['data'];
        setState(() {
          _searchResultCards = data['cards'] ?? [];
          _totalItems = data['total'] ?? 0;
          _totalPages = (data['total'] / _pageSize).ceil();
          if (_totalPages == 0) _totalPages = 1;
        });

        if (_searchResultCards.isEmpty) {
          _showErrorToast('未找到匹配的卡密');
        }
      } else {
        _showErrorToast('搜索卡密失败: ${result['message']}');
      }
    } catch (e) {
      _showErrorToast('搜索卡密失败: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // 修改loadBatches方法
  Future<void> _loadBatches() async {
    if (_isLoading) return;

    // 如果搜索框不为空且之前不是显示搜索结果，则执行搜索
    if (_cardSecretController.text.trim().isNotEmpty &&
        !_isShowingSearchResults) {
      _searchCardsByKeyword();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _cardService.getBatchList(
        cardType: _selectedCardType,
        status: _selectedStatus,
        keyword: "",
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (result['code'] == 0) {
        final data = result['data'];
        setState(() {
          _batches = data['batches'] ?? [];
          _totalItems = data['total'] ?? 0;
          _totalPages = (data['total'] / _pageSize).ceil();
          if (_totalPages == 0) _totalPages = 1;
        });
      } else {
        _showErrorToast('获取批次列表失败: ${result['message']}');
      }
    } catch (e) {
      _showErrorToast('加载批次列表失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToBatchCards(int batchId, String batchNo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BatchCardListPage(batchId: batchId, batchNo: batchNo),
      ),
    );
  }

  // 创建卡密批次
  Future<void> _createBatch() async {
    if (_createCardType == null) {
      _showErrorToast('请选择卡密类型');
      return;
    }
    final amountText = _createAmountController.text.trim();
    if (amountText.isEmpty) {
      _showErrorToast('请输入卡密面额');
      return;
    }
    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showErrorToast('卡密面额必须为正整数');
      return;
    }
    final countText = _createCountController.text.trim();
    final count = int.tryParse(countText);
    if (count == null || count <= 0) {
      _showErrorToast('创建数量必须为正整数');
      return;
    }
    if (count > 1000) {
      _showErrorToast('单次最多创建1000张卡密');
      return;
    }

    setState(() => _isCreatingBatch = true);

    try {
      await _cardService.createCardBatch(
        cardType: _createCardType!,
        amount: amount,
        count: count,
        remark: _createRemarkController.text.trim(),
      );
      _showSuccessToast('批次创建成功，已生成 $count 张卡密');
      _resetCreateBatchForm();
      Navigator.of(context).pop(); // 关闭对话框
      _currentPage = 1;
      _loadBatches();
    } catch (e) {
      _showErrorToast('创建批次失败: $e');
    } finally {
      setState(() => _isCreatingBatch = false);
    }
  }

  void _resetCreateBatchForm() {
    setState(() {
      _createCardType = null;
    });
    _createAmountController.clear();
    _createCountController.text = '1';
    _createRemarkController.clear();
  }

  void _showCreateBatchDialog() {
    _resetCreateBatchForm();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('创建卡密批次'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: '卡密类型',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  ),
                  value: _createCardType,
                  items: const [
                    DropdownMenuItem(value: 'coin', child: Text('小懿币卡')),
                    DropdownMenuItem(value: 'play_time', child: Text('畅玩时长卡')),
                    DropdownMenuItem(value: 'vip', child: Text('VIP会员卡')),
                  ],
                  onChanged: (value) =>
                      setStateDialog(() => _createCardType = value),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _createAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '卡密面额',
                    hintText: _createCardType == 'vip'
                        ? '例如：30, 90, 365'
                        : '例如：100, 500',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    suffixText: _createCardType == null
                        ? ''
                        : _cardService.getCardAmountUnitText(_createCardType!),
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _createCountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '创建数量',
                    hintText: '最多1000',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _createRemarkController,
                  decoration: InputDecoration(
                    labelText: '备注（可选）',
                    hintText: '添加批次备注信息',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消')),
            ElevatedButton(
              onPressed: _isCreatingBatch ? null : _createBatch,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white),
              child: _isCreatingBatch
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                          width: 16.r,
                          height: 16.r,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 8.w),
                      const Text('创建中...')
                    ])
                  : const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEmptyBatches() async {
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认操作'),
            content: const Text('确定要删除所有不包含任何卡密的空批次吗？'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消')),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('全部删除')),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;
    try {
      final result = await _cardService.deleteEmptyBatches();
      final count = result['data']?['deleted_batches_count'] ?? 0;
      _showSuccessToast('成功删除 $count 个空批次');
      _loadBatches();
    } catch (e) {
      _showErrorToast('删除空批次失败: $e');
    }
  }

  Future<void> _disableBatch(int batchId) async {
    try {
      final result = await _cardService.disableBatch(batchId);
      _showSuccessToast(
          '批次已禁用，影响 ${result['data']?['disabled_cards_count'] ?? 0} 张卡密');
      _loadBatches();
    } catch (e) {
      _showErrorToast('禁用批次失败: $e');
    }
  }

  Future<void> _enableBatch(int batchId) async {
    try {
      final result = await _cardService.enableBatch(batchId);
      _showSuccessToast(
          '批次已启用，影响 ${result['data']?['enabled_cards_count'] ?? 0} 张卡密');
      _loadBatches();
    } catch (e) {
      _showErrorToast('启用批次失败: $e');
    }
  }

  Future<void> _deleteBatch(int batchId) async {
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除该批次及其下所有卡密吗？此操作不可撤销。'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消')),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('删除')),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;
    try {
      final result = await _cardService.deleteBatch(batchId);
      _showSuccessToast(
          '批次已删除，共删除 ${result['data']?['deleted_cards_count'] ?? 0} 张卡密');
      _loadBatches();
    } catch (e) {
      _showErrorToast('删除批次失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryLight;
    final background = AppTheme.background;
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;
    final surfaceColor = AppTheme.cardBackground;

    return Scaffold(
      backgroundColor: background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('卡密批次管理',
                        style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: textPrimary)),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.add, size: 18.sp),
                          label:
                              Text('创建批次', style: TextStyle(fontSize: 13.sp)),
                          onPressed: _showCreateBatchDialog,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 8.h)),
                        ),
                        SizedBox(width: 10.w),
                        ElevatedButton.icon(
                          icon: Icon(Icons.delete_sweep, size: 18.sp),
                          label:
                              Text('删空批次', style: TextStyle(fontSize: 13.sp)),
                          onPressed: _deleteEmptyBatches,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 8.h)),
                        ),
                      ],
                    )
                  ],
                ),
                SizedBox(height: 16.h),
                _buildSearchFilters(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading || _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _isShowingSearchResults
                    ? _buildSearchResultsView(
                        surfaceColor, textPrimary, textSecondary)
                    : _batches.isEmpty
                        ? Center(
                            child: Text('暂无批次数据',
                                style: TextStyle(
                                    fontSize: 14.sp, color: textSecondary)))
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16.r),
                            itemCount: _batches.length,
                            itemBuilder: (context, index) {
                              final batch = _batches[index];
                              return _buildBatchListItem(batch, surfaceColor,
                                  primaryColor, textPrimary, textSecondary);
                            },
                          ),
          ),
          if (_totalPages > 1)
            _buildPaginationControls(textPrimary, textSecondary, primaryColor),
        ],
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cardSecretController,
                decoration: InputDecoration(
                    labelText: '卡密搜索',
                    hintText: '输入卡密关键词，搜索包含该卡密的批次',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.r)),
                    prefixIcon: const Icon(Icons.search),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h)),
                onSubmitted: (_) => _search(),
              ),
            ),
            SizedBox(width: 12.w),
            ElevatedButton(
                onPressed: _search,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    minimumSize: Size(100.w, 56.h)),
                child: const Text('搜索')),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56.h,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(
                      labelText: '卡密类型',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.r)),
                      isDense: true),
                  value: _selectedCardType,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('全部类型')),
                    DropdownMenuItem(value: 'coin', child: Text('小懿币卡')),
                    DropdownMenuItem(value: 'play_time', child: Text('畅玩时长卡')),
                    DropdownMenuItem(value: 'vip', child: Text('VIP会员卡')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCardType = value);
                    _search();
                  },
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: SizedBox(
                height: 56.h,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  decoration: InputDecoration(
                      labelText: '批次状态',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.r)),
                      isDense: true),
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('全部状态')),
                    DropdownMenuItem(value: 0, child: Text('激活')),
                    DropdownMenuItem(value: 1, child: Text('禁用'))
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _search();
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 修改search方法
  void _search() {
    _currentPage = 1;

    // 检查是否有卡密搜索关键词
    if (_cardSecretController.text.trim().isNotEmpty) {
      _searchCardsByKeyword();
    } else {
      // 重置搜索结果状态
      setState(() {
        _isShowingSearchResults = false;
        _searchResultCards = [];
      });
      _loadBatches();
    }
  }

  Widget _buildBatchListItem(Map<String, dynamic> batch, Color surfaceColor,
      Color primaryColor, Color textPrimary, Color textSecondary) {
    final bool isBatchDisabled = batch['status'] == 1;
    final int totalCards = batch['total_cards'] ?? 0;
    final int usedCards = batch['used_cards'] ?? 0;
    final int unusedCards = totalCards - usedCards;
    final String cardType = batch['card_type'] ?? '';
    final String cardTypeText = _cardService.getCardTypeText(cardType);
    final String amountText =
        '${batch['amount'] ?? '-'}${_cardService.getCardAmountUnitText(cardType)}';

    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 6.h),
      color: surfaceColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
          side: BorderSide(
              color: isBatchDisabled
                  ? Colors.grey.shade400
                  : primaryColor.withOpacity(0.5),
              width: 0.8)),
      child: InkWell(
        onTap: () =>
            _navigateToBatchCards(batch['id'], batch['batch_no'] ?? '批次详情'),
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text('批次号: ${batch['batch_no'] ?? '-'}',
                          style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: textPrimary),
                          overflow: TextOverflow.ellipsis)),
                  Chip(
                      label: Text(isBatchDisabled ? '已禁用' : '激活',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                      backgroundColor: isBatchDisabled
                          ? Colors.grey.shade600
                          : AppTheme.success,
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      labelPadding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ],
              ),
              SizedBox(height: 8.h),
              Row(children: [
                Text('类型: $cardTypeText',
                    style: TextStyle(fontSize: 13.sp, color: textSecondary)),
                SizedBox(width: 16.w),
                Text('面额: $amountText',
                    style: TextStyle(fontSize: 13.sp, color: textSecondary))
              ]),
              SizedBox(height: 4.h),
              Text('卡密数: $totalCards (已用: $usedCards / 未用: $unusedCards)',
                  style: TextStyle(fontSize: 13.sp, color: textSecondary)),
              if (batch['remark'] != null && batch['remark'].isNotEmpty)
                Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text('备注: ${batch['remark']}',
                        style: TextStyle(
                            fontSize: 13.sp,
                            color: textSecondary,
                            overflow: TextOverflow.ellipsis),
                        maxLines: 2)),
              SizedBox(height: 4.h),
              Text('创建: ${_formatDateTime(batch['created_at'])}',
                  style:
                      TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                      icon: Icon(
                          isBatchDisabled
                              ? Icons.check_circle_outline
                              : Icons.block,
                          size: 18.sp,
                          color: isBatchDisabled
                              ? Colors.green
                              : Colors.red.shade600),
                      label: Text(isBatchDisabled ? '启用' : '禁用',
                          style: TextStyle(
                              fontSize: 13.sp,
                              color: isBatchDisabled
                                  ? Colors.green
                                  : Colors.red.shade600)),
                      onPressed: () => isBatchDisabled
                          ? _enableBatch(batch['id'])
                          : _disableBatch(batch['id']),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h))),
                  SizedBox(width: 8.w),
                  TextButton.icon(
                      icon: Icon(Icons.delete_forever,
                          size: 18.sp, color: Colors.red.shade800),
                      label: Text('删批次',
                          style: TextStyle(
                              fontSize: 13.sp, color: Colors.red.shade800)),
                      onPressed: () => _deleteBatch(batch['id']),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h))),
                ],
              ),
            ],
          ),
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
                      ? () => setState(() {
                            _currentPage--;
                            _loadBatches();
                          })
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
                      ? () => setState(() {
                            _currentPage++;
                            _loadBatches();
                          })
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

  Widget _buildSearchResultsView(
      Color surfaceColor, Color textPrimary, Color textSecondary) {
    if (_searchResultCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48.r, color: Colors.grey.shade400),
            SizedBox(height: 16.h),
            Text('未找到匹配的卡密',
                style: TextStyle(fontSize: 16.sp, color: textSecondary)),
            SizedBox(height: 24.h),
            TextButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回批次列表'),
              onPressed: () {
                setState(() {
                  _cardSecretController.clear();
                  _isShowingSearchResults = false;
                  _searchResultCards = [];
                });
                _loadBatches();
              },
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '卡密搜索结果',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('返回批次列表'),
                onPressed: () {
                  setState(() {
                    _cardSecretController.clear();
                    _isShowingSearchResults = false;
                    _searchResultCards = [];
                  });
                  _loadBatches();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.r),
            itemCount: _searchResultCards.length,
            itemBuilder: (context, index) {
              final card = _searchResultCards[index];
              return _buildCardListItem(
                  card, surfaceColor, textPrimary, textSecondary);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardListItem(Map<String, dynamic> card, Color surfaceColor,
      Color textPrimary, Color textSecondary) {
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

    final batchId = card['batch_id'];
    final batchInfo = card['batch'] as Map<String, dynamic>?;
    final String cardType = batchInfo?['card_type'] ?? '';
    final String cardTypeText = _cardService.getCardTypeText(cardType);
    final String amountText =
        '${batchInfo?['amount'] ?? '-'}${_cardService.getCardAmountUnitText(cardType)}';

    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 4.h),
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                Clipboard.setData(
                    ClipboardData(text: card['card_secret'] ?? ''));
                _showSuccessToast('卡密已复制到剪贴板');
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.vpn_key, size: 18.r, color: AppTheme.primaryLight),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      card['card_secret'] ?? '-',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Text(
                  '批次ID: $batchId',
                  style: TextStyle(fontSize: 13.sp, color: textSecondary),
                ),
                SizedBox(width: 16.w),
                Text(
                  '类型: $cardTypeText',
                  style: TextStyle(fontSize: 13.sp, color: textSecondary),
                ),
                SizedBox(width: 16.w),
                Text(
                  '面额: $amountText',
                  style: TextStyle(fontSize: 13.sp, color: textSecondary),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                if (statusCode == 1)
                  Text(
                    '使用者ID: ${card['used_by'] ?? '-'}',
                    style: TextStyle(fontSize: 13.sp, color: textSecondary),
                  ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '创建时间: ${_formatDateTime(card['created_at'])}',
                    style:
                        TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
                  ),
                ),
                if (statusCode == 1)
                  Expanded(
                    child: Text(
                      '使用时间: ${_formatDateTime(card['used_at'])}',
                      style: TextStyle(
                          fontSize: 12.sp, color: Colors.grey.shade600),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(
                    Icons.info_outline,
                    size: 16.sp,
                    color: AppTheme.primaryLight,
                  ),
                  label: Text(
                    '查看批次',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _cardSecretController.clear();
                      _isShowingSearchResults = false;
                      _searchResultCards = [];
                    });

                    // 根据批次ID查询批次信息并跳转
                    _navigateToBatchCardsByBatchId(batchId);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                if (statusCode == 0)
                  TextButton.icon(
                    icon: Icon(
                      Icons.block,
                      size: 16.sp,
                      color: Colors.red.shade600,
                    ),
                    label: Text(
                      '禁用',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.red.shade600,
                      ),
                    ),
                    onPressed: () => _disableCard(card['id']),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                    ),
                  ),
                if (statusCode == 2)
                  TextButton.icon(
                    icon: Icon(
                      Icons.check_circle_outline,
                      size: 16.sp,
                      color: Colors.green,
                    ),
                    label: Text(
                      '启用',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.green,
                      ),
                    ),
                    onPressed: () => _enableCard(card['id']),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _disableCard(int cardId) async {
    try {
      await _cardService.disableCard(cardId);
      _showSuccessToast('卡密已禁用');
      // 刷新搜索结果
      if (_isShowingSearchResults) {
        _searchCardsByKeyword();
      } else {
        _loadBatches();
      }
    } catch (e) {
      _showErrorToast('禁用卡密失败: $e');
    }
  }

  Future<void> _enableCard(int cardId) async {
    try {
      await _cardService.enableCard(cardId);
      _showSuccessToast('卡密已启用');
      // 刷新搜索结果
      if (_isShowingSearchResults) {
        _searchCardsByKeyword();
      } else {
        _loadBatches();
      }
    } catch (e) {
      _showErrorToast('启用卡密失败: $e');
    }
  }

  Future<void> _navigateToBatchCardsByBatchId(int batchId) async {
    setState(() => _isLoading = true);
    try {
      // 获取批次详情
      final result = await _cardService.getBatchDetail(batchId);
      if (result['code'] == 0) {
        final batchInfo = result['data'];
        if (batchInfo != null) {
          // 导航到批次卡密列表页面
          _navigateToBatchCards(batchId, batchInfo['batch_no'] ?? '批次详情');
        } else {
          _showErrorToast('未找到批次信息');
        }
      } else {
        _showErrorToast('获取批次信息失败: ${result['message']}');
      }
    } catch (e) {
      _showErrorToast('获取批次信息失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
