import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_model.dart';

/// 🔥 会话数据服务（重构版）
/// 存储策略：
/// 1. SQLite数据库：只存储置顶会话的完整数据
/// 2. SharedPreferences：存储所有会话的activeArchiveId（键值对）
class SessionDataService {
  static final SessionDataService _instance = SessionDataService._internal();
  factory SessionDataService() => _instance;
  SessionDataService._internal();

  Database? _database;
  SharedPreferences? _prefs;
  final StreamController<List<SessionModel>> _characterSessionsController = 
      StreamController<List<SessionModel>>.broadcast();
  final StreamController<List<SessionModel>> _novelSessionsController = 
      StreamController<List<SessionModel>>.broadcast();
  final StreamController<List<SessionModel>> _groupChatSessionsController = 
      StreamController<List<SessionModel>>.broadcast();

  /// 角色会话数据流
  Stream<List<SessionModel>> get characterSessionsStream => 
      _characterSessionsController.stream;

  /// 小说会话数据流
  Stream<List<SessionModel>> get novelSessionsStream => 
      _novelSessionsController.stream;

  /// 群聊会话数据流
  Stream<List<SessionModel>> get groupChatSessionsStream => 
      _groupChatSessionsController.stream;

  /// 初始化数据库和SharedPreferences
  Future<void> initDatabase() async {
    if (_database != null && _prefs != null) return;
    
    // 初始化SharedPreferences
    _prefs ??= await SharedPreferences.getInstance();

    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'sessions.db');

    _database = await openDatabase(
      dbPath,
      version: 4, // 🔥 升级版本以支持群聊缓存和置顶功能
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );

