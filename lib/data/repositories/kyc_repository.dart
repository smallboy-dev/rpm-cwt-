import 'package:get/get.dart';
import '../models/kyc_model.dart';

class KYCRepository extends GetxService {
  void submitRequest(KYCRequestModel request) {}

  List<KYCRequestModel> getAllRequests() {
    return [];
  }

  Future<List<KYCRequestModel>> fetchAllRequests() async {
    return [];
  }

  KYCRequestModel? getRequestForUser(String userId) {
    return null;
  }

  Future<void> updateRequestStatus(
    String id,
    KYCStatus status, {
    String? adminNotes,
  }) async {}
}
