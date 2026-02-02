import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../controllers/withdrawal_controller.dart';
import '../../data/repositories/auth_repository.dart';

class WithdrawalScreen extends GetView<WithdrawalController> {
  const WithdrawalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<WithdrawalController>()) {
      Get.put(WithdrawalController());
    }

    final user = Get.find<AuthRepository>().currentUser.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw Funds'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(user?.walletBalance ?? 0.0),
            const SizedBox(height: 32),
            const Text(
              'Bank Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildBankForm(),
            const SizedBox(height: 40),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.handleWithdraw(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'INITIATE WITHDRAWAL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Funds typically arrive within 10-30 minutes.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return GlassCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Available for Withdrawal',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '₦${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankForm() {
    return Column(
      children: [
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedBank.value,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                items: controller.banks.map((bank) {
                  return DropdownMenuItem(
                    value: bank,
                    child: Text(
                      bank,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (val) => controller.selectedBank.value = val!,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller.accountController,
          keyboardType: TextInputType.number,
          maxLength: 10,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Account Number',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            counterStyle: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller.amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Amount to Withdraw (₦)',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            prefixText: '₦ ',
            prefixStyle: const TextStyle(color: AppColors.primary),
            filled: true,
            fillColor: AppColors.surface.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
