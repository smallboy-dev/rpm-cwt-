// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/dev_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/notification_controller.dart';
import '../../data/services/wallet_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/floating_navbar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_pages.dart';
import '../../data/models/project_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/matching_service.dart';
import '../../data/services/security_service.dart';

class DevDashboard extends GetView<DevController> {
  const DevDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final titles = ['Marketplace', 'My Tasks', 'Portfolio', 'Analytics'];
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
      body: Stack(
        children: [
          Column(
            children: [
              _buildWalletBar(),
              // Pinned Search Bar for Marketplace
              Obx(() {
                if (controller.selectedIndex.value != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: TextField(
                    onChanged: (value) => controller.searchQuery.value = value,
                    decoration: InputDecoration(
                      hintText: 'Search projects...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primary,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                );
              }),
              Expanded(
                child: Obx(
                  () => IndexedStack(
                    index: controller.selectedIndex.value,
                    children: [
                      _buildMarketplace(),
                      _buildMyTasks(),
                      _buildPortfolio(),
                      _buildAnalytics(),
                    ],
                  ),
                ),
              ),
            ],
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
                    icon: Icons.storefront_outlined,
                    activeIcon: Icons.storefront,
                    label: 'Market',
                  ),
                  FloatingNavbarItem(
                    icon: Icons.assignment_outlined,
                    activeIcon: Icons.assignment,
                    label: 'Tasks',
                  ),
                  FloatingNavbarItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                  ),
                  FloatingNavbarItem(
                    icon: Icons.analytics_outlined,
                    activeIcon: Icons.analytics,
                    label: 'Stats',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(),
          const SizedBox(height: 24),
          const Text(
            'Earnings History (Last 6 Months)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildEarningsChart(),
          const SizedBox(height: 24),
          GlassCard(
            child: ListTile(
              leading: const Icon(
                Icons.business_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Agency Mode'),
              subtitle: const Text('Manage your team & shared wallet'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed('/agency'),
            ),
          ),
          const SizedBox(height: 16),
          _buildExportCard(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Earned',
          '₦${controller.totalEarned.value}',
          Icons.account_balance_wallet_outlined,
          Colors.green,
        ),
        _buildStatCard(
          'Projects',
          '${controller.projectsCompleted.value}',
          Icons.assignment_turned_in_outlined,
          Colors.blue,
        ),
        _buildStatCard(
          'Pending',
          '₦${controller.pendingEscrow.value}',
          Icons.hourglass_empty,
          Colors.orange,
        ),
        _buildStatCard(
          'Active Bids',
          '4', // Mock
          Icons.gavel_outlined,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Get.isDarkMode
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsChart() {
    final data = controller.getEarningsData();
    return AspectRatio(
      aspectRatio: 1.7,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 16,
            right: 16,
            left: 8,
            bottom: 8,
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 3000,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                      return Text(
                        months[value.toInt()],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      color: AppColors.primary,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportCard() {
    return GlassCard(
      child: ListTile(
        leading: const Icon(
          Icons.file_download_outlined,
          color: AppColors.secondary,
        ),
        title: const Text('Export Earnings Report'),
        subtitle: const Text('Download CSV of all past payments'),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            Get.snackbar('Export', 'CSV report downloaded to your device.');
          },
        ),
      ),
    );
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
            const Icon(Icons.stars, color: AppColors.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Earnings',
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
              onPressed: () => Get.toNamed(AppRoutes.withdrawal),
              child: const Text('WITHDRAW'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMarketplace() {
    return CustomScrollView(
      slivers: [
        // AI Recommendations Section
        Obx(() {
          if (controller.recommendedProjects.isEmpty) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }
          return SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'AI Recommendations',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: controller.recommendedProjects.length,
                    itemBuilder: (context, index) {
                      final project = controller.recommendedProjects[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(
                          width: 280,
                          child: _buildProjectCard(
                            context,
                            project,
                            isMarketplace: true,
                            isSmall: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 32),
              ],
            ),
          );
        }),

        // All Projects Header
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Text(
              'All Projects',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),

        // Category Chips
        SliverToBoxAdapter(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.categories.length,
              itemBuilder: (context, index) {
                final category = controller.categories[index];
                return Obx(() {
                  final isSelected =
                      controller.selectedCategory.value == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        controller.selectedCategory.value = category;
                      },
                      backgroundColor: AppColors.surface.withValues(alpha: 0.3),
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                });
              },
            ),
          ),
        ),

        // Filtered Project List
        Obx(() {
          if (controller.filteredMarketplace.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text('No projects found matches your search.'),
                  ],
                ),
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final project = controller.filteredMarketplace[index];
                return _buildProjectCard(context, project, isMarketplace: true);
              }, childCount: controller.filteredMarketplace.length),
            ),
          );
        }),
      ],
    );
  }

  // _buildRecommendedSection integrated directly into CustomScrollView for unified scrolling

  Widget _buildMyTasks() {
    return Obx(() {
      final active = controller.myProjects
          .where((p) => p.status != ProjectStatus.completed)
          .toList();

      if (active.isEmpty) {
        return const Center(child: Text('You have no active projects.'));
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: active.length,
        itemBuilder: (context, index) {
          final project = active[index];
          return _buildProjectCard(context, project, isMarketplace: false);
        },
      );
    });
  }

  Widget _buildProjectCard(
    BuildContext context,
    ProjectModel project, {
    required bool isMarketplace,
    bool isSmall = false,
  }) {
    final matchingService = Get.find<MatchingService>();
    final user = Get.find<AuthRepository>().currentUser.value;
    double score = 0.0;
    if (user != null) {
      score = matchingService.calculateMatchScore(user, project);
    }

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
                if (project.category != null || !isMarketplace) ...[
                  if (project.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        project.category!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (!isMarketplace) ...[
                    const SizedBox(width: 8),
                    _buildStatusBadge(project.status),
                  ],
                ],
                if (!isSmall && isMarketplace && score > 0.5) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.amber,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(score * 100).toInt()}% Match',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project.description,
              maxLines: isSmall ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isSmall ? 8.0 : 16.0),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (isSmall && score > 0.5) ...[
                  const Spacer(),
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.amber.withValues(alpha: 0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(score * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
                const Spacer(),
                if (isMarketplace)
                  ElevatedButton(
                    onPressed: () => _showBidDialog(context, project),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 8 : 16,
                        vertical: isSmall ? 4 : 8,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      isSmall ? 'View' : 'Submit Proposal',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )
                else
                  TextButton(
                    onPressed: project.status == ProjectStatus.completed
                        ? null
                        : () => Get.toNamed('/workspace', arguments: project),
                    style: TextButton.styleFrom(
                      foregroundColor: project.status == ProjectStatus.completed
                          ? Colors.grey
                          : AppColors.primary,
                    ),
                    child: Text(
                      project.status == ProjectStatus.completed
                          ? 'WORKSPACE CLOSED'
                          : 'Open Workspace',
                      style: TextStyle(
                        fontWeight: project.status == ProjectStatus.completed
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ProjectStatus status) {
    Color color;
    String label;

    switch (status) {
      case ProjectStatus.open:
        color = Colors.blue;
        label = 'OPEN';
        break;
      case ProjectStatus.inProgress:
        color = Colors.orange;
        label = 'IN PROGRESS';
        break;
      case ProjectStatus.completed:
        color = Colors.green;
        label = 'COMPLETED';
        break;
      case ProjectStatus.cancelled:
        color = Colors.red;
        label = 'CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildPortfolio() {
    return Obx(() {
      final user = Get.find<AuthRepository>().currentUser.value;
      final completed = controller.myProjects
          .where((p) => p.status == ProjectStatus.completed)
          .toList();

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 24),
            _buildWeb3Card(),
            const SizedBox(height: 24),
            Text('Security Settings', style: Get.textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildSecurityCard(),
            const SizedBox(height: 24),
            Text('Skills & Verification', style: Get.textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildSkillBadges(user),
            const SizedBox(height: 24),
            Text('Project History', style: Get.textTheme.titleLarge),
            const SizedBox(height: 16),
            if (completed.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Complete your first project to build your portfolio!',
                  ),
                ),
              )
            else
              ...completed.map((p) => _buildPortfolioCard(p)),
          ],
        ),
      );
    });
  }

  Widget _buildProfileHeader(dynamic user) {
    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              user?.name[0] ?? '?',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user?.name ?? 'Anonymous',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user?.isVerified ?? false) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.blue, size: 16),
                    ],
                  ],
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!(user?.isVerified ?? false))
            TextButton(
              onPressed: () => Get.toNamed('/kyc-verification'),
              child: const Text('VERIFY ME'),
            ),
        ],
      ),
    );
  }

  Widget _buildSkillBadges(dynamic user) {
    final allSkills = user?.skills ?? [];
    final verifiedSkills = user?.verifiedSkills ?? [];

    if (allSkills.isEmpty) {
      return const Text(
        'No skills listed. You can add them when editing your profile.',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allSkills.map<Widget>((skill) {
        final isVerified = verifiedSkills.contains(skill);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isVerified
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isVerified ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                skill,
                style: TextStyle(
                  fontSize: 12,
                  color: isVerified
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: isVerified ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 12,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPortfolioCard(ProjectModel project) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  project.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Completed on: ${project.createdAt.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if ((project.developerRating ?? 0.0) > 0)
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    project.developerRating!.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              )
            else
              const Text(
                'No rating yet',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBidDialog(BuildContext context, ProjectModel project) {
    final amountController = TextEditingController(
      text: project.totalBudget.toString(),
    );
    final timeController = TextEditingController();
    final letterController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Submit Proposal for ${project.title}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Bid Amount (₦)',
                  prefixText: '₦ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Timeline (e.g. 2 weeks)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: letterController,
                decoration: const InputDecoration(
                  labelText: 'Cover Letter',
                  hintText: 'Why are you the best fit?',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isEmpty ||
                  timeController.text.isEmpty) {
                Get.snackbar('Error', 'Please fill in all fields');
                return;
              }
              controller.submitBid(
                projectId: project.id,
                amount: double.tryParse(amountController.text) ?? 0.0,
                time: timeController.text,
                coverLetter: letterController.text,
              );
            },
            child: const Text('Submit Bid'),
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
                : 'Enable decentralized Naira payments',
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
              subtitle: const Text('Extra layer for withdrawals'),
              value: security.is2FAEnabled.value,
              onChanged: (val) => security.toggle2FA(val),
            ),
          ),
        ],
      ),
    );
  }
}
