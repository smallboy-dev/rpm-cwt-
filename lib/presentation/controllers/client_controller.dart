import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/project_model.dart';
import '../../data/models/milestone_model.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/bid_repository.dart';
import '../../data/repositories/escrow_repository.dart';
import '../controllers/agency_controller.dart';
import '../../data/services/wallet_service.dart';
import '../../data/models/bid_model.dart';
import '../../data/repositories/supabase_project_repository.dart';
import '../../data/repositories/supabase_bid_repository.dart';

class ClientController extends GetxController {
  final ProjectRepository _projectRepo = Get.find<ProjectRepository>();
  final AuthRepository _authRepo = Get.find<AuthRepository>();
  final BidRepository _bidRepo = Get.find<BidRepository>();
  final EscrowRepository _escrowRepo = Get.find<EscrowRepository>();
  final AgencyController _agencyController = Get.find<AgencyController>();
  final WalletService _walletService = Get.find<WalletService>();

  final titleController = TextEditingController();
  final descController = TextEditingController();
  final skillsController = TextEditingController();
  final budgetController = TextEditingController();
  final timelineController = TextEditingController();

  var projects = <ProjectModel>[].obs;
  var projectBids = <String, List<BidModel>>{}.obs;
  var isLoadingBids = <String, bool>{}.obs;
  var isLoading = false.obs;
  var selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();

    _projectRepo.getProjectStream().listen((allProjects) {
      projects.value = allProjects
          .where((p) => p.clientId == _authRepo.currentUser.value?.id)
          .toList();
    });

    loadProjects();
  }

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }

  Future<void> fetchBids(String projectId) async {
    isLoadingBids[projectId] = true;
    try {
      if (_bidRepo is SupabaseBidRepository) {
        final bids = await _bidRepo.fetchBidsForProject(projectId);
        projectBids[projectId] = bids;
      } else {
        projectBids[projectId] = _bidRepo.getBidsForProject(projectId);
      }
    } catch (e) {
      print('Error fetching bids for project $projectId: $e');
    } finally {
      isLoadingBids[projectId] = false;
    }
  }

  Future<void> loadProjects() async {
    isLoading.value = true;
    if (_projectRepo is SupabaseProjectRepository) {
      await _projectRepo.fetchProjects();
    }

    final all = _projectRepo.getAllProjects();
    projects.value = all
        .where((p) => p.clientId == _authRepo.currentUser.value?.id)
        .toList();
    isLoading.value = false;
  }

  Future<void> createProject() async {
    if (budgetController.text.isEmpty) return;

    double budget = double.tryParse(budgetController.text) ?? 500.0;
    if (budget < 100) {
      Get.snackbar(
        'Error',
        'Minimum budget is \$100',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isLoading.value = true;

    List<MilestoneModel> milestones = _projectRepo.generateAutoMilestones(
      budget,
    );

    ProjectModel project = ProjectModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clientId: _authRepo.currentUser.value!.id,
      title: titleController.text,
      description: descController.text,
      requiredSkills: skillsController.text.split(','),
      timeline: timelineController.text,
      totalBudget: budget,
      milestones: milestones,
      createdAt: DateTime.now(),
    );

    await _projectRepo.createProject(project);
    loadProjects();
    isLoading.value = false;

    Get.find<NotificationController>().addNotification(
      title: 'Project Posted',
      body: 'Your project "${project.title}" is now live.',
      type: NotificationType.success,
      route: '/workspace',
      arguments: project.toJson(),
    );

    Get.back();
    Get.snackbar(
      'Success',
      'Project "${project.title}" posted successfully!',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> deleteProject(ProjectModel project) async {
    if (project.status != ProjectStatus.open) {
      Get.snackbar(
        'Action Denied',
        'Only "OPEN" projects can be deleted. Projects in progress or completed cannot be removed.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }

    Get.defaultDialog(
      title: 'Delete Project',
      middleText:
          'Are you sure you want to delete "${project.title}"? This action cannot be undone.',
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        onPressed: () async {
          Get.back(); 
          try {
            isLoading.value = true;
            await _projectRepo.deleteProject(project.id);

            projects.removeWhere((p) => p.id == project.id);
            projects.refresh();

            Get.snackbar(
              'Deleted',
              'Project deleted successfully.',
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              colorText: Colors.red,
            );
          } catch (e) {
            Get.snackbar('Error', 'Failed to delete project: $e');
          } finally {
            isLoading.value = false;
          }
        },
        child: const Text('Delete'),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
      ),
    );
  }

  Future<void> acceptBid(ProjectModel project, BidModel bid) async {
    final agency = _agencyController.currentAgency.value;

    if (agency != null || _walletService.isConnected.value) {
      Get.dialog(
        AlertDialog(
          title: const Text('Fund Project Escrow'),
          content: Text(
            'The total amount to fund is ₦${bid.amount}. Choose funding source:',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                _processAcceptBid(project, bid, fundingType: 'personal');
              },
              child: const Text('Personal Wallet'),
            ),
            if (agency != null)
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  _processAcceptBid(project, bid, fundingType: 'agency');
                },
                child: const Text('Agency Wallet'),
              ),
            if (_walletService.isConnected.value)
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  _processAcceptBid(project, bid, fundingType: 'onchain');
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text('On-Chain (NGN)'),
              ),
          ],
        ),
      );
    } else {
      _processAcceptBid(project, bid, fundingType: 'personal');
    }
  }

  Future<void> _processAcceptBid(
    ProjectModel project,
    BidModel bid, {
    required String fundingType,
  }) async {
    isLoading.value = true;

    // 1. Fund Escrow first
    bool success = false;
    if (fundingType == 'onchain') {
      success = await _escrowRepo.fundOnChain(project);
    } else if (fundingType == 'agency') {
      final agency = _agencyController.currentAgency.value;
      if (agency != null) {
        success = await _escrowRepo.fundFromAgency(project, agency.id);
      }
    } else {
      success = await _escrowRepo.fundEscrow(project);
    }

    if (!success) {
      isLoading.value = false;
      Get.snackbar(
        'Funding Failed',
        'Insufficient balance in selected wallet.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    // 2. Mark bid as accepted
    _bidRepo.acceptBid(bid.id);

    // 3. Update project details based on bid
    final updatedProject = project.copyWith(
      developerId: bid.developerId,
      totalBudget: bid.amount,
      milestones: _projectRepo.generateAutoMilestones(bid.amount),
      status: ProjectStatus.inProgress,
    );

    await _projectRepo.updateProject(updatedProject);

    Get.find<NotificationController>().addNotification(
      title: 'Bid Accepted!',
      body: 'Your bid for "${project.title}" was accepted. Start working!',
      type: NotificationType.success,
      route: '/workspace',
      arguments: updatedProject.toJson(),
    );

    loadProjects();

    isLoading.value = false;
    Get.back();
    Get.snackbar(
      'Success',
      'Project funded and moved to in-progress!',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  List<BidModel> getBids(String projectId) {
    return _bidRepo.getBidsForProject(projectId);
  }
}
