import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import 'violation_monitoring_service.dart';

class ViolationDetailPage extends StatefulWidget {
  final int violationId;

  const ViolationDetailPage({
    super.key,
    required this.violationId,
  });

  @override
  State<ViolationDetailPage> createState() => _ViolationDetailPageState();
}

class _ViolationDetailPageState extends State<ViolationDetailPage> {
  final ViolationMonitoringService _service = ViolationMonitoringService();
  
  Map<String, dynamic>? _violation;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadViolationDetail();
  }

  Future<void> _loadViolationDetail() async {
    try {
      final response = await _service.getViolationDetail(widget.violationId);
      if (response['code'] == 0) {
        final data = response['data'];
        if (data['items'] != null && data['items'].isNotEmpty) {
          setState(() {
            _violation = data['items'][0];
          });
        }
      } else {
        if (mounted) {
          CustomToast.show(context, message: response['msg'] ?? '获取详情失败', type: ToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '获取详情失败: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateRiskLevel(String riskLevel, String reason) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await _service.updateRiskLevel(
        widget.violationId,
        riskLevel,
        reason,
      );

      if (response['code'] == 0) {
        if (mounted) {
          CustomToast.show(context, message: '更新风控级别成功', type: ToastType.success);
        }
        _loadViolationDetail(); // 重新加载数据
      } else {
        if (mounted) {
          CustomToast.show(context, message: response['msg'] ?? '更新失败', type: ToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '更新失败: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _deleteViolation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除这条违规监测记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _service.deleteViolation(widget.violationId);
        if (response['code'] == 0) {
          if (mounted) {
            CustomToast.show(context, message: '删除成功', type: ToastType.success);
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            CustomToast.show(context, message: response['msg'] ?? '删除失败', type: ToastType.error);
          }
        }
      } catch (e) {
        if (mounted) {
          CustomToast.show(context, message: '删除失败: $e', type: ToastType.error);
        }
      }
    }
  }

  void _showUpdateRiskLevelDialog() {
    String selectedRiskLevel = 'suspicious';
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('更新风控级别'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedRiskLevel,
              decoration: InputDecoration(
                labelText: '风控级别',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'suspicious', child: Text('可疑行为')),
                DropdownMenuItem(value: 'malicious', child: Text('恶意行为')),
              ],
              onChanged: (value) {
                selectedRiskLevel = value!;
              },
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: '更新原因',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context);
                _updateRiskLevel(selectedRiskLevel, reasonController.text);
              } else {
                CustomToast.show(context, message: '请填写更新原因', type: ToastType.error);
              }
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  String _getCardTypeLabel(String? cardType) {
    switch (cardType) {
      case 'character_card':
        return '角色卡';
      case 'novel_card':
        return '小说卡';
      case 'group_chat_card':
        return '群聊卡';
      default:
        return '未知';
    }
  }

  String _getRiskLevelLabel(String? riskLevel) {
    switch (riskLevel) {
      case 'suspicious':
        return '可疑行为';
      case 'malicious':
        return '恶意行为';
      default:
        return '未知';
    }
  }

  Color _getRiskLevelColor(String? riskLevel) {
    switch (riskLevel) {
      case 'suspicious':
        return Colors.orange;
      case 'malicious':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 安全地获取会话ID列表字符串
  String _getSessionIdsString(dynamic sessionIds) {
    try {
      if (sessionIds == null) return '无';
      if (sessionIds is List) {
        return sessionIds.map((id) => id.toString()).join(', ');
      }
      if (sessionIds is String) {
        try {
          final parsed = jsonDecode(sessionIds);
          if (parsed is List) {
            return parsed.map((id) => id.toString()).join(', ');
          }
        } catch (e) {
          // 如果解析失败，直接返回字符串
          return sessionIds;
        }
      }
      return sessionIds.toString();
    } catch (e) {
      return '解析错误';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryColor;
    final background = AppTheme.background;
    final surfaceColor = AppTheme.cardBackground;
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        title: Text(
          '违规监测详情',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
        actions: [
          if (!_isLoading && _violation != null) ...[
            IconButton(
              icon: Icon(Icons.edit_outlined),
              onPressed: _isUpdating ? null : _showUpdateRiskLevelDialog,
              tooltip: '更新风控级别',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteViolation,
              tooltip: '删除记录',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : _violation == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64.sp,
                        color: textSecondary.withOpacity(0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '未找到违规记录',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoCard(),
                      SizedBox(height: 16.h),
                      _buildRiskLevelsCard(),
                      SizedBox(height: 16.h),
                      _buildInvolvedContentCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBasicInfoCard() {
    final primaryColor = AppTheme.primaryColor;
    final surfaceColor = AppTheme.cardBackground;
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;

    return Card(
      color: surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本信息',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            _buildInfoRow('记录ID', '${_violation!['id']}'),
            _buildInfoRow('用户ID', '${_violation!['user_id']}'),
            _buildInfoRow('被害人ID', '${_violation!['victim_id'] ?? '未知'}'),
            _buildInfoRow('卡片类型', _getCardTypeLabel(_violation!['card_type'])),
            _buildInfoRow('相关卡片ID', '${_violation!['related_card_id'] ?? '未知'}'),
            _buildInfoRow('相关卡片名称', _violation!['related_card_name'] ?? '未知'),
            _buildInfoRow('会话ID列表', _getSessionIdsString(_violation!['session_ids'])),
            _buildInfoRow('创建时间', _violation!['created_at'] ?? ''),
            _buildInfoRow('更新时间', _violation!['updated_at'] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskLevelsCard() {
    final surfaceColor = AppTheme.cardBackground;
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;

    final riskLevels = _violation!['risk_levels'] as List<dynamic>? ?? [];

    return Card(
      color: surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '风控记录',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            if (riskLevels.isEmpty)
              Text(
                '暂无风控记录',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: textSecondary,
                ),
              )
            else
              ...riskLevels.map((risk) => _buildRiskLevelItem(risk)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInvolvedContentCard() {
    final surfaceColor = AppTheme.cardBackground;
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;

    final involvedContent = _violation!['involved_content'] as List<dynamic>? ?? [];

    return Card(
      color: surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '涉及内容',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            if (involvedContent.isEmpty)
              Text(
                '暂无涉及内容',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: textSecondary,
                ),
              )
            else
              ...involvedContent.map((content) => _buildContentItem(content)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentItem(Map<String, dynamic> content) {
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部信息
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16.sp,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 8.w),
              Text(
                '会话ID: ${content['session_id'] ?? '未知'}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                content['time'] ?? '',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // 用户输入
          if (content['user_input'] != null) ...[
            Text(
              '用户输入:',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              content['user_input'],
              style: TextStyle(
                fontSize: 12.sp,
                color: textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
          ],

          // 用户设定
          if (content['user_setting'] != null) ...[
            Text(
              '用户设定:',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              content['user_setting'],
              style: TextStyle(
                fontSize: 12.sp,
                color: textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
          ],

          // 额外数据
          if (content['extra_data'] != null) ...[
            ExpansionTile(
              title: Text(
                '详细数据',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    _formatExtraData(content['extra_data']),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatExtraData(dynamic extraData) {
    try {
      if (extraData is Map) {
        return extraData.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
      }
      return extraData.toString();
    } catch (e) {
      return '数据格式错误';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLevelItem(Map<String, dynamic> risk) {
    final textPrimary = AppTheme.textPrimary;
    final textSecondary = AppTheme.textSecondary;
    final riskLevel = risk['risk_level'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _getRiskLevelColor(riskLevel).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: _getRiskLevelColor(riskLevel).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getRiskLevelColor(riskLevel),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  _getRiskLevelLabel(riskLevel),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '会话ID: ${risk['session_id'] ?? '未知'}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            risk['reason'] ?? '无原因说明',
            style: TextStyle(
              fontSize: 13.sp,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '时间: ${risk['time'] ?? ''}',
            style: TextStyle(
              fontSize: 11.sp,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
