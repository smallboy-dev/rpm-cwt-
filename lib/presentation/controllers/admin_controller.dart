// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/project_model.dart';
import '../../data/models/milestone_model.dart';
import '../../data/models/dispute_model.dart';
import '../../data/models/kyc_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/dispute_repository.dart';
import '../../data/repositories/escrow_repository.dart';
import '../../data/repositories/kyc_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../data/repositories/profile_repository.dart';
import 'notification_controller.dart';
import '../../data/models/notification_model.dart';

class AdminController extends GetxController {
  final ProjectRepository _projectRepo = Get.find<ProjectRepository>();
  final DisputeRepository _disputeRepo = Get.find<DisputeRepository>();
  final EscrowRepository _escrowRepo = Get.find<EscrowRepository>();
  final KYCRepository _kycRepo = Get.find<KYCRepository>();
  final AuthRepository _authRepo = Get.find<AuthRepository>();
  final AnalyticsRepository _analyticsRepo = Get.find<AnalyticsRepository>();
  final ProfileRepository _profileRepo = Get.find<ProfileRepository>();

  var disputedProjects = <ProjectModel>[].obs;
  var allProjects = <ProjectModel>[].obs;
  var allUsers = <UserModel>[].obs;
  var kycRequests = <KYCRequestModel>[].obs;
  var isLoading = false.obs;

  var sidebarIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadDisputedProjects();
    loadKYCRequests();
    loadAllUsers();
    loadAllProjects();
  }

  Future<void> loadAllUsers() async {
    isLoading.value = true;
    try {
      allUsers.value = await _profileRepo.getAllProfiles();
    } catch (e) {
      print('Error loading all users: $e');
    }
    isLoading.value = false;
  }

  Future<void> loadAllProjects() async {
    isLoading.value = true;
    try {
      allProjects.value = await _projectRepo.fetchProjects();
    } catch (e) {
      print('Error loading all projects: $e');
    }
    isLoading.value = false;
  }

  void changeSidebarIndex(int index) {
    sidebarIndex.value = index;
  }

  double getTotalRevenue() {
    return _analyticsRepo.getTotalRevenue();
  }

  Future<void> approveKyc(String userId) async {
    try {
      final request = kycRequests.firstWhereOrNull((r) => r.userId == userId);
      if (request == null) {
        Get.snackbar('Error', 'KYC Request not found for this user');
        return;
      }

      await _kycRepo.updateRequestStatus(
        request.id,
        KYCStatus.approved,
        adminNotes: 'Approved by admin',
      );

      final user = allUsers.firstWhereOrNull((u) => u.id == userId);
      if (user != null) {
        final updatedUser = user.copyWith(
          isVerified: true,
          kycStatus: KYCStatus.approved,
        );
        await _profileRepo.updateProfile(updatedUser);
      }

      await loadKYCRequests();
      await loadAllUsers();
      Get.snackbar('Success', 'User KYC approved');
    } catch (e) {
      Get.snackbar('Error', 'Failed to approve KYC: $e');
    }
  }

  Future<void> rejectKyc(String userId) async {
    try {
      final request = kycRequests.firstWhereOrNull((r) => r.userId == userId);
      if (request == null) {
        Get.snackbar('Error', 'KYC Request not found for this user');
        return;
      }

      await _kycRepo.updateRequestStatus(
        request.id,
        KYCStatus.rejected,
        adminNotes: 'Rejected by admin',
      );

      // Sync with profile
      final user = allUsers.firstWhereOrNull((u) => u.id == userId);
      if (user != null) {
        final updatedUser = user.copyWith(
          isVerified: false,
          kycStatus: KYCStatus.rejected,
        );
        await _profileRepo.updateProfile(updatedUser);
      }

      await loadKYCRequests();
      await loadAllUsers();
      Get.snackbar('Success', 'User KYC rejected');
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject KYC: $e');
    }
  }

  Future<void> loadKYCRequests() async {
    kycRequests.value = await _kycRepo.fetchAllRequests();
  }

  Future<void> reviewKYC(
    KYCRequestModel request,
    bool approve,
    String? notes,
  ) async {
    isLoading.value = true;

    request.status = approve ? KYCStatus.approved : KYCStatus.rejected;
    request.adminNotes = notes;

    await _kycRepo.updateRequestStatus(
      request.id,
      approve ? KYCStatus.approved : KYCStatus.rejected,
      adminNotes: notes,
    );

    if (approve) {
      final user = await _authRepo.getUserById(request.userId);
      if (user != null) {
        final updatedUser = user.copyWith(isVerified: true);
        _authRepo.updateUser(updatedUser);
      }
    }

    Get.find<NotificationController>().addNotification(
      title: approve ? 'KYC Approved!' : 'KYC Rejected',
      body: approve ? 'You now have a verified badge.' : 'Reason: $notes',
      type: approve ? NotificationType.success : NotificationType.warning,
    );

    loadKYCRequests();
    isLoading.value = false;
    Get.back();
  }

  void loadDisputedProjects() {
    final allProjects = _projectRepo.getAllProjects();
    disputedProjects.value = allProjects.where((p) {
      return p.milestones.any((m) => _disputeRepo.isMilestoneDisputed(m.id));
    }).toList();
  }

  DisputeModel? getDisputeForMilestone(String milestoneId) {
    return _disputeRepo.getAllDisputes().firstWhereOrNull(
      (d) => d.milestoneId == milestoneId,
    );
  }

  Future<void> resolveDispute({
    required ProjectModel project,
    required String milestoneId,
    required bool awardToDeveloper,
    required String reason,
  }) async {
    isLoading.value = true;

    final dispute = getDisputeForMilestone(milestoneId);
    if (dispute != null) {
      dispute.status = DisputeStatus.resolved;
      _disputeRepo.updateDispute(dispute);
    }

    if (awardToDeveloper) {
      await _escrowRepo.releaseMilestone(project, milestoneId);
      final index = project.milestones.indexWhere((m) => m.id == milestoneId);
      if (index != -1)
        project.milestones[index].status = MilestoneStatus.approved;
    } else {
      final index = project.milestones.indexWhere((m) => m.id == milestoneId);
      if (index != -1)
        project.milestones[index].status = MilestoneStatus.cancelled;
    }

    await _projectRepo.updateProject(project);

    Get.find<NotificationController>().addNotification(
      title: 'Dispute Resolved',
      body:
          'Admin has decided: ${awardToDeveloper ? "Fund Developer" : "Refund Client"}. Reason: $reason',
      type: awardToDeveloper
          ? NotificationType.success
          : NotificationType.warning,
      route: '/workspace',
      arguments: project.toJson(),
    );

    loadDisputedProjects();
    isLoading.value = false;
    Get.back();
    Get.snackbar(
      'Success',
      'Dispute resolved successfully',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
