import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'profile_repository.dart';

class SupabaseProfileRepository extends ProfileRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<List<UserModel>> getAllProfiles() async {
    try {
      final response = await _supabase.from('profiles').select().order('name');
      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      print('DEBUG: Supabase getAllProfiles Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    try {
      await _supabase.from('profiles').update(user.toJson()).eq('id', user.id);
    } catch (e) {
      print('DEBUG: Supabase updateProfile Error: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel?> getProfileById(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .single();
      return UserModel.fromJson(response);
    } catch (e) {
      print('DEBUG: Supabase getProfileById Error: $e');
      return null;
    }
  }
}
