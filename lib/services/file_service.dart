import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../net/http_client.dart';

class FileService {
  final HttpClient _httpClient = HttpClient();
  static const int _maxCacheSize = 500;
  Database? _db;

  // 单例模式
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  /// 初始化数据库
  Future<void> _initDb() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'file_cache.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE file_cache (
            uri TEXT PRIMARY KEY,
            response_data BLOB,
            last_accessed INTEGER
          )
        ''');
      },
    );
  }

  /// 从缓存中获取文件
  Future<Response?> _getFromCache(String uri) async {
    await _initDb();

    final result = await _db!.query(
      'file_cache',
      where: 'uri = ?',
      whereArgs: [uri],
    );

    if (result.isNotEmpty) {
      // 更新访问时间
      await _db!.update(
        'file_cache',
        {'last_accessed': DateTime.now().millisecondsSinceEpoch},
        where: 'uri = ?',
        whereArgs: [uri],
      );

      // 构造Response对象
      return Response(
        requestOptions: RequestOptions(path: ''),
        data: result.first['response_data'],
      );
    }

    return null;
  }

  /// 添加文件到缓存
  Future<void> _addToCache(String uri, Response response) async {
    await _initDb();

    // 检查缓存大小
    final count = Sqflite.firstIntValue(
            await _db!.rawQuery('SELECT COUNT(*) FROM file_cache')) ??
        0;

    // 如果缓存已满，删除最早访问的记录
    if (count >= _maxCacheSize) {
      await _db!.delete(
        'file_cache',
        where:
            'uri IN (SELECT uri FROM file_cache ORDER BY last_accessed LIMIT ?)',
        whereArgs: [count - _maxCacheSize + 1],
      );
    }

    // 添加新记录
    await _db!.insert(
      'file_cache',
      {
        'uri': uri,
        'response_data': response.data,
        'last_accessed': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 上传文件
  /// [file] 要上传的文件
  /// [type] 文件类型，例如："avatar"、"background"等
  /// 返回文件的URI
  Future<String> uploadFile(File file, String type) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'type': type,
      });

      final response = await _httpClient.post(
        '/files/upload',
        data: formData,
      );

      if (response.data['code'] == 0) {
        return response.data['data']['uri'];
      } else {
        throw Exception(response.data['msg'] ?? '上传失败');
      }
    } catch (e) {
      throw Exception('文件上传失败: $e');
    }
  }

  /// 获取文件
  /// [uri] 文件的唯一标识符，例如：xxx.jpg
  /// 返回文件的二进制数据
  Future<Response> getFile(String uri) async {
    try {
      // 先从缓存中查找
      final cachedResponse = await _getFromCache(uri);
      if (cachedResponse != null) {
        return cachedResponse;
      }

      // 缓存中没有，发起网络请求
      final response = await _httpClient.get(
        '/files',
        queryParameters: {'uri': uri},
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      );

      // 添加到缓存
      await _addToCache(uri, response);

      return response;
    } catch (e) {
      throw Exception('获取文件失败: $e');
    }
  }

  /// 清理缓存
  Future<void> clearCache() async {
    await _initDb();
    await _db!.delete('file_cache');
  }
}
