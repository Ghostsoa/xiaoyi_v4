import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:typed_data';
import 'base_custom_tag.dart';
import '../../../../../services/file_service.dart';
import 'utils/resource_mapping_helper.dart';
import '../../../../../dao/chat_settings_dao.dart';

/// 聊天列表标签组件 - 微信样式
class ChatListWidget extends BaseCustomTag {
  @override
  String get tagName => 'chat-list';

  @override
  String get defaultTitle => '聊天列表';

  @override
  bool get defaultExpanded => true;

  @override
  String get titleAlignment => 'left';

  @override
  String get containerType => 'chat-list';

  @override
  Widget build(
    BuildContext context,
    String? nameAttribute,
    String content,
    TextStyle baseStyle,
    dynamic formatter,
  ) {
    // 解析属性
    Map<String, String> attributes = _parseChatListAttributes(content);
    String title = attributes['title'] ?? '微信';
    
    // 移除属性标签后的纯内容
    String cleanContent = _removeChatListAttributes(content);

    // 解析资源映射
    final Map<String, String> nameToUri = ResourceMappingHelper.parseResourceMappings(formatter.resourceMapping);

    return ChatListWidgetStateful(
      title: title,
      content: cleanContent,
      baseStyle: baseStyle,
      formatter: formatter,
      nameToUri: nameToUri,
    );
  }

  /// 解析chat-list标签的属性
  Map<String, String> _parseChatListAttributes(String content) {
    Map<String, String> attributes = {};
    RegExp startTagRegex = RegExp(r'<chat-list([^>]*)>', multiLine: true);
    Match? startMatch = startTagRegex.firstMatch(content);
    
    if (startMatch != null) {
      String attributesString = startMatch.group(1) ?? '';
      RegExp attrRegex = RegExp(r'(\w+)="([^"]*)"');
      Iterable<Match> matches = attrRegex.allMatches(attributesString);
      
      for (Match match in matches) {
        attributes[match.group(1)!] = match.group(2)!;
      }
    }
    
    return attributes;
  }

  /// 移除chat-list属性标签
  String _removeChatListAttributes(String content) {
    return content
        .replaceAll(RegExp(r'<chat-list[^>]*>', multiLine: true), '')
        .replaceAll('</chat-list>', '')
        .trim();
  }
}

/// 聊天列表组件主体
class ChatListWidgetStateful extends StatelessWidget {
  final String title;
  final String content;
  final TextStyle baseStyle;
  final dynamic formatter;
  final Map<String, String> nameToUri;

