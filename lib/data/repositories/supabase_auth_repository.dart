import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class SupabaseAuthRepository extends AuthRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _fetchAndSetProfile(session.user.id);
    }
  }

  Future<void> _fetchAndSetProfile(String userId) async {
    final user = await getUserById(userId);
    if (user != null) {
      currentUser.value = user;
    }
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .single();
      return UserModel.fromJson(data);
    } catch (e) {
      print('Error fetching user by ID ($id): $e');
      return null;
    }
  }

  @override
  Future<bool> signUp(UserModel user, String password) async {
    try {
      // 1. Sign up with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: user.email,
        password: password,
      );

      if (response.user != null) {
        final profileData = user.toJson();
        profileData['id'] = response.user!.id; 

        await _supabase.from('profiles').insert(profileData);

        await _fetchAndSetProfile(response.user!.id);
        return true;
      }
      return false;
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _fetchAndSetProfile(response.user!.id);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  @override
  void logout() async {
    await _supabase.auth.signOut();
    currentUser.value = null;
  }

  @override
  void updateUser(UserModel user) async {
    try {
      await _supabase.from('profiles').update(user.toJson()).eq('id', user.id);
      currentUser.value = user;
    } catch (e) {
      print('Update error: $e');
    }
  }

  @override
  void updateWalletBalance(double amount) async {
    if (currentUser.value != null) {
      double newBalance = currentUser.value!.walletBalance + amount;

      // Safety check: ensure balance is finite and capped at database precision (numeric(12,2))
      if (!newBalance.isFinite) {
        print('Error: Wallet balance calculation resulted in non-finite value');
        return;
      }

      const double maxBalance = 9999999999.99;
      if (newBalance > maxBalance) {
        newBalance = maxBalance;
      } else if (newBalance < -maxBalance) {
        newBalance = -maxBalance;
      }

      newBalance = double.parse(newBalance.toStringAsFixed(2));

      final updatedUser = currentUser.value!.copyWith(
        walletBalance: newBalance,
      );

      try {
        await _supabase
            .from('profiles')
            .update({'wallet_balance': newBalance})
            .eq('id', currentUser.value!.id);

        currentUser.value = updatedUser;
        print('Wallet balance updated in Supabase: $newBalance');
      } catch (e) {
        print('Error updating wallet balance: $e');
        Get.snackbar(
          'Error',
          'Failed to sync wallet balance: $e',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    }
  }
}
