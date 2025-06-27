import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../dao/user_dao.dart';
import '../models/sse_response.dart';
import '../../../services/network_monitor_service.dart';

class CharacterChatStreamService {
  final UserDao _userDao = UserDao();
  final NetworkMonitorService _networkMonitor = NetworkMonitorService();
  
  // 请求超时配置
  static const Duration _requestTimeout = Duration(seconds: 90); // 请求超时时间

  /// 发送对话消息并获取流式响应
  /// [sessionId] 会话ID
  /// [input] 用户输入的消息内容
  Stream<SseResponse> sendMessage(int sessionId, String input) async* {
    try {
      // 获取授权令牌
      final token = await _userDao.getToken();
      if (token == null) {
        yield* Stream.error('未登录或token已失效');
        return;
      }

      // 获取当前选择的API节点
      final currentEndpoint = await _networkMonitor.getCurrentEndpoint();
      final baseUrl = '$currentEndpoint/api/v1';
      debugPrint('[角色对话] 使用节点: $currentEndpoint');

      final uri = Uri.parse('$baseUrl/sessions/character/$sessionId/chat');
      final request = http.Request('POST', uri);

      // 设置请求头
      request.headers.addAll({
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'text/event-stream',
        'Authorization': 'Bearer $token',
      });

      // 设置请求体
      request.body = jsonEncode({'input': input});

      // 发送请求并获取响应流
      final client = http.Client();
      final response = await client.send(request).timeout(
        _requestTimeout,
        onTimeout: () {
          client.close();
          throw TimeoutException('请求超时（${_requestTimeout.inSeconds}秒）');
        },
      );

      // HTTP级别的错误处理
      if (response.statusCode != 200) {
        final errorStr = await response.stream.bytesToString();
        Map<String, dynamic> errorData;
        try {
          errorData = jsonDecode(errorStr);
        } catch (e) {
          yield* Stream.error('请求失败: $errorStr');
          return;
        }

        if (errorData['code'] == 1019) {
          await _userDao.clearUserInfo();
          yield* Stream.error(errorData['msg'] ?? '登录已过期');
          return;
        }
        
        yield* Stream.error(errorData['msg'] ?? '未知错误');
        return;
      }

      String buffer = '';

      // 处理SSE流
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;

        // 处理完整的数据行
        while (buffer.contains('\n')) {
          final index = buffer.indexOf('\n');
          final line = buffer.substring(0, index).trim();
          buffer = buffer.substring(index + 1);

          if (line.isEmpty) continue;
          if (!line.startsWith('data:')) continue;

          try {
            final data = line.substring(5).trim();
            final sseResponse = SseResponse.fromSseData(data);

            // 所有SSE消息都直接传递给上层处理，包括错误消息
            yield sseResponse;

            // 如果收到done事件，流处理结束，但不抛出异常
            if (sseResponse.isDone) {
              return;
            }
          } catch (e) {
            debugPrint('解析SSE数据错误: $e');
            continue;
          }
        }
      }

      // 处理缓冲区中剩余的数据
      if (buffer.isNotEmpty) {
        final line = buffer.trim();
        if (line.startsWith('data:')) {
          try {
            final data = line.substring(5).trim();
            final sseResponse = SseResponse.fromSseData(data);
            yield sseResponse;
          } catch (e) {
            debugPrint('解析最后一行SSE数据错误: $e');
          }
        }
      }
    } on TimeoutException catch (e) {
      debugPrint('请求超时: $e');
      yield* Stream.error('请求超时（${_requestTimeout.inSeconds}秒）');
      return;
    } on SocketException catch (e) {
      debugPrint('网络连接错误: $e');
      yield* Stream.error('网络连接失败: ${e.message}');
      return;
    } catch (e) {
      debugPrint('发送消息错误: $e');
      yield* Stream.error('发送消息失败: $e');
      return;
    }
  }

  /// 重新生成AI回复
  /// [sessionId] 会话ID
  /// [msgId] 需要重新生成的消息ID
  Stream<SseResponse> regenerateMessage(int sessionId, String msgId) async* {
    try {
      final token = await _userDao.getToken();
      if (token == null) {
        yield* Stream.error('未登录或token已失效');
        return;
      }

      // 获取当前选择的API节点
      final currentEndpoint = await _networkMonitor.getCurrentEndpoint();
      final baseUrl = '$currentEndpoint/api/v1';
      debugPrint('[角色对话] 使用节点: $currentEndpoint');

      final uri = Uri.parse('$baseUrl/sessions/character/$sessionId/regenerate');
      final request = http.Request('POST', uri);

      // 设置请求头
      request.headers.addAll({
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'text/event-stream',
        'Authorization': 'Bearer $token',
      });

      // 设置请求体
      request.body = jsonEncode({'msgId': msgId});

      // 发送请求并获取响应流
      final client = http.Client();
      final response = await client.send(request).timeout(
        _requestTimeout,
        onTimeout: () {
          client.close();
          throw TimeoutException('请求超时（${_requestTimeout.inSeconds}秒）');
        },
      );

      // 处理非200状态码的HTTP级别错误
      if (response.statusCode != 200) {
        final errorStr = await response.stream.bytesToString();
        Map<String, dynamic> errorData;
        try {
          errorData = jsonDecode(errorStr);
        } catch (e) {
          yield* Stream.error('请求失败: $errorStr');
          return;
        }

        if (errorData['code'] == 1019) {
          await _userDao.clearUserInfo();
          yield* Stream.error(errorData['msg'] ?? '登录已过期');
          return;
        }
        
        yield* Stream.error(errorData['msg'] ?? '未知错误');
        return;
      }

      String buffer = '';

      // 处理SSE流
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;

        // 处理完整的数据行
        while (buffer.contains('\n')) {
          final index = buffer.indexOf('\n');
          final line = buffer.substring(0, index).trim();
          buffer = buffer.substring(index + 1);

          if (line.isEmpty) continue;
          if (!line.startsWith('data:')) continue;

          try {
            final data = line.substring(5).trim();
            final sseResponse = SseResponse.fromSseData(data);

            // 所有SSE消息都直接传递给上层处理，包括错误消息
            yield sseResponse;

            // 如果收到done事件，流处理结束，但不抛出异常
            if (sseResponse.isDone) {
              return;
            }
          } catch (e) {
            debugPrint('解析SSE数据错误: $e');
            continue;
          }
        }
      }

      // 处理缓冲区中剩余的数据
      if (buffer.isNotEmpty) {
        final line = buffer.trim();
        if (line.startsWith('data:')) {
          try {
            final data = line.substring(5).trim();
            final sseResponse = SseResponse.fromSseData(data);
            yield sseResponse;
          } catch (e) {
            debugPrint('解析最后一行SSE数据错误: $e');
          }
        }
      }
    } on TimeoutException catch (e) {
      debugPrint('请求超时: $e');
      yield* Stream.error('请求超时（${_requestTimeout.inSeconds}秒）');
      return;
    } on SocketException catch (e) {
      debugPrint('网络连接错误: $e');
      yield* Stream.error('网络连接失败: ${e.message}');
      return;
    } catch (e) {
      debugPrint('重新生成消息错误: $e');
      yield* Stream.error('重新生成失败: $e');
      return;
    }
  }
}