  const ChatListWidgetStateful({
    super.key,
    required this.title,
    required this.content,
    required this.baseStyle,
    required this.formatter,
    required this.nameToUri,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> chatItems = _parseChatItems(content);

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: ChatSettingsDao().getCustomTagStyles(),
      builder: (context, snapshot) {
        final customStyles = snapshot.data ?? {};
        final chatListStyle = customStyles['chat-list'];

        Color backgroundColor;
        double opacity;
        Color textColor;

        if (chatListStyle != null) {
          backgroundColor = Color(int.parse(chatListStyle['backgroundColor'].toString().replaceAll('0x', ''), radix: 16));
          opacity = (chatListStyle['opacity'] as num).toDouble();
          textColor = Color(int.parse(chatListStyle['textColor'].toString().replaceAll('0x', ''), radix: 16));
        } else {
          backgroundColor = baseStyle.color ?? Colors.grey;
          opacity = 0.1;
          textColor = baseStyle.color ?? Colors.black;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      backgroundColor.withOpacity((opacity * 0.4).clamp(0.0, 1.0)),
                      backgroundColor.withOpacity((opacity * 0.2).clamp(0.0, 1.0)),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: backgroundColor.withOpacity((opacity * 1.2).clamp(0.0, 1.0)),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
            child: Column(
              children: [
                // 微信头部
                _buildWeChatHeader(context, backgroundColor, opacity, textColor),
                // 聊天列表
                ...chatItems.map((item) => _buildChatItem(context, item, textColor)),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  /// 构建微信头部
  Widget _buildWeChatHeader(BuildContext context, Color backgroundColor, double opacity, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor.withOpacity((opacity * 1.2).clamp(0.0, 1.0)),
            backgroundColor.withOpacity((opacity * 0.8).clamp(0.0, 1.0)),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: backgroundColor.withOpacity((opacity * 1.5).clamp(0.0, 1.0)),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 聊天图标
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              Icons.chat,
              size: 20,
              color: backgroundColor,
            ),
          ),
          const SizedBox(width: 12.0),
          // 标题
          Expanded(
            child: Text(
              title,
              style: baseStyle.copyWith(
                fontSize: baseStyle.fontSize! * 1.1,
                fontWeight: FontWeight.bold,
                color: backgroundColor,
              ),
            ),
          ),
          // 搜索按钮
          Icon(
            Icons.search,
            size: 22,
            color: backgroundColor,
          ),
          const SizedBox(width: 8.0),
          // 添加按钮
          Icon(
            Icons.add,
            size: 22,
            color: backgroundColor,
          ),
        ],
      ),
    );
  }

  /// 构建单个聊天项
  Widget _buildChatItem(BuildContext context, Map<String, String> item, Color textColor) {
    String name = item['name'] ?? '未知';
    String lastMsg = item['lastMsg'] ?? '';
    String time = item['time'] ?? '';
    String unread = item['unread'] ?? '0';
    String status = item['status'] ?? 'offline';
    String type = item['type'] ?? 'private'; // private or group
    
    bool hasUnread = int.tryParse(unread) != null && int.parse(unread) > 0;
    bool isOnline = status == 'online';
    bool isGroup = type == 'group';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 头像 + 状态指示
          Stack(
            children: [
              ChatAvatar(
                nameToUri: nameToUri,
                name: name,
                baseStyle: baseStyle,
                size: 48.0,
                isGroup: isGroup,
              ),
              // 在线状态指示
              if (isOnline && !isGroup)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF07C160), // 微信绿色
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12.0),
          // 聊天信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 第一行：姓名 + 时间
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: baseStyle.copyWith(
                          fontSize: baseStyle.fontSize! * 0.9,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      time,
                      style: baseStyle.copyWith(
                        fontSize: baseStyle.fontSize! * 0.75,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                // 第二行：最后消息
                Text(
                  lastMsg,
                  style: baseStyle.copyWith(
                    fontSize: baseStyle.fontSize! * 0.8,
                    color: textColor.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 未读消息红点
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(left: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Text(
                int.parse(unread) > 99 ? '99+' : unread,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 解析聊天项
  List<Map<String, String>> _parseChatItems(String content) {
    List<Map<String, String>> items = [];
    
    RegExp itemRegex = RegExp(
      r'<chat-item([^>]*?)>(.*?)</chat-item>',
      multiLine: true,
      dotAll: true,
    );
    
    Iterable<Match> matches = itemRegex.allMatches(content);
    
    for (Match match in matches) {
      String attributesString = match.group(1) ?? '';
      String itemContent = match.group(2) ?? '';
      
      // 解析属性
      Map<String, String> attributes = {};
      RegExp attrRegex = RegExp(r'(\w+)="([^"]*)"');
      Iterable<Match> attrMatches = attrRegex.allMatches(attributesString);
      
      for (Match attrMatch in attrMatches) {
        attributes[attrMatch.group(1)!] = attrMatch.group(2)!;
      }
      
      attributes['content'] = itemContent.trim();
      items.add(attributes);
    }
    
    return items;
  }
}

/// 聊天头像组件
class ChatAvatar extends StatefulWidget {
  final Map<String, String> nameToUri;
  final String name;
  final TextStyle baseStyle;
  final double size;
  final bool isGroup;

  const ChatAvatar({
    super.key,
    required this.nameToUri,
    required this.name,
    required this.baseStyle,
    required this.size,
    required this.isGroup,
  });

  @override
  State<ChatAvatar> createState() => _ChatAvatarState();
}

class _ChatAvatarState extends State<ChatAvatar> {
  final FileService _fileService = FileService();
  Uint8List? _imageBytes;
  bool _loading = false;
  String? _currentUri;
  static final Map<String, Uint8List> _memoryCache = <String, Uint8List>{};

  @override
  void initState() {
    super.initState();
    _currentUri = ResourceMappingHelper.getResourceUri(widget.nameToUri, widget.name);
    _maybeLoad();
  }

  @override
  void didUpdateWidget(covariant ChatAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? newUri = ResourceMappingHelper.getResourceUri(widget.nameToUri, widget.name);
    if (oldWidget.name != widget.name || newUri != _currentUri) {
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

    Widget avatar;
    if (_imageBytes != null) {
      avatar = ClipRRect(
        borderRadius: BorderRadius.circular(widget.isGroup ? 8.0 : widget.size / 2),
        child: Image.memory(
          _imageBytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
      );
    } else {
      // 默认头像
      Color avatarColor = widget.isGroup ? Colors.grey.shade400 : Colors.blue.shade400;
      IconData avatarIcon = widget.isGroup ? Icons.group : Icons.person;
      
      avatar = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: avatarColor,
          borderRadius: BorderRadius.circular(widget.isGroup ? 8.0 : widget.size / 2),
        ),
        child: Center(
          child: widget.isGroup 
              ? Icon(
                  avatarIcon,
                  color: Colors.white,
                  size: widget.size * 0.5,
                )
              : Text(
                  widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.size * 0.35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      );
    }

    return avatar;
  }
}
