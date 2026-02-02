enum NotificationType { info, success, warning, message, bid, milestone }

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;
  final String? route;
  final Map<String, dynamic>? arguments;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.route,
    this.arguments,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'body': body,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'route': route,
    'arguments': arguments,
  };

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'],
        userId: json['userId'] ?? '',
        title: json['title'],
        body: json['body'],
        type: NotificationType.values.firstWhere((e) => e.name == json['type']),
        timestamp: DateTime.parse(json['timestamp']),
        isRead: json['isRead'],
        route: json['route'],
        arguments: json['arguments'] != null
            ? Map<String, dynamic>.from(json['arguments'])
            : null,
      );
}
