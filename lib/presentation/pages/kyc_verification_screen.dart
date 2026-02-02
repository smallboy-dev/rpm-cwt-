import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/kyc_model.dart';
import '../../data/repositories/kyc_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/glass_card.dart';
import '../../core/theme/app_colors.dart';

class KYCVerificationScreen extends StatefulWidget {
  const KYCVerificationScreen({super.key});

  @override
  State<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen> {
  final idController = TextEditingController();
  final portfolioController = TextEditingController();
  final kycRepo = Get.find<KYCRepository>();
  final authRepo = Get.find<AuthRepository>();

  bool isUploading = false;
  KYCRequestModel? existingRequest;

  @override
  void initState() {
    super.initState();
    existingRequest = kycRepo.getRequestForUser(authRepo.currentUser.value!.id);
    if (existingRequest != null) {
      idController.text = existingRequest!.idNumber;
      portfolioController.text = existingRequest!.portfolioUrl;
    }
  }

  Future<void> _submitKYC() async {
    if (idController.text.isEmpty || portfolioController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all fields',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    setState(() => isUploading = true);
    await Future.delayed(const Duration(seconds: 2));

    final request = KYCRequestModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: authRepo.currentUser.value!.id,
      idNumber: idController.text,
      documentUrl:
          'https://mock-storage.com/docs/id_${authRepo.currentUser.value!.id}.jpg',
      portfolioUrl: portfolioController.text,
      submittedAt: DateTime.now(),
    );

    kycRepo.submitRequest(request);

    setState(() {
      isUploading = false;
      existingRequest = request;
    });

    Get.snackbar(
      'Success',
      'KYC request submitted for review!',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Identity Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(isDark),
            const SizedBox(height: 48),
            _buildSectionTitle('IDENTIFICATION DETAILS', isDark),
            const SizedBox(height: 16),
            TextField(
              controller: idController,
              enabled: existingRequest?.status != KYCStatus.approved,
              decoration: const InputDecoration(
                hintText: 'National ID or Passport Number',
                prefixIcon: Icon(Icons.badge_outlined, size: 22),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('CORE SKILLS', isDark),
            const SizedBox(height: 16),
            _buildSkillBadges(authRepo.currentUser.value?.skills ?? []),
            const SizedBox(height: 24),
            _buildSectionTitle('PORTFOLIO & WORK', isDark),
            const SizedBox(height: 16),
            TextField(
              controller: portfolioController,
              enabled: existingRequest?.status != KYCStatus.approved,
              decoration: const InputDecoration(
                hintText: 'https://github.com/yourusername',
                prefixIcon: Icon(Icons.link_rounded, size: 22),
              ),
            ),
            const SizedBox(height: 40),
            _buildSectionTitle('ID DOCUMENT UPLOAD', isDark),
            const SizedBox(height: 16),
            _buildUploadSection(isDark),
            const SizedBox(height: 60),
            if (existingRequest?.status != KYCStatus.approved)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUploading ? null : _submitKYC,
                  child: isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          existingRequest == null
                              ? 'Submit for Review'
                              : 'Update Verification',
                        ),
                ),
              ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Verification usually takes 24-48 hours.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    );
  }

  Widget _buildStatusHeader(bool isDark) {
    if (existingRequest == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: AppColors.primary),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Verification adds a trust badge to your profile and increases your visibility to high-value clients.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (existingRequest!.status) {
      case KYCStatus.approved:
        statusColor = AppColors.secondary;
        statusIcon = Icons.verified_rounded;
        statusText = 'Verified Account';
        break;
      case KYCStatus.rejected:
        statusColor = AppColors.accent;
        statusIcon = Icons.error_rounded;
        statusText = 'Verification Failed';
        break;
      case KYCStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top_rounded;
        statusText = 'Under Review';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (existingRequest!.status == KYCStatus.rejected)
                  Text(
                    existingRequest!.adminNotes ?? 'Please check your details.',
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection(bool isDark) {
    final isApproved = existingRequest?.status == KYCStatus.approved;
    return GestureDetector(
      onTap: isApproved ? null : () {},
      child: GlassCard(
        height: 140,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                existingRequest != null
                    ? Icons.document_scanner_rounded
                    : Icons.add_a_photo_rounded,
                size: 32,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              const SizedBox(height: 12),
              Text(
                existingRequest != null ? 'ID Submitted' : 'Tap to upload ID',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillBadges(List<String> skills) {
    if (skills.isEmpty) {
      return const Text(
        'No skills listed. You can add them in your profile.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Text(
            skill,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }
}
