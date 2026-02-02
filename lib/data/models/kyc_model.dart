enum KYCStatus { pending, approved, rejected }

class KYCRequestModel {
  final String id;
  final String userId;
  final String idNumber;
  final String documentUrl;
  final String portfolioUrl;
  KYCStatus status;
  final DateTime submittedAt;
  String? adminNotes;

  KYCRequestModel({
    required this.id,
    required this.userId,
    required this.idNumber,
    required this.documentUrl,
    required this.portfolioUrl,
    this.status = KYCStatus.pending,
    required this.submittedAt,
    this.adminNotes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'idNumber': idNumber,
    'documentUrl': documentUrl,
    'portfolioUrl': portfolioUrl,
    'status': status.name,
    'submittedAt': submittedAt.toIso8601String(),
    'adminNotes': adminNotes,
  };

  factory KYCRequestModel.fromJson(Map<String, dynamic> json) =>
      KYCRequestModel(
        id: json['id'],
        userId: json['userId'],
        idNumber: json['idNumber'],
        documentUrl: json['documentUrl'],
        portfolioUrl: json['portfolioUrl'],
        status: KYCStatus.values.firstWhere((e) => e.name == json['status']),
        submittedAt: DateTime.parse(json['submittedAt']),
        adminNotes: json['adminNotes'],
      );
}
