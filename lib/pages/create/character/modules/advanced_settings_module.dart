import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
import 'dart:math' as math;
import '../../../../theme/app_theme.dart';
import '../../../../widgets/custom_toast.dart';
import '../../world/select_world_book_page.dart';
import '../../material/select_text_page.dart';
import '../../material/select_image_page.dart';
import '../../../../services/file_service.dart';
import '../../../../utils/resource_mapping_parser.dart';

class AdvancedSettingsModule extends StatefulWidget {
  final int memoryTurns;
  final int searchDepth;
  final String status;
  final String uiSettings;
  final List<Map<String, dynamic>> selectedWorldBooks;
  final TextEditingController prefixController;
  final TextEditingController suffixController;
  final String enhanceMode;
  final TextEditingController resourceMappingController;
  final Map<String, Uint8List> imageCache;
  final Function(int) onMemoryTurnsChanged;
  final Function(int) onSearchDepthChanged;
  final Function(String) onStatusChanged;
  final Function(String) onUiSettingsChanged;
  final Function(List<Map<String, dynamic>>) onWorldBooksChanged;
  final Function(Map<String, dynamic>) onWorldbookMapChanged;
  final Function(String) onEnhanceModeChanged;

  const AdvancedSettingsModule({
    super.key,
    required this.memoryTurns,
    required this.searchDepth,
    required this.status,
    required this.uiSettings,
    required this.selectedWorldBooks,
    required this.prefixController,
    required this.suffixController,
    required this.enhanceMode,
    required this.resourceMappingController,
    required this.imageCache,
    required this.onMemoryTurnsChanged,
    required this.onSearchDepthChanged,
    required this.onStatusChanged,
    required this.onUiSettingsChanged,
    required this.onWorldBooksChanged,
    required this.onWorldbookMapChanged,
    required this.onEnhanceModeChanged,
  });

  @override
  State<AdvancedSettingsModule> createState() => _AdvancedSettingsModuleState();
}

class _AdvancedSettingsModuleState extends State<AdvancedSettingsModule> {
  final _fileService = FileService();

