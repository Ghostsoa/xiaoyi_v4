import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

/// 消息缓存服务
/// 管理按存档ID隔离的消息本地存储
class MessageCacheService {
  static final MessageCacheService _instance = MessageCacheService._internal();
  factory MessageCacheService() => _instance;
  MessageCacheService._internal();

  Database? _database;

  /// 初始化数据库
  Future<void> initDatabase() async {
    if (_database != null) return;

    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'messages_cache.db');

    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );

    debugPrint('[MessageCacheService] 数据库初始化完成: $dbPath');
  }

  /// 创建数据库表
  Future<void> _createTables(Database db, int version) async {
    // 消息缓存表（按存档ID隔离）
    await db.execute('''
      CREATE TABLE messages_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        archive_id TEXT NOT NULL,
        msg_id TEXT NOT NULL,
        content TEXT,
        role TEXT,
        created_at TEXT,
        token_count INTEGER,
        status_bar TEXT,
        enhanced INTEGER,
        keywords TEXT,
        last_sync_time INTEGER,
        UNIQUE(session_id, archive_id, msg_id)
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_messages_session_archive ON messages_cache(session_id, archive_id)');
    await db.execute('CREATE INDEX idx_messages_created_at ON messages_cache(created_at)');

    debugPrint('[MessageCacheService] 数据库表创建完成');
  }

  /// 升级数据库表
  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    debugPrint('[MessageCacheService] 数据库升级: $oldVersion -> $newVersion');
  }

  /// 获取指定存档的消息列表（分页）
  Future<Map<String, dynamic>> getArchiveMessages({
    required int sessionId,
    required String archiveId,
    int page = 1,
    int pageSize = 20,
  }) async {
    await initDatabase();
    
    final offset = (page - 1) * pageSize;
    
    // 获取总数
    final countResult = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM messages_cache WHERE session_id = ? AND archive_id = ?',
      [sessionId, archiveId]
    );
    final total = countResult.first['count'] as int;

    // 获取分页数据（按创建时间倒序排序，配合ListView的reverse: true）
    final result = await _database!.query(
      'messages_cache',
      where: 'session_id = ? AND archive_id = ?',
      whereArgs: [sessionId, archiveId],
      orderBy: 'created_at DESC',
      limit: pageSize,
      offset: offset,
    );

    final messages = result.map((row) {
      final data = Map<String, dynamic>.from(row);
      
      // 解析JSON字段
      if (data['keywords'] != null && data['keywords'].isNotEmpty) {
        try {
          data['keywords'] = jsonDecode(data['keywords']);
        } catch (e) {
          data['keywords'] = [];
        }
      }
      
      return {
        'msgId': data['msg_id'],
        'content': data['content'],
        'role': data['role'],
        'createdAt': data['created_at'],
        'tokenCount': data['token_count'],
        'statusBar': data['status_bar'],
        'enhanced': data['enhanced'] == 1,
        'keywords': data['keywords'] ?? [],
      };
    }).toList();

    return {
      'list': messages,
      'pagination': {
        'total_pages': (total / pageSize).ceil(),
        'current_page': page,
        'total_count': total,
        'page_size': pageSize,
      }
    };
  }

  /// 批量插入或更新消息
  Future<void> insertOrUpdateMessages({
    required int sessionId,
    required String archiveId,
    required List<Map<String, dynamic>> messages,
  }) async {
    await initDatabase();
    
    final batch = _database!.batch();
    
    for (final message in messages) {
      final data = {
        'session_id': sessionId,
        'archive_id': archiveId,
        'msg_id': message['msgId'],
        'content': message['content'],
        'role': message['role'],
        'created_at': message['createdAt'],
        'token_count': message['tokenCount'] ?? 0,
        'status_bar': message['statusBar'],
        'enhanced': message['enhanced'] == true ? 1 : 0,
        'keywords': message['keywords'] != null ? jsonEncode(message['keywords']) : null,
        'last_sync_time': DateTime.now().millisecondsSinceEpoch,
      };
      
      batch.insert(
        'messages_cache',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
    
    debugPrint('[MessageCacheService] 批量更新消息: ${messages.length} 条 (session: $sessionId, archive: $archiveId)');
  }

  /// 删除指定消息
  Future<void> deleteMessage({
    required int sessionId,
    required String archiveId,
    required String msgId,
  }) async {
    await initDatabase();

    await _database!.delete(
      'messages_cache',
      where: 'session_id = ? AND archive_id = ? AND msg_id = ?',
      whereArgs: [sessionId, archiveId, msgId],
    );

    debugPrint('[MessageCacheService] 删除消息: $msgId (session: $sessionId, archive: $archiveId)');
  }

  /// 删除指定时间及之后的所有消息（用于撤销操作）
  Future<void> deleteMessagesFromTime({
    required int sessionId,
    required String archiveId,
    required String fromTime,
  }) async {
    await initDatabase();

    await _database!.delete(
      'messages_cache',
      where: 'session_id = ? AND archive_id = ? AND created_at >= ?',
      whereArgs: [sessionId, archiveId, fromTime],
    );

    debugPrint('[MessageCacheService] 删除消息从时间 $fromTime 开始 (session: $sessionId, archive: $archiveId)');
  }

  /// 搜索消息（关键词搜索）
  Future<List<Map<String, dynamic>>> searchMessages({
    required int sessionId,
    required String archiveId,
    required String keyword,
  }) async {
    await initDatabase();

    // 使用 LIKE 进行模糊搜索，搜索消息内容
    final result = await _database!.query(
      'messages_cache',
      where: 'session_id = ? AND archive_id = ? AND content LIKE ?',
      whereArgs: [sessionId, archiveId, '%$keyword%'],
      orderBy: 'created_at DESC', // 按时间倒序，最新的在前
    );

    debugPrint('[MessageCacheService] 搜索关键词 "$keyword" 找到 ${result.length} 条消息 (session: $sessionId, archive: $archiveId)');

    return result;
  }



  /// 更新指定消息
  Future<void> updateMessage({
    required int sessionId,
    required String archiveId,
    required String msgId,
    required Map<String, dynamic> messageData,
  }) async {
    await initDatabase();
    
    final data = {
      'content': messageData['content'],
      'token_count': messageData['tokenCount'] ?? 0,
      'status_bar': messageData['statusBar'],
      'enhanced': messageData['enhanced'] == true ? 1 : 0,
      'keywords': messageData['keywords'] != null ? jsonEncode(messageData['keywords']) : null,
      'last_sync_time': DateTime.now().millisecondsSinceEpoch,
    };
    
    await _database!.update(
      'messages_cache',
      data,
      where: 'session_id = ? AND archive_id = ? AND msg_id = ?',
      whereArgs: [sessionId, archiveId, msgId],
    );
    
    debugPrint('[MessageCacheService] 更新消息: $msgId (session: $sessionId, archive: $archiveId)');
  }

  /// 检查指定存档是否有缓存数据
  Future<bool> hasArchiveCache({
    required int sessionId,
    required String archiveId,
  }) async {
    await initDatabase();
    
    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM messages_cache WHERE session_id = ? AND archive_id = ?',
      [sessionId, archiveId]
    );
    
    final count = result.first['count'] as int;
    return count > 0;
  }

  /// 获取存档缓存统计信息
  Future<Map<String, dynamic>> getArchiveCacheStats({
    required int sessionId,
    required String archiveId,
  }) async {
    await initDatabase();
    
    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count, MAX(last_sync_time) as last_sync FROM messages_cache WHERE session_id = ? AND archive_id = ?',
      [sessionId, archiveId]
    );
    
    final row = result.first;
    return {
      'messageCount': row['count'] as int,
      'lastSyncTime': row['last_sync'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(row['last_sync'] as int)
          : null,
    };
  }

  /// 清理指定存档的所有缓存
  Future<void> clearArchiveCache({
    required int sessionId,
    required String archiveId,
  }) async {
    await initDatabase();
    
    await _database!.delete(
      'messages_cache',
      where: 'session_id = ? AND archive_id = ?',
      whereArgs: [sessionId, archiveId],
    );
    
    debugPrint('[MessageCacheService] 清理存档缓存: session=$sessionId, archive=$archiveId');
  }

  /// 清理指定会话的所有缓存
  Future<void> clearSessionCache(int sessionId) async {
    await initDatabase();
    
    await _database!.delete(
      'messages_cache',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    
    debugPrint('[MessageCacheService] 清理会话缓存: session=$sessionId');
  }

  /// 清理资源
  void dispose() {
    _database?.close();
    _database = null;
  }
}
