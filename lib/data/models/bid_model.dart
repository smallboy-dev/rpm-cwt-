enum BidStatus { pending, accepted, rejected }

class BidModel {
  final String id;
  final String projectId;
  final String developerId;
  final String developerName;
  final double amount;
  final String proposedTime; // e.g., "2 weeks"
  final String coverLetter;
  final BidStatus status;
  final DateTime timestamp;

  BidModel({
    required this.id,
    required this.projectId,
    required this.developerId,
    required this.developerName,
    required this.amount,
    required this.proposedTime,
    required this.coverLetter,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'developer_id': developerId,
    'developer_name': developerName,
    'amount': amount,
    'proposed_time': proposedTime,
    'cover_letter': coverLetter,
    'status': status.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BidModel.fromJson(Map<String, dynamic> json) => BidModel(
    id: (json['id'] ?? '').toString(),
    projectId: (json['project_id'] ?? '').toString(),
    developerId: (json['developer_id'] ?? '').toString(),
    developerName: json['developer_name'] ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    proposedTime: json['proposed_time'] ?? '',
    coverLetter: json['cover_letter'] ?? '',
    status: BidStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => BidStatus.pending,
    ),
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'])
        : DateTime.now(),
  );

  BidModel copyWith({
    String? id,
    String? projectId,
    String? developerId,
    String? developerName,
    double? amount,
    String? proposedTime,
    String? coverLetter,
    BidStatus? status,
    DateTime? timestamp,
  }) {
    return BidModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      developerId: developerId ?? this.developerId,
      developerName: developerName ?? this.developerName,
      amount: amount ?? this.amount,
      proposedTime: proposedTime ?? this.proposedTime,
      coverLetter: coverLetter ?? this.coverLetter,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
