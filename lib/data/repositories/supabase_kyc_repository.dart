import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kyc_model.dart';
import 'kyc_repository.dart';

class SupabaseKYCRepository extends KYCRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<void> submitRequest(KYCRequestModel request) async {
    try {
      await _supabase.from('kyc_requests').upsert(request.toJson());
    } catch (e) {
      print('Error submitting KYC: $e');
    }
  }

  @override
  List<KYCRequestModel> getAllRequests() {
    return [];
  }

  Future<List<KYCRequestModel>> fetchAllRequests() async {
    try {
      final response = await _supabase.from('kyc_requests').select();
      return (response as List)
          .map((json) => KYCRequestModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching KYC requests: $e');
      return [];
    }
  }

  @override
  KYCRequestModel? getRequestForUser(String userId) {
    return null;
  }

  Future<KYCRequestModel?> fetchRequestForUser(String userId) async {
    try {
      final data = await _supabase
          .from('kyc_requests')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null) return KYCRequestModel.fromJson(data);
      return null;
    } catch (e) {
      print('Error fetching KYC for user: $e');
      return null;
    }
  }

  @override
  Future<void> updateRequest(KYCRequestModel request) async {
    try {
      await _supabase
          .from('kyc_requests')
          .update(request.toJson())
          .eq('id', request.id);
    } catch (e) {
      print('Error updating KYC: $e');
    }
  }

  @override
  Future<void> updateRequestStatus(
    String id,
    KYCStatus status, {
    String? adminNotes,
  }) async {
    try {
      final updateData = {'status': status.name};
      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
      }

      await _supabase.from('kyc_requests').update(updateData).eq('id', id);
    } catch (e) {
      print('Error updating KYC status: $e');
    }
  }
}
