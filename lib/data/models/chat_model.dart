enum ChatMessageType { text, code, image, call }

class ChatMessage {
  final String id;
  final String projectId;
  final String senderId;
  final String message;
  final DateTime timestamp;
  final ChatMessageType type;
  final String? attachmentUrl;

  ChatMessage({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.message,
    required this.timestamp,
    this.type = ChatMessageType.text,
    this.attachmentUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'sender_id': senderId,
    'content': message,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'attachment_url': attachmentUrl,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: (json['id'] ?? '').toString(),
    projectId: (json['project_id'] ?? '').toString(),
    senderId: (json['sender_id'] ?? '').toString(),
    message: json['content'] ?? '',
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'])
        : DateTime.now(),
    type: ChatMessageType.values.firstWhere(
      (e) => e.name == (json['type'] ?? 'text'),
      orElse: () => ChatMessageType.text,
    ),
    attachmentUrl: json['attachment_url'],
  );
}
