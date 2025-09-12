import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import '../../../services/file_service.dart';
import 'report_management_service.dart';
import 'report_constants.dart';

class ReportDetailPage extends StatefulWidget {
  final String reportId;

  const ReportDetailPage({
    super.key,
    required this.reportId,
  });

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final ReportManagementService _service = ReportManagementService();
  final FileService _fileService = FileService();
  final TextEditingController _reviewNoteController = TextEditingController();
  final TextEditingController _penaltyReasonController =
      TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  Map<String, dynamic>? _reportDetail;
  bool _isLoading = false;
  bool _isProcessing = false;

  // 处罚设置
  int _selectedPenaltyType = PenaltyType.warning;
  final int _selectedDuration = 7; // 默认7天

  @override
  void initState() {
    super.initState();
    _loadReportDetail();
  }

  @override
  void dispose() {
    _reviewNoteController.dispose();
    _penaltyReasonController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadReportDetail() async {
    setState(() => _isLoading = true);

    try {
      final result = await _service.getReportDetail(widget.reportId);

      if (result['code'] == 0) {
        setState(() {
          _reportDetail = result['data'];
          _isLoading = false;
        });
      } else {
        throw Exception(result['msg'] ?? '获取举报详情失败');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      CustomToast.show(
        context,
        message: '加载举报详情失败: $e',
        type: ToastType.error,
      );
    }
  }

  Future<void> _reviewReport(bool approved) async {
    if (_reviewNoteController.text.trim().isEmpty) {
      CustomToast.show(
        context,
        message: '请填写审核意见',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await _service.reviewReport(
        widget.reportId,
        approved,
        _reviewNoteController.text.trim(),
      );

      if (result['code'] == 0) {
        CustomToast.show(
          context,
          message: result['msg'] ?? (approved ? '审核通过成功' : '审核拒绝成功'),
          type: ToastType.success,
        );

        await _loadReportDetail();
      } else {
        throw Exception(result['msg'] ?? '审核操作失败');
      }
    } catch (e) {
      CustomToast.show(
        context,
        message: '审核失败: $e',
        type: ToastType.error,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleReport() async {
    if (_penaltyReasonController.text.trim().isEmpty) {
      CustomToast.show(
        context,
        message: '请填写处理原因',
        type: ToastType.warning,
      );
      return;
    }

    int? duration;
    if (PenaltyType.needsDuration(_selectedPenaltyType)) {
      if (_durationController.text.trim().isEmpty) {
        CustomToast.show(
          context,
          message: '请填写封禁天数',
          type: ToastType.warning,
        );
        return;
      }

      try {
        duration = int.parse(_durationController.text.trim());
        if (duration <= 0) {
          CustomToast.show(
            context,
            message: '封禁天数必须大于0',
            type: ToastType.warning,
          );
          return;
        }
      } catch (e) {
        CustomToast.show(
          context,
          message: '封禁天数必须为整数',
          type: ToastType.warning,
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final result = await _service.handleReport(
        widget.reportId,
        _selectedPenaltyType,
        _penaltyReasonController.text.trim(),
        duration,
      );

      if (result['code'] == 0) {
        CustomToast.show(
          context,
          message: result['msg'] ?? '处理举报成功',
          type: ToastType.success,
        );

        // 刷新数据
        await _loadReportDetail();

        // 返回上一页并刷新列表
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(result['msg'] ?? '处理举报失败');
      }
    } catch (e) {
      CustomToast.show(
        context,
        message: '处理失败: $e',
        type: ToastType.error,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: Text('举报详情 #${widget.reportId}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportDetail == null
              ? Center(
                  child: Text(
                    '获取举报详情失败',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReportInfoCard(),
                      SizedBox(height: 16.h),
                      _buildReportedItemCard(),
                      SizedBox(height: 16.h),
                      _buildEvidenceSection(),
                      SizedBox(height: 16.h),
                      if (_reportDetail?['status'] == ReportStatus.pending)
                        _buildReviewSection(),
                      if (_reportDetail?['status'] == ReportStatus.approved)
                        _buildHandleSection(),
                      if (_reportDetail?['status'] == ReportStatus.handled)
                        _buildHandledInfoCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildReportInfoCard() {
    final int status = _reportDetail?['status'] ?? ReportStatus.pending;
    final int reportType = _reportDetail?['report_type'] ?? ReportType.illegal;

    Color statusColor;
    switch (status) {
      case ReportStatus.pending:
        statusColor = Colors.orange;
        break;
      case ReportStatus.approved:
        statusColor = Colors.green;
        break;
      case ReportStatus.rejected:
        statusColor = Colors.red;
        break;
      case ReportStatus.handled:
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.report_problem_outlined,
                  size: 20.sp,
                  color: statusColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  '举报信息',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    ReportStatus.getName(status),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 24.h),
            _buildInfoItem('举报类型', ReportType.getName(reportType)),
            SizedBox(height: 8.h),
            _buildInfoItem('举报人', _reportDetail?['reporter_name'] ?? '未知'),
            SizedBox(height: 8.h),
            _buildInfoItem(
                '举报时间', _formatDateTime(_reportDetail?['created_at'])),
            SizedBox(height: 8.h),
            _buildInfoItem('举报内容', _reportDetail?['content'] ?? '无举报内容',
                isMultiLine: true),
            SizedBox(height: 8.h),
            _buildInfoItem('处理类型', _getProcessTypeText(_reportDetail?['process_type'])),
            if (status == ReportStatus.approved ||
                status == ReportStatus.rejected) ...[
              SizedBox(height: 16.h),
              Divider(height: 1.h),
              SizedBox(height: 16.h),
              _buildInfoItem('审核人', _reportDetail?['reviewer_name'] ?? '未知'),
              SizedBox(height: 8.h),
              _buildInfoItem(
                  '审核时间', _formatDateTime(_reportDetail?['review_time'])),
              SizedBox(height: 8.h),
              _buildInfoItem('审核意见', _reportDetail?['review_note'] ?? '无审核意见',
                  isMultiLine: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportedItemCard() {
    final dynamic itemTypeValue = _reportDetail?['item_type'];
    final String itemType = itemTypeValue is String
        ? itemTypeValue
        : (itemTypeValue?.toString() ?? '');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 20.sp,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  '被举报内容',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24.h),
            _buildInfoItem(
                '内容ID', _reportDetail?['item_id']?.toString() ?? '未知'),
            SizedBox(height: 8.h),
            _buildInfoItem('内容标题', _reportDetail?['item_title'] ?? '未知内容'),
            SizedBox(height: 8.h),
            _buildInfoItem('内容类型', _getItemTypeText(itemType)),
            SizedBox(height: 8.h),
            _buildInfoItem('作者', _reportDetail?['author_name'] ?? '未知'),
            SizedBox(height: 8.h),
            _buildInfoItem('内容摘要', _reportDetail?['item_content'] ?? '无内容摘要',
                isMultiLine: true),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceSection() {
    final List<dynamic> evidence = _reportDetail?['evidence'] ?? [];

    if (evidence.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '举报证据',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 8.h,
          ),
          itemCount: evidence.length,
          itemBuilder: (context, index) {
            final String uri = evidence[index].toString();
            return GestureDetector(
              onTap: () => _showImagePreview(uri),
              child: FutureBuilder<Response>(
                future: _fileService.getFile(uri),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.w,
                          color: Colors.blue.shade300,
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Center(
                        child: Icon(Icons.error_outline, color: Colors.red),
                      ),
                    );
                  } else if (snapshot.hasData) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        image: DecorationImage(
                          image: MemoryImage(snapshot.data!.data as Uint8List),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Center(child: Text('无图片')),
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  void _showImagePreview(String uri) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '查看证据图片',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20.sp),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1.h),
              Flexible(
                child: FutureBuilder<Response>(
                  future: _fileService.getFile(uri),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.w,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 48.sp),
                            SizedBox(height: 16.h),
                            Text('加载图片失败', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      );
                    } else if (snapshot.hasData) {
                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: Image.memory(
                          snapshot.data!.data as Uint8List,
                          fit: BoxFit.contain,
                        ),
                      );
                    } else {
                      return Center(child: Text('无图片数据'));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 20.sp,
                  color: Colors.green,
                ),
                SizedBox(width: 8.w),
                Text(
                  '审核处理',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24.h),
            Text(
              '审核意见',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _reviewNoteController,
              decoration: InputDecoration(
                hintText: '请填写审核意见',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                isDense: true,
                contentPadding: EdgeInsets.all(12.w),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isProcessing ? null : () => _reviewReport(false),
                    icon: Icon(Icons.close, size: 18.sp),
                    label: Text(_isProcessing ? '处理中...' : '拒绝举报'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _reviewReport(true),
                    icon: Icon(Icons.check, size: 18.sp),
                    label: Text(_isProcessing ? '处理中...' : '通过审核'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade500,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
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

  Widget _buildHandleSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.gavel,
                  size: 20.sp,
                  color: Colors.orange,
                ),
                SizedBox(width: 8.w),
                Text(
                  '处罚处理',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24.h),
            Text(
              '处罚类型',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedPenaltyType,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: PenaltyType.getOptions()
                      .where((item) => item['value'] != PenaltyType.all)
                      .map((item) {
                    return DropdownMenuItem<int>(
                      value: item['value'],
                      child: Text(
                        item['label'],
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedPenaltyType = newValue);
                    }
                  },
                ),
              ),
            ),
            if (PenaltyType.needsDuration(_selectedPenaltyType)) ...[
              SizedBox(height: 16.h),
              Text(
                '封禁天数',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _durationController,
                decoration: InputDecoration(
                  hintText: '请输入封禁天数',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.all(12.w),
                  suffixText: '天',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            SizedBox(height: 16.h),
            Text(
              '处罚原因',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _penaltyReasonController,
              decoration: InputDecoration(
                hintText: '请填写处罚原因',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                isDense: true,
                contentPadding: EdgeInsets.all(12.w),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleReport,
                icon: Icon(Icons.gavel, size: 18.sp),
                label: Text(_isProcessing ? '处理中...' : '确认处理'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandledInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.gavel,
                  size: 20.sp,
                  color: Colors.blue,
                ),
                SizedBox(width: 8.w),
                Text(
                  '处理信息',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24.h),
            // 在已处理状态下，处理人可能是管理员或审核人
            _buildInfoItem('处理人', _reportDetail?['reviewer_name'] ?? '未知管理员'),
            SizedBox(height: 8.h),
            // 使用更新时间作为处理时间
            _buildInfoItem(
                '处理时间', _formatDateTime(_reportDetail?['updated_at'])),
            SizedBox(height: 8.h),
            // 使用审核意见作为处理备注
            _buildInfoItem('处理备注', _reportDetail?['review_note'] ?? '无处理备注',
                isMultiLine: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value,
      {bool isMultiLine = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            color: AppTheme.textPrimary,
          ),
          maxLines: isMultiLine ? null : 1,
          overflow: isMultiLine ? null : TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '未知时间';
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '时间格式错误';
    }
  }

  String _getItemTypeText(String? type) {
    switch (type) {
      case "character_card":
        return '角色卡';
      case "novel_card":
        return '小说卡';
      case "chat_card":
        return '群聊卡';
      default:
        return type ?? '未知类型';
    }
  }

  String _getProcessTypeText(String? processType) {
    switch (processType) {
      case 'ai':
        return 'AI自动处理';
      case 'manual':
        return '人工处理';
      default:
        return processType ?? '未知处理类型';
    }
  }
}
