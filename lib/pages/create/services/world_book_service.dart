import '../../../net/http_client.dart';
import '../../../widgets/custom_toast.dart';
import 'package:flutter/material.dart';

class WorldBookService {
  final HttpClient _httpClient = HttpClient();

  Future<Map<String, dynamic>> getMyWorldBooks({
    int page = 1,
    int pageSize = 10,
    String? keyword,
    required BuildContext context,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      };

      final response =
          await _httpClient.get('/worldbooks/my', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data['code'] == 0) {
        return response.data['data'];
      }
      CustomToast.show(
        context,
        message: response.data['msg'] ?? '获取世界书列表失败',
        type: ToastType.error,
      );
      throw Exception(response.data['msg'] ?? '获取世界书列表失败');
    } catch (e) {
      CustomToast.show(
        context,
        message: '获取世界书列表失败: $e',
        type: ToastType.error,
      );
      throw Exception('获取世界书列表失败: $e');
    }
  }

  Future<void> deleteWorldBook(String id, BuildContext context) async {
    try {
      final response = await _httpClient.delete('/worldbooks/$id');
      if (response.statusCode != 200 || response.data['code'] != 0) {
        CustomToast.show(
          context,
          message: response.data['msg'] ?? '删除世界书失败',
          type: ToastType.error,
        );
        throw Exception(response.data['msg'] ?? '删除世界书失败');
      }
      CustomToast.show(
        context,
        message: '删除成功',
        type: ToastType.success,
      );
    } catch (e) {
      CustomToast.show(
        context,
        message: '删除世界书失败: $e',
        type: ToastType.error,
      );
      throw Exception('删除世界书失败: $e');
    }
  }

  Future<void> updateWorldBook(
    String id, {
    String? title,
    String? content,
    List<String>? keywords,
    String? status,
    required BuildContext context,
  }) async {
    try {
      final body = {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (keywords != null) 'keywords': keywords,
        if (status != null) 'status': status,
      };

      final response = await _httpClient.put('/worldbooks/$id', data: body);
      if (response.statusCode != 200 || response.data['code'] != 0) {
        CustomToast.show(
          context,
          message: response.data['msg'] ?? '更新世界书失败',
          type: ToastType.error,
        );
        throw Exception(response.data['msg'] ?? '更新世界书失败');
      }
      CustomToast.show(
        context,
        message: '更新成功',
        type: ToastType.success,
      );
    } catch (e) {
      CustomToast.show(
        context,
        message: '更新世界书失败: $e',
        type: ToastType.error,
      );
      throw Exception('更新世界书失败: $e');
    }
  }

  Future<Map<String, dynamic>> createWorldBook({
    required String title,
    required String content,
    required List<String> keywords,
    required String status,
    required BuildContext context,
  }) async {
    try {
      final body = {
        'title': title,
        'content': content,
        'keywords': keywords,
        'status': status,
      };

      final response = await _httpClient.post('/worldbooks', data: body);
      if (response.statusCode == 200 && response.data['code'] == 0) {
        CustomToast.show(
          context,
          message: '创建成功',
          type: ToastType.success,
        );
        return response.data['data'];
      }
      CustomToast.show(
        context,
        message: response.data['msg'] ?? '创建世界书失败',
        type: ToastType.error,
      );
      throw Exception(response.data['msg'] ?? '创建世界书失败');
    } catch (e) {
      CustomToast.show(
        context,
        message: '创建世界书失败: $e',
        type: ToastType.error,
      );
      throw Exception('创建世界书失败: $e');
    }
  }

  Future<Map<String, dynamic>> getPublicWorldBooks({
    int page = 1,
    int pageSize = 10,
    String? keyword,
    required BuildContext context,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      };

      final response = await _httpClient.get(
        '/worldbooks/public',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        return response.data['data'];
      }
      CustomToast.show(
        context,
        message: response.data['msg'] ?? '获取公共世界书列表失败',
        type: ToastType.error,
      );
      throw Exception(response.data['msg'] ?? '获取公共世界书列表失败');
    } catch (e) {
      CustomToast.show(
        context,
        message: '获取公共世界书列表失败: $e',
        type: ToastType.error,
      );
      throw Exception('获取公共世界书列表失败: $e');
    }
  }
}
