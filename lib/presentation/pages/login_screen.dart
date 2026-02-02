import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/security_service.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }

    final isDark = Get.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -100,
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
                  const SizedBox(height: 60),
                  // Logo/Brand Section
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Welcome back!',
                    style: Get.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your RPM account to manage your projects and payments.',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Form Section
                  Column(
                    children: [
                      TextField(
                        controller: controller.emailController,
                        decoration: const InputDecoration(
                          hintText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: controller.passwordController,
                        decoration: const InputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : () => controller.login(),
                            child: controller.isLoading.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Sign In'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Biometrics Section
                  Obx(() {
                    final security = Get.find<SecurityService>();
                    if (!security.isBiometricsEnabled.value) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'Or use secure login',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : AppColors.textSecondaryLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: () => controller.biometricLogin(),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                            ),
                            child: Icon(
                              Icons.fingerprint_rounded,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 40),
                  Center(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: RichText(
                        text: TextSpan(
                          style: Get.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.textSecondaryLight,
                          ),
                          children: [
                            const TextSpan(text: 'Don\'t have an account? '),
                            TextSpan(
                              text: 'Create account',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Admin Access Button (Hidden/Subtle)
          Positioned(
            bottom: 16,
            right: 16,
            child: IconButton(
              icon: Icon(
                Icons.admin_panel_settings_outlined,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
              onPressed: () => Get.toNamed('/admin-dashboard'),
              tooltip: 'Admin Access',
            ),
          ),
        ],
      ),
    );
  }
}
