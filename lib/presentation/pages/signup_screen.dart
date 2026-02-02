import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';

class SignupScreen extends GetView<AuthController> {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }

    final Map args = Get.arguments ?? {'isDeveloper': true};
    final bool isDeveloper = args['isDeveloper'];
    final isDark = Get.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BackButton(),
                  const SizedBox(height: 32),
                  Text(
                    isDeveloper ? 'Developer Profile' : 'Client Profile',
                    style: Get.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us a bit about yourself to get started on the RPM marketplace.',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildForm(isDeveloper, isDark),
                  const SizedBox(height: 40),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () => controller.signUp(isDeveloper),
                        child: controller.isLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Complete Registration'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDeveloper, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ACCOUNT INFORMATION', isDark),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.nameController,
          label: 'Full Name',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: controller.emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: controller.passwordController,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
        ),
        const SizedBox(height: 32),
        _buildSectionTitle(
          isDeveloper ? 'SKILLS & EXPERIENCE' : 'BUSINESS DETAILS',
          isDark,
        ),
        const SizedBox(height: 16),
        if (isDeveloper) ...[
          _buildTextField(
            controller: controller.githubController,
            label: 'GitHub URL',
            icon: Icons.link_rounded,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: controller.skillsController,
            label: 'Core Skills (e.g. Flutter, Rust)',
            icon: Icons.bolt_rounded,
          ),
        ] else ...[
          _buildTextField(
            controller: controller.industryController,
            label: 'Industry',
            icon: Icons.business_center_outlined,
          ),
        ],
        const SizedBox(height: 32),
        _buildSectionTitle('ABOUT YOU', isDark),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.bioController,
          label: 'Professional Bio',
          icon: Icons.description_outlined,
          maxLines: 4,
        ),
      ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, size: 22),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
      ),
    );
  }
}
