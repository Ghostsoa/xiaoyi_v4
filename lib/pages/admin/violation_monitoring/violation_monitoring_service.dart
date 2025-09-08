import '../../../net/http_client.dart';

class ViolationMonitoringService {
  final HttpClient _httpClient = HttpClient();

  /// 获取违规监测记录列表
  Future<Map<String, dynamic>> getViolations({
    int page = 1,
    int pageSize = 20,
    int? userId,
    int? relatedCardId,
    String? cardType,
    String? riskLevel,
    int? victimId,
    String? relatedCardName,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'page_size': pageSize,
      };

      if (userId != null) queryParameters['user_id'] = userId;
      if (relatedCardId != null) queryParameters['related_card_id'] = relatedCardId;
      if (cardType != null && cardType.isNotEmpty) {
        queryParameters['card_type'] = cardType;
      }
      if (riskLevel != null && riskLevel.isNotEmpty) {
        queryParameters['risk_level'] = riskLevel;
      }
      if (victimId != null) queryParameters['victim_id'] = victimId;
      if (relatedCardName != null && relatedCardName.isNotEmpty) {
        queryParameters['related_card_name'] = relatedCardName;
      }

      final response = await _httpClient.get(
        '/admin/violations',
        queryParameters: queryParameters,
      );

      return response.data;
    } catch (e) {
      throw Exception('获取违规监测记录失败: $e');
    }
  }

  /// 获取单个违规监测记录详情
  Future<Map<String, dynamic>> getViolationDetail(int id) async {
    try {
      final response = await _httpClient.get('/admin/violations/$id');
      return response.data;
    } catch (e) {
      throw Exception('获取违规监测记录详情失败: $e');
    }
  }

  /// 更新风控级别
  Future<Map<String, dynamic>> updateRiskLevel(
    int id,
    String riskLevel,
    String reason,
  ) async {
    try {
      final response = await _httpClient.put(
        '/admin/violations/$id/risk-level',
        data: {
          'risk_level': riskLevel,
          'reason': reason,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('更新风控级别失败: $e');
    }
  }

  /// 删除违规监测记录
  Future<Map<String, dynamic>> deleteViolation(int id) async {
    try {
      final response = await _httpClient.delete('/admin/violations/$id');
      return response.data;
    } catch (e) {
      throw Exception('删除违规监测记录失败: $e');
    }
  }
}
