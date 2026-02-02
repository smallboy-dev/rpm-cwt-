import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/project_model.dart';
import '../../data/models/milestone_model.dart';
import '../widgets/glass_card.dart';

class InvoiceDialog extends StatelessWidget {
  final ProjectModel project;
  final MilestoneModel milestone;

  const InvoiceDialog({
    super.key,
    required this.project,
    required this.milestone,
  });

  @override
  Widget build(BuildContext context) {
    final double grossAmount = milestone.amount;
    final double platformFee = grossAmount * 0.10;
    final double netAmount = grossAmount - platformFee;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'INVOICE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(color: AppColors.textSecondary),
              const SizedBox(height: 16),
              _buildInfoRow('Project:', project.title),
              _buildInfoRow('Milestone:', milestone.title),
              _buildInfoRow(
                'Date:',
                DateTime.now().toLocal().toString().split(' ')[0],
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Summary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildAmountRow('Gross Amount:', grossAmount),
              _buildAmountRow(
                'Platform Fee (10%):',
                platformFee,
                isNegative: true,
              ),
              const Divider(color: AppColors.textSecondary),
              _buildAmountRow('Net Payout:', netAmount, isBold: true),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('CLOSE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount, {
    bool isNegative = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}₦${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isNegative
                  ? Colors.redAccent
                  : (isBold ? AppColors.primary : AppColors.textPrimary),
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
