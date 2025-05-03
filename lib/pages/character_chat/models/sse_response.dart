import 'dart:convert';

class SseResponse {
  final String id;
  final String event;
  final int timestamp;
  final Map<String, dynamic> data;

  SseResponse({
    required this.id,
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

  String? get content => isMessage ? data['content'] : null;
  String? get errorMsg => isError ? data['error_msg'] : null;
  int? get tokens => isTokens ? data['tokens'] : null;
  String get status => data['status'];
  int? get messageId => isMessage ? data['message_id'] : null;
}
