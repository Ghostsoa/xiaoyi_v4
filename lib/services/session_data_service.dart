import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/session_model.dart';

/// 会话数据服务
/// 管理本地会话数据的存储、同步和更新
class SessionDataService {
  static final SessionDataService _instance = SessionDataService._internal();
  factory SessionDataService() => _instance;
  SessionDataService._internal();

  Database? _database;
  final StreamController<List<SessionModel>> _characterSessionsController = 
      StreamController<List<SessionModel>>.broadcast();
  final StreamController<List<SessionModel>> _novelSessionsController = 
      StreamController<List<SessionModel>>.broadcast();

  /// 角色会话数据流
  Stream<List<SessionModel>> get characterSessionsStream => 
      _characterSessionsController.stream;

  /// 小说会话数据流
  Stream<List<SessionModel>> get novelSessionsStream => 
      _novelSessionsController.stream;

  /// 初始化数据库
  Future<void> initDatabase() async {
    if (_database != null) return;

    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'sessions.db');

    _database = await openDatabase(
      dbPath,
      version: 3, // 🔥 升级版本以支持置顶功能
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

    // 创建索引
    await db.execute('CREATE INDEX idx_character_sessions_updated_at ON character_sessions(updated_at)');
    await db.execute('CREATE INDEX idx_novel_sessions_updated_at ON novel_sessions(updated_at)');
    // 🔥 添加置顶字段索引，优化排序性能
    await db.execute('CREATE INDEX idx_character_sessions_pinned ON character_sessions(is_pinned, pinned_at)');
    await db.execute('CREATE INDEX idx_novel_sessions_pinned ON novel_sessions(is_pinned, pinned_at)');

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
  }

  /// 获取本地角色会话列表（分页）
  Future<SessionListResponse> getLocalCharacterSessions({
    int page = 1,
    int pageSize = 10,
  }) async {
    await initDatabase();
    
    final offset = (page - 1) * pageSize;
    
    // 获取总数
    final countResult = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM character_sessions'
    );
    final total = countResult.first['count'] as int;

    // 🔥 获取分页数据，置顶会话优先显示，置顶内按消息时间排序（微信方式）
    final result = await _database!.query(
      'character_sessions',
      orderBy: 'is_pinned DESC, updated_at DESC, id DESC',
      limit: pageSize,
      offset: offset,
    );

    final sessions = result.map((row) {
      final data = Map<String, dynamic>.from(row);
      if (data['extra_data'] != null) {
        data['extra_data'] = jsonDecode(data['extra_data']);
      }
      return SessionModel.fromDbJson(data);
    }).toList();

