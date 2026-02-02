enum TransactionType { payment, refund, platformFee, escrowFunding }

class FinancialTransactionModel {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final String? projectId;
  final String? milestoneId;
  final DateTime timestamp;
  final String description;

  FinancialTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    this.projectId,
    this.milestoneId,
    required this.timestamp,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'amount': amount,
    'type': type.name,
    'projectId': projectId,
    'milestoneId': milestoneId,
    'timestamp': timestamp.toIso8601String(),
    'description': description,
  };

  factory FinancialTransactionModel.fromJson(Map<String, dynamic> json) =>
      FinancialTransactionModel(
        id: json['id'],
        userId: json['userId'],
        amount: json['amount'].toDouble(),
        type: TransactionType.values.firstWhere((e) => e.name == json['type']),
        projectId: json['projectId'],
        milestoneId: json['milestoneId'],
        timestamp: DateTime.parse(json['timestamp']),
        description: json['description'],
      );
}
