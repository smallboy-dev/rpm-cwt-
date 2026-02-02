import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bid_model.dart';
import '../models/project_model.dart';
import 'bid_repository.dart';

class SupabaseBidRepository extends BidRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  List<BidModel> getBidsForProject(String projectId) {
    return [];
  }

  Future<List<BidModel>> fetchBidsForProject(String projectId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select()
          .eq('project_id', projectId);

      return (response as List).map((json) => BidModel.fromJson(json)).toList();
    } catch (e) {
      print('DEBUG: Supabase fetchBidsForProject Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> submitBid(BidModel bid) async {
    try {
      final data = bid.toJson();
      if (data['id'] != null && data['id'].length < 32) {
        data.remove('id');
      }
      await _supabase.from('bids').insert(data);
    } catch (e) {
      print('DEBUG: Supabase submitBid Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> acceptBid(String bidId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('project_id')
          .eq('id', bidId)
          .single();

      final projectId = response['project_id'];

      // 1. Accept this bid
      await _supabase
          .from('bids')
          .update({'status': BidStatus.accepted.name})
          .eq('id', bidId);

      // 2. Reject others for same project
      await _supabase
          .from('bids')
          .update({'status': BidStatus.rejected.name})
          .eq('project_id', projectId)
          .neq('id', bidId);

      // 3. Update project status and developer_id
      final bidData = await _supabase
          .from('bids')
          .select('developer_id')
          .eq('id', bidId)
          .single();

      await _supabase
          .from('projects')
          .update({
            'status': ProjectStatus.inProgress.name,
            'developer_id': bidData['developer_id'],
          })
          .eq('id', projectId);
    } catch (e) {
      print('DEBUG: Supabase acceptBid Error: $e');
      rethrow;
    }
  }

  Future<List<String>> fetchProjectIdsWithBids() async {
    try {
      final response = await _supabase.from('bids').select('project_id');
      return (response as List)
          .map((item) => item['project_id'].toString())
          .toSet()
          .toList();
    } catch (e) {
      print('Error fetching project IDs with bids: $e');
      return [];
    }
  }
}
