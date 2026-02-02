// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../controllers/agency_controller.dart';
import '../widgets/glass_card.dart';
import '../../data/models/agency_model.dart';

class AgencyDashboard extends GetView<AgencyController> {
  const AgencyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, AppColors.background.withBlue(40)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Obx(() {
              final agency = controller.currentAgency.value;

              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (agency == null) {
                return _buildCreateAgencyView();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(agency),
                  const SizedBox(height: 24),
                  _buildStats(agency),
                  const SizedBox(height: 24),
                  const Text(
                    'Team Members',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildMembersList(agency)),
                ],
              );
            }),
          ),
        ),
      ),
      floatingActionButton: Obx(() {
        if (controller.currentAgency.value != null && controller.isOwner) {
          return FloatingActionButton.extended(
            onPressed: () => _showInviteDialog(context),
            label: const Text('Invite Member'),
            icon: const Icon(Icons.person_add),
            backgroundColor: AppColors.primary,
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildCreateAgencyView() {
    final nameController = TextEditingController();
    return Center(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_add, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Create an Agency',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Form a team, share resources, and scale your growth.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Agency Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.createAgency(nameController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Launch Agency'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AgencyModel agency) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              agency.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              'Agency Management',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildStats(AgencyModel agency) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Agency Wallet',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₦${agency.walletBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Team Size',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${agency.members.length}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMembersList(AgencyModel agency) {
    return ListView.builder(
      itemCount: agency.members.length,
      itemBuilder: (context, index) {
        final member = agency.members[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassCard(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(
                  member.userName[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
              title: Text(
                member.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                member.role.name.capitalizeFirst!,
                style: TextStyle(
                  color: member.role == AgencyRole.admin
                      ? AppColors.accent
                      : Colors.white60,
                ),
              ),
              trailing: member.userId == agency.ownerId
                  ? const Chip(
                      label: Text('Owner', style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.amber,
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  void _showInviteDialog(BuildContext context) {
    final emailController = TextEditingController();
    AgencyRole selectedRole = AgencyRole.member;

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text(
          'Invite Team Member',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'User Email',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AgencyRole>(
              value: selectedRole,
              items: AgencyRole.values.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.name.capitalizeFirst!),
                );
              }).toList(),
              onChanged: (val) => selectedRole = val!,
              decoration: const InputDecoration(
                labelText: 'Role',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.inviteMember(emailController.text, selectedRole);
              Get.back();
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }
}
