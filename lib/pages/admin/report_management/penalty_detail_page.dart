import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import 'report_constants.dart';
import 'report_management_service.dart';

class PenaltyDetailPage extends StatefulWidget {
  final String penaltyId;

  const PenaltyDetailPage({
    super.key,
    required this.penaltyId,
  });

  @override
  State<PenaltyDetailPage> createState() => _PenaltyDetailPageState();
}

class _PenaltyDetailPageState extends State<PenaltyDetailPage> {
  final ReportManagementService _service = ReportManagementService();
  final TextEditingController _revokeReasonController = TextEditingController();

  Map<String, dynamic>? _penaltyDetail;
  bool _isLoading = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadPenaltyDetail();
  }

  @override
  void dispose() {
    _revokeReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadPenaltyDetail() async {
    setState(() => _isLoading = true);

    try {
      final result = await _service.getPenaltyDetail(widget.penaltyId);

      if (result['code'] == 0) {
        setState(() {
          _penaltyDetail = result['data'];
          _isLoading = false;
        });
      } else {
        throw Exception(result['msg'] ?? '获取处罚详情失败');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      CustomToast.show(
        context,
        message: '加载处罚详情失败: $e',
        type: ToastType.error,
      );
    }
  }

  Future<void> _revokePenalty() async {
    if (_revokeReasonController.text.trim().isEmpty) {
      CustomToast.show(
        context,
        message: '请填写撤销原因',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await _service.revokePenalty(
        widget.penaltyId,
        _revokeReasonController.text.trim(),
      );

      if (result['code'] == 0) {
        CustomToast.show(
          context,
          message: result['msg'] ?? '撤销处罚成功',
          type: ToastType.success,
        );

        // 刷新数据
        await _loadPenaltyDetail();

        // 返回上一页并刷新列表
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(result['msg'] ?? '撤销处罚失败');
      }
    } catch (e) {
      CustomToast.show(
        context,
        message: '撤销失败: $e',
        type: ToastType.error,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showRevokeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('撤销处罚'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '确定要撤销此处罚吗？',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _revokeReasonController,
                decoration: InputDecoration(
                  labelText: '撤销原因',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _revokePenalty();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('确认撤销'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        title: Text('处罚详情 #${widget.penaltyId}'),
        actions: [
          if (_penaltyDetail != null &&
              _penaltyDetail!['status'] == PenaltyStatus.active)
            TextButton.icon(
              icon: Icon(
                Icons.cancel_outlined,
                size: 20.sp,
                color: Colors.red.shade700,
              ),
              label: Text(
                '撤销处罚',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 14.sp,
                ),
              ),
              onPressed: _showRevokeDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _penaltyDetail == null
              ? Center(
                  child: Text(
                    '获取处罚详情失败',
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
                      _buildPenaltyInfoCard(),
                      SizedBox(height: 16.h),
                      _buildContentCard(),
                      SizedBox(height: 16.h),
                      _buildReportCard(),
                      SizedBox(height: 16.h),
                      if (_penaltyDetail!['status'] == PenaltyStatus.revoked)
                        _buildRevokeInfoCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPenaltyInfoCard() {
    final int status = _penaltyDetail?['status'] ?? PenaltyStatus.active;
    final int penaltyType =
        _penaltyDetail?['penalty_type'] ?? PenaltyType.warning;

    Color statusColor;
    switch (status) {
      case PenaltyStatus.active:
        statusColor = Colors.red;
        break;
      case PenaltyStatus.expired:
        statusColor = Colors.grey;
        break;
      case PenaltyStatus.revoked:
        statusColor = Colors.orange;
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
                  Icons.gavel,
                  size: 20.sp,
                  color: statusColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  '处罚信息',
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
                    PenaltyStatus.getName(status),
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
            _buildInfoItem('处罚类型', PenaltyType.getName(penaltyType)),
            if (penaltyType == PenaltyType.authorBanTemp &&
                _penaltyDetail?['duration'] != null)
              _buildInfoItem('封禁时长', '${_penaltyDetail!['duration']}天'),
            SizedBox(height: 8.h),
            _buildInfoItem('处理人', _penaltyDetail?['operator_name'] ?? '未知'),
            SizedBox(height: 8.h),
            _buildInfoItem(
                '处罚时间', _formatDateTime(_penaltyDetail?['created_at'])),
            if (status == PenaltyStatus.active &&
                _penaltyDetail?['expiry_time'] != null) ...[
              SizedBox(height: 8.h),
              _buildInfoItem(
                  '到期时间', _formatDateTime(_penaltyDetail?['expiry_time'])),
            ],
            SizedBox(height: 8.h),
            _buildInfoItem('处罚原因', _penaltyDetail?['reason'] ?? '无处罚原因',
                isMultiLine: true),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard() {
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
                  '被处罚内容',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24.h),
            _buildInfoItem(
                '内容ID', _penaltyDetail?['item_id']?.toString() ?? '未知'),
            SizedBox(height: 8.h),
            _buildInfoItem('内容标题', _penaltyDetail?['item_title'] ?? '未知内容'),
            SizedBox(height: 8.h),
            _buildInfoItem(
                '作者ID', _penaltyDetail?['author_id']?.toString() ?? '未知'),
            SizedBox(height: 8.h),
            _buildInfoItem('作者名称', _penaltyDetail?['author_name'] ?? '未知'),
            SizedBox(height: 8.h),
            _buildInfoItem('内容摘要', _penaltyDetail?['item_content'] ?? '无内容摘要',
                isMultiLine: true),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard() {
    final reportData = _penaltyDetail?['report'];
    if (reportData == null) return const SizedBox.shrink();

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
                  color: Colors.orange,
                ),
                SizedBox(width: 8.w),
                Text(
                  '相关举报',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24.h),
            _buildInfoItem('举报ID', reportData['id']?.toString() ?? '未知'),
            SizedBox(height: 8.h),
            _buildInfoItem('举报人', reportData['reporter_name'] ?? '未知'),
            SizedBox(height: 8.h),
            _buildInfoItem('举报时间', _formatDateTime(reportData['created_at'])),
            SizedBox(height: 8.h),
            _buildInfoItem('举报内容', reportData['content'] ?? '无举报内容',
                isMultiLine: true),

            // 举报证据
            if (reportData['evidence'] != null &&
                (reportData['evidence'] as List).isNotEmpty) ...[
              SizedBox(height: 16.h),
              Text(
                '举报证据',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8.w,
                  mainAxisSpacing: 8.h,
                ),
                itemCount: (reportData['evidence'] as List).length,
                itemBuilder: (context, index) {
                  final String uri =
                      (reportData['evidence'] as List)[index].toString();
                  return GestureDetector(
                    onTap: () => _showImagePreview(uri),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        image: DecorationImage(
                          image: NetworkImage("/api/v1/files?uri=$uri"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRevokeInfoCard() {
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
                  Icons.cancel_outlined,
                  size: 20.sp,
                  color: Colors.orange,
                ),
                SizedBox(width: 8.w),
                Text(
                  '撤销信息',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24.h),
            _buildInfoItem(
                '撤销人', _penaltyDetail?['revoke_operator_name'] ?? '未知'),
            SizedBox(height: 8.h),
            _buildInfoItem(
                '撤销时间', _formatDateTime(_penaltyDetail?['revoke_time'])),
            SizedBox(height: 8.h),
            _buildInfoItem('撤销原因', _penaltyDetail?['revoke_reason'] ?? '无撤销原因',
                isMultiLine: true),
          ],
        ),
      ),
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
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.network(
                    "/api/v1/files?uri=$uri",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
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
}
