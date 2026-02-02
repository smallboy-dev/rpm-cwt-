import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/admin_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/glass_card.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/project_model.dart';
import '../../data/models/milestone_model.dart';
import '../../data/models/kyc_model.dart';
import '../../data/models/user_model.dart';
import '../widgets/floating_navbar.dart';

class AdminDashboard extends GetView<AdminController> {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AdminController>()) {
      Get.put(AdminController());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWeb = constraints.maxWidth > 900;

        return Scaffold(
          body: Row(
            children: [
              if (isWeb) _buildSidebar(),
              Expanded(
                child: Column(
                  children: [
                    _buildAppBar(isWeb),
                    Expanded(
                      child: Obx(() {
                        switch (controller.sidebarIndex.value) {
                          case 0:
                            return _buildOverview();
                          case 1:
                            return _buildUserManagement();
                          case 2:
                            return _buildProjectManagement();
                          case 3:
                            return _buildResolutionCenter();
                          default:
                            return _buildOverview();
                        }
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: !isWeb
              ? Obx(
                  () => FloatingNavbar(
                    currentIndex: controller.sidebarIndex.value,
                    onTap: controller.changeSidebarIndex,
                    items: [
                      FloatingNavbarItem(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard,
                        label: 'Overview',
                      ),
                      FloatingNavbarItem(
                        icon: Icons.people_outline,
                        activeIcon: Icons.people,
                        label: 'Users',
                      ),
                      FloatingNavbarItem(
                        icon: Icons.assignment_outlined,
                        activeIcon: Icons.assignment,
                        label: 'Projects',
                      ),
                      FloatingNavbarItem(
                        icon: Icons.gavel_outlined,
                        activeIcon: Icons.gavel,
                        label: 'Resolutions',
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildAppBar(bool isWeb) {
    return AppBar(
      title: Obx(() {
        final titles = [
          'Overview',
          'User Management',
          'Project Management',
          'Resolution Center',
        ];
        return Text(titles[controller.sidebarIndex.value]);
      }),
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        Obx(() {
          final isDark = Get.find<ThemeController>().isDarkMode.value;
          return IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => Get.find<ThemeController>().toggleTheme(),
          );
        }),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => Get.offAllNamed('/welcome'),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Theme.of(Get.context!).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 32),
          const FlutterLogo(size: 40),
          const SizedBox(height: 8),
          const Text(
            'RPM ADMIN',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 32),
          _buildSidebarItem(0, Icons.dashboard_outlined, 'Overview'),
          _buildSidebarItem(1, Icons.people_outline, 'Users'),
          _buildSidebarItem(2, Icons.assignment_outlined, 'Projects'),
          _buildSidebarItem(3, Icons.gavel_outlined, 'Resolutions'),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {},
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    return Obx(
      () => ListTile(
        selected: controller.sidebarIndex.value == index,
        selectedTileColor: AppColors.primary.withOpacity(0.1),
        leading: Icon(
          icon,
          color: controller.sidebarIndex.value == index
              ? AppColors.primary
              : Colors.grey,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: controller.sidebarIndex.value == index
                ? AppColors.primary
                : null,
            fontWeight: controller.sidebarIndex.value == index
                ? FontWeight.bold
                : null,
          ),
        ),
        onTap: () => controller.changeSidebarIndex(index),
      ),
    );
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Revenue',
                    '₦${controller.getTotalRevenue()}',
                    Icons.account_balance_wallet,
                    [Colors.green.shade400, Colors.green.shade700],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Users',
                    '${controller.allUsers.length}',
                    Icons.people_alt,
                    [Colors.blue.shade400, Colors.blue.shade700],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Active Projects',
                    '${controller.allProjects.where((p) => p.status == ProjectStatus.inProgress).length}',
                    Icons.rocket_launch,
                    [Colors.purple.shade400, Colors.purple.shade700],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Disputes',
                    '${controller.disputedProjects.length}',
                    Icons.gavel,
                    [Colors.orange.shade400, Colors.orange.shade700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Revenue Analytics',
            style: Theme.of(Get.context!).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildRevenueChart(),
        ],
      ),
    );
  }

  Widget _buildUserManagement() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'User Directory',
                  style: Theme.of(Get.context!).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Theme(
                  data: Theme.of(
                    Get.context!,
                  ).copyWith(dividerColor: Colors.grey.withOpacity(0.2)),
                  child: DataTable(
                    horizontalMargin: 24,
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('KYC Status')),
                      DataColumn(label: Text('Balance')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: controller.allUsers.map((user) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.1),
                                  child: Text(
                                    user.name[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      user.email,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: user.role == UserRole.admin
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user.role.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: user.role == UserRole.admin
                                      ? Colors.red
                                      : Colors.blue,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                Icon(
                                  user.kycStatus == KYCStatus.approved
                                      ? Icons.check_circle
                                      : (user.kycStatus == KYCStatus.rejected
                                            ? Icons.cancel
                                            : Icons.hourglass_empty),
                                  size: 16,
                                  color: user.kycStatus == KYCStatus.approved
                                      ? Colors.green
                                      : (user.kycStatus == KYCStatus.rejected
                                            ? Colors.red
                                            : Colors.orange),
                                ),
                                const SizedBox(width: 4),
                                Text(user.kycStatus.name.capitalizeFirst!),
                              ],
                            ),
                          ),
                          DataCell(
                            Text('₦${user.walletBalance.toStringAsFixed(2)}'),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProjectManagement() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Project Monitor',
                  style: Theme.of(Get.context!).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Export Report'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Theme(
                  data: Theme.of(
                    Get.context!,
                  ).copyWith(dividerColor: Colors.grey.withOpacity(0.2)),
                  child: DataTable(
                    horizontalMargin: 24,
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('Project Title')),
                      DataColumn(label: Text('Budget')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Milestones')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: controller.allProjects.map((project) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                project.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text('₦${project.totalBudget.toStringAsFixed(2)}'),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: project.status == ProjectStatus.completed
                                    ? Colors.green.withOpacity(0.1)
                                    : (project.status ==
                                              ProjectStatus.inProgress
                                          ? Colors.purple.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                project.status.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      project.status == ProjectStatus.completed
                                      ? Colors.green
                                      : (project.status ==
                                                ProjectStatus.inProgress
                                            ? Colors.purple
                                            : Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                Text(
                                  '${project.milestones.where((m) => m.isApproved).length}/${project.milestones.length}',
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 60,
                                  height: 4,
                                  child: LinearProgressIndicator(
                                    value: project.milestones.isEmpty
                                        ? 0
                                        : project.milestones
                                                  .where((m) => m.isApproved)
                                                  .length /
                                              project.milestones.length,
                                    backgroundColor: Colors.grey.withOpacity(
                                      0.2,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () =>
                                  Get.toNamed('/workspace', arguments: project),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildResolutionCenter() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 28, color: Colors.orange),
              const SizedBox(width: 12),
              Text(
                'Resolution Center',
                style: Theme.of(Get.context!).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage KYC verify requests and conflicting project disputes.',
          ),
          const SizedBox(height: 32),

          Text(
            'Pending Verifications',
            style: Theme.of(
              Get.context!,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildKYCList(),

          const SizedBox(height: 40),

          Text(
            'Active Disputes',
            style: Theme.of(
              Get.context!,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDisputeList(),
        ],
      ),
    );
  }

  Widget _buildKYCList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final kycRequests = controller.allUsers
          .where((user) => user.kycStatus == KYCStatus.pending)
          .toList();
      if (kycRequests.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(32),
          alignment: Alignment.center,
          child: const Text('No pending KYC requests.'),
        );
      }
      return Column(
        children: kycRequests.map((user) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(user.name[0]),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            onPressed: () => controller.approveKyc(user.id),
                            child: const Text('Approve'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => controller.rejectKyc(user.id),
                            child: const Text('Reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildRevenueChart() {
    return AspectRatio(
      aspectRatio: 1.7,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Platform Revenue (Last 6 Months)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 300),
                          FlSpot(1, 450),
                          FlSpot(2, 400),
                          FlSpot(3, 620),
                          FlSpot(4, 580),
                          FlSpot(5, 850),
                        ],
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 4,
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                      ),
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

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    List<Color> colors,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputeList() {
    return Obx(() {
      if (controller.disputedProjects.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(32),
          alignment: Alignment.center,
          child: const Text('No active disputes! Platform is healthy.'),
        );
      }

      return Column(
        children: controller.disputedProjects.map((project) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          project.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DISPUTED',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...project.milestones
                        .where(
                          (m) =>
                              Get.find<AdminController>()
                                  .getDisputeForMilestone(m.id) !=
                              null,
                        )
                        .map(
                          (m) => _buildMilestoneResolutionRow(
                            Get.context!,
                            project,
                            m,
                          ),
                        ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildMilestoneResolutionRow(
    BuildContext context,
    ProjectModel project,
    MilestoneModel milestone,
  ) {
    final dispute = controller.getDisputeForMilestone(milestone.id);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Reason: ${dispute?.reason ?? "No reason provided"}',
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () =>
                      _showResolutionDialog(context, project, milestone, true),
                  child: const Text('Pay Dev'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _showResolutionDialog(context, project, milestone, false),
                  child: const Text('Refund Client'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResolutionDialog(
    BuildContext context,
    ProjectModel project,
    MilestoneModel milestone,
    bool awardToDeveloper,
  ) {
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text(awardToDeveloper ? 'Release Funds' : 'Refund Client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to ${awardToDeveloper ? "pay the developer" : "refund the client"} for "${milestone.title}"?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Admin Reason/Verdict',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => controller.resolveDispute(
              project: project,
              milestoneId: milestone.id,
              awardToDeveloper: awardToDeveloper,
              reason: reasonController.text,
            ),
            child: const Text('Confirm Verdict'),
          ),
        ],
      ),
    );
  }
}