    return SessionListResponse.fromLocalData(sessions, page, pageSize, total);
  }

  /// 获取本地小说会话列表（分页）
  Future<SessionListResponse> getLocalNovelSessions({
    int page = 1,
    int pageSize = 10,
  }) async {
    await initDatabase();
    
    final offset = (page - 1) * pageSize;
    
    // 获取总数
    final countResult = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM novel_sessions'
    );
    final total = countResult.first['count'] as int;

    // 🔥 获取分页数据，置顶会话优先显示，置顶内按消息时间排序（微信方式）
    final result = await _database!.query(
      'novel_sessions',
      orderBy: 'is_pinned DESC, updated_at DESC, id DESC',
      limit: pageSize,
      offset: offset,
    );

    final sessions = result.map((row) {
      final data = Map<String, dynamic>.from(row);
      if (data['extra_data'] != null) {
        data['extra_data'] = jsonDecode(data['extra_data']);
      }
      return SessionModel.fromDbJson(data);
    }).toList();

    return SessionListResponse.fromLocalData(sessions, page, pageSize, total);
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

      // 用本地置顶字段覆盖API构造的数据
      final pinnedRow = localPinned[session.id];
      if (pinnedRow != null) {
        data['is_pinned'] = pinnedRow['is_pinned'] ?? data['is_pinned'];
        data['pinned_at'] = pinnedRow['pinned_at'];
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

      // 用本地置顶字段覆盖API构造的数据
      final pinnedRow = localPinned[session.id];
      if (pinnedRow != null) {
        data['is_pinned'] = pinnedRow['is_pinned'] ?? data['is_pinned'];
        data['pinned_at'] = pinnedRow['pinned_at'];
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

  /// 读取本地已有置顶状态（id -> {is_pinned, pinned_at}）
  Future<Map<int, Map<String, Object?>>> _loadLocalPinnedState(
    String table,
    List<int> ids,
  ) async {
    if (ids.isEmpty) return <int, Map<String, Object?>>{};

    // 构造 WHERE IN 子句
    final String placeholders = List.filled(ids.length, '?').join(',');
    final List<Map<String, Object?>> rows = await _database!.rawQuery(
      'SELECT id, is_pinned, pinned_at FROM ' + table + ' WHERE id IN (' + placeholders + ')',
      ids,
    );

    final Map<int, Map<String, Object?>> result = <int, Map<String, Object?>>{};
    for (final row in rows) {
      final int id = (row['id'] as int);
      result[id] = <String, Object?>{
        'is_pinned': row['is_pinned'],
        'pinned_at': row['pinned_at'],
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
      final response = await getLocalCharacterSessions(page: 1, pageSize: 1000);
      _characterSessionsController.add(response.sessions);
    } catch (e) {
      debugPrint('[SessionDataService] 通知角色会话更新失败: $e');
    }
  }

  /// 通知小说会话更新
  Future<void> _notifyNovelSessionsUpdate() async {
    try {
      final response = await getLocalNovelSessions(page: 1, pageSize: 1000);
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
    final sessionsToDelete = <int>[];

    // 检测需要更新的会话
    for (final apiSession in apiSessions) {
      final localUpdatedAt = localSessionMap[apiSession.id];

      if (localUpdatedAt == null ||
          _isApiSessionNewer(apiSession.updatedAt, localUpdatedAt)) {
        sessionsToUpdate.add(apiSession);
      }

      // 从本地映射中移除，剩下的就是需要删除的
      localSessionMap.remove(apiSession.id);
    }

    // 删除本地存在但API中不存在的会话
    sessionsToDelete.addAll(localSessionMap.keys);

    // 执行更新
    if (sessionsToUpdate.isNotEmpty) {
      await insertOrUpdateCharacterSessions(sessionsToUpdate);
    }

    // 执行删除
    for (final sessionId in sessionsToDelete) {
      await deleteCharacterSession(sessionId);
    }

    debugPrint('[SessionDataService] 角色会话同步完成: 更新${sessionsToUpdate.length}条, 删除${sessionsToDelete.length}条');

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
    final sessionsToDelete = <int>[];

    // 检测需要更新的会话
    for (final apiSession in apiSessions) {
      final localUpdatedAt = localSessionMap[apiSession.id];

      if (localUpdatedAt == null ||
          _isApiSessionNewer(apiSession.updatedAt, localUpdatedAt)) {
        sessionsToUpdate.add(apiSession);
      }

      // 从本地映射中移除，剩下的就是需要删除的
      localSessionMap.remove(apiSession.id);
    }

    // 删除本地存在但API中不存在的会话
    sessionsToDelete.addAll(localSessionMap.keys);

    // 执行更新
    if (sessionsToUpdate.isNotEmpty) {
      await insertOrUpdateNovelSessions(sessionsToUpdate);
    }

    // 执行删除
    for (final sessionId in sessionsToDelete) {
      await deleteNovelSession(sessionId);
    }

    debugPrint('[SessionDataService] 小说会话同步完成: 更新${sessionsToUpdate.length}条, 删除${sessionsToDelete.length}条');

    return sessionsToUpdate;
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
    debugPrint('[SessionDataService] 已清理所有会话数据');
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
      'totalSessionCount': characterCount + novelCount,
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
    _database?.close();
    _database = null;
  }
}
