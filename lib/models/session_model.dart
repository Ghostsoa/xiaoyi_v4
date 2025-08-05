/// 会话数据模型
/// 用于本地数据库存储和API数据交换
class SessionModel {
  final int id;
  final String name;
  final String? lastMessage;
  final String? coverUri;
  final String? createdAt;
  final String? updatedAt;
  final int? characterId;
  final String? title; // 用于小说会话
  final String? activeArchiveId; // 激活的存档ID
  final Map<String, dynamic>? extraData; // 存储其他扩展字段
  final DateTime? lastSyncTime; // 最后同步时间
  final bool isPinned; // 🔥 是否置顶
  final String? pinnedAt; // 🔥 置顶时间

  const SessionModel({
    required this.id,
    required this.name,
    this.lastMessage,
    this.coverUri,
    this.createdAt,
    this.updatedAt,
    this.characterId,
    this.title,
    this.activeArchiveId,
    this.extraData,
    this.lastSyncTime,
    this.isPinned = false, // 🔥 默认不置顶
    this.pinnedAt, // 🔥 置顶时间
  });

  /// 从API返回的JSON创建SessionModel
  factory SessionModel.fromApiJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      lastMessage: json['last_message'] as String?,
      coverUri: json['cover_uri'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      characterId: json['character_id'] as int?,
      title: json['title'] as String?, // 小说会话使用
      activeArchiveId: json['active_archive_id'] as String?, // 激活的存档ID
      extraData: _extractExtraData(json),
      lastSyncTime: DateTime.now(),
      // 🔥 API数据默认不包含置顶信息，使用默认值
      isPinned: false,
      pinnedAt: null,
    );
  }

  /// 从本地数据库JSON创建SessionModel
  factory SessionModel.fromDbJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as int,
      name: json['name'] as String,
      lastMessage: json['last_message'] as String?,
      coverUri: json['cover_uri'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      characterId: json['character_id'] as int?,
      title: json['title'] as String?,
      activeArchiveId: json['active_archive_id'] as String?,
      extraData: json['extra_data'] != null
          ? Map<String, dynamic>.from(json['extra_data'])
          : null,
      lastSyncTime: json['last_sync_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_sync_time'])
          : null,
      // 🔥 从数据库读取置顶信息
      isPinned: (json['is_pinned'] as int? ?? 0) == 1,
      pinnedAt: json['pinned_at'] as String?,
    );
  }

  /// 转换为数据库存储的JSON格式
  Map<String, dynamic> toDbJson() {
    final result = {
      'id': id,
      'name': name,
      'last_message': lastMessage,
      'cover_uri': coverUri,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'active_archive_id': activeArchiveId,
      'extra_data': extraData,
      'last_sync_time': lastSyncTime?.millisecondsSinceEpoch,
      // 🔥 添加置顶信息
      'is_pinned': isPinned ? 1 : 0,
      'pinned_at': pinnedAt,
    };

    // 根据会话类型添加特定字段
    if (isCharacterSession) {
      result['character_id'] = characterId;
    } else if (isNovelSession) {
      result['title'] = title;
    }

    return result;
  }

  /// 转换为API兼容的JSON格式（用于UI显示）
  Map<String, dynamic> toApiJson() {
    final result = <String, dynamic>{
      'id': id,
      'name': name,
      'last_message': lastMessage,
      'cover_uri': coverUri,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'active_archive_id': activeArchiveId,
      // 🔥 添加置顶信息到UI数据
      'is_pinned': isPinned ? 1 : 0,
      'pinned_at': pinnedAt,
    };

    // 添加角色会话特有字段
    if (characterId != null) {
      result['character_id'] = characterId;
    }

    // 添加小说会话特有字段
    if (title != null) {
      result['title'] = title;
    }

    // 添加扩展数据
    if (extraData != null) {
      result.addAll(extraData!);
    }

    return result;
  }

  /// 创建副本并更新指定字段
  SessionModel copyWith({
    int? id,
    String? name,
    String? lastMessage,
    String? coverUri,
    String? createdAt,
    String? updatedAt,
    int? characterId,
    String? title,
    String? activeArchiveId,
    Map<String, dynamic>? extraData,
    DateTime? lastSyncTime,
    bool? isPinned, // 🔥 添加置顶字段
    String? pinnedAt, // 🔥 添加置顶时间字段
  }) {
    return SessionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      coverUri: coverUri ?? this.coverUri,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      characterId: characterId ?? this.characterId,
      title: title ?? this.title,
      activeArchiveId: activeArchiveId ?? this.activeArchiveId,
      extraData: extraData ?? this.extraData,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isPinned: isPinned ?? this.isPinned, // 🔥 添加置顶字段
      pinnedAt: pinnedAt ?? this.pinnedAt, // 🔥 添加置顶时间字段
    );
  }

  /// 提取API返回数据中的扩展字段
  static Map<String, dynamic>? _extractExtraData(Map<String, dynamic> json) {
    final knownFields = {
      'id', 'name', 'last_message', 'cover_uri', 'created_at', 
      'updated_at', 'character_id', 'title'
    };
    
    final extraData = <String, dynamic>{};
    for (final entry in json.entries) {
      if (!knownFields.contains(entry.key)) {
        extraData[entry.key] = entry.value;
      }
    }
    
    return extraData.isEmpty ? null : extraData;
  }

  /// 判断是否为角色会话
  bool get isCharacterSession => characterId != null;

  /// 判断是否为小说会话
  bool get isNovelSession => title != null && characterId == null;

  /// 获取显示名称（角色会话用name，小说会话用title）
  String get displayName => isNovelSession ? (title ?? name) : name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionModel &&
        other.id == id &&
        other.name == name &&
        other.lastMessage == lastMessage &&
        other.coverUri == coverUri &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.characterId == characterId &&
        other.title == title;
  }

  @override
  int get hashCode {
    return Object.hash(
      id, name, lastMessage, coverUri, 
      createdAt, updatedAt, characterId, title
    );
  }

  @override
  String toString() {
    return 'SessionModel(id: $id, name: $name, type: ${isCharacterSession ? "character" : "novel"})';
  }
}

/// 会话列表响应模型
class SessionListResponse {
  final List<SessionModel> sessions;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const SessionListResponse({
    required this.sessions,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory SessionListResponse.fromApiJson(Map<String, dynamic> json, bool isNovelSession) {
    final List<dynamic> listData = isNovelSession 
        ? (json['sessions'] as List? ?? [])
        : (json['list'] as List? ?? []);
    
    final sessions = listData
        .map((item) => SessionModel.fromApiJson(item as Map<String, dynamic>))
        .toList();

    final total = json['total'] as int? ?? 0;
    final page = json['page'] as int? ?? 1;
    final pageSize = json['pageSize'] as int? ?? 10;

    return SessionListResponse(
      sessions: sessions,
      total: total,
      page: page,
      pageSize: pageSize,
      hasMore: sessions.length < total,
    );
  }

  factory SessionListResponse.fromLocalData(
    List<SessionModel> sessions, 
    int page, 
    int pageSize,
    int total,
  ) {
    return SessionListResponse(
      sessions: sessions,
      total: total,
      page: page,
      pageSize: pageSize,
      hasMore: (page * pageSize) < total,
    );
  }
}
