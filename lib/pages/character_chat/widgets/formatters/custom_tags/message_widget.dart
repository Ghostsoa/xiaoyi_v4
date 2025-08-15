import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:typed_data';
import 'base_custom_tag.dart';
import '../../../../../services/file_service.dart';
import 'utils/resource_mapping_helper.dart';
import '../../../../../dao/chat_settings_dao.dart';

/// 消息标签组件 - 对话气泡样式
class MessageWidget extends BaseCustomTag {
  @override
  String get tagName => 'message';

  @override
  String get defaultTitle => '消息';

  @override
  bool get defaultExpanded => true;

  @override
  String get titleAlignment => 'left';

  @override
  String get containerType => 'message';

  @override
  Widget build(
    BuildContext context,
    String? nameAttribute,
    String content,
    TextStyle baseStyle,
    dynamic formatter,
  ) {
    // 解析标签属性
    Map<String, String> attributes = _parseAttributes(content);
    String characterName = nameAttribute?.isNotEmpty == true
        ? nameAttribute!
        : '未知角色';

    // 解析side属性，默认为left
    String side = attributes['side']?.toLowerCase() ?? 'left';
    if (side != 'left' && side != 'right') {
      side = 'left'; // 默认左边
    }

    // 移除属性标签后的纯内容
    String cleanContent = _removeAttributeTags(content);

    // 解析资源映射为 Map<Name, Uri>
    final Map<String, String> nameToUri = ResourceMappingHelper.parseResourceMappings(formatter.resourceMapping);

    return MessageWidgetStateful(
      characterName: characterName,
      content: cleanContent,
      side: side,
      baseStyle: baseStyle,
      formatter: formatter,
      nameToUri: nameToUri,
    );
  }

  /// 使用属性字典构建组件（供解析器调用）
  Widget buildWithAttributes(
    BuildContext context,
    Map<String, String> attributes,
    String content,
    TextStyle baseStyle,
    dynamic formatter,
  ) {
    String characterName = attributes['name']?.isNotEmpty == true
        ? attributes['name']!
        : '未知角色';

    // 解析side属性，默认为left
    String side = attributes['side']?.toLowerCase() ?? 'left';
    if (side != 'left' && side != 'right') {
      side = 'left'; // 默认左边
    }

    // 解析资源映射为 Map<Name, Uri>
    final Map<String, String> nameToUri = ResourceMappingHelper.parseResourceMappings(formatter.resourceMapping);

    return MessageWidgetStateful(
      characterName: characterName,
      content: content,
      side: side,
      baseStyle: baseStyle,
      formatter: formatter,
      nameToUri: nameToUri,
    );
  }

  /// 解析标签内的属性（已废弃，使用解析器的方法）
  Map<String, String> _parseAttributes(String content) {
    Map<String, String> attributes = {};
    RegExp attrRegex = RegExp(r'<attr\s+(\w+)="([^"]*)">', multiLine: true);
    Iterable<Match> matches = attrRegex.allMatches(content);

    for (Match match in matches) {
      String key = match.group(1)!;
      String value = match.group(2)!;
      attributes[key] = value;
    }

    return attributes;
  }

  /// 移除属性标签，返回纯内容（已废弃）
  String _removeAttributeTags(String content) {
    return content.replaceAll(RegExp(r'<attr\s+\w+="[^"]*">', multiLine: true), '').trim();
  }
}

/// 消息组件 - 头像 + 名字 + 对话气泡
class MessageWidgetStateful extends StatelessWidget {
  final String characterName;
  final String content;
  final String side; // 'left' 或 'right'
  final TextStyle baseStyle;
  final dynamic formatter;
  final Map<String, String> nameToUri;

  const MessageWidgetStateful({
    super.key,
    required this.characterName,
    required this.content,
    required this.side,
    required this.baseStyle,
    required this.formatter,
    required this.nameToUri,
  });

