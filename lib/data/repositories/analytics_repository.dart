import 'package:get/get.dart';
import '../models/transaction_model.dart';
import '../providers/mock_database.dart';

class AnalyticsRepository extends GetxService {
  final MockDatabase _db = MockDatabase();
  final String _key = 'transactions';

  void recordTransaction(FinancialTransactionModel transaction) {
    List<FinancialTransactionModel> all = getAllTransactions();
    all.add(transaction);
    _db.saveList(_key, all, (t) => t.toJson());
  }

  List<FinancialTransactionModel> getAllTransactions() {
    return _db.getList(_key, FinancialTransactionModel.fromJson);
  }

  List<FinancialTransactionModel> getTransactionsForUser(String userId) {
    return getAllTransactions().where((t) => t.userId == userId).toList();
  }

  double getTotalRevenue() {
    return getAllTransactions()
        .where((t) => t.type == TransactionType.platformFee)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getSpendingByCategory(String userId) {
    // In a real app, this would join with ProjectRepo
    // For mock, we'll return some static patterns
    return {'Mobile': 1200.0, 'Web': 800.0, 'Design': 450.0, 'Backend': 300.0};
  }
}
