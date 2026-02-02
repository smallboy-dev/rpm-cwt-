import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/security_service.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final bioController = TextEditingController();
  final skillsController = TextEditingController();
  final industryController = TextEditingController();
  final githubController = TextEditingController();

  var isLoading = false.obs;

  Future<void> signUp(bool isDeveloper) async {
    if (emailController.text.isEmpty ||
        nameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all fields',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isLoading.value = true;

    UserModel user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text,
      email: emailController.text,
      role: isDeveloper ? UserRole.developer : UserRole.client,
      bio: bioController.text,
      skills: skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      industry: industryController.text,
      githubLink: githubController.text,
      walletBalance: 1000.0,
    );

    try {
      bool success = await _authRepo.signUp(user, passwordController.text);
      isLoading.value = false;

      if (success) {
        Get.offAllNamed(isDeveloper ? '/dev-dashboard' : '/client-dashboard');
      }
    } catch (e) {
      isLoading.value = false;
      String message = e.toString();
      if (message.contains('AuthApiError')) {
        message = message.split(':').last.trim();
      }
      Get.snackbar(
        'Registration Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter email and password',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    try {
      bool success = await _authRepo.login(
        emailController.text,
        passwordController.text,
      );
      isLoading.value = false;

      if (success) {
        var user = _authRepo.currentUser.value!;
        if (user.role == UserRole.admin) {
          Get.offAllNamed('/admin-dashboard');
        } else {
          Get.offAllNamed(
            user.role == UserRole.developer
                ? '/dev-dashboard'
                : '/client-dashboard',
          );
        }
      }
    } catch (e) {
      isLoading.value = false;
      String message = e.toString();
      if (message.contains('AuthApiError')) {
        message = message.split(':').last.trim();
      }
      Get.snackbar(
        'Login Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> biometricLogin() async {
    final security = Get.find<SecurityService>();
    if (!security.isBiometricsEnabled.value) {
      Get.snackbar(
        'Security',
        'Biometrics not enabled. Enable it in your profile.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    bool authenticated = await security.authenticateWithBiometrics();
    if (authenticated) {
      // In a real app, we would retrieve stored credentials or a session token
      // For now, we show an error if no user is found or session expired
      final currentUser = _authRepo.currentUser.value;
      if (currentUser != null) {
        Get.offAllNamed(
          currentUser.role == UserRole.developer
              ? '/dev-dashboard'
              : '/client-dashboard',
        );
      } else {
        Get.snackbar(
          'Login Required',
          'Please sign in with your email and password once to enable biometric entry.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    }
  }
}
