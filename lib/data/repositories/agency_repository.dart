// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agency_model.dart';

class AgencyRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<AgencyModel?> getAgency(String agencyId) async {
    try {
      final response = await _supabase
          .from('agencies')
          .select('*, agency_members(*)')
          .eq('id', agencyId)
          .maybeSingle();

      if (response != null) {
        return AgencyModel(
          id: response['id'],
          name: response['name'],
          ownerId: response['owner_id'],
          members: (response['agency_members'] as List)
              .map(
                (m) => TeamMemberModel(
                  userId: m['user_id'],
                  userName: m['user_name'] ?? 'Unknown Member',
                  role: AgencyRole.values.firstWhere(
                    (e) => e.name == m['role'],
                    orElse: () => AgencyRole.member,
                  ),
                  joinedAt: DateTime.parse(m['created_at']),
                ),
              )
              .toList(),
          walletBalance: (response['wallet_balance'] as num).toDouble(),
          createdAt: DateTime.parse(response['created_at']),
        );
      }
      return null;
    } catch (e) {
      print('Error fetching agency: $e');
      return null;
    }
  }

  Future<AgencyModel?> createAgency(String name, String ownerId) async {
    try {
      final response = await _supabase
          .from('agencies')
          .insert({'name': name, 'owner_id': ownerId, 'wallet_balance': 0.0})
          .select()
          .maybeSingle();

      if (response != null) {
        await addMember(response['id'], ownerId, ownerId, AgencyRole.admin);
        return getAgency(response['id']);
      }
      return null;
    } catch (e) {
      print('Error creating agency: $e');
      return null;
    }
  }

  Future<void> addMember(
    String agencyId,
    String userId,
    String userName,
    AgencyRole role,
  ) async {
    try {
      await _supabase.from('agency_members').insert({
        'agency_id': agencyId,
        'user_id': userId,
        'user_name': userName,
        'role': role.name,
      });

      await _supabase
          .from('profiles')
          .update({'agency_id': agencyId, 'agency_role': role.name})
          .eq('id', userId);
    } catch (e) {
      print('Error adding member: $e');
    }
  }

  Future<void> updateWalletBalance(String agencyId, double amount) async {
    try {
      final agency = await getAgency(agencyId);
      if (agency != null) {
        double newBalance = agency.walletBalance + amount;

        // Safety check: finite and capped for numeric(12,2)
        if (!newBalance.isFinite) return;

        const double maxBalance = 9999999999.99;
        if (newBalance > maxBalance) {
          newBalance = maxBalance;
        } else if (newBalance < -maxBalance) {
          newBalance = -maxBalance;
        }

        newBalance = double.parse(newBalance.toStringAsFixed(2));

        await _supabase
            .from('agencies')
            .update({'wallet_balance': newBalance})
            .eq('id', agencyId);
      }
    } catch (e) {
      print('Error updating agency wallet: $e');
    }
  }
}
