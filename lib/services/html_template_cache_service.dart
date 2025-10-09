import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../net/http_client.dart';

/// HTML 模板缓存服务
/// 专门用于缓存生产版本的 HTML 模板代码
class HtmlTemplateCacheService {
  final HttpClient _httpClient = HttpClient();
  
  static const int _maxCacheSize = 100; // 最多缓存100个模板
  Database? _db;

  // 单例模式
  static final HtmlTemplateCacheService _instance = HtmlTemplateCacheService._internal();
  factory HtmlTemplateCacheService() => _instance;
  HtmlTemplateCacheService._internal();

  /// 初始化数据库
  Future<void> _initDb() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'html_template_cache.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE html_template_cache (
            id INTEGER PRIMARY KEY,
            html_template TEXT,
            last_accessed INTEGER
          )
        ''');
      },
    );
  }

  /// 从缓存中获取模板
  Future<String?> _getFromCache(int id) async {
    await _initDb();

    final result = await _db!.query(
      'html_template_cache',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      // 更新访问时间
      await _db!.update(
        'html_template_cache',
        {'last_accessed': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );

      return result.first['html_template'] as String?;
    }

    return null;
  }

  /// 添加模板到缓存
  Future<void> _addToCache(int id, String htmlTemplate) async {
    await _initDb();

    // 检查缓存大小
    final count = Sqflite.firstIntValue(
      await _db!.rawQuery('SELECT COUNT(*) FROM html_template_cache')
    ) ?? 0;

    // 如果缓存已满，删除最早访问的记录
    if (count >= _maxCacheSize) {
      await _db!.rawDelete('''
        DELETE FROM html_template_cache 
        WHERE id IN (
          SELECT id FROM html_template_cache 
          ORDER BY last_accessed ASC 
          LIMIT 1
        )
      ''');
    }

    // 插入或替换缓存
    await _db!.insert(
      'html_template_cache',
      {
        'id': id,
        'html_template': htmlTemplate,
        'last_accessed': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 从后端获取项目详情（带重试机制）
  Future<Map<String, dynamic>?> _fetchProjectDetail(int id, {int retryCount = 0}) async {
    try {
      final response = await _httpClient.get('/html-beautify/projects/$id');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 0) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
      
      return null;
    } catch (e) {
      // 如果失败且还有重试次数，则重试一次
      if (retryCount < 1) {
        await Future.delayed(const Duration(milliseconds: 500)); // 延迟500ms后重试
        return _fetchProjectDetail(id, retryCount: retryCount + 1);
      }
      
      // 重试后仍失败，返回null
      return null;
    }
  }

  /// 数据准备方法：解析ID并批量缓存
  /// @param htmlTemplates 格式如 "1,2,3" 或 "100"
  Future<void> prepareTemplates(String htmlTemplates) async {
    if (htmlTemplates.isEmpty) return;

    // 解析ID列表
    final ids = htmlTemplates.split(',')
        .map((e) => int.tryParse(e.trim()))
        .where((e) => e != null)
        .cast<int>()
        .toList();

    if (ids.isEmpty) return;

    // 批量获取并缓存
    for (final id in ids) {
      try {
        final projectData = await _fetchProjectDetail(id);
        
        if (projectData != null) {
          final version = projectData['version'] as int?;
          
          // 只缓存生产版本（version == 2）
          if (version == 2) {
            final htmlTemplate = projectData['html_template'] as String?;
            if (htmlTemplate != null && htmlTemplate.isNotEmpty) {
              await _addToCache(id, htmlTemplate);
            }
          }
        }
      } catch (e) {
        // 忽略单个项目的错误，继续处理下一个
        print('准备HTML模板缓存失败 (ID: $id): $e');
      }
    }
  }

  /// 获取单个模板（先从缓存找，没有就请求）
  /// @param id 模板ID
  /// @return HTML模板代码，如果获取失败返回null
  Future<String?> getTemplate(int id) async {
    // 1. 先从缓存获取
    final cachedTemplate = await _getFromCache(id);
    if (cachedTemplate != null) {
      return cachedTemplate;
    }

    // 2. 缓存中没有，从后端获取
    try {
      final projectData = await _fetchProjectDetail(id);
      
      if (projectData != null) {
        final version = projectData['version'] as int?;
        final htmlTemplate = projectData['html_template'] as String?;
        
        // 只缓存生产版本
        if (version == 2 && htmlTemplate != null && htmlTemplate.isNotEmpty) {
          await _addToCache(id, htmlTemplate);
          return htmlTemplate;
        }
        
        // 非生产版本也返回，但不缓存
        return htmlTemplate;
      }
      
      return null;
    } catch (e) {
      print('获取HTML模板失败 (ID: $id): $e');
      return null;
    }
  }

  /// 批量获取模板
  /// @param ids 模板ID列表
  /// @return Map<id, htmlTemplate>
  Future<Map<int, String>> getTemplates(List<int> ids) async {
    final result = <int, String>{};
    
    for (final id in ids) {
      final template = await getTemplate(id);
      if (template != null) {
        result[id] = template;
      }
    }
    
    return result;
  }

  /// 清空缓存
  Future<void> clearCache() async {
    await _initDb();
    await _db!.delete('html_template_cache');
  }

  /// 删除指定模板缓存
  Future<void> removeTemplate(int id) async {
    await _initDb();
    await _db!.delete(
      'html_template_cache',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    await _initDb();
    
    final count = Sqflite.firstIntValue(
      await _db!.rawQuery('SELECT COUNT(*) FROM html_template_cache')
    ) ?? 0;
    
    return {
      'count': count,
      'maxSize': _maxCacheSize,
    };
  }

  /// 检查指定的模板是否都已缓存
  /// @param htmlTemplates 格式如 "1,2,3" 或 "100"
  /// @return true 表示全部已缓存，false 表示有未缓存的
  Future<bool> checkAllCached(String htmlTemplates) async {
    if (htmlTemplates.isEmpty) return true;

    await _initDb();

    // 解析ID列表
    final ids = htmlTemplates.split(',')
        .map((e) => int.tryParse(e.trim()))
        .where((e) => e != null)
        .cast<int>()
        .toList();

    if (ids.isEmpty) return true;

    // 检查每个ID是否都在缓存中
    for (final id in ids) {
      final result = await _db!.query(
        'html_template_cache',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) {
        return false; // 有未缓存的
      }
    }

    return true; // 全部已缓存
  }

  /// 数据准备方法（带进度回调）
  /// @param htmlTemplates 格式如 "1,2,3" 或 "100"
  /// @param onProgress 进度回调 (current, total)
  Future<void> prepareTemplatesWithProgress(
    String htmlTemplates, {
    Function(int current, int total)? onProgress,
  }) async {
    if (htmlTemplates.isEmpty) return;

    // 解析ID列表
    final ids = htmlTemplates.split(',')
        .map((e) => int.tryParse(e.trim()))
        .where((e) => e != null)
        .cast<int>()
        .toList();

    if (ids.isEmpty) return;

    final total = ids.length;
    int current = 0;

    // 批量获取并缓存
    for (final id in ids) {
      try {
        final projectData = await _fetchProjectDetail(id);
        
        if (projectData != null) {
          final version = projectData['version'] as int?;
          
          // 只缓存生产版本（version == 2）
          if (version == 2) {
            final htmlTemplate = projectData['html_template'] as String?;
            if (htmlTemplate != null && htmlTemplate.isNotEmpty) {
              await _addToCache(id, htmlTemplate);
            }
          }
        }
      } catch (e) {
        // 忽略单个项目的错误，继续处理下一个
        print('准备HTML模板缓存失败 (ID: $id): $e');
      } finally {
        current++;
        onProgress?.call(current, total);
      }
    }
  }
}

