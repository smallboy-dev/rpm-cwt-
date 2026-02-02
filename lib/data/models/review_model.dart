class ReviewModel {
  final String id;
  final String projectId;
  final String reviewerId;
  final String revieweeId;
  final double rating;
  final String comment;
  final double qualityOfWork;
  final double communication;
  final double adherenceToTimeline;
  final DateTime timestamp;

  ReviewModel({
    required this.id,
    required this.projectId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    required this.comment,
    this.qualityOfWork = 5.0,
    this.communication = 5.0,
    this.adherenceToTimeline = 5.0,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'reviewerId': reviewerId,
    'revieweeId': revieweeId,
    'rating': rating,
    'comment': comment,
    'qualityOfWork': qualityOfWork,
    'communication': communication,
    'adherenceToTimeline': adherenceToTimeline,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id: json['id'],
    projectId: json['projectId'],
    reviewerId: json['reviewerId'],
    revieweeId: json['revieweeId'],
    rating: (json['rating'] as num).toDouble(),
    comment: json['comment'],
    qualityOfWork: (json['qualityOfWork'] as num).toDouble(),
    communication: (json['communication'] as num).toDouble(),
    adherenceToTimeline: (json['adherenceToTimeline'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp']),
  );
}
