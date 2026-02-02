class FileModel {
  final String id;
  final String projectId;
  final String uploaderId;
  final String fileName;
  final String? fileUrl;
  final String fileSize;
  final DateTime uploadDate;
  final String fileType; // e.g., 'pdf', 'img', 'doc'

  FileModel({
    required this.id,
    required this.projectId,
    required this.uploaderId,
    required this.fileName,
    this.fileUrl,
    required this.fileSize,
    required this.uploadDate,
    required this.fileType,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'uploader_id': uploaderId,
    'file_name': fileName,
    'file_url': fileUrl,
    'file_size': fileSize,
    'upload_date': uploadDate.toIso8601String(),
    'file_type': fileType,
  };

  factory FileModel.fromJson(Map<String, dynamic> json) => FileModel(
    id: json['id'] ?? '',
    projectId: json['project_id'] ?? '',
    uploaderId: json['uploader_id'] ?? '',
    fileName: json['file_name'] ?? '',
    fileUrl: json['file_url'],
    fileSize: json['file_size'] ?? '',
    uploadDate: json['upload_date'] != null
        ? DateTime.parse(json['upload_date'])
        : DateTime.now(),
    fileType: json['file_type'] ?? 'unknown',
  );
}

enum ActivityType { upload, milestone, payment, chat, info }

class ActivityItemModel {
  final String id;
  final String projectId;
  final String userId;
  final ActivityType type;
  final String description;
  final DateTime timestamp;

  ActivityItemModel({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.type,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'user_id': userId,
    'type': type.name,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ActivityItemModel.fromJson(Map<String, dynamic> json) =>
      ActivityItemModel(
        id: json['id'] ?? '',
        projectId: json['project_id'] ?? '',
        userId: json['user_id'] ?? '',
        type: ActivityType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ActivityType.info,
        ),
        description: json['description'] ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
      );
}
