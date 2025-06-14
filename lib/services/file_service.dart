import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../net/http_client.dart';
import '../services/network_monitor_service.dart';

class FileService {
  final HttpClient _httpClient = HttpClient();
  final NetworkMonitorService _networkMonitor = NetworkMonitorService();
  final Dio _directDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 10),
  ));

  static const int _maxCacheSize = 500;
  Database? _db;

  // 随机数生成器用于负载均衡
  final Random _random = Random();

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
      // 如果插入失败，可能是数据类型问题，记录日志但不中断流程
      print('缓存文件失败: $e');
    }
  }

  /// 为图片请求选择一个可用的节点
  /// 使用加权随机策略根据各节点的响应时间和可用性选择
  Future<String> _selectEndpointForFile() async {
    try {
      // 获取所有端点状态 - 即使NetworkMonitorService未完全初始化，也能获取默认状态
      final endpointsStatus = await _networkMonitor.getEndpointsStatus();
      final availableEndpoints = <String, int>{}; // 节点 -> 权重

      // 计算总权重和收集可用节点
      endpointsStatus.forEach((endpoint, status) {
        if (status['available'] == true) {
          // 使用加权响应时间计算权重（响应时间越短，权重越高）
          final responseTime = status['weightedResponseTime'] as int;
          // 最大响应时间设为3000ms，如果超过则设为3000
          final cappedTime = min(responseTime, 3000);
          // 权重 = 3000 - 响应时间，确保响应时间短的有更高权重
          final weight = 3000 - cappedTime;
          availableEndpoints[endpoint as String] = weight;
        }
      });

      // 如果没有可用节点，返回默认节点
      if (availableEndpoints.isEmpty) {
        return NetworkMonitorService.getDefaultEndpoint();
      }

      // 计算总权重
      int totalWeight = availableEndpoints.values.reduce((a, b) => a + b);

      // 随机选择一个节点，基于权重
      int randomWeight = _random.nextInt(totalWeight);
      int currentWeight = 0;

      for (final entry in availableEndpoints.entries) {
        currentWeight += entry.value;
        if (randomWeight < currentWeight) {
          return entry.key;
        }
      }

      // 兜底返回列表中的第一个
      return availableEndpoints.keys.first;
    } catch (e) {
      // 出错或网络服务未初始化完成时，使用默认节点
      try {
        // 尝试获取当前URL，如果失败则使用默认节点
        return await _networkMonitor
            .getCurrentApiUrl()
            .timeout(const Duration(milliseconds: 100));
      } catch (_) {
        return NetworkMonitorService.getDefaultEndpoint();
      }
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

      // 上传文件使用标准HttpClient，不进行负载均衡
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

      // 为此次文件请求选择一个节点
      final endpoint = await _selectEndpointForFile();

      // 构建完整的文件URL
      final fileUrl = '$endpoint/api/v1/files?uri=$uri';

      // 使用直接的Dio实例请求文件，绕过HttpClient
      final response = await _directDio.get(
        fileUrl,
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
      // 如果特定节点请求失败，尝试使用标准HttpClient（可能会使用不同节点）
      try {
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
      } catch (fallbackError) {
        throw Exception('获取文件失败: $e, 备用方式也失败: $fallbackError');
      }
    }
  }

  /// 清理缓存
  Future<void> clearCache() async {
    await _initDb();
    await _db!.delete('file_cache');
  }
}