  @override
  Widget build(BuildContext context) {
    bool isLeft = side == 'left';

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: ChatSettingsDao().getCustomTagStyles(),
      builder: (context, snapshot) {
        final customStyles = snapshot.data ?? {};
        final messageStyle = customStyles['message'];

        Color textColor;

        if (messageStyle != null) {
          textColor = Color(int.parse(messageStyle['textColor'].toString().replaceAll('0x', ''), radix: 16));
        } else {
          textColor = baseStyle.color ?? Colors.black;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: isLeft ? _buildLeftMessage(context, textColor) : _buildRightMessage(context, textColor),
          ),
        );
      },
    );
  }

  /// 构建左侧消息布局
  List<Widget> _buildLeftMessage(BuildContext context, Color textColor) {
    return [
      // 左侧：头像（垂直居中，占据2行高度）
      SizedBox(
        height: baseStyle.fontSize! * 2.0 * 1.4 + 14.0, // 2行高度 + 名字空间
        child: Center(
          child: MessageAvatar(
            nameToUri: nameToUri,
            characterName: characterName,
            baseStyle: baseStyle,
          ),
        ),
      ),
      const SizedBox(width: 12.0),
      // 右侧：对话气泡（名字嵌入边框）
      Expanded(
        child: _buildMessageBubbleWithName(context, isLeft: true, textColor: textColor),
      ),
    ];
  }

  /// 构建右侧消息布局
  List<Widget> _buildRightMessage(BuildContext context, Color textColor) {
    return [
      // 左侧：空白区域（推动气泡到右边）
      const Expanded(child: SizedBox.shrink()),
      // 中间：对话气泡（名字嵌入边框，右对齐）
      Flexible(
        child: _buildMessageBubbleWithName(context, isLeft: false, textColor: textColor),
      ),
      const SizedBox(width: 12.0),
      // 右侧：头像（垂直居中，占据2行高度）
      SizedBox(
        height: baseStyle.fontSize! * 2.0 * 1.4 + 14.0, // 2行高度 + 名字空间
        child: Center(
          child: MessageAvatar(
            nameToUri: nameToUri,
            characterName: characterName,
            baseStyle: baseStyle,
          ),
        ),
      ),
    ];
  }

  /// 构建带名字的对话气泡容器（名字作为纯文本嵌入边框）
  Widget _buildMessageBubbleWithName(BuildContext context, {required bool isLeft, required Color textColor}) {
    return Stack(
      children: [
        // 主气泡容器
        Container(
          margin: const EdgeInsets.only(top: 6.0), // 为名字留出空间
          child: _buildMessageBubble(context, isLeft: isLeft),
        ),
        // 名字文本（纯文本，无背景）
        Positioned(
          top: 0,
          left: isLeft ? 16.0 : null,
          right: isLeft ? null : 16.0,
          child: Text(
            characterName,
            style: baseStyle.copyWith(
              fontSize: baseStyle.fontSize! * 0.65,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建对话气泡容器
  Widget _buildMessageBubble(BuildContext context, {required bool isLeft}) {
    // 统一的圆角，不要凸出的角
    BorderRadius bubbleRadius = BorderRadius.circular(8.0);

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: ChatSettingsDao().getCustomTagStyles(),
      builder: (context, snapshot) {
        final customStyles = snapshot.data ?? {};
        final messageStyle = customStyles['message'];

        Color backgroundColor;
        double opacity;
        Color textColor;

        if (messageStyle != null) {
          backgroundColor = Color(int.parse(messageStyle['backgroundColor'].toString().replaceAll('0x', ''), radix: 16));
          opacity = (messageStyle['opacity'] as num).toDouble();
          textColor = Color(int.parse(messageStyle['textColor'].toString().replaceAll('0x', ''), radix: 16));
        } else {
          backgroundColor = baseStyle.color ?? Colors.grey;
          opacity = 0.1;
          textColor = baseStyle.color ?? Colors.black;
        }

        // 根据左右位置调整透明度（保留逻辑注释，当前未使用渐变）

        return ClipRRect(
          borderRadius: bubbleRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280.0), // 限制最大宽度
              padding: const EdgeInsets.all(8.0), // 减少内边距
              decoration: BoxDecoration(
                color: isLeft
                    ? backgroundColor.withOpacity((opacity * 0.5).clamp(0.0, 1.0))
                    : backgroundColor.withOpacity((opacity * 1.5).clamp(0.0, 1.0)),
                borderRadius: bubbleRadius,
                border: Border.all(
                  color: isLeft
                      ? backgroundColor.withOpacity((opacity * 1.5).clamp(0.0, 1.0))
                      : backgroundColor.withOpacity((opacity * 3.0).clamp(0.0, 1.0)),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: formatter.formatMarkdownOnly(
                context,
                content,
                baseStyle.copyWith(
                  color: textColor,
                ),
                isInCustomTag: true,
                allowNestedTags: true,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 消息头像组件（复用角色组件的头像逻辑）
class MessageAvatar extends StatefulWidget {
  final Map<String, String> nameToUri;
  final String characterName;
  final TextStyle baseStyle;

  const MessageAvatar({
    super.key,
    required this.nameToUri,
    required this.characterName,
    required this.baseStyle,
  });

  @override
  State<MessageAvatar> createState() => _MessageAvatarState();
}

class _MessageAvatarState extends State<MessageAvatar> {
  final FileService _fileService = FileService();
  Uint8List? _imageBytes;
  bool _loading = false;
  String? _currentUri;
  static final Map<String, Uint8List> _memoryCache = <String, Uint8List>{};

  @override
  void initState() {
    super.initState();
    _currentUri = ResourceMappingHelper.getResourceUri(widget.nameToUri, widget.characterName);
    _maybeLoad();
  }

  @override
  void didUpdateWidget(covariant MessageAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? newUri = ResourceMappingHelper.getResourceUri(widget.nameToUri, widget.characterName);
    if (oldWidget.characterName != widget.characterName || newUri != _currentUri) {
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
        borderRadius: BorderRadius.circular(20.0), // 圆形头像
        child: Image.memory(
          _imageBytes!,
          width: 40.0,
          height: 40.0,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
      );
    } else if (noMapping) {
      avatar = Container(
        width: 40.0,
        height: 40.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fallbackStart, fallbackEnd],
          ),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: const Center(
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    } else {
      avatar = Container(
        width: 40.0,
        height: 40.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fallbackStart, fallbackEnd],
          ),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Center(
          child: Text(
            widget.characterName.isNotEmpty ? widget.characterName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return avatar;
  }
}
