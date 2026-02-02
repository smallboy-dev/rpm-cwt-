import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/project_model.dart';
import '../../data/models/milestone_model.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/escrow_repository.dart';
import '../../data/repositories/dispute_repository.dart';
import '../../data/models/dispute_model.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/models/collaboration_models.dart';
import '../../data/repositories/collaboration_repository.dart';

class WorkspaceController extends GetxController {
  final ProjectRepository _projectRepo = Get.find<ProjectRepository>();
  final EscrowRepository _escrowRepo = Get.find<EscrowRepository>();
  final DisputeRepository _disputeRepo = Get.find<DisputeRepository>();
  final AuthRepository _authRepo = Get.find<AuthRepository>();
  final ReviewRepository _reviewRepo = Get.find<ReviewRepository>();
  final CollaborationRepository _collabRepo =
      Get.find<CollaborationRepository>();

  final Rxn<ProjectModel> project = Rxn<ProjectModel>();
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  StreamSubscription? _milestoneSubscription;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is ProjectModel) {
      project.value = Get.arguments as ProjectModel;
      refreshWorkspace();
    }
  }

  Future<void> refreshWorkspace() async {
    hasError.value = false;
    isLoading.value = true;
    try {
      await fetchLatestProject();
      _setupMilestoneStream();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Connection Error: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  void _setupMilestoneStream() {
    if (project.value == null) return;
    _milestoneSubscription?.cancel();
    _milestoneSubscription = _projectRepo
        .getMilestonesStream(project.value!.id)
        .listen(
          (updatedMilestones) {
            if (project.value != null) {
              project.value = project.value!.copyWith(
                milestones: updatedMilestones,
              );
              project.refresh();
            }
          },
          onError: (e) {
            print('Milestone Stream Error: $e');
            hasError.value = true;
            errorMessage.value = 'Connection lost. Retrying...';
          },
        );
  }

  Future<void> fetchLatestProject() async {
    if (project.value == null) return;
    try {
      final projects = await _projectRepo.fetchProjects();
      final latest = projects.firstWhereOrNull(
        (p) => p.id == project.value!.id,
      );
      if (latest != null) {
        project.value = latest;
        project.refresh();
      }
    } catch (e) {
      print('Error fetching latest project: $e');
      hasError.value = true;
      errorMessage.value =
          'Failed to fetch project details. Please check your connection.';
      rethrow;
    }
  }

  Future<void> fundProject() async {
    if (project.value == null) return;
    isLoading.value = true;
    bool success = await _escrowRepo.fundEscrow(project.value!);
    if (success) {
      project.refresh();
      Get.snackbar(
        'Success',
        'Escrow funded successfully!',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } else {
      Get.snackbar(
        'Error',
        'Insufficient wallet balance',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
    isLoading.value = false;
  }

  Future<void> submitMilestone(String milestoneId, String proofLink) async {
    if (project.value == null) return;
    int index = project.value!.milestones.indexWhere(
      (m) => m.id == milestoneId,
    );
    if (index == -1) return;

    project.value!.milestones[index].status = MilestoneStatus.submitted;
    project.value!.milestones[index].proofLink = proofLink;

    await _projectRepo.updateMilestoneStatus(
      milestoneId,
      MilestoneStatus.submitted,
      proofUrl: proofLink,
    );
    project.refresh();

    // Log Activity
    try {
      await _collabRepo.logActivity(
        ActivityItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          projectId: project.value!.id,
          userId: _authRepo.currentUser.value?.id ?? 'unknown',
          type: ActivityType.milestone,
          description:
              'submitted proof for milestone: ${project.value!.milestones[index].title}',
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Error logging activity: $e');
    }

    Get.find<NotificationController>().addNotification(
      title: 'Milestone Submitted',
      body: 'Milestone "${project.value!.milestones[index].title}" submitted.',
      type: NotificationType.milestone,
      route: '/workspace',
      arguments: project.value?.toJson(),
    );

    Get.snackbar(
      'Success',
      'Milestone submitted for approval',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> approveMilestone(String milestoneId) async {
    if (project.value == null) return;
    int index = project.value!.milestones.indexWhere(
      (m) => m.id == milestoneId,
    );
    if (index == -1) return;

    project.value!.milestones[index].status = MilestoneStatus.approved;

    bool released = await _escrowRepo.releaseMilestone(
      project.value!,
      milestoneId,
    );

    if (released) {
      if (project.value!.milestones.every(
        (m) => m.status == MilestoneStatus.settled,
      )) {
        _showRatingDialog();
      }
    } else {
      Get.snackbar('Error', 'Failed to release funds. Check escrow balance.');
      return;
    }

    await _projectRepo.updateMilestoneStatus(
      milestoneId,
      MilestoneStatus.approved,
    );
    project.refresh();

    // Log Activity
    try {
      await _collabRepo.logActivity(
        ActivityItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          projectId: project.value!.id,
          userId: _authRepo.currentUser.value?.id ?? 'unknown',
          type: ActivityType.milestone,
          description:
              'approved milestone: ${project.value!.milestones[index].title}',
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Error logging activity: $e');
    }

    Get.find<NotificationController>().addNotification(
      title: 'Funds Released!',
      body: 'Funds for "${project.value!.milestones[index].title}" released.',
      type: NotificationType.success,
      route: '/workspace',
      arguments: project.value?.toJson(),
    );

    Get.snackbar('Success', 'Milestone approved! Funds released.');
  }

  void _showRatingDialog() {
    final commentController = TextEditingController();
    double quality = 5.0;
    double communication = 5.0;
    double timeline = 5.0;

    Get.dialog(
      AlertDialog(
        title: const Text('Rate Developer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your experience working with the developer?'),
              const SizedBox(height: 16),
              _buildStarRating('Quality of Work', (v) => quality = v),
              _buildStarRating('Communication', (v) => communication = v),
              _buildStarRating('Timeline Adherence', (v) => timeline = v),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Testimonial/Comment',
                  hintText: 'Share your feedback...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              skipReview();
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              final avg = (quality + communication + timeline) / 3;
              _submitReview(
                avg,
                commentController.text,
                quality,
                communication,
                timeline,
              );
            },
            child: const Text('Submit Review'),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(String label, Function(double) onRated) {
    var currentRating = 5.obs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Obx(
          () => Row(
            children: List.generate(5, (index) {
              return IconButton(
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  index < currentRating.value ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  currentRating.value = index + 1;
                  onRated((index + 1).toDouble());
                },
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _submitReview(
    double avgRating,
    String comment,
    double quality,
    double communication,
    double timeline,
  ) async {
    if (project.value == null) return;
    final devId = project.value!.developerId;
    if (devId == null) return;

    final review = ReviewModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: project.value!.id,
      reviewerId: _authRepo.currentUser.value!.id,
      revieweeId: devId,
      rating: avgRating,
      comment: comment,
      qualityOfWork: quality,
      communication: communication,
      adherenceToTimeline: timeline,
      timestamp: DateTime.now(),
    );

    await _reviewRepo.addReview(review);

    project.value!.developerRating = avgRating;
    project.value!.status = ProjectStatus.completed;
    await _projectRepo.updateProject(project.value!);

    project.refresh();

    Get.until(
      (route) =>
          Get.currentRoute == '/client-dashboard' ||
          Get.currentRoute == '/dev-dashboard',
    );
    Get.snackbar('Success', 'Detailed review submitted, thank you!');
  }

  void showReviewDialog() => _showRatingDialog();

  void skipReview() async {
    if (project.value == null) return;
    project.value!.status = ProjectStatus.completed;
    await _projectRepo.updateProject(project.value!);
    project.refresh();

    Get.until(
      (route) =>
          Get.currentRoute == '/client-dashboard' ||
          Get.currentRoute == '/dev-dashboard',
    );
    Get.snackbar('Project Completed', 'Project marked as closed.');
  }

  void raiseDispute(String milestoneId, String reason) {
    if (project.value == null) return;
    if (reason.isEmpty) {
      Get.snackbar('Error', 'Please provide a reason for the dispute');
      return;
    }

    final dispute = DisputeModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: project.value!.id,
      milestoneId: milestoneId,
      raiserId: _authRepo.currentUser.value!.id,
      reason: reason,
      status: DisputeStatus.open,
      timestamp: DateTime.now(),
    );

    _disputeRepo.raiseDispute(dispute);

    project.refresh();

    Get.back(); // Close dialog
    Get.snackbar('Dispute Raised', 'Admin will review this case shortly.');
  }

  bool isMilestoneDisputed(String milestoneId) {
    return _disputeRepo.isMilestoneDisputed(milestoneId);
  }

  @override
  void onClose() {
    _milestoneSubscription?.cancel();
    super.onClose();
  }
}
