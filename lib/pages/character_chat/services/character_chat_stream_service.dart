import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../dao/user_dao.dart';
import '../models/sse_response.dart';

class CharacterChatStreamService {
  static const String baseUrl = 'http://156.238.229.127:18080/api/v1';
  final UserDao _userDao = UserDao();

  /// 发送对话消息并获取流式响应
  /// [sessionId] 会话ID
  /// [input] 用户输入的消息内容
  Stream<SseResponse> sendMessage(int sessionId, String input) async* {
    try {
      final token = await _userDao.getToken();
      if (token == null) {
        yield* Stream.error('未登录或token已失效');
        return;
      }

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
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        final error = await response.stream.bytesToString();

        // 检查是否包含 error 字段
        if (error.contains('"error"')) {
          yield SseResponse(
              id: '0',
              event: 'error',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              data: {
                'error': {'message': 'MODEL_OVERLOADED'}
              });
          return;
        }

        yield* Stream.error('请求失败: $error');
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

            if (sseResponse.isError) {
              yield* Stream.error(sseResponse.errorMsg ?? '未知错误');
              return;
            }

            yield sseResponse;

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
    } catch (e) {
      debugPrint('发送消息错误: $e');
      yield* Stream.error('发送消息失败: $e');
    }
  }
}
