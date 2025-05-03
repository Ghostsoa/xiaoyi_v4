import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/file_service.dart';
import '../services/character_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_toast.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';
import '../../create/character/select_model_page.dart';

class CharacterPanelPage extends StatefulWidget {
  final Map<String, dynamic> characterData;

  const CharacterPanelPage({
    super.key,
    required this.characterData,
  });

  @override
  State<CharacterPanelPage> createState() => _CharacterPanelPageState();
}

class _CharacterPanelPageState extends State<CharacterPanelPage> {
  final FileService _fileService = FileService();
  final CharacterService _characterService = CharacterService();

  Uint8List? _coverImage;
  bool _isLoadingCover = false;
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _sessionData = {};
  final Map<String, dynamic> _editedData = {};
  String? _error;

  final _settingController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _topPController = TextEditingController();
  final _topKController = TextEditingController();
  final _maxTokensController = TextEditingController();
  final _memoryTurnsController = TextEditingController();
  final _searchDepthController = TextEditingController();
  final _greetingController = TextEditingController();
  final _prefixController = TextEditingController();
  final _suffixController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  @override
  void dispose() {
    _settingController.dispose();
    _temperatureController.dispose();
    _topPController.dispose();
    _topKController.dispose();
    _maxTokensController.dispose();
    _memoryTurnsController.dispose();
    _searchDepthController.dispose();
    _greetingController.dispose();
    _prefixController.dispose();
    _suffixController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _characterService
          .getCharacterSession(widget.characterData['id']);
      if (!mounted) return;

      setState(() {
        _sessionData = data;
        _isLoading = false;
      });

      // 加载封面图
      if (data['coverUri'] != null) {
        _loadCoverImage(data['coverUri']);
      }

      // 初始化编辑器的值
      _settingController.text = data['setting'] ?? '';
      _temperatureController.text = (data['temperature'] ?? 0.7).toString();
      _topPController.text = (data['topP'] ?? 0.9).toString();
      _topKController.text = (data['topK'] ?? 40).toString();
      _maxTokensController.text = (data['maxTokens'] ?? 2000).toString();
      _memoryTurnsController.text = (data['memoryTurns'] ?? 10).toString();
      _searchDepthController.text = (data['searchDepth'] ?? 5).toString();
      _greetingController.text = data['greeting'] ?? '';
      _prefixController.text = data['prefix'] ?? '';
      _suffixController.text = data['suffix'] ?? '';
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCoverImage(String coverUri) async {
    if (_isLoadingCover || _coverImage != null) return;

    _isLoadingCover = true;
    try {
      final result = await _fileService.getFile(coverUri);
      if (mounted) {
        setState(() {
          _coverImage = result.data;
          _isLoadingCover = false;
        });
      }
    } catch (e) {
      debugPrint('封面图加载失败: $e');
      if (mounted) {
        setState(() => _isLoadingCover = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_editedData.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      await _characterService.updateCharacterSession(
        widget.characterData['id'],
        _editedData,
      );

      if (!mounted) return;

      CustomToast.show(
        context,
        message: '保存成功',
        type: ToastType.success,
      );

      // 重新加载数据
      await _loadSessionData();

      // 清空编辑数据
      _editedData.clear();
    } catch (e) {
      if (!mounted) return;
      CustomToast.show(
        context,
        message: e.toString(),
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _updateField(String field, dynamic value) {
    if (_sessionData[field] == value) return; // 如果值没有变化，不更新
    setState(() {
      _editedData[field] = value;
    });
  }

  Widget _buildEditableInfoItem(
    String label,
    String field,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? suffix,
    bool enabled = true,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14.sp,
                ),
              ),
              if (suffix != null) ...[
                SizedBox(width: 4.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: enabled
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    suffix,
                    style: TextStyle(
                      color: enabled ? AppTheme.primaryColor : Colors.grey,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),
          if (enabled)
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
              ),
              onChanged: (value) {
                if (keyboardType == TextInputType.number ||
                    keyboardType ==
                        const TextInputType.numberWithOptions(decimal: true)) {
                  final num? parsedValue = num.tryParse(value);
                  if (parsedValue != null) {
                    _updateField(field, parsedValue);
                  }
                } else {
                  _updateField(field, value);
                }
              },
            )
          else
            Text(
              '无法查看和编辑',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModelInfoCard() {
    return _buildSectionCard(
      title: 'AI模型配置',
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '模型',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      '可编辑',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelectModelPage(),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _updateField('model_name', result);
                      // 同时更新显示的数据
                      _sessionData['model_name'] = result;
                    });
                  }
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _sessionData['model_name'] ?? '未知',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16.sp,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '温度',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '可编辑',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _temperatureController.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
                  thumbColor: AppTheme.primaryColor,
                  overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                  trackHeight: 4.h,
                ),
                child: Slider(
                  value: double.tryParse(_temperatureController.text) ?? 0.7,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  onChanged: (value) {
                    setState(() {
                      _temperatureController.text = value.toStringAsFixed(2);
                      _updateField('temperature', value);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Top P',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '可编辑',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _topPController.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
                  thumbColor: AppTheme.primaryColor,
                  overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                  trackHeight: 4.h,
                ),
                child: Slider(
                  value: double.tryParse(_topPController.text) ?? 0.9,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  onChanged: (value) {
                    setState(() {
                      _topPController.text = value.toStringAsFixed(2);
                      _updateField('topP', value);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Top K',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '可编辑',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _topKController.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
                  thumbColor: AppTheme.primaryColor,
                  overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                  trackHeight: 4.h,
                ),
                child: Slider(
                  value:
                      double.tryParse(_topKController.text)?.toDouble() ?? 40,
                  min: 1,
                  max: 100,
                  divisions: 99,
                  onChanged: (value) {
                    setState(() {
                      _topKController.text = value.toInt().toString();
                      _updateField('topK', value.toInt());
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '最大Token',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '可编辑',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _maxTokensController.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
                  thumbColor: AppTheme.primaryColor,
                  overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                  trackHeight: 4.h,
                ),
                child: Slider(
                  value:
                      double.tryParse(_maxTokensController.text)?.toDouble() ??
                          2000,
                  min: 100,
                  max: 8196,
                  divisions: 81,
                  onChanged: (value) {
                    setState(() {
                      _maxTokensController.text = value.toInt().toString();
                      _updateField('maxTokens', value.toInt());
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '记忆轮数',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '可编辑',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _memoryTurnsController.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
                  thumbColor: AppTheme.primaryColor,
                  overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                  trackHeight: 4.h,
                ),
                child: Slider(
                  value: double.tryParse(_memoryTurnsController.text)
                          ?.toDouble() ??
                      10,
                  min: 1,
                  max: 500,
                  divisions: 499,
                  onChanged: (value) {
                    setState(() {
                      _memoryTurnsController.text = value.toInt().toString();
                      _updateField('memoryTurns', value.toInt());
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '搜索深度',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '可编辑',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _searchDepthController.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
                  thumbColor: AppTheme.primaryColor,
                  overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                  trackHeight: 4.h,
                ),
                child: Slider(
                  value: double.tryParse(_searchDepthController.text)
                          ?.toDouble() ??
                      5,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() {
                      _searchDepthController.text = value.toInt().toString();
                      _updateField('searchDepth', value.toInt());
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionCard() {
    return _buildSectionCard(
      title: '交互设置',
      children: [
        _buildEditableInfoItem(
          '问候语',
          'greeting',
          _greetingController,
          suffix: '可编辑',
        ),
        _buildEditableInfoItem(
          '前缀',
          'prefix',
          _prefixController,
          suffix: '可编辑',
        ),
        _buildEditableInfoItem(
          '后缀',
          'suffix',
          _suffixController,
          suffix: '可编辑',
        ),
        _buildInfoItem(
            '设定可编辑', _sessionData['settingEditable'] == true ? '是' : '否'),
        _buildInfoItem('总对话轮数', (_sessionData['totalTurns'] ?? 0).toString()),
        if (_sessionData['lastMessage']?.isNotEmpty == true)
          _buildInfoItem('最后消息', _sessionData['lastMessage']),
      ],
    );
  }

  Widget _buildAuthorCard() {
    String formatDateTime(String? dateTimeStr) {
      if (dateTimeStr == null) return '未知';
      try {
        return DateTime.parse(dateTimeStr).toLocal().toString().split('.')[0];
      } catch (e) {
        return '未知';
      }
    }

    return _buildSectionCard(
      title: '创作信息',
      children: [
        _buildInfoItem('作者', _sessionData['authorName'] ?? '未知'),
        _buildInfoItem('创建时间', formatDateTime(_sessionData['createdAt'])),
        _buildInfoItem('更新时间', formatDateTime(_sessionData['updatedAt'])),
      ],
    );
  }

  Widget _buildShimmerCard({
    required String title,
    required int itemCount,
  }) {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            ...List.generate(
              itemCount,
              (index) => Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[800]!,
                  highlightColor: Colors.grey[600]!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: double.infinity,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(4.r),
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
    );
  }

  Widget _buildLoadingContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerCard(title: '基本信息', itemCount: 3),
          SizedBox(height: 16.h),
          _buildShimmerCard(title: '人设信息', itemCount: 1),
          SizedBox(height: 16.h),
          _buildShimmerCard(title: 'AI模型配置', itemCount: 7),
          SizedBox(height: 16.h),
          _buildShimmerCard(title: '交互设置', itemCount: 6),
          SizedBox(height: 16.h),
          _buildShimmerCard(title: '创作信息', itemCount: 3),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('角色信息'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '加载失败',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: _loadSessionData,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '角色信息',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_editedData.isNotEmpty && !_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      '保存',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingContent()
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基本信息
                  _buildSectionCard(
                    title: '基本信息',
                    children: [
                      _buildInfoItem('名称', _sessionData['name'] ?? '未知'),
                      _buildInfoItem(
                          '描述', _sessionData['description'] ?? '暂无描述'),
                      if (_sessionData['tags'] != null)
                        _buildInfoItem(
                          '标签',
                          (_sessionData['tags'] as List<dynamic>)
                              .map((tag) => '#$tag')
                              .join(' '),
                        ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  // 人设信息
                  if (_sessionData['setting'] != null)
                    _buildSectionCard(
                      title: '人设信息',
                      children: [
                        _buildEditableInfoItem(
                          '人设',
                          'setting',
                          _settingController,
                          enabled: _sessionData['settingEditable'] == true,
                          suffix: _sessionData['settingEditable'] == true
                              ? '可编辑'
                              : '不可编辑',
                        ),
                      ],
                    ),
                  SizedBox(height: 16.h),
                  // AI模型配置
                  _buildModelInfoCard(),
                  SizedBox(height: 16.h),
                  // 交互设置
                  _buildInteractionCard(),
                  SizedBox(height: 16.h),
                  // 创作信息
                  _buildAuthorCard(),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
