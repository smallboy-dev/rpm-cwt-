import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/agency_model.dart';
import '../../data/repositories/agency_repository.dart';
import '../../data/repositories/auth_repository.dart';

class AgencyController extends GetxController {
  final AgencyRepository _agencyRepo = Get.find<AgencyRepository>();
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  final Rxn<AgencyModel> currentAgency = Rxn<AgencyModel>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserAgency();
  }

  Future<void> _loadUserAgency() async {
    final user = _authRepo.currentUser.value;
    if (user != null && user.agencyId != null) {
      isLoading.value = true;
      currentAgency.value = await _agencyRepo.getAgency(user.agencyId!);
      isLoading.value = false;
    }
  }

  Future<void> createAgency(String name) async {
    final user = _authRepo.currentUser.value;
    if (user == null) return;

    isLoading.value = true;
    final agency = await _agencyRepo.createAgency(name, user.id);
    if (agency != null) {
      currentAgency.value = agency;
      await _authRepo.refreshProfile();
    }
    isLoading.value = false;
  }

  Future<void> inviteMember(String email, AgencyRole role) async {
    if (currentAgency.value == null) return;

    Get.snackbar(
      'Coming Soon',
      'Invitation system will be fully implemented soon.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  bool get isOwner {
    final user = _authRepo.currentUser.value;
    return currentAgency.value?.ownerId == user?.id;
  }

  bool hasPermission(AgencyRole requiredRole) {
    final user = _authRepo.currentUser.value;
    if (user == null || currentAgency.value == null) return false;

    if (user.agencyRole == AgencyRole.admin.name) return true;

    return user.agencyRole == requiredRole.name;
  }
}
