import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../net/http_client.dart';

class FileService {
  final HttpClient _httpClient = HttpClient();
  final Dio _directDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 10),
  ));

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

      // 获取缓存数据
      final cachedData = result.first['response_data'];

      // 确保数据类型正确
      if (cachedData is String) {
        // 如果是字符串，说明缓存数据有问题，返回null让它重新获取
        return null;
      }

      // 构造Response对象
      return Response(
        requestOptions: RequestOptions(path: ''),
        data: cachedData,
      );
    }

    return null;
  }

  /// 添加文件到缓存
  Future<void> _addToCache(String uri, Response response) async {
    await _initDb();

    // 确保只缓存二进制数据
    if (response.data is! List<int> && response.data is! Uint8List) {
      // 如果数据不是二进制格式，跳过缓存
      return;
    }

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
    try {
      await _db!.insert(
        'file_cache',
        {
          'uri': uri,
          'response_data': response.data,
          'last_accessed': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('缓存文件失败: $e');
    }
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

      // 上传文件使用HttpClient
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

      // 使用HttpClient获取文件，它会使用用户选择的节点
      final response = await _httpClient.get(
        '/files',
        queryParameters: {'uri': uri},
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      );

      // 验证响应数据是二进制格式
      if (response.data is! List<int> && response.data is! Uint8List) {
        throw Exception('服务器返回的数据不是二进制格式');
      }

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
