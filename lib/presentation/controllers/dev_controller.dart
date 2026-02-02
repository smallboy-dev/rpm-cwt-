import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/project_model.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/bid_repository.dart';
import '../../data/models/bid_model.dart';
import '../../data/services/matching_service.dart';
import '../../data/repositories/supabase_project_repository.dart';

class DevController extends GetxController {
  final ProjectRepository _projectRepo = Get.find<ProjectRepository>();
  final AuthRepository _authRepo = Get.find<AuthRepository>();
  final BidRepository _bidRepo = Get.find<BidRepository>();
  final MatchingService _matchingService = Get.find<MatchingService>();

  var marketplaceProjects = <ProjectModel>[].obs;
  var filteredMarketplace = <ProjectModel>[].obs;
  var recommendedProjects = <ProjectModel>[].obs;
  var myProjects = <ProjectModel>[].obs;
  var isLoading = false.obs;
  var projectIdsWithBids = <String>[].obs;

  var searchQuery = ''.obs;
  var selectedCategory = 'All'.obs;

  final categories = ['All', 'Mobile', 'Web', 'Design', 'Backend', 'AI'];

  var totalEarned = 0.0.obs;
  var pendingEscrow = 0.0.obs;
  var projectsCompleted = 0.obs;

  var selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();

    _projectRepo.getProjectStream().listen((allProjects) {
      _updateProjectLists(allProjects);
    });

    loadMarketplace();
    loadMyProjects();
    _calculateStats();

    debounce(searchQuery, (_) => filterMarketplace(), time: 300.milliseconds);
    ever(selectedCategory, (_) => filterMarketplace());
  }

  void _updateProjectLists(List<ProjectModel> all) {
    marketplaceProjects.value = all
        .where(
          (p) =>
              p.status == ProjectStatus.open &&
              p.developerId == null &&
              !projectIdsWithBids.contains(p.id),
        )
        .toList();

    final user = _authRepo.currentUser.value;
    if (user != null) {
      recommendedProjects.value = _matchingService.getRecommendations(
        user,
        all,
      );
    }

    myProjects.value = all
        .where((p) => p.developerId == _authRepo.currentUser.value?.id)
        .toList();

    filterMarketplace();
    _calculateStats();
  }

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }

  Future<void> loadMarketplace() async {
    isLoading.value = true;
    if (_projectRepo is SupabaseProjectRepository) {
      await _projectRepo.fetchProjects();
    }
    projectIdsWithBids.value = await _bidRepo.fetchProjectIdsWithBids();

    final all = _projectRepo.getAllProjects();
    marketplaceProjects.value = all
        .where(
          (p) =>
              p.status == ProjectStatus.open &&
              p.developerId == null &&
              !projectIdsWithBids.contains(p.id),
        )
        .toList();

    final user = _authRepo.currentUser.value;
    if (user != null) {
      recommendedProjects.value = _matchingService.getRecommendations(
        user,
        all,
      );
    }

    filterMarketplace();
    isLoading.value = false;
  }

  void filterMarketplace() {
    filteredMarketplace.value = marketplaceProjects.where((p) {
      final matchesSearch =
          p.title.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          p.description.toLowerCase().contains(searchQuery.value.toLowerCase());

      final matchesCategory =
          selectedCategory.value == 'All' ||
          p.category == selectedCategory.value;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> loadMyProjects() async {
    isLoading.value = true;
    if (_projectRepo is SupabaseProjectRepository) {
      await _projectRepo.fetchProjects();
    }

    myProjects.value = _projectRepo
        .getAllProjects()
        .where((p) => p.developerId == _authRepo.currentUser.value?.id)
        .toList();
    _calculateStats();
    isLoading.value = false;
  }

  void _calculateStats() {
    totalEarned.value = myProjects
        .where((p) => p.status == ProjectStatus.completed)
        .fold(0.0, (sum, p) => sum + p.totalBudget);
    pendingEscrow.value = myProjects
        .where((p) => p.status == ProjectStatus.inProgress)
        .fold(0.0, (sum, p) => sum + p.escrowBalance);
    projectsCompleted.value = myProjects
        .where((p) => p.status == ProjectStatus.completed)
        .length;
  }

  List<double> getEarningsData() {
    // Mock monthly earnings for the last 6 months
    return [450.0, 1200.0, 800.0, 2100.0, 1500.0, 2800.0];
  }

  Future<void> submitBid({
    required String projectId,
    required double amount,
    required String time,
    required String coverLetter,
  }) async {
    isLoading.value = true;
    final currentUser = _authRepo.currentUser.value;
    if (currentUser == null) return;

    final bid = BidModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: projectId,
      developerId: currentUser.id,
      developerName: currentUser.name,
      amount: amount,
      proposedTime: time,
      coverLetter: coverLetter,
      status: BidStatus.pending,
      timestamp: DateTime.now(),
    );

    _bidRepo.submitBid(bid);

    // Update local state to hide project instantly
    projectIdsWithBids.add(projectId);
    _updateProjectLists(_projectRepo.getAllProjects());

    isLoading.value = false;

    Get.find<NotificationController>().addNotification(
      title: 'Bid Proposed',
      body: 'Your bid of ₦${bid.amount} was sent for "$projectId".',
      type: NotificationType.bid,
    );

    Get.back();
    Get.snackbar(
      'Success',
      'Bid submitted successfully! Client will review it.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