  void _showToast(String message, {ToastType type = ToastType.info}) {
    if (!mounted) return;
    CustomToast.show(context, message: message, type: type);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h, bottom: 16.h),
      child: Text(
        title,
        style: AppTheme.titleStyle.copyWith(
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildStatusButton(String value, String label, IconData icon) {
    final bool isSelected = widget.status == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onStatusChanged(value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.border,
            ),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: AppTheme.bodySize,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUiSettingsButton(String value, String label, IconData icon) {
    final bool isSelected = widget.uiSettings == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onUiSettingsChanged(value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.border,
            ),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectButton({
    required String title,
    required TextSelectType type,
    required Function(String) onSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectTextPage(
              source: TextSelectSource.myMaterial,
              type: type,
            ),
          ),
        );
        if (result != null && mounted) {
          onSelected(result);
          _showToast(
            '已导入${type == TextSelectType.prefix ? "前缀词" : "后缀词"}',
            type: ToastType.success,
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppTheme.buttonGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(6.r),
          boxShadow: [
            BoxShadow(
              color: AppTheme.buttonGradient.first.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.format_quote_outlined,
              size: 16.sp,
              color: Colors.white,
            ),
            SizedBox(width: 4.w),
            Text(
              '选择',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String title,
    required TextEditingController controller,
    required String hintText,
    required TextSelectType type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppTheme.secondaryStyle),
            const Spacer(),
            _buildSelectButton(
              title: title,
              type: type,
              onSelected: (value) {
                controller.text = value;
              },
            ),
          ],
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: AppTheme.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
          ),
          minLines: 1,
          maxLines: null,
        ),
      ],
    );
  }

  Widget _buildEnhanceModeButton(
      String value, String label, String description) {
    final bool isSelected = widget.enhanceMode == value;
    return GestureDetector(
      onTap: () => widget.onEnhanceModeChanged(value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.border,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.border,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 14.sp,
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimary,
                    fontSize: 14.sp,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: AppTheme.hintStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建资源映射卡片
  Widget _buildResourceCard(ResourceMapping resource) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // 小图片
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: AppTheme.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: FutureBuilder(
                future: widget.imageCache[resource.uri] != null
                    ? Future.value(widget.imageCache[resource.uri])
                    : _fileService.getFile(resource.uri).then((file) {
                        return file.data;
                      }),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.hasError) {
                    return Icon(
                      Icons.image_outlined,
                      size: 20.sp,
                      color: AppTheme.textSecondary,
                    );
                  }
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // 资源名称
          Expanded(
            child: Text(
              resource.name,
              style: AppTheme.bodyStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 删除按钮
          GestureDetector(
            onTap: () => _removeResource(resource),
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Icon(
                Icons.delete_outline,
                size: 18.sp,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 添加资源
  void _addResource() async {
    // 限制最多 30 个资源映射
    final existing = ResourceMappingParser.parseResourceMappings(
      widget.resourceMappingController.text,
    );
    if (existing.length >= 30) {
      _showToast('最多可添加30个资源映射', type: ToastType.warning);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectImagePage(
          type: ImageSelectType.cover,
          source: ImageSelectSource.myMaterial,
        ),
      ),
    );

    if (result != null && mounted) {
      // 弹出对话框让用户输入资源名称
      _showResourceNameDialog(result);
    }
  }

  /// 显示资源名称输入对话框
  void _showResourceNameDialog(String uri) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('输入资源名称', style: AppTheme.titleStyle),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: '请输入资源名称',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              // 二次校验上限，防止并发或多入口绕过
              final resources = ResourceMappingParser.parseResourceMappings(
                widget.resourceMappingController.text,
              );
              if (resources.length >= 30) {
                _showToast('最多可添加30个资源映射', type: ToastType.warning);
                return;
              }

              final name = nameController.text.trim();
              if (name.isNotEmpty && ResourceMappingParser.isValidResourceName(name)) {
                final newText = ResourceMappingParser.addResource(
                  widget.resourceMappingController.text,
                  name,
                  uri,
                );
                widget.resourceMappingController.text = newText;
                Navigator.pop(context);
                _showToast('已添加资源：$name', type: ToastType.success);
                setState(() {}); // 刷新UI
              } else {
                _showToast('请输入有效的资源名称', type: ToastType.warning);
              }
            },
            child: Text('确定', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  /// 移除资源
  void _removeResource(ResourceMapping resource) {
    final newText = ResourceMappingParser.removeResource(
      widget.resourceMappingController.text,
      resource,
    );
    widget.resourceMappingController.text = newText;
    _showToast('已移除资源：${resource.name}', type: ToastType.success);
    setState(() {}); // 刷新UI
  }

  @override
  Widget build(BuildContext context) {
    // 计算关键词总数
    int totalKeywords = 0;
    for (var worldBook in widget.selectedWorldBooks) {
      if (worldBook['keywords'] != null) {
        totalKeywords += (worldBook['keywords'] as List).length;
      }
    }

    // 资源映射计数与上限
    final currentResources = ResourceMappingParser.parseResourceMappings(
      widget.resourceMappingController.text,
    );
    const int resourceLimit = 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('高级设定'),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '记忆轮数',
                    style: AppTheme.secondaryStyle,
                  ),
                  Text(
                    widget.memoryTurns.toString(),
                    style: AppTheme.bodyStyle,
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              RichText(
                text: TextSpan(
                  style: AppTheme.hintStyle,
                  children: [
                    const TextSpan(text: '角色能记住的对话轮数，数值越大记忆越长，但会消耗更多'),
                    TextSpan(
                      text: 'Token',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
                  value: widget.memoryTurns.toDouble(),
                  min: 1,
                  max: 500,
                  divisions: 499,
                  onChanged: (value) =>
                      widget.onMemoryTurnsChanged(value.toInt()),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '搜索深度',
                    style: AppTheme.secondaryStyle,
                  ),
                  Text(
                    widget.searchDepth.toString(),
                    style: AppTheme.bodyStyle,
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              RichText(
                text: TextSpan(
                  style: AppTheme.hintStyle,
                  children: [
                    const TextSpan(text: '检索最近'),
                    TextSpan(
                      text: 'N轮对话',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '中出现的'),
                    TextSpan(
                      text: '世界书关键词',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，查询数据库，给予模型参考'),
                  ],
                ),
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
                  value: widget.searchDepth.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) =>
                      widget.onSearchDepthChanged(value.toInt()),
                ),
              ),
              SizedBox(height: 24.h),
              _buildInputField(
                title: '前缀词',
                controller: widget.prefixController,
                hintText: '可选，例如：(xxx)',
                type: TextSelectType.prefix,
              ),
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: RichText(
                  text: TextSpan(
                    style: AppTheme.hintStyle,
                    children: [
                      const TextSpan(text: '在每次发送给模型的消息'),
                      TextSpan(
                        text: '前',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '添加的固定文本，用于增强角色设定'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _buildInputField(
                title: '后缀词',
                controller: widget.suffixController,
                hintText: '可选，例如：(xxx)',
                type: TextSelectType.suffix,
              ),
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: RichText(
                  text: TextSpan(
                    style: AppTheme.hintStyle,
                    children: [
                      const TextSpan(text: '在每次发送给模型的消息'),
                      TextSpan(
                        text: '后',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '添加的固定文本，用于增强角色设定'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '世界书',
                    style: AppTheme.secondaryStyle,
                  ),
                  if (widget.selectedWorldBooks.isNotEmpty)
                    Text(
                      '已选择 ${widget.selectedWorldBooks.length} 个 · $totalKeywords 个关键词',
                      style: AppTheme.hintStyle,
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              RichText(
                text: TextSpan(
                  style: AppTheme.hintStyle,
                  children: [
                    const TextSpan(text: '为角色添加'),
                    TextSpan(
                      text: '背景知识库',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，当对话中出现'),
                    TextSpan(
                      text: '关键词',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '时会自动调用相关知识'),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectWorldBookPage(
                        source: WorldBookSelectSource.myWorldBook,
                        initialSelected: widget.selectedWorldBooks,
                      ),
                    ),
                  );
                  if (result != null && mounted) {
                    final selectedBooks =
                        List<Map<String, dynamic>>.from(result);
                    widget.onWorldBooksChanged(selectedBooks);

                    final Map<String, dynamic> worldbookMap = {};
                    for (var worldBook in selectedBooks) {
                      final id = worldBook['id'].toString();
                      final keywords =
                          List<dynamic>.from(worldBook['keywords'] as List);
                      for (var keyword in keywords) {
                        worldbookMap[keyword.toString()] = id;
                      }
                    }
                    widget.onWorldbookMapChanged(worldbookMap);
                    _showToast('已选择 ${selectedBooks.length} 个世界书');
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppTheme.buttonGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: const GradientRotation(0.4),
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.buttonGradient.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.public, size: 20.sp, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        '选择世界书',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppTheme.bodySize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'UI格式化类型',
                style: AppTheme.secondaryStyle,
              ),
              SizedBox(height: 4.h),
              RichText(
                text: TextSpan(
                  style: AppTheme.hintStyle,
                  children: [
                    const TextSpan(text: '选择对话界面的'),
                    TextSpan(
                      text: '渲染格式',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，设置用户使用角色卡时'),
                    TextSpan(
                      text: '默认UI样式',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，用户可根据需要调整'),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  _buildUiSettingsButton(
                      'markdown', 'Markdown\n格式化', Icons.text_fields),
                  SizedBox(width: 8.w),
                  _buildUiSettingsButton(
                      'disabled', '标准\n模式', Icons.chat_outlined),
                  SizedBox(width: 8.w),
                  _buildUiSettingsButton(
                      'legacy_bar', '兼容\n模式', Icons.view_stream),
                ],
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: RichText(
                  text: TextSpan(
                    style: AppTheme.hintStyle.copyWith(fontSize: 11.sp),
                    children: [
                      TextSpan(
                        text: 'Markdown格式化：',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '支持富文本格式、增强优化版\n'),
                      TextSpan(
                        text: '标准模式：',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '普通聊天界面，无特殊格式化\n'),
                      TextSpan(
                        text: '新版UI样式：',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '新版UI样式'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                '回复增强',
                style: AppTheme.secondaryStyle,
              ),
              SizedBox(height: 4.h),
              RichText(
                text: TextSpan(
                  style: AppTheme.hintStyle,
                  children: [
                    const TextSpan(text: '利用'),
                    TextSpan(
                      text: '特殊技术',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '增强角色的'),
                    TextSpan(
                      text: '回复质量',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，选择合适的模式获得更好的体验'),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              _buildEnhanceModeButton('disabled', '禁用回复增强', '使用原生模型输出，不进行特殊处理'),
              _buildEnhanceModeButton(
                  'full', '回复增强', '对所有回复进行增强，大幅度提升\n回复质量，文笔，内容，逻辑，等'),
              _buildEnhanceModeButton(
                  'partial', '回复UI增强', '对UI显示效果，内容进行增强\n平衡了UI显示与回复质量'),
              _buildEnhanceModeButton('fullpromax', '???', '???'),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '资源映射',
                    style: AppTheme.secondaryStyle,
                  ),
                  Text(
                    '${currentResources.length}/$resourceLimit',
                    style: AppTheme.hintStyle,
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              RichText(
                text: TextSpan(
                  style: AppTheme.hintStyle,
                  children: [
                    const TextSpan(text: '为卡添加'),
                    TextSpan(
                      text: '图片资源',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '，可在对话中通过名称引用显示'),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              // 解析并显示现有资源
              Builder(
                builder: (context) {
                  final resources = currentResources;

                  final bool canAdd = resources.length < 30;

                  // 智能高度：最多显示 3 个条目的高度，少于则按实际数量
                  final int visibleCount = math.min(resources.length, 3);
                  final double estimatedItemHeight = 72.h; // 估算单项高度(含间距)
                  final double listHeight = visibleCount > 0
                      ? visibleCount * estimatedItemHeight
                      : 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (resources.isNotEmpty)
                        SizedBox(
                          height: listHeight,
                          child: ListView.builder(
                            itemCount: resources.length,
                            shrinkWrap: true,
                            physics: resources.length > 3
                                ? const ClampingScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) =>
                                _buildResourceCard(resources[index]),
                          ),
                        ),
                      if (resources.isNotEmpty) SizedBox(height: 8.h),
                      // 添加资源按钮（达到上限禁用）
                      GestureDetector(
                        onTap: canAdd
                            ? _addResource
                            : () => _showToast('最多可添加30个资源映射',
                                type: ToastType.warning),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            gradient: canAdd
                                ? LinearGradient(
                                    colors: AppTheme.buttonGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    transform: const GradientRotation(0.4),
                                  )
                                : null,
                            color:
                                canAdd ? null : AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: canAdd
                                ? [
                                    BoxShadow(
                                      color: AppTheme.buttonGradient.first
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                            border: canAdd
                                ? null
                                : Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 20.sp,
                                color: canAdd
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                canAdd ? '从素材库选择' : '已达上限 (30)',
                                style: TextStyle(
                                  color: canAdd
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontSize: AppTheme.bodySize,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 24.h),
              Text(
                '发布状态',
                style: AppTheme.secondaryStyle,
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  _buildStatusButton('draft', '草稿', Icons.edit_outlined),
                  SizedBox(width: 8.w),
                  _buildStatusButton('published', '发布', Icons.public),
                  SizedBox(width: 8.w),
                  _buildStatusButton('private', '私密', Icons.lock_outline),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
