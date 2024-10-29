import 'dart:convert';

class ChatHistory {
  final String reportId;
  final String reportName;
  final List<ChatMessage> messages;
  final DateTime lastUpdated;

  ChatHistory({
    required this.reportId,
    required this.reportName,
    required this.messages,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'reportId': reportId,
    'reportName': reportName,
    'messages': messages.map((m) => m.toJson()).toList(),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory ChatHistory.fromJson(Map<String, dynamic> json) => ChatHistory(
    reportId: json['reportId'],
    reportName: json['reportName'],
    messages: (json['messages'] as List).map((m) => ChatMessage.fromJson(m)).toList(),
    lastUpdated: DateTime.parse(json['lastUpdated']),
  );
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}
