import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../../../dao/user_dao.dart';
import '../../../net/http_client.dart';
import '../../../pages/login/login_page.dart';
import '../../character_chat/models/sse_response.dart';
import '../../../services/network_monitor_service.dart';

class GroupChatStreamService {
  final UserDao _userDao = UserDao();
  final NetworkMonitorService _networkMonitor = NetworkMonitorService();

  // 请求超时配置
  static const Duration _requestTimeout = Duration(minutes: 5); // 请求超时时间

  // 获取应用版本号
  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      debugPrint('获取版本号失败: $e');
      return '1.0.0+1'; // 默认版本号
    }
  }

  /// 处理令牌失效
  void _handleTokenExpired() async {
    // 清除用户信息
    await _userDao.clearUserInfo();

    // 使用navigatorKey导航到登录页面
    if (HttpClient.navigatorKey.currentContext != null) {
      Navigator.pushAndRemoveUntil(
        HttpClient.navigatorKey.currentContext!,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  /// 发送群聊消息并获取流式响应
  /// [sessionId] 会话ID
  /// [input] 用户输入的消息内容
  Stream<SseResponse> sendMessage(int sessionId, String input) async* {
    final controller = StreamController<SseResponse>();
    http.Client? sseClient;
    bool finished = false;

    Future<void> safeCloseAll() async {
      if (finished) return;
      finished = true;
      try {
        sseClient?.close();
      } catch (_) {}
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    try {
      // 获取授权令牌
      final token = await _userDao.getToken();
      if (token == null) {
        controller.addError('令牌失效');
        await safeCloseAll();
        yield* controller.stream;
        return;
      }

      // 获取当前选择的API节点
      final currentEndpoint = await _networkMonitor.getCurrentEndpoint();
      final baseUrl = '$currentEndpoint/api/v1';
      debugPrint('[群聊对话] 使用节点: $currentEndpoint');

      // 获取应用版本号
      final appVersion = await _getAppVersion();

      // 预先准备SSE请求
      final chatUri = Uri.parse('$baseUrl/sessions/groupchat/$sessionId/chat');
      final sseRequest = http.Request('POST', chatUri);
      sseRequest.headers.addAll({
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'text/event-stream',
        'Authorization': 'Bearer $token',
        'X-App-Version': appVersion,
      });
      sseRequest.body = jsonEncode({'input': input});

      // 启动SSE读取
      sseClient = http.Client();
      () async {
        http.StreamedResponse? response;
        try {
          response = await sseClient!.send(sseRequest).timeout(
            _requestTimeout,
            onTimeout: () {
              sseClient?.close();
              throw TimeoutException('请求超时（${_requestTimeout.inSeconds}秒）');
            },
          );
        } on TimeoutException catch (e) {
          debugPrint('请求超时: $e');
          if (!controller.isClosed) {
            controller.addError('请求超时');
          }
          await safeCloseAll();
          return;
        } on SocketException catch (e) {
          debugPrint('网络连接错误: $e');
          if (!controller.isClosed) {
            controller.addError('网络连接错误');
          }
          await safeCloseAll();
          return;
        } catch (e) {
          debugPrint('发送消息错误: $e');
          if (!controller.isClosed) {
            controller.addError('发送消息失败: $e');
          }
          await safeCloseAll();
          return;
        }

        if (response.statusCode != 200) {
          try {
            final errorStr = await response.stream.bytesToString();
            final errorData = jsonDecode(errorStr);
            if (errorData is Map && errorData['code'] == 1019) {
              _handleTokenExpired();
              if (!controller.isClosed) {
                controller.addError(errorData['msg'] ?? '登录已过期');
              }
              await safeCloseAll();
            }
          } catch (_) {}
          return;
        }

        String buffer = '';
        
        try {
          await for (final chunk in response.stream.transform(utf8.decoder)) {
            if (finished) break;
            buffer += chunk;
        
            while (buffer.contains('\n')) {
              final index = buffer.indexOf('\n');
              final line = buffer.substring(0, index).trim();
              buffer = buffer.substring(index + 1);
        
              if (line.isEmpty) continue;
              if (!line.startsWith('data:')) continue;
        
              try {
                final data = line.substring(5).trim();
                final sseResponse = SseResponse.fromSseData(data);
        
                if (sseResponse.isMessage) {
                  debugPrint('[群聊SSE] 收到消息: customRole=${sseResponse.data['customRole']}, content=${sseResponse.content}');
                } else if (sseResponse.isDone) {
                  debugPrint('[群聊SSE] 收到完成信号');
                } else if (sseResponse.isError) {
                  debugPrint('[群聊SSE] 收到错误: ${sseResponse.errorMsg}');
                }
        
                if (!controller.isClosed) {
                  controller.add(sseResponse);
                }
        
                if (sseResponse.isDone) {
                  await safeCloseAll();
                  break;
                }
              } catch (e) {
                debugPrint('解析SSE数据错误: $e');
                continue;
              }
            }
          }
        } catch (e) {
          debugPrint('SSE读取异常: $e');
          if (!controller.isClosed) {
            controller.addError('SSE读取异常: $e');
          }
          await safeCloseAll();
        }
      }();

      // 返回组合后的流
      yield* controller.stream;
      return;
    } catch (e) {
      debugPrint('发送消息错误(外层): $e');
      if (!controller.isClosed) {
        controller.addError('发送消息失败: $e');
      }
      await safeCloseAll();
      yield* controller.stream;
      return;
    }
  }
}

