import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import 'card_management_service.dart';

class CardManagementPage extends StatefulWidget {
  const CardManagementPage({super.key});

  @override
  State<CardManagementPage> createState() => _CardManagementPageState();
}

class _CardManagementPageState extends State<CardManagementPage> {
  final CardManagementService _cardService = CardManagementService();

  // 搜索筛选条件
  String? _selectedCardType;
  int? _selectedStatus;
  final TextEditingController _batchNoController = TextEditingController();
  final TextEditingController _cardSecretController = TextEditingController();

  // 创建卡密表单控制器
  String? _createCardType;
  final TextEditingController _createAmountController = TextEditingController();
  final TextEditingController _createCountController =
      TextEditingController(text: '1');
  final TextEditingController _createBatchNoController =
      TextEditingController();
  final TextEditingController _createRemarkController = TextEditingController();

  // 列表数据
  List<dynamic> _cards = [];
  bool _isLoading = false;
  bool _isCreating = false;
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
    _loadCards();
  }

  @override
  void dispose() {
    _batchNoController.dispose();
    _cardSecretController.dispose();
    _createAmountController.dispose();
    _createCountController.dispose();
    _createBatchNoController.dispose();
    _createRemarkController.dispose();
    super.dispose();
  }

  // 加载卡密列表
  Future<void> _loadCards() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _cardService.getCardList(
        cardType: _selectedCardType,
        status: _selectedStatus,
        cardSecret: _cardSecretController.text.trim(),
        page: _currentPage,
        pageSize: _pageSize,
      );

      // 检查API返回的数据结构
      if (result['code'] == 0) {
        // 获取成功
        final data = result['data'];
        setState(() {
          _cards = data['cards'] ?? [];
          _totalItems = data['total'] ?? 0;
          _totalPages = data['total_pages'] ?? 1;
        });
      } else {
        // API返回错误
        _showErrorToast('获取失败: ${result['msg']}');
      }
    } catch (e) {
      _showErrorToast('加载卡密列表失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 创建卡密
  Future<void> _createCards() async {
    // 表单验证
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

    setState(() {
      _isCreating = true;
    });

    try {
      if (count == 1) {
        // 创建单个卡密
        await _cardService.createCard(
          cardType: _createCardType!,
          amount: amount,
          batchNo: _createBatchNoController.text.trim(),
          remark: _createRemarkController.text.trim(),
        );

        _showSuccessToast('卡密创建成功');
      } else {
        // 批量创建卡密
        await _cardService.batchCreateCards(
          cardType: _createCardType!,
          amount: amount,
          count: count,
          batchNo: _createBatchNoController.text.trim(),
          remark: _createRemarkController.text.trim(),
        );

        _showSuccessToast('成功创建 $count 张卡密');
      }

      // 重置表单并刷新列表
      _resetCreateForm();
      Navigator.of(context).pop(); // 关闭对话框
      _currentPage = 1;
      _loadCards();
    } catch (e) {
      _showErrorToast('创建卡密失败: $e');
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  void _resetCreateForm() {
    setState(() {
      _createCardType = null;
    });
    _createAmountController.clear();
    _createCountController.text = '1';
    _createBatchNoController.clear();
    _createRemarkController.clear();
  }

  // 显示创建卡密对话框
  void _showCreateCardDialog() {
    _resetCreateForm();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('创建卡密'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 卡密类型选择
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: '卡密类型',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                  value: _createCardType,
                  items: [
                    DropdownMenuItem(
                      value: 'coin',
                      child: Text('小懿币卡'),
                    ),
                    DropdownMenuItem(
                      value: 'play_time',
                      child: Text('畅玩时长卡'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _createCardType = value;
                    });
                  },
                ),
                SizedBox(height: 16.h),

                // 卡密面额
                TextField(
                  controller: _createAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '卡密面额',
                    hintText: '例如：100, 500',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // 创建数量
                TextField(
                  controller: _createCountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '创建数量',
                    hintText: '数量大于1时批量创建',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // 批次号
                TextField(
                  controller: _createBatchNoController,
                  decoration: InputDecoration(
                    labelText: '批次号（可选）',
                    hintText: '用于卡密分组管理',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // 备注
                TextField(
                  controller: _createRemarkController,
                  decoration: InputDecoration(
                    labelText: '备注（可选）',
                    hintText: '添加卡密备注信息',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: _isCreating ? null : _createCards,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isCreating
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16.r,
                          height: 16.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text('创建中...'),
                      ],
                    )
                  : Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  // 禁用卡密
  Future<void> _disableCard(int cardId) async {
    try {
      await _cardService.disableCard(cardId);
      _showSuccessToast('卡密已禁用');
      _loadCards(); // 刷新列表
    } catch (e) {
      _showErrorToast('禁用卡密失败: $e');
    }
  }

  // 启用卡密
  Future<void> _enableCard(int cardId) async {
    try {
      await _cardService.enableCard(cardId);
      _showSuccessToast('卡密已启用');
      _loadCards(); // 刷新列表
    } catch (e) {
      _showErrorToast('启用卡密失败: $e');
    }
  }

  // 删除卡密
  Future<void> _deleteCard(int cardId) async {
    try {
      await _cardService.deleteCard(cardId);
      _showSuccessToast('卡密已删除');
      _loadCards(); // 刷新列表
    } catch (e) {
      _showErrorToast('删除卡密失败: $e');
    }
  }

  // 批量禁用卡密
  Future<void> _batchDisableCards() async {
    if (_selectedCardIds.isEmpty) {
      _showErrorToast('请先选择要操作的卡密');
      return;
    }

    setState(() {
      _isBatchProcessing = true;
    });

    try {
      final result = await _cardService.batchDisableCards(_selectedCardIds);
      _showSuccessToast('成功禁用 ${result['data']['disabled_count']} 张卡密');
      _clearSelection();
      _loadCards(); // 刷新列表
    } catch (e) {
      _showErrorToast('批量禁用失败: $e');
    } finally {
      setState(() {
        _isBatchProcessing = false;
      });
    }
  }

  // 批量启用卡密
  Future<void> _batchEnableCards() async {
    if (_selectedCardIds.isEmpty) {
      _showErrorToast('请先选择要操作的卡密');
      return;
    }

    setState(() {
      _isBatchProcessing = true;
    });

    try {
      final result = await _cardService.batchEnableCards(_selectedCardIds);
      _showSuccessToast('成功启用 ${result['data']['enabled_count']} 张卡密');
      _clearSelection();
      _loadCards(); // 刷新列表
    } catch (e) {
      _showErrorToast('批量启用失败: $e');
    } finally {
      setState(() {
        _isBatchProcessing = false;
      });
    }
  }

  // 批量删除卡密
  Future<void> _batchDeleteCards() async {
    if (_selectedCardIds.isEmpty) {
      _showErrorToast('请先选择要删除的卡密');
      return;
    }

    // 显示确认对话框
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('确认删除'),
            content: Text('确定要删除选中的 ${_selectedCardIds.length} 张卡密吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: Text('删除'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() {
      _isBatchProcessing = true;
    });

    try {
      final result = await _cardService.batchDeleteCards(_selectedCardIds);
      _showSuccessToast('成功删除 ${result['data']['deleted_count']} 张卡密');
      _clearSelection();
      _loadCards(); // 刷新列表
    } catch (e) {
      _showErrorToast('批量删除失败: $e');
    } finally {
      setState(() {
        _isBatchProcessing = false;
      });
    }
  }

  // 导出未使用的卡密
  Future<void> _exportUnusedCards() async {
    try {
      final result = await _cardService.exportUnusedCards(
        cardType: _selectedCardType,
      );

      // 获取未使用的卡密
      final unusedCards = result['data']['unused_cards'] as List;

      if (unusedCards.isEmpty) {
        _showErrorToast('没有未使用的卡密可导出');
        return;
      }

      // 整理卡密数据并分组
      Map<String, List<dynamic>> groupedCards = {};

      for (var card in unusedCards) {
        final cardType = card['card_type'] == 'coin' ? '小懿币卡' : '畅玩时长卡';
        final amount = card['amount'];
        final key = '$cardType+$amount';

        if (!groupedCards.containsKey(key)) {
          groupedCards[key] = [];
        }

        groupedCards[key]!.add(card);
      }

      // 获取所有批次号
      Set<String> batchNos = {};
      for (var card in unusedCards) {
        final batchNo = card['batch_no'];
        if (batchNo != null && batchNo.toString().isNotEmpty) {
          batchNos.add(batchNo.toString());
        }
      }

      // 显示批次信息对话框
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('导出卡密'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '共 ${unusedCards.length} 张未使用卡密',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                if (batchNos.isNotEmpty) ...[
                  Text(
                    '批次信息：',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // 显示所有批次号
                  Container(
                    height: 120.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: batchNos.length,
                      itemBuilder: (context, index) {
                        final batchNo = batchNos.elementAt(index);
                        return ListTile(
                          dense: true,
                          title: Text(batchNo),
                          trailing: IconButton(
                            icon: Icon(Icons.copy, size: 18.r),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: batchNo));
                              Navigator.of(context).pop(); // 关闭对话框
                              _showSuccessToast('批次号已复制到剪贴板');
                            },
                            tooltip: '复制批次号',
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(4.r),
                          ),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: batchNo));
                            Navigator.of(context).pop(); // 关闭对话框
                            _showSuccessToast('批次号已复制到剪贴板');
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
                Text(
                  '点击下方按钮复制所有卡密到剪贴板',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                // 构建文本内容，保持原有格式
                StringBuffer content = StringBuffer();

                groupedCards.forEach((key, groupCards) {
                  // 添加分组标题
                  content.writeln(key);

                  // 添加每张卡密
                  for (var card in groupCards) {
                    content.writeln(card['card_secret']);
                  }

                  // 添加分组间的空行
                  content.writeln();
                });

                // 复制到剪贴板
                await Clipboard.setData(
                    ClipboardData(text: content.toString()));

                Navigator.of(context).pop(); // 关闭对话框
                _showSuccessToast('已复制 ${unusedCards.length} 张卡密到剪贴板');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('复制所有卡密'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorToast('导出失败: $e');
    }
  }

  // 清除选择
  void _clearSelection() {
    setState(() {
      _selectedCardIds = [];
    });
  }

  // 切换卡密选择状态
  void _toggleCardSelection(int cardId) {
    setState(() {
      if (_selectedCardIds.contains(cardId)) {
        _selectedCardIds.remove(cardId);
      } else {
        _selectedCardIds.add(cardId);
      }
    });
  }

  // 确认删除单个卡密
  Future<void> _confirmDeleteCard(int cardId) async {
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('确认删除'),
            content: Text('确定要删除该卡密吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: Text('删除'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      _deleteCard(cardId);
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
          // 顶部搜索区域 - 仅占2行
          Container(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 第一行：标题和创建按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '卡密管理',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showCreateCardDialog,
                      icon: Icon(Icons.add),
                      label: Text('创建卡密'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // 搜索条件
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 第一行：卡密密文搜索和搜索按钮
                    Row(
                      children: [
                        // 卡密密文搜索
                        Expanded(
                          child: TextField(
                            controller: _cardSecretController,
                            decoration: InputDecoration(
                              labelText: '卡密密文',
                              hintText: '输入卡密关键词进行搜索',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              prefixIcon: Icon(Icons.search),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 12.h),
                            ),
                            onSubmitted: (_) {
                              _currentPage = 1;
                              _loadCards();
                            },
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // 搜索按钮
                        ElevatedButton(
                          onPressed: () {
                            _currentPage = 1;
                            _loadCards();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            minimumSize: Size(100.w, 56.h), // 匹配输入框高度
                          ),
                          child: Text('搜索'),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // 第二行：卡密类型和状态筛选
                    Row(
                      children: [
                        // 卡密类型筛选
                        Expanded(
                          child: SizedBox(
                            height: 56.h,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: '卡密类型',
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12.w),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                isDense: true,
                              ),
                              value: _selectedCardType,
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('全部类型'),
                                ),
                                DropdownMenuItem(
                                  value: 'coin',
                                  child: Text('小懿币卡'),
                                ),
                                DropdownMenuItem(
                                  value: 'play_time',
                                  child: Text('畅玩时长卡'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCardType = value;
                                  _currentPage = 1; // 重置页码
                                });
                                _loadCards(); // 立即刷新
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),

                        // 状态筛选
                        Expanded(
                          child: SizedBox(
                            height: 56.h,
                            child: DropdownButtonFormField<int?>(
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: '状态',
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12.w),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                isDense: true,
                              ),
                              value: _selectedStatus,
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('全部状态'),
                                ),
                                DropdownMenuItem(
                                  value: 0,
                                  child: Text('未使用'),
                                ),
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text('已使用'),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text('已禁用'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value;
                                  _currentPage = 1; // 重置页码
                                });
                                _loadCards(); // 立即刷新
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 列表区域
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 列表标题和操作按钮
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题部分
                      Row(
                        children: [
                          Text(
                            '卡密列表',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Text(
                            '共 $_totalItems 条记录',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      // 操作按钮部分
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // 批量操作按钮
                            if (_selectedCardIds.isNotEmpty) ...[
                              Text(
                                '已选择 ${_selectedCardIds.length} 项',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: primaryColor,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              SizedBox(
                                height: 36.h,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.block,
                                          color: Colors.red, size: 20.r),
                                      tooltip: '批量禁用',
                                      padding: EdgeInsets.all(4.r),
                                      constraints: BoxConstraints(),
                                      onPressed: _isBatchProcessing
                                          ? null
                                          : _batchDisableCards,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.check_circle,
                                          color: Colors.green, size: 20.r),
                                      tooltip: '批量启用',
                                      padding: EdgeInsets.all(4.r),
                                      constraints: BoxConstraints(),
                                      onPressed: _isBatchProcessing
                                          ? null
                                          : _batchEnableCards,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          color: Colors.red.shade700,
                                          size: 20.r),
                                      tooltip: '批量删除',
                                      padding: EdgeInsets.all(4.r),
                                      constraints: BoxConstraints(),
                                      onPressed: _isBatchProcessing
                                          ? null
                                          : _batchDeleteCards,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close, size: 20.r),
                                      tooltip: '取消选择',
                                      padding: EdgeInsets.all(4.r),
                                      constraints: BoxConstraints(),
                                      onPressed: _clearSelection,
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              IconButton(
                                icon: Icon(Icons.copy, color: Colors.blue),
                                tooltip: '复制未使用卡密到剪贴板',
                                onPressed: _exportUnusedCards,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // 使用SingleChildScrollView实现水平滑动
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : _cards.isEmpty
                            ? Center(
                                child: Text(
                                  '暂无卡密数据',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: textSecondary,
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  // 整个表格一起水平滚动
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: 1000.w, // 增加总宽度，确保所有列都有足够空间
                                        child: Column(
                                          children: [
                                            // 表格头部
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12.h,
                                                  horizontal: 16.w),
                                              decoration: BoxDecoration(
                                                color: surfaceColor
                                                    .withOpacity(0.3),
                                              ),
                                              child: Row(
                                                children: [
                                                  // 选择框
                                                  SizedBox(
                                                    width: 40.w,
                                                    child: Checkbox(
                                                      value:
                                                          _cards.isNotEmpty &&
                                                              _selectedCardIds
                                                                      .length ==
                                                                  _cards.length,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          if (value == true) {
                                                            // 全选
                                                            _selectedCardIds = _cards
                                                                .map<int>((card) =>
                                                                    card['id']
                                                                        as int)
                                                                .toList();
                                                          } else {
                                                            // 取消全选
                                                            _selectedCardIds =
                                                                [];
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 180.w,
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          '卡密',
                                                          style: TextStyle(
                                                            fontSize: 14.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: textPrimary,
                                                          ),
                                                        ),
                                                        SizedBox(width: 4.w),
                                                        Tooltip(
                                                          message: '点击可复制卡密',
                                                          child: Icon(
                                                            Icons.info_outline,
                                                            size: 14.sp,
                                                            color:
                                                                textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 80.w,
                                                    child: Text(
                                                      '类型',
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 60.w,
                                                    child: Text(
                                                      '面额',
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 100.w,
                                                    child: Text(
                                                      '批次号',
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 70.w,
                                                    child: Text(
                                                      '状态',
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 80.w,
                                                    child: Text(
                                                      '使用人ID',
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 100.w,
                                                    child: Text(
                                                      '创建时间',
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 120.w,
                                                    child: Text(
                                                      '使用时间',
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      '操作',
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: textPrimary,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // 列表内容
                                            Expanded(
                                              child: ListView.builder(
                                                itemCount: _cards.length,
                                                itemBuilder: (context, index) {
                                                  final card = _cards[index];

                                                  // 解析status值
                                                  int statusCode = 0;
                                                  if (card['status'] is int) {
                                                    statusCode = card['status'];
                                                  } else if (card['status']
                                                      is String) {
                                                    statusCode = int.tryParse(
                                                            card['status']
                                                                .toString()) ??
                                                        0;
                                                  }

                                                  // 根据状态码确定显示文本和颜色
                                                  String statusText;
                                                  Color statusColor;
                                                  bool isDisabled = false;
                                                  bool isUsed = false;

                                                  switch (statusCode) {
                                                    case 1:
                                                      statusText = '已使用';
                                                      statusColor =
                                                          AppTheme.warning;
                                                      isUsed = true;
                                                      break;
                                                    case 2:
                                                      statusText = '已禁用';
                                                      statusColor =
                                                          AppTheme.error;
                                                      isDisabled = true;
                                                      break;
                                                    case 0:
                                                    default:
                                                      statusText = '未使用';
                                                      statusColor =
                                                          AppTheme.success;
                                                      break;
                                                  }

                                                  // 格式化创建时间
                                                  String createdAt = '';
                                                  if (card['created_at'] !=
                                                      null) {
                                                    createdAt = _formatDateTime(
                                                        card['created_at']
                                                            .toString());
                                                  }

                                                  // 添加使用时间信息
                                                  String usedAt = '';
                                                  if (card['used_at'] != null) {
                                                    usedAt = _formatDateTime(
                                                        card['used_at']
                                                            .toString());
                                                  }

                                                  return Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      vertical: 12.h,
                                                      horizontal: 16.w,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: index % 2 == 0
                                                          ? Colors.transparent
                                                          : surfaceColor
                                                              .withOpacity(0.1),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        // 选择框
                                                        SizedBox(
                                                          width: 40.w,
                                                          child: Checkbox(
                                                            value: _selectedCardIds
                                                                .contains(
                                                                    card['id']),
                                                            onChanged: (value) {
                                                              _toggleCardSelection(
                                                                  card['id']);
                                                            },
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 180.w,
                                                          child: InkWell(
                                                            onTap: () {
                                                              Clipboard.setData(
                                                                  ClipboardData(
                                                                      text: card[
                                                                              'card_secret'] ??
                                                                          ''));
                                                              _showSuccessToast(
                                                                  '卡密已复制到剪贴板');
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    card['card_secret'] ??
                                                                        '-',
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          14.sp,
                                                                      color:
                                                                          textPrimary,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                                Icon(
                                                                  Icons.copy,
                                                                  size: 16.sp,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 80.w,
                                                          child: Text(
                                                            card['card_type'] ==
                                                                    'coin'
                                                                ? '小懿币卡'
                                                                : '畅玩时长卡',
                                                            style: TextStyle(
                                                              fontSize: 14.sp,
                                                              color:
                                                                  textPrimary,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 60.w,
                                                          child: Text(
                                                            '${card['amount'] ?? '0'}',
                                                            style: TextStyle(
                                                              fontSize: 14.sp,
                                                              color:
                                                                  textPrimary,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 100.w,
                                                          child: Text(
                                                            card['batch_no'] ??
                                                                '-',
                                                            style: TextStyle(
                                                              fontSize: 14.sp,
                                                              color:
                                                                  textPrimary,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 70.w,
                                                          child: Text(
                                                            statusText,
                                                            style: TextStyle(
                                                              fontSize: 14.sp,
                                                              color:
                                                                  statusColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 80.w,
                                                          child: Text(
                                                            isUsed
                                                                ? '${card['used_by'] ?? '-'}'
                                                                : '-',
                                                            style: TextStyle(
                                                              fontSize: 14.sp,
                                                              color:
                                                                  textPrimary,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 100.w,
                                                          child: Text(
                                                            createdAt,
                                                            style: TextStyle(
                                                              fontSize: 14.sp,
                                                              color:
                                                                  textPrimary,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 120.w,
                                                          child: Text(
                                                            usedAt,
                                                            style: TextStyle(
                                                              fontSize: 14.sp,
                                                              color:
                                                                  textPrimary,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Container(
                                                            alignment: Alignment
                                                                .center,
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                // 根据状态显示不同操作按钮
                                                                if (statusCode ==
                                                                    0) // 未使用
                                                                  IconButton(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .block,
                                                                      color: Colors
                                                                          .red,
                                                                      size:
                                                                          20.sp,
                                                                    ),
                                                                    tooltip:
                                                                        '禁用',
                                                                    onPressed: () =>
                                                                        _disableCard(
                                                                            card['id']),
                                                                    padding: EdgeInsets
                                                                        .all(4
                                                                            .r),
                                                                    constraints:
                                                                        BoxConstraints(),
                                                                  ),
                                                                if (statusCode ==
                                                                    2) // 已禁用
                                                                  IconButton(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .check_circle,
                                                                      color: Colors
                                                                          .green,
                                                                      size:
                                                                          20.sp,
                                                                    ),
                                                                    tooltip:
                                                                        '启用',
                                                                    onPressed: () =>
                                                                        _enableCard(
                                                                            card['id']),
                                                                    padding: EdgeInsets
                                                                        .all(4
                                                                            .r),
                                                                    constraints:
                                                                        BoxConstraints(),
                                                                  ),
                                                                IconButton(
                                                                  icon: Icon(
                                                                    Icons
                                                                        .delete,
                                                                    color: Colors
                                                                        .red
                                                                        .shade700,
                                                                    size: 20.sp,
                                                                  ),
                                                                  tooltip: '删除',
                                                                  onPressed: () =>
                                                                      _confirmDeleteCard(
                                                                          card[
                                                                              'id']),
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(4
                                                                              .r),
                                                                  constraints:
                                                                      BoxConstraints(),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                  ),

                  // 分页控制
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '共 $_totalItems 条记录，每页 $_pageSize 条',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left),
                              onPressed: (_currentPage > 1 && !_isLoading)
                                  ? () {
                                      setState(() {
                                        _currentPage--;
                                      });
                                      _loadCards();
                                    }
                                  : null,
                              color: _currentPage > 1 && !_isLoading
                                  ? primaryColor
                                  : Colors.grey.withOpacity(0.5),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 4.h),
                              child: Text(
                                '$_currentPage / ${(_totalItems / _pageSize).ceil()}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right),
                              onPressed: (_currentPage <
                                          (_totalItems / _pageSize).ceil() &&
                                      !_isLoading)
                                  ? () {
                                      setState(() {
                                        _currentPage++;
                                      });
                                      _loadCards();
                                    }
                                  : null,
                              color: _currentPage <
                                          (_totalItems / _pageSize).ceil() &&
                                      !_isLoading
                                  ? primaryColor
                                  : Colors.grey.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 格式化日期时间
  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime =
          DateTime.parse(dateTimeStr).add(const Duration(hours: 8)); // 添加8小时时差
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  // 显示错误提示
  void _showErrorToast(String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.error,
    );
  }

  // 显示成功提示
  void _showSuccessToast(String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.success,
    );
  }
}