    debugPrint('[SessionDataService] 数据库初始化完成: $dbPath');
  }

  /// 创建数据库表
  Future<void> _createTables(Database db, int version) async {
    // 角色会话表（不包含title字段）
    await db.execute('''
      CREATE TABLE character_sessions (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        last_message TEXT,
        cover_uri TEXT,
        created_at TEXT,
        updated_at TEXT,
        character_id INTEGER,
        active_archive_id TEXT,
        extra_data TEXT,
        last_sync_time INTEGER,
        is_pinned INTEGER DEFAULT 0,
        pinned_at TEXT
      )
    ''');

    // 小说会话表（包含title字段）
    await db.execute('''
      CREATE TABLE novel_sessions (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        title TEXT,
        last_message TEXT,
        cover_uri TEXT,
        created_at TEXT,
        updated_at TEXT,
        active_archive_id TEXT,
        extra_data TEXT,
        last_sync_time INTEGER,
        is_pinned INTEGER DEFAULT 0,
        pinned_at TEXT
      )
    ''');

    // 群聊会话表
    await db.execute('''
      CREATE TABLE group_chat_sessions (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        last_message TEXT,
        cover_uri TEXT,
        created_at TEXT,
        updated_at TEXT,
        extra_data TEXT,
        last_sync_time INTEGER,
        is_pinned INTEGER DEFAULT 0,
        pinned_at TEXT
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_character_sessions_updated_at ON character_sessions(updated_at)');
    await db.execute('CREATE INDEX idx_novel_sessions_updated_at ON novel_sessions(updated_at)');
    await db.execute('CREATE INDEX idx_group_chat_sessions_updated_at ON group_chat_sessions(updated_at)');
    // 🔥 添加置顶字段索引，优化排序性能
    await db.execute('CREATE INDEX idx_character_sessions_pinned ON character_sessions(is_pinned, pinned_at)');
    await db.execute('CREATE INDEX idx_novel_sessions_pinned ON novel_sessions(is_pinned, pinned_at)');
    await db.execute('CREATE INDEX idx_group_chat_sessions_pinned ON group_chat_sessions(is_pinned, pinned_at)');

    debugPrint('[SessionDataService] 数据库表创建完成');
  }

  /// 升级数据库表
  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    debugPrint('[SessionDataService] 数据库升级: $oldVersion -> $newVersion');

    if (oldVersion < 2) {
      // 添加 active_archive_id 字段
      await db.execute('ALTER TABLE character_sessions ADD COLUMN active_archive_id TEXT');
      await db.execute('ALTER TABLE novel_sessions ADD COLUMN active_archive_id TEXT');
      debugPrint('[SessionDataService] 已添加 active_archive_id 字段');
    }

    if (oldVersion < 3) {
      // 🔥 添加置顶功能字段
      await db.execute('ALTER TABLE character_sessions ADD COLUMN is_pinned INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE character_sessions ADD COLUMN pinned_at TEXT');
      await db.execute('ALTER TABLE novel_sessions ADD COLUMN is_pinned INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE novel_sessions ADD COLUMN pinned_at TEXT');

      // 添加置顶字段索引
      await db.execute('CREATE INDEX idx_character_sessions_pinned ON character_sessions(is_pinned, pinned_at)');
      await db.execute('CREATE INDEX idx_novel_sessions_pinned ON novel_sessions(is_pinned, pinned_at)');

      debugPrint('[SessionDataService] 已添加置顶功能字段和索引');
    }

    if (oldVersion < 4) {
      // 🔥 添加群聊会话表
      await db.execute('''
        CREATE TABLE group_chat_sessions (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          last_message TEXT,
          cover_uri TEXT,
          created_at TEXT,
          updated_at TEXT,
          extra_data TEXT,
          last_sync_time INTEGER,
          is_pinned INTEGER DEFAULT 0,
          pinned_at TEXT
        )
      ''');

      // 创建索引
      await db.execute('CREATE INDEX idx_group_chat_sessions_updated_at ON group_chat_sessions(updated_at)');
      await db.execute('CREATE INDEX idx_group_chat_sessions_pinned ON group_chat_sessions(is_pinned, pinned_at)');

      debugPrint('[SessionDataService] 已添加群聊会话表和索引');
    }
  }

  /// 🔥 获取本地置顶的角色会话列表（只返回置顶）
  Future<List<SessionModel>> getPinnedCharacterSessions() async {
    await initDatabase();
    
    final result = await _database!.query(
      'character_sessions',
      where: 'is_pinned = 1',
      orderBy: 'pinned_at DESC, updated_at DESC, id DESC',
    );

    final sessions = result.map((row) {
      final data = Map<String, dynamic>.from(row);
      if (data['extra_data'] != null) {
        data['extra_data'] = jsonDecode(data['extra_data']);
      }
      return SessionModel.fromDbJson(data);
    }).toList();

    debugPrint('[SessionDataService] 获取置顶角色会话: ${sessions.length}条');
    return sessions;
  }
  
  /// 🔥 兼容旧接口：getLocalCharacterSessions（已废弃，保留用于搜索）
  Future<SessionListResponse> getLocalCharacterSessions({
    int page = 1,
    int pageSize = 10,
    String? searchName,
  }) async {
    await initDatabase();
    
    // 如果有搜索，返回空（搜索由API处理）
    if (searchName != null && searchName.isNotEmpty) {
      return SessionListResponse.fromLocalData([], page, pageSize, 0);
    }
    
    // 只返回置顶会话
    final pinnedSessions = await getPinnedCharacterSessions();
    return SessionListResponse.fromLocalData(pinnedSessions, 1, pinnedSessions.length, pinnedSessions.length);
  }

  /// 🔥 获取本地置顶的小说会话列表（只返回置顶）
  Future<List<SessionModel>> getPinnedNovelSessions() async {
    await initDatabase();
    
    final result = await _database!.query(
      'novel_sessions',
      where: 'is_pinned = 1',
      orderBy: 'pinned_at DESC, updated_at DESC, id DESC',
    );

    final sessions = result.map((row) {
      final data = Map<String, dynamic>.from(row);
      if (data['extra_data'] != null) {
        data['extra_data'] = jsonDecode(data['extra_data']);
      }
      return SessionModel.fromDbJson(data);
    }).toList();

    debugPrint('[SessionDataService] 获取置顶小说会话: ${sessions.length}条');
    return sessions;
  }
  
  /// 🔥 兼容旧接口：getLocalNovelSessions（已废弃，保留用于搜索）
  Future<SessionListResponse> getLocalNovelSessions({
    int page = 1,
    int pageSize = 10,
    String? searchName,
  }) async {
    await initDatabase();
    
    // 如果有搜索，返回空（搜索由API处理）
    if (searchName != null && searchName.isNotEmpty) {
      return SessionListResponse.fromLocalData([], page, pageSize, 0);
    }
    
    // 只返回置顶会话
    final pinnedSessions = await getPinnedNovelSessions();
    return SessionListResponse.fromLocalData(pinnedSessions, 1, pinnedSessions.length, pinnedSessions.length);
  }

  /// 批量插入或更新角色会话
  Future<void> insertOrUpdateCharacterSessions(List<SessionModel> sessions) async {
    await initDatabase();

    // 读取本地已有的置顶状态，避免被API数据覆盖
    final List<int> ids = sessions.map((s) => s.id).toList(growable: false);
    final Map<int, Map<String, Object?>> localPinned = await _loadLocalPinnedState(
      'character_sessions',
      ids,
    );

    final batch = _database!.batch();

    for (final session in sessions) {
      final data = session.toDbJson();
      if (data['extra_data'] != null) {
        data['extra_data'] = jsonEncode(data['extra_data']);
      }

      // 用本地置顶字段和存档ID覆盖API构造的数据
      final pinnedRow = localPinned[session.id];
      if (pinnedRow != null) {
        data['is_pinned'] = pinnedRow['is_pinned'] ?? data['is_pinned'];
        data['pinned_at'] = pinnedRow['pinned_at'];
        // 🔥 关键修复：保留本地的激活存档ID，避免被API数据覆盖
        if (pinnedRow['active_archive_id'] != null) {
          data['active_archive_id'] = pinnedRow['active_archive_id'];
        }
      }

      batch.insert(
        'character_sessions',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);

    // 通知UI更新
    _notifyCharacterSessionsUpdate();

    debugPrint('[SessionDataService] 批量更新角色会话: ${sessions.length} 条');
  }

  /// 批量插入或更新小说会话
  Future<void> insertOrUpdateNovelSessions(List<SessionModel> sessions) async {
    await initDatabase();
    
    // 读取本地已有的置顶状态，避免被API数据覆盖
    final List<int> ids = sessions.map((s) => s.id).toList(growable: false);
    final Map<int, Map<String, Object?>> localPinned = await _loadLocalPinnedState(
      'novel_sessions',
      ids,
    );

    final batch = _database!.batch();
    
    for (final session in sessions) {
      final data = session.toDbJson();
      if (data['extra_data'] != null) {
        data['extra_data'] = jsonEncode(data['extra_data']);
      }

      // 用本地置顶字段和存档ID覆盖API构造的数据
      final pinnedRow = localPinned[session.id];
      if (pinnedRow != null) {
        data['is_pinned'] = pinnedRow['is_pinned'] ?? data['is_pinned'];
        data['pinned_at'] = pinnedRow['pinned_at'];
        // 🔥 关键修复：保留本地的激活存档ID，避免被API数据覆盖
        if (pinnedRow['active_archive_id'] != null) {
          data['active_archive_id'] = pinnedRow['active_archive_id'];
        }
      }
      
      batch.insert(
        'novel_sessions',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
    
    // 通知UI更新
    _notifyNovelSessionsUpdate();
    
    debugPrint('[SessionDataService] 批量更新小说会话: ${sessions.length} 条');
  }

  /// 读取本地已有置顶状态和存档ID（id -> {is_pinned, pinned_at, active_archive_id}）
  Future<Map<int, Map<String, Object?>>> _loadLocalPinnedState(
    String table,
    List<int> ids,
  ) async {
    if (ids.isEmpty) return <int, Map<String, Object?>>{};

    // 🔥 群聊表没有 active_archive_id 字段
    final bool hasArchiveId = table != 'group_chat_sessions';

    // 构造 WHERE IN 子句
    final String placeholders = List.filled(ids.length, '?').join(',');
    final String columns = hasArchiveId
        ? 'id, is_pinned, pinned_at, active_archive_id'
        : 'id, is_pinned, pinned_at';
    
    final List<Map<String, Object?>> rows = await _database!.rawQuery(
      'SELECT $columns FROM $table WHERE id IN ($placeholders)',
      ids,
    );

    final Map<int, Map<String, Object?>> result = <int, Map<String, Object?>>{};
    for (final row in rows) {
      final int id = (row['id'] as int);
      result[id] = <String, Object?>{
        'is_pinned': row['is_pinned'],
        'pinned_at': row['pinned_at'],
        if (hasArchiveId) 'active_archive_id': row['active_archive_id'],
      };
    }
    return result;
  }

  /// 更新单个角色会话
  Future<void> updateCharacterSession(SessionModel session) async {
    await initDatabase();
    
    final data = session.toDbJson();
    if (data['extra_data'] != null) {
      data['extra_data'] = jsonEncode(data['extra_data']);
    }
    
    await _database!.update(
      'character_sessions',
      data,
      where: 'id = ?',
      whereArgs: [session.id],
    );
    
    _notifyCharacterSessionsUpdate();
    debugPrint('[SessionDataService] 更新角色会话: ${session.id}');
  }

  /// 更新单个小说会话
  Future<void> updateNovelSession(SessionModel session) async {
    await initDatabase();
    
    final data = session.toDbJson();
    if (data['extra_data'] != null) {
      data['extra_data'] = jsonEncode(data['extra_data']);
    }
    
    await _database!.update(
      'novel_sessions',
      data,
      where: 'id = ?',
      whereArgs: [session.id],
    );
    
    _notifyNovelSessionsUpdate();
    debugPrint('[SessionDataService] 更新小说会话: ${session.id}');
  }

  /// 删除角色会话
  Future<void> deleteCharacterSession(int sessionId) async {
    await initDatabase();
    
    await _database!.delete(
      'character_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    
    _notifyCharacterSessionsUpdate();
    debugPrint('[SessionDataService] 删除角色会话: $sessionId');
  }

  /// 删除小说会话
  Future<void> deleteNovelSession(int sessionId) async {
    await initDatabase();
    
    await _database!.delete(
      'novel_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    
    _notifyNovelSessionsUpdate();
    debugPrint('[SessionDataService] 删除小说会话: $sessionId');
  }

  /// 通知角色会话更新
  Future<void> _notifyCharacterSessionsUpdate() async {
    try {
      // 只获取前100条用于UI更新，避免内存压力
      final response = await getLocalCharacterSessions(page: 1, pageSize: 100);
      _characterSessionsController.add(response.sessions);
    } catch (e) {
      debugPrint('[SessionDataService] 通知角色会话更新失败: $e');
    }
  }

  /// 通知小说会话更新
  Future<void> _notifyNovelSessionsUpdate() async {
    try {
      // 只获取前100条用于UI更新，避免内存压力
      final response = await getLocalNovelSessions(page: 1, pageSize: 100);
      _novelSessionsController.add(response.sessions);
    } catch (e) {
      debugPrint('[SessionDataService] 通知小说会话更新失败: $e');
    }
  }

  /// 与API数据同步角色会话（增量更新）
  Future<List<SessionModel>> syncCharacterSessionsWithApi(
    List<SessionModel> apiSessions,
  ) async {
    await initDatabase();

    // 获取本地所有会话的ID和更新时间
    final localResult = await _database!.query(
      'character_sessions',
      columns: ['id', 'updated_at'],
    );

    final localSessionMap = <int, String>{};
    for (final row in localResult) {
      localSessionMap[row['id'] as int] = row['updated_at'] as String? ?? '';
    }

    final sessionsToUpdate = <SessionModel>[];

    // 检测需要更新的会话
    for (final apiSession in apiSessions) {
      final localUpdatedAt = localSessionMap[apiSession.id];

      if (localUpdatedAt == null ||
          _isApiSessionNewer(apiSession.updatedAt, localUpdatedAt)) {
        sessionsToUpdate.add(apiSession);
      }
    }

    // 只执行更新，不删除其他页的数据
    if (sessionsToUpdate.isNotEmpty) {
      await insertOrUpdateCharacterSessions(sessionsToUpdate);
    }

    debugPrint('[SessionDataService] 角色会话同步完成: 更新${sessionsToUpdate.length}条');

    return sessionsToUpdate;
  }

  /// 与API数据同步小说会话（增量更新）
  Future<List<SessionModel>> syncNovelSessionsWithApi(
    List<SessionModel> apiSessions,
  ) async {
    await initDatabase();

    // 获取本地所有会话的ID和更新时间
    final localResult = await _database!.query(
      'novel_sessions',
      columns: ['id', 'updated_at'],
    );

    final localSessionMap = <int, String>{};
    for (final row in localResult) {
      localSessionMap[row['id'] as int] = row['updated_at'] as String? ?? '';
    }

    final sessionsToUpdate = <SessionModel>[];

    // 检测需要更新的会话
    for (final apiSession in apiSessions) {
      final localUpdatedAt = localSessionMap[apiSession.id];

      if (localUpdatedAt == null ||
          _isApiSessionNewer(apiSession.updatedAt, localUpdatedAt)) {
        sessionsToUpdate.add(apiSession);
      }
    }

    // 只执行更新，不删除其他页的数据
    if (sessionsToUpdate.isNotEmpty) {
      await insertOrUpdateNovelSessions(sessionsToUpdate);
    }

    debugPrint('[SessionDataService] 小说会话同步完成: 更新${sessionsToUpdate.length}条');

    return sessionsToUpdate;
  }

  /// 🔥 基于API数据同步角色会话：
  /// 1. 保存所有会话的activeArchiveId到SharedPreferences
  /// 2. 只把置顶的会话完整数据保存到SQLite
  Future<void> reconcileCharacterPageWithApi(
    List<SessionModel> apiSessions,
    int page,
    int pageSize,
  ) async {
    await initDatabase();

    if (apiSessions.isEmpty) return;

    // 1️⃣ 保存所有会话的activeArchiveId到SharedPreferences
    final Map<int, String?> archiveIds = {};
    for (final session in apiSessions) {
      archiveIds[session.id] = session.activeArchiveId;
    }
    await batchSaveCharacterArchiveIds(archiveIds);

    // 2️⃣ 只保存置顶的会话到SQLite
    final pinnedSessions = apiSessions.where((s) => s.isPinned == true).toList();
    if (pinnedSessions.isNotEmpty) {
      await insertOrUpdateCharacterSessions(pinnedSessions);
      debugPrint('[SessionDataService] 角色会话同步：保存${pinnedSessions.length}条置顶会话到SQLite（page=$page）');
    }
    
    debugPrint('[SessionDataService] 角色会话同步：保存${archiveIds.length}条activeArchiveId到SharedPreferences（page=$page）');
  }

  /// 🔥 基于API数据同步小说会话：
  /// 1. 保存所有会话的activeArchiveId到SharedPreferences
  /// 2. 只把置顶的会话完整数据保存到SQLite
  Future<void> reconcileNovelPageWithApi(
    List<SessionModel> apiSessions,
    int page,
    int pageSize,
  ) async {
    await initDatabase();

    if (apiSessions.isEmpty) return;

    // 1️⃣ 保存所有会话的activeArchiveId到SharedPreferences
    final Map<int, String?> archiveIds = {};
    for (final session in apiSessions) {
      archiveIds[session.id] = session.activeArchiveId;
    }
    await batchSaveNovelArchiveIds(archiveIds);

    // 2️⃣ 只保存置顶的会话到SQLite
    final pinnedSessions = apiSessions.where((s) => s.isPinned == true).toList();
    if (pinnedSessions.isNotEmpty) {
      await insertOrUpdateNovelSessions(pinnedSessions);
      debugPrint('[SessionDataService] 小说会话同步：保存${pinnedSessions.length}条置顶会话到SQLite（page=$page）');
    }
    
    debugPrint('[SessionDataService] 小说会话同步：保存${archiveIds.length}条activeArchiveId到SharedPreferences（page=$page）');
  }

  /// 判断API会话是否比本地会话更新
  bool _isApiSessionNewer(String? apiUpdatedAt, String localUpdatedAt) {
    if (apiUpdatedAt == null || apiUpdatedAt.isEmpty) return false;
    if (localUpdatedAt.isEmpty) return true;

    try {
      final apiTime = DateTime.parse(apiUpdatedAt);
      final localTime = DateTime.parse(localUpdatedAt);
      return apiTime.isAfter(localTime);
    } catch (e) {
      debugPrint('[SessionDataService] 时间比较失败: $e');
      return true; // 出错时默认更新
    }
  }

  /// 获取本地会话总数
  Future<int> getCharacterSessionCount() async {
    await initDatabase();
    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM character_sessions'
    );
    return result.first['count'] as int;
  }

  /// 获取本地小说会话总数
  Future<int> getNovelSessionCount() async {
    await initDatabase();
    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM novel_sessions'
    );
    return result.first['count'] as int;
  }

  /// 清理所有角色会话数据
  Future<void> clearAllCharacterSessions() async {
    await initDatabase();
    await _database!.delete('character_sessions');
    _notifyCharacterSessionsUpdate();
    debugPrint('[SessionDataService] 已清理所有角色会话数据');
  }

  /// 清理所有小说会话数据
  Future<void> clearAllNovelSessions() async {
    await initDatabase();
    await _database!.delete('novel_sessions');
    _notifyNovelSessionsUpdate();
    debugPrint('[SessionDataService] 已清理所有小说会话数据');
  }

  /// 清理所有会话数据
  Future<void> clearAllSessions() async {
    await clearAllCharacterSessions();
    await clearAllNovelSessions();
    await clearAllGroupChatSessions();
    debugPrint('[SessionDataService] 已清理所有会话数据');
  }

  /// 🔥 获取本地置顶的群聊会话列表（只返回置顶）
  Future<List<SessionModel>> getPinnedGroupChatSessions() async {
    await initDatabase();
    
    final result = await _database!.query(
      'group_chat_sessions',
      where: 'is_pinned = 1',
      orderBy: 'pinned_at DESC, updated_at DESC, id DESC',
    );

    final sessions = result.map((row) {
      final data = Map<String, dynamic>.from(row);
      if (data['extra_data'] != null) {
        data['extra_data'] = jsonDecode(data['extra_data']);
      }
      return SessionModel.fromDbJson(data);
    }).toList();

    debugPrint('[SessionDataService] 获取置顶群聊会话: ${sessions.length}条');
    return sessions;
  }
  
  /// 🔥 兼容旧接口：getLocalGroupChatSessions（已废弃，保留用于搜索）
  Future<SessionListResponse> getLocalGroupChatSessions({
    int page = 1,
    int pageSize = 10,
    String? searchName,
  }) async {
    await initDatabase();
    
    // 如果有搜索，返回空（搜索由API处理）
    if (searchName != null && searchName.isNotEmpty) {
      return SessionListResponse.fromLocalData([], page, pageSize, 0);
    }
    
    // 只返回置顶会话
    final pinnedSessions = await getPinnedGroupChatSessions();
    return SessionListResponse.fromLocalData(pinnedSessions, 1, pinnedSessions.length, pinnedSessions.length);
  }

  /// 批量插入或更新群聊会话
  Future<void> insertOrUpdateGroupChatSessions(List<SessionModel> sessions) async {
    await initDatabase();

    // 读取本地已有的置顶状态，避免被API数据覆盖
    final List<int> ids = sessions.map((s) => s.id).toList(growable: false);
    final Map<int, Map<String, Object?>> localPinned = await _loadLocalPinnedState(
      'group_chat_sessions',
      ids,
    );

    final batch = _database!.batch();

    for (final session in sessions) {
      final data = session.toDbJson();
      if (data['extra_data'] != null) {
        data['extra_data'] = jsonEncode(data['extra_data']);
      }

      // 🔥 群聊表不需要 active_archive_id 字段
      data.remove('active_archive_id');

      // 用本地置顶字段覆盖API构造的数据
      final pinnedRow = localPinned[session.id];
      if (pinnedRow != null) {
        data['is_pinned'] = pinnedRow['is_pinned'] ?? data['is_pinned'];
        data['pinned_at'] = pinnedRow['pinned_at'];
      }

      batch.insert(
        'group_chat_sessions',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);

    // 通知UI更新
    _notifyGroupChatSessionsUpdate();

    debugPrint('[SessionDataService] 批量更新群聊会话: ${sessions.length} 条');
  }

  /// 更新单个群聊会话
  Future<void> updateGroupChatSession(SessionModel session) async {
    await initDatabase();
    
    final data = session.toDbJson();
    if (data['extra_data'] != null) {
      data['extra_data'] = jsonEncode(data['extra_data']);
    }
    
    // 🔥 群聊表不需要 active_archive_id 字段
    data.remove('active_archive_id');
    
    await _database!.update(
      'group_chat_sessions',
      data,
      where: 'id = ?',
      whereArgs: [session.id],
    );
    
    _notifyGroupChatSessionsUpdate();
    debugPrint('[SessionDataService] 更新群聊会话: ${session.id}');
  }

  /// 删除群聊会话
  Future<void> deleteGroupChatSession(int sessionId) async {
    await initDatabase();
    
    await _database!.delete(
      'group_chat_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    
    _notifyGroupChatSessionsUpdate();
    debugPrint('[SessionDataService] 删除群聊会话: $sessionId');
  }

  /// 通知群聊会话更新
  Future<void> _notifyGroupChatSessionsUpdate() async {
    try {
      // 只获取前100条用于UI更新，避免内存压力
      final response = await getLocalGroupChatSessions(page: 1, pageSize: 100);
      _groupChatSessionsController.add(response.sessions);
    } catch (e) {
      debugPrint('[SessionDataService] 通知群聊会话更新失败: $e');
    }
  }

  /// 与API数据同步群聊会话（增量更新）
  Future<List<SessionModel>> syncGroupChatSessionsWithApi(
    List<SessionModel> apiSessions,
  ) async {
    await initDatabase();

    // 获取本地所有会话的ID和更新时间
    final localResult = await _database!.query(
      'group_chat_sessions',
      columns: ['id', 'updated_at'],
    );

    final localSessionMap = <int, String>{};
    for (final row in localResult) {
      localSessionMap[row['id'] as int] = row['updated_at'] as String? ?? '';
    }

    final sessionsToUpdate = <SessionModel>[];

    // 检测需要更新的会话
    for (final apiSession in apiSessions) {
      final localUpdatedAt = localSessionMap[apiSession.id];

      if (localUpdatedAt == null ||
          _isApiSessionNewer(apiSession.updatedAt, localUpdatedAt)) {
        sessionsToUpdate.add(apiSession);
      }
    }

    // 只执行更新，不删除其他页的数据
    if (sessionsToUpdate.isNotEmpty) {
      await insertOrUpdateGroupChatSessions(sessionsToUpdate);
    }

    debugPrint('[SessionDataService] 群聊会话同步完成: 更新${sessionsToUpdate.length}条');

    return sessionsToUpdate;
  }

  /// 🔥 基于API数据同步群聊会话：
  /// 1. 只把置顶的会话完整数据保存到SQLite（群聊无activeArchiveId）
  Future<void> reconcileGroupChatPageWithApi(
    List<SessionModel> apiSessions,
    int page,
    int pageSize,
  ) async {
    await initDatabase();

    if (apiSessions.isEmpty) return;

    // 只保存置顶的会话到SQLite
    final pinnedSessions = apiSessions.where((s) => s.isPinned == true).toList();
    if (pinnedSessions.isNotEmpty) {
      await insertOrUpdateGroupChatSessions(pinnedSessions);
      debugPrint('[SessionDataService] 群聊会话同步：保存${pinnedSessions.length}条置顶会话到SQLite（page=$page）');
    }
  }

  /// 获取本地群聊会话总数
  Future<int> getGroupChatSessionCount() async {
    await initDatabase();
    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM group_chat_sessions'
    );
    return result.first['count'] as int;
  }

  /// 清理所有群聊会话数据
  Future<void> clearAllGroupChatSessions() async {
    await initDatabase();
    await _database!.delete('group_chat_sessions');
    _notifyGroupChatSessionsUpdate();
    debugPrint('[SessionDataService] 已清理所有群聊会话数据');
  }

  /// 🔥 置顶群聊会话
  Future<void> pinGroupChatSession(int sessionId) async {
    await initDatabase();

    final pinnedAt = DateTime.now().toIso8601String();
    await _database!.update(
      'group_chat_sessions',
      {
        'is_pinned': 1,
        'pinned_at': pinnedAt,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    _notifyGroupChatSessionsUpdate();
    debugPrint('[SessionDataService] 置顶群聊会话: $sessionId');
  }

  /// 🔥 取消置顶群聊会话
  Future<void> unpinGroupChatSession(int sessionId) async {
    await initDatabase();

    await _database!.update(
      'group_chat_sessions',
      {
        'is_pinned': 0,
        'pinned_at': null,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    _notifyGroupChatSessionsUpdate();
    debugPrint('[SessionDataService] 取消置顶群聊会话: $sessionId');
  }

  /// 🔥 置顶角色会话
  Future<void> pinCharacterSession(int sessionId) async {
    await initDatabase();

    final pinnedAt = DateTime.now().toIso8601String();
    await _database!.update(
      'character_sessions',
      {
        'is_pinned': 1,
        'pinned_at': pinnedAt,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    _notifyCharacterSessionsUpdate();
    debugPrint('[SessionDataService] 置顶角色会话: $sessionId');
  }

  /// 🔥 取消置顶角色会话
  Future<void> unpinCharacterSession(int sessionId) async {
    await initDatabase();

    await _database!.update(
      'character_sessions',
      {
        'is_pinned': 0,
        'pinned_at': null,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    _notifyCharacterSessionsUpdate();
    debugPrint('[SessionDataService] 取消置顶角色会话: $sessionId');
  }

  /// 🔥 置顶小说会话
  Future<void> pinNovelSession(int sessionId) async {
    await initDatabase();

    final pinnedAt = DateTime.now().toIso8601String();
    await _database!.update(
      'novel_sessions',
      {
        'is_pinned': 1,
        'pinned_at': pinnedAt,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    _notifyNovelSessionsUpdate();
    debugPrint('[SessionDataService] 置顶小说会话: $sessionId');
  }

  /// 🔥 取消置顶小说会话
  Future<void> unpinNovelSession(int sessionId) async {
    await initDatabase();

    await _database!.update(
      'novel_sessions',
      {
        'is_pinned': 0,
        'pinned_at': null,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    _notifyNovelSessionsUpdate();
    debugPrint('[SessionDataService] 取消置顶小说会话: $sessionId');
  }

  /// 获取数据库统计信息
  Future<Map<String, dynamic>> getDatabaseStats() async {
    await initDatabase();

    final characterCount = await getCharacterSessionCount();
    final novelCount = await getNovelSessionCount();
    final groupChatCount = await getGroupChatSessionCount();

    // 获取数据库文件大小
    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'sessions.db');

    int dbSize = 0;
    try {
      final file = File(dbPath);
      if (await file.exists()) {
        dbSize = await file.length();
      }
    } catch (e) {
      debugPrint('[SessionDataService] 获取数据库大小失败: $e');
    }

    return {
      'characterSessionCount': characterCount,
      'novelSessionCount': novelCount,
      'groupChatSessionCount': groupChatCount,
      'totalSessionCount': characterCount + novelCount + groupChatCount,
      'databaseSizeBytes': dbSize,
      'databaseSizeMB': (dbSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  /// 检查数据库健康状态
  Future<bool> checkDatabaseHealth() async {
    try {
      await initDatabase();

      // 执行简单查询测试数据库连接
      await _database!.rawQuery('SELECT COUNT(*) FROM character_sessions');
      await _database!.rawQuery('SELECT COUNT(*) FROM novel_sessions');
      await _database!.rawQuery('SELECT COUNT(*) FROM group_chat_sessions');

      return true;
    } catch (e) {
      debugPrint('[SessionDataService] 数据库健康检查失败: $e');
      return false;
    }
  }

  /// 重建数据库（用于修复损坏的数据库）
  Future<void> rebuildDatabase() async {
    try {
      // 关闭当前数据库连接
      await _database?.close();
      _database = null;

      // 删除数据库文件
      final databasesPath = await getDatabasesPath();
      final dbPath = path.join(databasesPath, 'sessions.db');
      final file = File(dbPath);
      if (await file.exists()) {
        await file.delete();
      }

      // 重新初始化数据库
      await initDatabase();

      debugPrint('[SessionDataService] 数据库重建完成');
    } catch (e) {
      debugPrint('[SessionDataService] 数据库重建失败: $e');
      rethrow;
    }
  }

  /// 清理资源
  void dispose() {
    _characterSessionsController.close();
    _novelSessionsController.close();
    _groupChatSessionsController.close();
    _database?.close();
    _database = null;
  }

  // ==================== 🔥 SharedPreferences 存取 activeArchiveId ====================
  
  /// 保存角色会话的activeArchiveId
  Future<void> saveCharacterArchiveId(int sessionId, String? archiveId) async {
    await initDatabase();
    final key = 'character_archive_$sessionId';
    if (archiveId == null) {
      await _prefs!.remove(key);
    } else {
      await _prefs!.setString(key, archiveId);
    }
  }

  /// 获取角色会话的activeArchiveId
  String? getCharacterArchiveId(int sessionId) {
    final key = 'character_archive_$sessionId';
    return _prefs?.getString(key);
  }

  /// 保存小说会话的activeArchiveId
  Future<void> saveNovelArchiveId(int sessionId, String? archiveId) async {
    await initDatabase();
    final key = 'novel_archive_$sessionId';
    if (archiveId == null) {
      await _prefs!.remove(key);
    } else {
      await _prefs!.setString(key, archiveId);
    }
  }

  /// 获取小说会话的activeArchiveId
  String? getNovelArchiveId(int sessionId) {
    final key = 'novel_archive_$sessionId';
    return _prefs?.getString(key);
  }

  /// 批量保存角色会话的activeArchiveId
  Future<void> batchSaveCharacterArchiveIds(Map<int, String?> archiveIds) async {
    await initDatabase();
    for (final entry in archiveIds.entries) {
      await saveCharacterArchiveId(entry.key, entry.value);
    }
  }

  /// 批量保存小说会话的activeArchiveId
  Future<void> batchSaveNovelArchiveIds(Map<int, String?> archiveIds) async {
    await initDatabase();
    for (final entry in archiveIds.entries) {
      await saveNovelArchiveId(entry.key, entry.value);
    }
  }
}
