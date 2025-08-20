import '../../../net/http_client.dart';

class ReportManagementService {
  final HttpClient _httpClient = HttpClient();

  /// 获取举报列表
  Future<Map<String, dynamic>> getReports({
    int status = 0,
    int reportType = 0,
    String? itemId,
    String? reporterId,
    String? keyword,
    String? startTime,
    String? endTime,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'status': status,
        'report_type': reportType,
        'page': page,
        'page_size': pageSize,
      };

      if (itemId != null) queryParameters['item_id'] = itemId;
      if (reporterId != null) queryParameters['reporter_id'] = reporterId;
      if (keyword != null && keyword.isNotEmpty) {
        queryParameters['keyword'] = keyword;
      }
      if (startTime != null) queryParameters['start_time'] = startTime;
      if (endTime != null) queryParameters['end_time'] = endTime;

      final response = await _httpClient.get(
        '/admin/reports',
        queryParameters: queryParameters,
      );

      return response.data;
    } catch (e) {
      throw Exception('获取举报列表失败: $e');
    }
  }

  /// 获取举报详情
  Future<Map<String, dynamic>> getReportDetail(String reportId) async {
    try {
      final response = await _httpClient.get('/admin/reports/$reportId');
      return response.data;
    } catch (e) {
      throw Exception('获取举报详情失败: $e');
    }
  }

  /// 审核举报
  Future<Map<String, dynamic>> reviewReport(
    String reportId,
    bool approved,
    String note,
  ) async {
    try {
      final response = await _httpClient.put(
        '/admin/reports/$reportId/review',
        data: {
          'approved': approved, // 布尔值，不是字符串
          'note': note,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('审核举报失败: $e');
    }
  }

  /// 处理举报
  Future<Map<String, dynamic>> handleReport(
    String reportId,
    int penaltyType,
    String reason,
    int? duration,
  ) async {
    try {
      final Map<String, dynamic> data = {
        'penalty_type': penaltyType,
        'reason': reason,
      };

      if (duration != null) {
        data['duration'] = duration;
      }

      final response = await _httpClient.put(
        '/admin/reports/$reportId/handle',
        data: data,
      );
      return response.data;
    } catch (e) {
      throw Exception('处理举报失败: $e');
    }
  }

  /// 获取处罚列表
  Future<Map<String, dynamic>> getPenalties({
    int status = 0,
    int penaltyType = 0,
    String? itemId,
    String? authorId,
    String? keyword,
    String? startTime,
    String? endTime,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'status': status,
        'penalty_type': penaltyType,
        'page': page,
        'page_size': pageSize,
      };

      if (itemId != null) queryParameters['item_id'] = itemId;
      if (authorId != null) queryParameters['author_id'] = authorId;
      if (keyword != null && keyword.isNotEmpty) {
        queryParameters['keyword'] = keyword;
      }
      if (startTime != null) queryParameters['start_time'] = startTime;
      if (endTime != null) queryParameters['end_time'] = endTime;

      final response = await _httpClient.get(
        '/admin/penalties',
        queryParameters: queryParameters,
      );

      return response.data;
    } catch (e) {
      throw Exception('获取处罚列表失败: $e');
    }
  }

  /// 获取处罚详情
  Future<Map<String, dynamic>> getPenaltyDetail(String penaltyId) async {
    try {
      final response = await _httpClient.get('/admin/penalties/$penaltyId');
      return response.data;
    } catch (e) {
      throw Exception('获取处罚详情失败: $e');
    }
  }

  /// 撤销处罚
  Future<Map<String, dynamic>> revokePenalty(
    String penaltyId,
    String reason,
  ) async {
    try {
      final response = await _httpClient.put(
        '/admin/penalties/$penaltyId/revoke',
        data: {'reason': reason},
      );
      return response.data;
    } catch (e) {
      throw Exception('撤销处罚失败: $e');
    }
  }
}
