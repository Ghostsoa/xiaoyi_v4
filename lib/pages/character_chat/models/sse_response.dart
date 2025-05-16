import 'dart:convert';

class SseResponse {
  final String? id;
  final String event;
  final int timestamp;
  final Map<String, dynamic> data;

  SseResponse({
    this.id,
    required this.event,
    required this.timestamp,
    required this.data,
  });

  factory SseResponse.fromJson(Map<String, dynamic> json) {
    return SseResponse(
      id: json['id'],
      event: json['event'],
      timestamp: json['timestamp'],
      data: json['data'],
    );
  }

  factory SseResponse.fromSseData(String data) {
    final json = jsonDecode(data);
    return SseResponse.fromJson(json);
  }

  bool get isMessage => event == 'message';
  bool get isError => event == 'error';
  bool get isTokens => event == 'tokens';
  bool get isDone => event == 'done';

  String? get content => data['content'];
  String? get errorMsg =>
      isError ? (data['error'] ?? data['message'] ?? data['error_msg']) : null;
  int? get tokens => isTokens ? data['tokens'] : null;
  String? get status => data['status'];

  String? get messageId => data['msgId'];

  Map<String, dynamic>? get statusBar => data['statusBar'];

  bool? get enhanced =>
      data.containsKey('enhanced') ? data['enhanced'] as bool : null;
}
