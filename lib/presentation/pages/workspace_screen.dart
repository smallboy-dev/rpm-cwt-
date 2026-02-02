import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/workspace_controller.dart';
import '../widgets/glass_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/milestone_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/models/project_model.dart';
import '../controllers/chat_controller.dart';
import '../controllers/collaboration_controller.dart';
import 'chat_sheet.dart';
import '../../data/models/collaboration_models.dart';
import '../../data/services/collaboration_service.dart';

class WorkspaceScreen extends GetView<WorkspaceController> {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<WorkspaceController>()) {
      Get.put(WorkspaceController());
    }

    final collabController = Get.put(CollaborationController());
    final currentUser = Get.find<AuthRepository>().currentUser.value;

    return Obx(() {
      final p = controller.project.value;
      if (p == null) {
        if (controller.hasError.value) {
          return Scaffold(
            appBar: AppBar(title: const Text('Project Workspace')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Connection Error',
                      style: Get.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.errorMessage.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => controller.refreshWorkspace(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Connection'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Project Workspace')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      final bool isClient = currentUser?.role == UserRole.client;
      final bool isAdmin = currentUser?.role == UserRole.admin;
      final bool canManage = isClient || isAdmin;

      // Initialize collaboration tools only when project is loaded
      collabController.init(p.id);
      Get.find<CollaborationService>().initProject(p.id);

      return DefaultTabController(
        length: 5,
        child: Scaffold(
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text(
              p.title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
                indicatorColor: AppColors.primary,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 3, color: AppColors.primary),
                  borderRadius: BorderRadius.circular(2),
                ),
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: const [
                  Tab(text: 'OVERVIEW'),
                  Tab(text: 'FILES'),
                  Tab(text: 'COLLAB'),
                  Tab(text: 'ACTIVITY'),
                  Tab(text: 'STATS'),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showChatSheet(context, p.id),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.chat_bubble_outline),
          ),
          body: TabBarView(
            children: [
              // Tab 1: Overview
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProjectHeader(p),
                    const SizedBox(height: 40),
                    const Text(
                      'Milestones',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...p.milestones.map(
                      (milestone) => _buildMilestoneTile(milestone, canManage),
                    ),
                  ],
                ),
              ),

              _buildFilesTab(collabController),

              _buildCollabTab(),

              _buildActivityTab(collabController),

              _buildAnalyticsTab(p),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFilesTab(CollaborationController collabController) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              const Text(
                'Project Files',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => collabController.pickAndUploadFile(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('UPLOAD'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (collabController.files.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.folder_open_rounded,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No files uploaded yet',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: collabController.files.length,
              itemBuilder: (context, index) {
                final file = collabController.files[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getFileColor(
                              file.fileType,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getFileIcon(file.fileType),
                            color: _getFileColor(file.fileType),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.fileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${file.fileSize} • ${_formatDate(file.uploadDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildFileAction(
                          icon: Icons.download_rounded,
                          onPressed: () => Get.snackbar(
                            'Downloading',
                            'Saving ${file.fileName} to device...',
                            snackPosition: SnackPosition.BOTTOM,
                            margin: const EdgeInsets.all(16),
                            backgroundColor: Colors.black87,
                            colorText: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'jpg':
      case 'png':
        return Icons.image_rounded;
      case 'zip':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.redAccent;
      case 'doc':
      case 'docx':
        return Colors.blueAccent;
      case 'jpg':
      case 'png':
        return Colors.orangeAccent;
      case 'zip':
        return Colors.amberAccent;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildFileAction({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primary, size: 18),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildActivityTab(CollaborationController collabController) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              _buildSmallAction(
                icon: Icons.refresh_rounded,
                onPressed: () => collabController.refreshActivity(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (collabController.activityFeed.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No activity recorded yet',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: collabController.activityFeed.length,
              itemBuilder: (context, index) {
                final item = collabController.activityFeed[index];
                final bool isLast =
                    index == collabController.activityFeed.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _getActivityColor(
                                item.type,
                              ).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getActivityColor(
                                  item.type,
                                ).withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _getActivityIcon(item.type),
                              size: 14,
                              color: _getActivityColor(item.type),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(item.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.upload:
        return Icons.file_present_rounded;
      case ActivityType.milestone:
        return Icons.flag_rounded;
      case ActivityType.payment:
        return Icons.payments_rounded;
      case ActivityType.chat:
        return Icons.chat_bubble_outline_rounded;
      case ActivityType.info:
      default:
        return Icons.bolt_rounded;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.upload:
        return Colors.blueAccent;
      case ActivityType.milestone:
        return Colors.greenAccent;
      case ActivityType.payment:
        return Colors.amberAccent;
      case ActivityType.chat:
        return Colors.purpleAccent;
      case ActivityType.info:
      default:
        return AppColors.primary;
    }
  }

  Widget _buildSmallAction({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textSecondary, size: 18),
        onPressed: onPressed,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Widget _buildProjectHeader(ProjectModel project) {
    final double completion = project.milestones.isEmpty
        ? 0
        : project.milestones
                  .where((m) => m.status == MilestoneStatus.approved)
                  .length /
              project.milestones.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESCROW BALANCE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₦${project.escrowBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.secondary,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL BUDGET',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₦${project.totalBudget.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TIMELINE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${project.duration} Days', // Assuming duration is in days or descriptive string
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Project Progress',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${(completion * 100).toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: completion,
                minHeight: 14,
                backgroundColor: AppColors.surface,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            if (project.clientId ==
                    Get.find<AuthRepository>().currentUser.value?.id &&
                project.escrowBalance < project.totalBudget) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => controller.fundProject(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_card_rounded, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'FUND ESCROW',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            // Show "REVIEW & COMPLETE" button if all milestones are settled but project is IN PROGRESS
            if (project.clientId ==
                    Get.find<AuthRepository>().currentUser.value?.id &&
                project.status == ProjectStatus.inProgress &&
                project.milestones.isNotEmpty &&
                project.milestones.every(
                  (m) => m.status == MilestoneStatus.settled,
                )) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.greenAccent, Colors.green],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => controller.showReviewDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_rounded, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'REVIEW & COMPLETE',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneTile(MilestoneModel milestone, bool canManage) {
    bool canSubmit = !canManage && milestone.status == MilestoneStatus.pending;
    bool canApprove =
        canManage && milestone.status == MilestoneStatus.submitted;
    bool isDisputed = controller.isMilestoneDisputed(milestone.id);

    Color statusColor;
    if (isDisputed) {
      statusColor = Colors.red;
    } else {
      switch (milestone.status) {
        case MilestoneStatus.approved:
          statusColor = Colors.green;
          break;
        case MilestoneStatus.submitted:
          statusColor = Colors.orange;
          break;
        case MilestoneStatus.pending:
          statusColor = AppColors.primary;
          break;
        default:
          statusColor = AppColors.textSecondary;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Indicator Bar
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              milestone.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          _getStatusPill(milestone.status, isDisputed),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${milestone.percentage.toInt()}%',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '₦${milestone.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (milestone.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          milestone.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (milestone.proofLink != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.link_rounded,
                                size: 16,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Proof: ${milestone.proofLink}',
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!isDisputed && (canSubmit || canApprove)) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (canSubmit) {
                                    _showSubmitDialog(milestone.id);
                                  } else if (canApprove) {
                                    controller.approveMilestone(milestone.id);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canApprove
                                      ? Colors.green
                                      : AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  canSubmit
                                      ? 'SUBMIT PROOF'
                                      : 'APPROVE & RELEASE',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => _showDisputeDialog(milestone.id),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              child: const Text(
                                'DISPUTE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getStatusPill(MilestoneStatus status, bool isDisputed) {
    if (isDisputed) {
      return _buildPill('DISPUTED', Colors.red);
    }
    switch (status) {
      case MilestoneStatus.approved:
        return _buildPill('APPROVED', Colors.green);
      case MilestoneStatus.submitted:
        return _buildPill('SUBMITTED', Colors.orange);
      case MilestoneStatus.pending:
        return _buildPill('PENDING', AppColors.primary);
      default:
        return _buildPill(status.name.toUpperCase(), AppColors.textSecondary);
    }
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showDisputeDialog(String milestoneId) {
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Raise Dispute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please describe the issue with this milestone. An admin will review it.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'e.g. Work is incomplete',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.raiseDispute(milestoneId, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Raise Dispute'),
          ),
        ],
      ),
    );
  }

  void _showSubmitDialog(String milestoneId) {
    final linkController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Submit Work'),
        content: TextField(
          controller: linkController,
          decoration: const InputDecoration(hintText: 'Link to GitHub/Demo'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.submitMilestone(milestoneId, linkController.text);
              Get.back();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showChatSheet(BuildContext context, String projectId) {
    // Initialize controller for this specific project
    final chatController = Get.put(ChatController());
    chatController.initChat(projectId);

    Get.bottomSheet(
      ChatSheet(projectId: projectId),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
  }

  Widget _buildAnalyticsTab(ProjectModel project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Burndown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Visualize remaining work vs. time. Ideally, the trend should move from top-left to bottom-right.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _buildBurndownChart(),
          const SizedBox(height: 32),
          _buildMilestoneStats(project),
        ],
      ),
    );
  }

  Widget _buildBurndownChart() {
    return AspectRatio(
      aspectRatio: 1.5,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        'Day ${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 100),
                    FlSpot(1, 90),
                    FlSpot(2, 75),
                    FlSpot(3, 75),
                    FlSpot(4, 50),
                    FlSpot(5, 40),
                    FlSpot(6, 20),
                  ],
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 4,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                // Ideal Burndown Line
                LineChartBarData(
                  spots: const [FlSpot(0, 100), FlSpot(6, 0)],
                  isCurved: false,
                  color: Colors.grey.withValues(alpha: 0.3),
                  barWidth: 2,
                  dashArray: [5, 5],
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneStats(ProjectModel project) {
    final completed = project.milestones
        .where((m) => m.status == MilestoneStatus.approved)
        .length;
    final total = project.milestones.length;

    return Row(
      children: [
        _buildSmallStatCard(
          'Completed',
          '$completed/$total',
          Icons.check_circle_outline,
          Colors.green,
        ),
        const SizedBox(width: 16),
        _buildSmallStatCard(
          'Remaining',
          '${total - completed}',
          Icons.pending_actions,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: GlassCard(
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollabTab() {
    final collab = Get.find<CollaborationService>();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.amberAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Collaboration Hub',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Draw and share code in real-time with your team.',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shared Whiteboard',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              Row(
                children: [
                  _buildSmallTool(
                    icon: Icons.undo_rounded,
                    onPressed: () =>
                        Get.snackbar('Undo', 'Whiteboard undo not implemented'),
                  ),
                  const SizedBox(width: 8),
                  _buildSmallTool(
                    icon: Icons.delete_outline_rounded,
                    onPressed: () => collab.clearWhiteboard(),
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 350,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  GestureDetector(
                    onPanUpdate: (details) {
                      RenderBox renderBox =
                          Get.context!.findRenderObject() as RenderBox;
                      collab.addPoint(
                        renderBox.globalToLocal(details.localPosition),
                      );
                    },
                    onPanEnd: (details) => collab.endLine(),
                    child: Obx(
                      () => CustomPaint(
                        painter: WhiteboardPainter(
                          points: collab.whiteboardPoints.toList(),
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIVE_CANVAS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Active Code Stream',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.code_rounded,
                        color: Colors.greenAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'main.dart',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _buildSmallAction(
                        icon: Icons.copy_rounded,
                        onPressed: () => Get.snackbar(
                          'Copied',
                          'Code copied to clipboard',
                          backgroundColor: Colors.black87,
                          colorText: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Colors.white10),
                  ),
                  Text(
                    collab.sharedCode.value,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.greenAccent,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSmallTool({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? AppColors.textSecondary, size: 18),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class WhiteboardPainter extends CustomPainter {
  final List<DrawingPoint> points;

  WhiteboardPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != null && points[i + 1].offset != null) {
        canvas.drawLine(
          points[i].offset!,
          points[i + 1].offset!,
          points[i].paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
