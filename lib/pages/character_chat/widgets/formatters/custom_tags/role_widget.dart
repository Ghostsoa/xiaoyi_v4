import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:typed_data';
import 'base_custom_tag.dart';
import '../../../../../services/file_service.dart';
import 'utils/resource_mapping_helper.dart';
import '../../../../../dao/chat_settings_dao.dart';

/// 角色标签组件
class RoleWidget extends BaseCustomTag {
  @override
  String get tagName => 'role';

  @override
  String get defaultTitle => '角色';

  @override
  bool get defaultExpanded => true;

  @override
  String get titleAlignment => 'left';

  @override
  String get containerType => 'role';

  @override
  Widget build(
    BuildContext context,
    String? nameAttribute,
    String content,
    TextStyle baseStyle,
    dynamic formatter,
  ) {
    String roleName = nameAttribute?.isNotEmpty == true
        ? nameAttribute!
        : '未知角色';

    // 解析资源映射为 Map<Name, Uri>
    final Map<String, String> nameToUri = ResourceMappingHelper.parseResourceMappings(formatter.resourceMapping);

    return RoleWidgetStateful(
      roleName: roleName,
      content: content,
      baseStyle: baseStyle,
      formatter: formatter,
      nameToUri: nameToUri,
    );
  }
}

/// 独立的角色组件，整体容器风格设计
class RoleWidgetStateful extends StatelessWidget {
  final String roleName;
  final String content;
  final TextStyle baseStyle;
  final dynamic formatter;
  final Map<String, String> nameToUri;

