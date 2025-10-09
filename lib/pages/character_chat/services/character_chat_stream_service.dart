import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../../../dao/user_dao.dart';
import '../../../net/http_client.dart';
import '../../../pages/login/login_page.dart';
import '../models/sse_response.dart';
import '../../../services/network_monitor_service.dart';

class CharacterChatStreamService {
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

  /// 发送对话消息并获取流式响应
  /// 增加高可用轮询：在发起SSE后并行每3秒轮询一次 /polling，
  /// 哪个先返回数据先用哪个；若同时到达优先SSE；一旦完成则断开两者。
  /// [sessionId] 会话ID
  /// [input] 用户输入的消息内容
  Stream<SseResponse> sendMessage(int sessionId, String input) async* {
    final controller = StreamController<SseResponse>();
    Timer? pollingTimer;
    http.Client? sseClient;
    bool finished = false; // 是否已完成（收到SSE done或采用了轮询结果）
    bool sseDisconnected = false; // SSE是否已断开

    Future<void> safeCloseAll() async {
      if (finished) return;
      finished = true;
      try {
        pollingTimer?.cancel();
      } catch (_) {}
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
      debugPrint('[角色对话] 使用节点: $currentEndpoint');

      // 获取应用版本号
      final appVersion = await _getAppVersion();

      // 预先准备SSE请求
      final chatUri = Uri.parse('$baseUrl/sessions/character/$sessionId/chat');
      final sseRequest = http.Request('POST', chatUri);
      sseRequest.headers.addAll({
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'text/event-stream',
        'Authorization': 'Bearer $token',
        'X-App-Version': appVersion,
      });
      sseRequest.body = jsonEncode({'input': input});

      // 启动轮询（每3秒）
      final pollingUri = Uri.parse('$baseUrl/polling');
      pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        if (finished || sseDisconnected || controller.isClosed) {
          timer.cancel();
          if (sseDisconnected) {
            debugPrint('【轮询停止】SSE已断开，停止轮询');
          } else if (controller.isClosed) {
            debugPrint('【轮询停止】页面已销毁，停止轮询');
          }
          return;
        }
        try {
          final pollingResp = await http
              .post(
                pollingUri,
                headers: {
                  'Content-Type': 'application/json; charset=utf-8',
                  'Accept': 'application/json',
                  'Authorization': 'Bearer $token',
                  'X-App-Version': appVersion,
                },
                body: jsonEncode({
                  'session_id': sessionId,
                  'session_type': 'character',
                }),
              )
              .timeout(const Duration(seconds: 10));

          Map<String, dynamic> json;
          try {
            json = jsonDecode(pollingResp.body);
          } catch (e) {
            debugPrint('轮询解析失败: $e');
            return;
          }

          // 处理token失效
          if (json['code'] == 1019) {
            _handleTokenExpired();
            if (!finished && !controller.isClosed) {
              controller.addError(json['msg'] ?? '登录已过期');
            }
            await safeCloseAll();
            return;
          }

          if (json['code'] != 0) {
            // 非成功，不中断，等待下次轮询
            return;
          }

          final data = json['data'];
          if (data is! Map) return;

          final status = data['status'];
          if (status == 'pending') {
            // 等待中，忽略
            return;
          }

          if (status == 'error') {
            // 延迟到下一个事件循环，让可能已到达的SSE done优先执行
            Future.delayed(Duration.zero, () async {
              if (!finished && !controller.isClosed) {
                final now = DateTime.now().millisecondsSinceEpoch;
                controller.add(
                  SseResponse(
                    id: null,
                    event: 'error',
                    timestamp: now,
                    data: {
                      'content': data['message'] ?? '未知错误',
                      'message': data['message'] ?? '未知错误',
                      'success': data['success'] ?? false,
                      'status': 'error',
                    },
                  ),
                );
                await safeCloseAll();
              }
            });
            return;
          }

          // completed
          if (status == 'completed') {
            // 延迟到下一个事件循环，让可能已到达的SSE done优先执行
            Future.delayed(Duration.zero, () async {
              if (!finished && !controller.isClosed) {
                debugPrint('【轮询接管】轮询获取到完成结果，msgId: ${data['msgId']}, content: ${data['content']}');
                
                final now = DateTime.now().millisecondsSinceEpoch;
                final msgData = <String, dynamic>{
                  'msgId': data['msgId'],
                  'role': data['role'] ?? 'assistant',
                  'content': data['content'] ?? '',
                  'status': data['status'] ?? 'completed',
                  'enhanced': data['enhanced'] ?? false,
                };

                controller.add(
                  SseResponse(
                    id: null,
                    event: 'message',
                    timestamp: now,
                    data: msgData,
                  ),
                );

                controller.add(
                  SseResponse(
                    id: null,
                    event: 'done',
                    timestamp: now,
                    data: {
                      'status': 'done',
                      'msgId': data['msgId'],
                    },
                  ),
                );

                debugPrint('【轮询接管】轮询结果已发送到UI，会话完成');
                await safeCloseAll();
              }
            });
            return;
          }
        } catch (e) {
          // 轮询失败不影响主流程
          debugPrint('轮询请求失败: $e');
        }
      });

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
          sseDisconnected = true;
          // SSE超时，不直接报错，等待轮询补偿
          return;
        } on SocketException catch (e) {
          debugPrint('网络连接错误: $e');
          sseDisconnected = true;
          // SSE网络错误，不直接报错，等待轮询补偿
          return;
        } catch (e) {
          debugPrint('发送消息错误: $e');
          sseDisconnected = true;
          // 其他错误，等待轮询补偿
          return;
        }

        // response在成功路径上非空

        if (response.statusCode != 200) {
          // 非200时，若是token失效则立即处理；否则交由轮询兜底
          sseDisconnected = true;
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
                  debugPrint('【SSE正常返回】收到消息: ${sseResponse.content}');
                } else if (sseResponse.isDone) {
                  debugPrint('【SSE正常返回】收到完成信号，msgId: ${sseResponse.messageId}');
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
          // SSE流异常时，标记断开并等待轮询
          debugPrint('SSE读取异常: $e');
          sseDisconnected = true;
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

  /// 重新生成AI回复
  /// 增加高可用轮询：在发起SSE后并行每3秒轮询一次 /polling，
  /// 哪个先返回数据先用哪个；若同时到达优先SSE；一旦完成则断开两者。
  /// [sessionId] 会话ID
  /// [msgId] 需要重新生成的消息ID
  Stream<SseResponse> regenerateMessage(int sessionId, String msgId) async* {
    final controller = StreamController<SseResponse>();
    Timer? pollingTimer;
    http.Client? sseClient;
    bool finished = false; // 是否已完成（收到SSE done或采用了轮询结果）
    bool sseDisconnected = false; // SSE是否已断开

    Future<void> safeCloseAll() async {
      if (finished) return;
      finished = true;
      try {
        pollingTimer?.cancel();
      } catch (_) {}
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
      debugPrint('[角色对话重新生成] 使用节点: $currentEndpoint');

      // 获取应用版本号
      final appVersion = await _getAppVersion();

      // 预先准备SSE请求
      final regenerateUri = Uri.parse('$baseUrl/sessions/character/$sessionId/regenerate');
      final sseRequest = http.Request('POST', regenerateUri);
      sseRequest.headers.addAll({
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'text/event-stream',
        'Authorization': 'Bearer $token',
        'X-App-Version': appVersion,
      });
      sseRequest.body = jsonEncode({'msgId': msgId});

      // 启动轮询（每3秒）
      final pollingUri = Uri.parse('$baseUrl/polling');
      pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        if (finished || sseDisconnected || controller.isClosed) {
          timer.cancel();
          if (sseDisconnected) {
            debugPrint('【轮询停止】SSE已断开，停止轮询');
          } else if (controller.isClosed) {
            debugPrint('【轮询停止】页面已销毁，停止轮询');
          }
          return;
        }
        try {
          final pollingResp = await http
              .post(
                pollingUri,
                headers: {
                  'Content-Type': 'application/json; charset=utf-8',
                  'Accept': 'application/json',
                  'Authorization': 'Bearer $token',
                  'X-App-Version': appVersion,
                },
                body: jsonEncode({
                  'session_id': sessionId,
                  'session_type': 'character',
                }),
              )
              .timeout(const Duration(seconds: 10));

          Map<String, dynamic> json;
          try {
            json = jsonDecode(pollingResp.body);
          } catch (e) {
            debugPrint('轮询解析失败: $e');
            return;
          }

          // 处理token失效
          if (json['code'] == 1019) {
            _handleTokenExpired();
            if (!finished && !controller.isClosed) {
              controller.addError(json['msg'] ?? '登录已过期');
            }
            await safeCloseAll();
            return;
          }

          if (json['code'] != 0) {
            // 非成功，不中断，等待下次轮询
            return;
          }

          final data = json['data'];
          if (data is! Map) return;

          final status = data['status'];
          if (status == 'pending') {
            // 等待中，忽略
            return;
          }

          if (status == 'error') {
            // 延迟到下一个事件循环，让可能已到达的SSE done优先执行
            Future.delayed(Duration.zero, () async {
              if (!finished && !controller.isClosed) {
                final now = DateTime.now().millisecondsSinceEpoch;
                controller.add(
                  SseResponse(
                    id: null,
                    event: 'error',
                    timestamp: now,
                    data: {
                      'content': data['message'] ?? '未知错误',
                      'message': data['message'] ?? '未知错误',
                      'success': data['success'] ?? false,
                      'status': 'error',
                    },
                  ),
                );
                await safeCloseAll();
              }
            });
            return;
          }

          // completed
          if (status == 'completed') {
            // 延迟到下一个事件循环，让可能已到达的SSE done优先执行
            Future.delayed(Duration.zero, () async {
              if (!finished && !controller.isClosed) {
                debugPrint('【轮询接管】重新生成轮询获取到完成结果，msgId: ${data['msgId']}, content: ${data['content']}');
                
                final now = DateTime.now().millisecondsSinceEpoch;
                final msgData = <String, dynamic>{
                  'msgId': data['msgId'],
                  'role': data['role'] ?? 'assistant',
                  'content': data['content'] ?? '',
                  'status': data['status'] ?? 'completed',
                  'enhanced': data['enhanced'] ?? false,
                };

                controller.add(
                  SseResponse(
                    id: null,
                    event: 'message',
                    timestamp: now,
                    data: msgData,
                  ),
                );

                controller.add(
                  SseResponse(
                    id: null,
                    event: 'done',
                    timestamp: now,
                    data: {
                      'status': 'done',
                      'msgId': data['msgId'],
                    },
                  ),
                );

                debugPrint('【轮询接管】重新生成轮询结果已发送到UI，会话完成');
                await safeCloseAll();
              }
            });
            return;
          }
        } catch (e) {
          // 轮询失败不影响主流程
          debugPrint('轮询请求失败: $e');
        }
      });

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
          sseDisconnected = true;
          // SSE超时，不直接报错，等待轮询补偿
          return;
        } on SocketException catch (e) {
          debugPrint('网络连接错误: $e');
          sseDisconnected = true;
          // SSE网络错误，不直接报错，等待轮询补偿
          return;
        } catch (e) {
          debugPrint('发送消息错误: $e');
          sseDisconnected = true;
          // 其他错误，等待轮询补偿
          return;
        }

        // response在成功路径上非空

        if (response.statusCode != 200) {
          // 非200时，若是token失效则立即处理；否则交由轮询兜底
          sseDisconnected = true;
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
                  debugPrint('【SSE正常返回】重新生成收到消息: ${sseResponse.content}');
                } else if (sseResponse.isDone) {
                  debugPrint('【SSE正常返回】重新生成收到完成信号，msgId: ${sseResponse.messageId}');
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
          // SSE流异常时，标记断开并等待轮询
          debugPrint('SSE读取异常: $e');
          sseDisconnected = true;
        }
      }();

      // 返回组合后的流
      yield* controller.stream;
      return;
    } catch (e) {
      debugPrint('重新生成消息错误(外层): $e');
      if (!controller.isClosed) {
        controller.addError('重新生成失败: $e');
      }
      await safeCloseAll();
      yield* controller.stream;
      return;
    }
  }
}
