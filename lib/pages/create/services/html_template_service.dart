import '../../../net/http_client.dart';

class HtmlTemplateService {
  final HttpClient _httpClient = HttpClient();

  /// 通用错误处理：提取后端返回的错误信息
  String _extractErrorMessage(dynamic response, String defaultMsg) {
    try {
      if (response.data != null && response.data is Map) {
        final msg = response.data['msg'];
        if (msg != null && msg.toString().isNotEmpty) {
          return msg.toString();
        }
      }
    } catch (e) {
      // 解析失败，使用默认错误
    }
    return '$defaultMsg (${response.statusCode})';
  }

  /// 获取我的项目列表
  Future<Map<String, dynamic>> getMyProjects({
    int page = 1,
    int size = 10,
    String? search,
    int status = -1, // 1=私有，2=公开，-1=全部
    int taskStatus = -1, // 1=创建成功，2=正在处理，3=已完成，4=任务失败，5=待确认，-1=全部
    int version = -1, // 1=测试版本，2=生产版本，-1=全部
    bool? aiOptimized,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'status': status,
      'task_status': taskStatus,
      'version': version,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (aiOptimized != null) {
      queryParams['ai_optimized'] = aiOptimized;
    }

    final response = await _httpClient.get(
      '/html-beautify/my-projects',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['code'] == 0) {
        return data['data'];
      } else {
        throw Exception(data['msg'] ?? '获取项目列表失败');
      }
    } else {
      throw Exception(_extractErrorMessage(response, '获取项目列表失败'));
    }
  }

  /// 获取公开项目列表
  Future<Map<String, dynamic>> getPublicProjects({
    int page = 1,
    int size = 10,
    String? search,
    int version = -1, // 1=测试版本，2=生产版本，-1=全部
    bool? aiOptimized,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (version != -1) {
      queryParams['version'] = version;
    }

    if (aiOptimized != null) {
      queryParams['ai_optimized'] = aiOptimized.toString();
    }

    final response = await _httpClient.get(
      '/html-beautify/public',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['code'] == 0) {
        return data['data'];
      } else {
        throw Exception(data['msg'] ?? '获取公开项目列表失败');
      }
    } else {
      throw Exception(_extractErrorMessage(response, '获取公开项目列表失败'));
    }
  }

  /// 创建项目
  Future<Map<String, dynamic>> createProject({
    required String projectName,
    required int status, // 1=私有，2=公开
    required String htmlTemplate,
    required String exampleData,
    required String promptInstruction,
    bool needAiAutomation = false,
  }) async {
    final body = {
      'project_name': projectName,
      'status': status,
      'html_template': htmlTemplate,
      'example_data': exampleData,
      'prompt_instruction': promptInstruction,
      'need_ai_automation': needAiAutomation,
    };

    final response = await _httpClient.post(
      '/html-beautify/projects',
      data: body,
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['code'] == 0) {
        return data['data'];
      } else {
        throw Exception(data['msg'] ?? '创建项目失败');
      }
    } else {
      throw Exception(_extractErrorMessage(response, '创建项目失败'));
    }
  }

  /// 获取状态文本
  static String getStatusText(int status) {
    switch (status) {
      case 1:
        return '私有';
      case 2:
        return '公开';
      default:
        return '未知';
    }
  }

  /// 获取任务状态文本
  static String getTaskStatusText(int taskStatus) {
    switch (taskStatus) {
      case 1:
        return '创建成功';
      case 2:
        return '正在处理';
      case 3:
        return '已完成';
      case 4:
        return '任务失败';
      case 5:
        return '待确认';
      default:
        return '未知';
    }
  }

  /// 获取版本文本
  static String getVersionText(int version) {
    switch (version) {
      case 1:
        return '测试版';
      case 2:
        return '生产版';
      default:
        return '未知';
    }
  }

  /// 更新项目状态
  Future<void> updateProjectStatus({
    required int projectId,
    required int status, // 1=私有，2=公开
  }) async {
    final body = {
      'status': status,
    };

    final response = await _httpClient.put(
      '/html-beautify/projects/$projectId/status',
      data: body,
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['code'] == 0) {
        return;
      } else {
        throw Exception(data['msg'] ?? '更新项目状态失败');
      }
    } else {
      throw Exception(_extractErrorMessage(response, '更新项目状态失败'));
    }
  }

  /// 更新项目版本
  Future<void> updateProjectVersion({
    required int projectId,
    required int version, // 1=测试版本，2=生产版本
  }) async {
    final body = {
      'version': version,
    };

    final response = await _httpClient.put(
      '/html-beautify/projects/$projectId/version',
      data: body,
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['code'] == 0) {
        return;
      } else {
        throw Exception(data['msg'] ?? '更新项目版本失败');
      }
    } else {
      throw Exception(_extractErrorMessage(response, '更新项目版本失败'));
    }
  }

  /// 删除项目
  Future<void> deleteProject({
    required int projectId,
  }) async {
    final response = await _httpClient.delete(
      '/html-beautify/projects/$projectId',
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['code'] == 0) {
        return;
      } else {
        throw Exception(data['msg'] ?? '删除项目失败');
      }
    } else {
      throw Exception(_extractErrorMessage(response, '删除项目失败'));
    }
  }

  /// 更新项目内容
  /// 生产版本：可以更新名称、状态、示例数据、提示词指令，但不能更新HTML模板
  /// AI已介入的项目：不允许更新任何内容
  Future<void> updateProject({
    required int projectId,
    required String projectName,
    required int status, // 1=私有，2=公开
    String? htmlTemplate, // 生产版本时可以不传，保持原值
    required String exampleData,
    required String promptInstruction,
  }) async {
    final body = {
      'project_name': projectName,
      'status': status,
      'example_data': exampleData,
      'prompt_instruction': promptInstruction,
    };
    
    // 只有提供了htmlTemplate时才添加到请求体
    if (htmlTemplate != null) {
      body['html_template'] = htmlTemplate;
    }

    final response = await _httpClient.put(
      '/html-beautify/projects/$projectId',
      data: body,
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['code'] == 0) {
        return;
      } else {
        throw Exception(data['msg'] ?? '更新项目失败');
      }
    } else {
      throw Exception(_extractErrorMessage(response, '更新项目失败'));
    }
  }
}

