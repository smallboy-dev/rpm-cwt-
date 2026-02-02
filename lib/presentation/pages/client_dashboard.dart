// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/client_controller.dart';
import '../widgets/glass_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/project_model.dart';
import '../../data/models/milestone_model.dart';
import '../../data/models/bid_model.dart';
import '../../data/models/user_model.dart';
import '../controllers/theme_controller.dart';
import '../controllers/notification_controller.dart';
import '../../data/services/wallet_service.dart';
import '../../data/services/payment_service.dart';
import '../widgets/top_up_dialog.dart';
import '../widgets/invoice_dialog.dart';
import '../widgets/floating_navbar.dart';
import '../../data/services/security_service.dart';
import '../../data/services/matching_service.dart';

class ClientDashboard extends GetView<ClientController> {
  const ClientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ClientController>()) {
      Get.put(ClientController());
    }

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final titles = ['My Projects', 'Discovery', 'Profile'];
          return Text(titles[controller.selectedIndex.value]);
        }),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Obx(() {
            final unreadCount =
                Get.find<NotificationController>().unreadCount.value;
            return IconButton(
              icon: Badge.count(
                count: unreadCount,
                isLabelVisible: unreadCount > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => Get.toNamed('/notifications'),
            );
          }),
          Obx(() {
            final isDark = Get.find<ThemeController>().isDarkMode.value;
            return IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => Get.find<ThemeController>().toggleTheme(),
            );
          }),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Get.find<AuthRepository>().logout();
              Get.offAllNamed('/welcome');
            },
          ),
        ],
      ),
      floatingActionButton: Obx(
        () => controller.selectedIndex.value == 0
            ? FloatingActionButton.extended(
                onPressed: () => _showCreateProjectSheet(context),
                label: const Text('Post Project'),
                icon: const Icon(Icons.add),
                backgroundColor: AppColors.primary,
              )
            : const SizedBox.shrink(),
      ),
      body: Stack(
        children: [
          Obx(
            () => IndexedStack(
              index: controller.selectedIndex.value,
              children: [
                _buildMyProjects(context),
                _buildDiscovery(),
                _buildProfile(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Obx(
              () => FloatingNavbar(
                currentIndex: controller.selectedIndex.value,
                onTap: controller.changeTabIndex,
                items: [
                  FloatingNavbarItem(
                    icon: Icons.assignment_outlined,
                    activeIcon: Icons.assignment,
                    label: 'Projects',
                  ),
                  FloatingNavbarItem(
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore,
                    label: 'Explore',
                  ),
                  FloatingNavbarItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProjects(BuildContext context) {
    return Column(
      children: [
        _buildWalletBar(),
        Expanded(
          child: Obx(() {
            final active = controller.projects
                .where((p) => p.status != ProjectStatus.completed)
                .toList();
            final completed = controller.projects
                .where((p) => p.status == ProjectStatus.completed)
                .toList();

            if (active.isEmpty && completed.isEmpty) {
              return const Center(
                child: Text('No projects yet. Post your first one!'),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (active.isNotEmpty) ...[
                  const Text(
                    'Active Projects',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...active.map((p) => _buildProjectCardItem(context, p)),
                ],
                if (completed.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Text(
                    'Completed & Closed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...completed.map((p) => _buildProjectCardItem(context, p)),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildProjectCardItem(BuildContext context, ProjectModel project) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: Get.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (project.status == ProjectStatus.completed
                                ? Colors.green
                                : project.status == ProjectStatus.inProgress
                                ? Colors.orange
                                : AppColors.primary)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          (project.status == ProjectStatus.completed
                                  ? Colors.green
                                  : project.status == ProjectStatus.inProgress
                                  ? Colors.orange
                                  : AppColors.primary)
                              .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    project.status.name.toUpperCase(),
                    style: TextStyle(
                      color: project.status == ProjectStatus.completed
                          ? Colors.green
                          : project.status == ProjectStatus.inProgress
                          ? Colors.orange
                          : AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '₦${project.totalBudget}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      Get.toNamed('/workspace', arguments: project),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  child: Text(
                    project.status == ProjectStatus.completed
                        ? 'HISTORY'
                        : (project.milestones.isNotEmpty &&
                              project.milestones.every(
                                (m) => m.status == MilestoneStatus.settled,
                              ))
                        ? 'REVIEW & CLOSE'
                        : 'Workspace',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (project.milestones.any(
                  (m) => m.status == MilestoneStatus.settled,
                ))
                  TextButton(
                    onPressed: () => _showInvoicesSheet(context, project),
                    child: const Text('Invoices'),
                  ),
                if (project.status == ProjectStatus.open)
                  TextButton(
                    onPressed: () => _showBidsSheet(context, project),
                    child: const Text('View Bids'),
                  ),
                if (project.status == ProjectStatus.open) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => controller.deleteProject(project),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete Project',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscovery() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Marketplace Intelligence', style: Get.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Live insights into the Nigerian developer ecosystem.',
            style: TextStyle(
              color: Get.isDarkMode
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          _buildMarketInsightCard(
            'Trending Skills',
            'High demand for specialized talent.',
            [
              {'label': 'Flutter', 'trend': '+12%', 'color': Colors.blue},
              {'label': 'Solidity', 'trend': '+45%', 'color': Colors.purple},
              {'label': 'Python', 'trend': '+8%', 'color': Colors.green},
            ],
          ),
          const SizedBox(height: 16),
          _buildMarketInsightCard(
            'Weekly Volume',
            'Project count by category.',
            [
              {'label': 'Mobile', 'trend': '24 Jobs', 'color': Colors.orange},
              {'label': 'Web', 'trend': '18 Jobs', 'color': Colors.lightBlue},
              {'label': 'AI/ML', 'trend': '12 Jobs', 'color': Colors.teal},
            ],
          ),
          const SizedBox(height: 24),
          _buildAIProjectionCard(),
        ],
      ),
    );
  }

  Widget _buildMarketInsightCard(
    String title,
    String subtitle,
    List<Map<String, dynamic>> items,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Get.isDarkMode
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(radius: 4, backgroundColor: item['color']),
                  const SizedBox(width: 8),
                  Text(item['label']),
                  const Spacer(),
                  Text(
                    item['trend'],
                    style: TextStyle(
                      color: item['trend'].startsWith('+')
                          ? Colors.green
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIProjectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.query_stats, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'AI Market Projection',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Based on current trends, mobile commerce and smart contract security will dominate the local market next quarter. We recommend focusing on verified talent in these areas.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final user = Get.find<AuthRepository>().currentUser.value;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              user?.name[0] ?? '?',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Anonymous',
            style: Get.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user?.email ?? '',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _buildWeb3Card(),
          const SizedBox(height: 24),
          _buildSecurityCard(),
          const SizedBox(height: 16),
          GlassCard(
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: ListTile(
              leading: const Icon(
                Icons.analytics_outlined,
                color: AppColors.secondary,
              ),
              title: const Text('Advanced Analytics'),
              subtitle: const Text('Spending trends & velocity'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed('/client-analytics'),
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeb3Card() {
    final walletService = Get.find<WalletService>();
    return Obx(() {
      final isConnected = walletService.isConnected.value;
      return GlassCard(
        child: ListTile(
          leading: Icon(
            isConnected ? Icons.account_balance_wallet : Icons.link_off,
            color: isConnected ? Colors.green : Colors.orange,
          ),
          title: Text(
            isConnected ? 'On-Chain Wallet (NGN)' : 'Connect Web3 Wallet',
          ),
          subtitle: Text(
            isConnected
                ? 'Balance: ₦${walletService.nairaBalance.value}'
                : 'Enable decentralized Naira escrows',
          ),
          trailing: isConnected
              ? const Icon(Icons.check_circle, color: Colors.green)
              : ElevatedButton(
                  onPressed: () => walletService.connectWallet(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Connect'),
                ),
        ),
      );
    });
  }

  Widget _buildWalletBar() {
    return Obx(() {
      final user = Get.find<AuthRepository>().currentUser.value;
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.2),
              AppColors.secondary.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: AppColors.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Wallet',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '₦${user?.walletBalance ?? 0.0}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _handleTopUp(),
              child: const Text('TOP UP'),
            ),
          ],
        ),
      );
    });
  }

  void _handleTopUp() {
    final paymentService = Get.find<PaymentService>();
    final authRepo = Get.find<AuthRepository>();
    final user = authRepo.currentUser.value;

    if (user == null) return;

    Get.dialog(
      TopUpDialog(
        onAmountSelected: (amount) async {
          bool success = await paymentService.initiatePaystackPayment(
            amount: amount,
            email: user.email,
          );

          if (success) {
            authRepo.updateWalletBalance(amount);
          }
        },
      ),
    );
  }

  void _showCreateProjectSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Post New Project', style: Get.textTheme.headlineSmall),
              const SizedBox(height: 24),
              TextField(
                controller: controller.titleController,
                decoration: const InputDecoration(labelText: 'Project Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.budgetController,
                      decoration: const InputDecoration(
                        labelText: 'Budget (₦)',
                        prefixText: '₦',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: controller.timelineController,
                      decoration: const InputDecoration(
                        labelText: 'Timeline (e.g. 2 weeks)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.skillsController,
                decoration: const InputDecoration(
                  labelText: 'Required Skills (comma separated)',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => controller.createProject(),
                  child: const Text('Post & Generate Milestones'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Note: Milestones are auto-generated (15/25/40/20 split) but can be adjusted later.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showBidsSheet(BuildContext context, ProjectModel project) {
    controller.fetchBids(project.id); // Trigger async fetch

    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            // Handle and Header
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Proposals',
                          style: Get.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          project.title,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(() {
                    final bids = controller.projectBids[project.id] ?? [];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${bids.length} BIDS',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                final isLoading = controller.isLoadingBids[project.id] ?? false;
                final bids = controller.projectBids[project.id] ?? [];

                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (bids.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_late_outlined,
                          size: 48,
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No bids yet.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  itemCount: bids.length,
                  itemBuilder: (context, index) {
                    final bid = bids[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Text(
                                    bid.developerName[0],
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            bid.developerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                          _buildDevBadges(bid.developerId),
                                        ],
                                      ),
                                      Text(
                                        '₦${bid.amount.toStringAsFixed(0)} • ${bid.proposedTime}',
                                        style: TextStyle(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildAIInsight(project, bid.developerId),
                            const SizedBox(height: 16),
                            Text(
                              bid.coverLetter,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            if (bid.status == BidStatus.pending) ...[
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      controller.acceptBid(project, bid),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'ACCEPT PROPOSAL',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDevBadges(String devId) {
    return FutureBuilder<UserModel?>(
      future: Get.find<AuthRepository>().getUserById(devId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final dev = snapshot.data!;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dev.isVerified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified_rounded, color: Colors.blue, size: 14),
            ],
            const SizedBox(width: 8),
            Icon(
              Icons.star_rounded,
              color: Colors.amber.withValues(alpha: 0.8),
              size: 14,
            ),
            const SizedBox(width: 4),
            const Text(
              '4.9',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAIInsight(ProjectModel project, String devId) {
    return FutureBuilder<UserModel?>(
      future: Get.find<AuthRepository>().getUserById(devId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final dev = snapshot.data!;
        final matching = Get.find<MatchingService>();
        final score = matching.calculateMatchScore(dev, project);
        final reason = matching.getMatchReason(score);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.amber,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AI MATCH INSIGHT: ${(score * 100).toInt()}%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                reason,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInvoicesSheet(BuildContext context, ProjectModel project) {
    final paidMilestones = project.milestones
        .where((m) => m.status == MilestoneStatus.settled)
        .toList();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settled Invoices', style: Get.textTheme.titleLarge),
            const SizedBox(height: 16),
            ...paidMilestones.map(
              (m) => ListTile(
                title: Text(m.title),
                subtitle: Text('Released: ₦${m.amount}'),
                trailing: const Icon(
                  Icons.receipt_long,
                  color: AppColors.primary,
                ),
                onTap: () {
                  Get.back();
                  Get.dialog(InvoiceDialog(project: project, milestone: m));
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    final security = Get.find<SecurityService>();
    return GlassCard(
      child: Column(
        children: [
          Obx(
            () => SwitchListTile(
              secondary: const Icon(
                Icons.fingerprint,
                color: AppColors.primary,
              ),
              title: const Text('Biometric Login'),
              subtitle: const Text('Unlock with Fingerprint/FaceID'),
              value: security.isBiometricsEnabled.value,
              onChanged: (val) => security.toggleBiometrics(val),
            ),
          ),
          const Divider(height: 1),
          Obx(
            () => SwitchListTile(
              secondary: const Icon(Icons.security, color: AppColors.secondary),
              title: const Text('2-Factor Auth (2FA)'),
              subtitle: const Text('Extra layer for funding'),
              value: security.is2FAEnabled.value,
              onChanged: (val) => security.toggle2FA(val),
            ),
          ),
        ],
      ),
    );
  }
}
