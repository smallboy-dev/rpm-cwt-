enum DisputeStatus { open, resolved }

class DisputeModel {
  final String id;
  final String projectId;
  final String milestoneId;
  final String raiserId; // User who raised the dispute
  final String reason;
  DisputeStatus status;
  final DateTime timestamp;

  DisputeModel({
    required this.id,
    required this.projectId,
    required this.milestoneId,
    required this.raiserId,
    required this.reason,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'milestoneId': milestoneId,
    'raiserId': raiserId,
    'reason': reason,
    'status': status.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory DisputeModel.fromJson(Map<String, dynamic> json) => DisputeModel(
    id: json['id'],
    projectId: json['projectId'],
    milestoneId: json['milestoneId'],
    raiserId: json['raiserId'],
    reason: json['reason'],
    status: DisputeStatus.values.firstWhere((e) => e.name == json['status']),
    timestamp: DateTime.parse(json['timestamp']),
  );
}
