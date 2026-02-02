enum MilestoneStatus {
  pending,
  submitted,
  approved,
  rejected,
  cancelled,
  settled,
}

class MilestoneModel {
  final String id;
  final String title;
  final String description;
  final double percentage;
  final double amount;
  MilestoneStatus status;
  String? proofLink;
  String? feedback;

  MilestoneModel({
    required this.id,
    required this.title,
    required this.description,
    required this.percentage,
    required this.amount,
    this.status = MilestoneStatus.pending,
    this.proofLink,
    this.feedback,
  });

  bool get isApproved => status == MilestoneStatus.approved;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'percentage': percentage,
    'amount': amount,
    'status': status.name,
    'proof_link': proofLink,
    'proof_url': proofLink, // For Supabase compatibility
    'feedback': feedback,
  };

  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    try {
      return MilestoneModel(
        id: (json['id'] ?? '').toString(),
        title: json['title'] ?? 'Untitled Milestone',
        description: json['description'] ?? '',
        percentage:
            double.tryParse((json['percentage'] ?? 0.0).toString()) ?? 0.0,
        amount: double.tryParse((json['amount'] ?? 0.0).toString()) ?? 0.0,
        status: MilestoneStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => MilestoneStatus.pending,
        ),
        proofLink: json['proof_url'] ?? json['proof_link'] ?? json['proofLink'],
        feedback: json['feedback'] ?? json['milestone_feedback'],
      );
    } catch (e) {
      print('ERROR parsing MilestoneModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}