  const RoleWidgetStateful({
    super.key,
    required this.roleName,
    required this.content,
    required this.baseStyle,
    required this.formatter,
    required this.nameToUri,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: ChatSettingsDao().getCustomTagStyles(),
      builder: (context, snapshot) {
        final customStyles = snapshot.data ?? {};
        final roleStyle = customStyles['role'];

        Color backgroundColor;
        double opacity;
        Color textColor;

        if (roleStyle != null) {
          backgroundColor = Color(int.parse(roleStyle['backgroundColor'].toString().replaceAll('0x', ''), radix: 16));
          opacity = (roleStyle['opacity'] as num).toDouble();
          textColor = Color(int.parse(roleStyle['textColor'].toString().replaceAll('0x', ''), radix: 16));
        } else {
          backgroundColor = baseStyle.color ?? Colors.grey;
          opacity = 0.1;
          textColor = baseStyle.color ?? Colors.black;
        }

        final customTextStyle = baseStyle.copyWith(color: textColor);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      backgroundColor.withOpacity((opacity * 1.2).clamp(0.0, 1.0)),
                      backgroundColor.withOpacity((opacity * 0.8).clamp(0.0, 1.0)),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: backgroundColor.withOpacity((opacity * 2).clamp(0.0, 1.0)),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧：立绘头像和名字
                    RoleAvatar(nameToUri: nameToUri, roleName: roleName, baseStyle: customTextStyle),
                    const SizedBox(width: 12.0),
                    // 右侧：对话内容区域
                    Expanded(
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: customTextStyle.fontSize! * 1.4 * 3,
                        ),
                        child: _formatRoleContent(context, content, customTextStyle),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 处理角色内容，识别心理活动标签
  Widget _formatRoleContent(BuildContext context, String content, TextStyle baseStyle) {
    // 查找心理活动标签 <thought>...</thought>
    RegExp thoughtRegex = RegExp(r'<thought>(.*?)</thought>', multiLine: true, dotAll: true);

    List<Widget> widgets = [];
    int lastEnd = 0;

    Iterable<Match> matches = thoughtRegex.allMatches(content);

    for (Match match in matches) {
      // 添加心理活动前的普通内容
      if (match.start > lastEnd) {
        String beforeText = content.substring(lastEnd, match.start).trim();
        if (beforeText.isNotEmpty) {
          widgets.add(formatter.formatMarkdownOnly(context, beforeText, baseStyle, isInCustomTag: true, allowNestedTags: true));
        }
      }

      // 添加心理活动内容（特殊样式，无容器）
      String thoughtContent = match.group(1)?.trim() ?? '';
      if (thoughtContent.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: formatter.formatMarkdownOnly(
            context,
            thoughtContent,
            baseStyle.copyWith(
              color: baseStyle.color?.withOpacity(0.6),
              fontStyle: FontStyle.italic,
              fontSize: baseStyle.fontSize! * 0.9,
              decoration: TextDecoration.underline,
              decorationColor: baseStyle.color?.withOpacity(0.3),
              decorationStyle: TextDecorationStyle.dotted,
            ),
            isInCustomTag: true,
            allowNestedTags: true
          ),
        ));
      }

      lastEnd = match.end;
    }

    // 添加最后剩余的内容
    if (lastEnd < content.length) {
      String remainingText = content.substring(lastEnd).trim();
      if (remainingText.isNotEmpty) {
        widgets.add(formatter.formatMarkdownOnly(context, remainingText, baseStyle, isInCustomTag: true, allowNestedTags: true));
      }
    }

    // 如果没有找到心理活动标签，直接返回格式化的内容
    if (widgets.isEmpty) {
      return formatter.formatMarkdownOnly(context, content, baseStyle, isInCustomTag: true, allowNestedTags: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

/// 角色头像组件
class RoleAvatar extends StatefulWidget {
  final Map<String, String> nameToUri;
  final String roleName;
  final TextStyle baseStyle;

  const RoleAvatar({
    super.key,
    required this.nameToUri,
    required this.roleName,
    required this.baseStyle,
  });

  @override
  State<RoleAvatar> createState() => _RoleAvatarState();
}

class _RoleAvatarState extends State<RoleAvatar> {
  final FileService _fileService = FileService();
  Uint8List? _imageBytes;
  bool _loading = false;
  String? _currentUri;
  static final Map<String, Uint8List> _memoryCache = <String, Uint8List>{};

  @override
  void initState() {
    super.initState();
    _currentUri = ResourceMappingHelper.getResourceUri(widget.nameToUri, widget.roleName);
    _maybeLoad();
  }

  @override
  void didUpdateWidget(covariant RoleAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? newUri = ResourceMappingHelper.getResourceUri(widget.nameToUri, widget.roleName);
    if (oldWidget.roleName != widget.roleName || newUri != _currentUri) {
      _currentUri = newUri;
      setState(() {
        _imageBytes = null;
      });
      _maybeLoad();
    }
  }

  Future<void> _maybeLoad() async {
    final String? uri = _currentUri;
    if (uri == null || uri.isEmpty) return;
    if (_loading) return;

    final Uint8List? cached = _memoryCache[uri];
    if (cached != null) {
      if (mounted) {
        setState(() => _imageBytes = cached);
      } else {
        _imageBytes = cached;
      }
      return;
    }
    setState(() => _loading = true);
    try {
      final resp = await _fileService.getFile(uri);
      final data = resp.data;
      if (mounted && (data is Uint8List || data is List<int>)) {
        final Uint8List bytes = Uint8List.fromList(List<int>.from(data));
        _memoryCache[uri] = bytes;
        setState(() => _imageBytes = bytes);
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool noMapping = _currentUri == null || (_currentUri?.isEmpty ?? true);
    final Color fallbackStart = const Color(0xFF7E57C2).withOpacity(0.8);
    final Color fallbackEnd = const Color(0xFF5E35B1).withOpacity(0.6);

    Widget avatar;
    if (_imageBytes != null) {
      avatar = ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.memory(
          _imageBytes!,
          width: 60.0,
          height: 80.0,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
      );
    } else if (noMapping) {
      avatar = Container(
        width: 60.0,
        height: 80.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fallbackStart, fallbackEnd],
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              '无法找到资源映射',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    } else {
      avatar = Container(
        width: 60.0,
        height: 80.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fallbackStart, fallbackEnd],
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Text(
            widget.roleName.isNotEmpty ? widget.roleName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        avatar,
        const SizedBox(height: 6.0),
        Container(
          constraints: const BoxConstraints(maxWidth: 70),
          child: Text(
            widget.roleName,
            style: widget.baseStyle.copyWith(
              fontSize: widget.baseStyle.fontSize! * 0.8,
              color: widget.baseStyle.color?.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
