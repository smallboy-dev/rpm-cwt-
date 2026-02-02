import 'package:get/get.dart';
import '../providers/mock_database.dart';

enum PayoutStatus { pending, completed, failed }

class PayoutRequest {
  final String id;
  final String userId;
  final double amount;
  final String bankName;
  final String accountNumber;
  final DateTime timestamp;
  PayoutStatus status;

  PayoutRequest({
    required this.id,
    required this.userId,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.timestamp,
    this.status = PayoutStatus.pending,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'amount': amount,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
  };

  factory PayoutRequest.fromJson(Map<String, dynamic> json) => PayoutRequest(
    id: json['id'],
    userId: json['userId'],
    amount: json['amount'],
    bankName: json['bankName'],
    accountNumber: json['accountNumber'],
    timestamp: DateTime.parse(json['timestamp']),
    status: PayoutStatus.values.byName(json['status']),
  );
}

class PayoutRepository extends GetxService {
  final MockDatabase _db = MockDatabase();
  static const String keyPayouts = 'payout_requests';

  Future<void> requestPayout(PayoutRequest request) async {
    List<PayoutRequest> payouts = _db.getList(
      keyPayouts,
      PayoutRequest.fromJson,
    );
    payouts.add(request);
    _db.saveList(keyPayouts, payouts, (p) => p.toJson());

    // Simulate processing
    await Future.delayed(const Duration(seconds: 2));
    completePayout(request.id);
  }

  void completePayout(String id) {
    List<PayoutRequest> payouts = _db.getList(
      keyPayouts,
      PayoutRequest.fromJson,
    );
    int index = payouts.indexWhere((p) => p.id == id);
    if (index != -1) {
      payouts[index].status = PayoutStatus.completed;
      _db.saveList(keyPayouts, payouts, (p) => p.toJson());
    }
  }

  List<PayoutRequest> getPayoutsForUser(String userId) {
    return _db
        .getList(keyPayouts, PayoutRequest.fromJson)
        .where((p) => p.userId == userId)
        .toList();
  }
}
