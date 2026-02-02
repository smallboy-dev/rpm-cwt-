import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/payout_repository.dart';
import '../../data/services/security_service.dart';

class WithdrawalController extends GetxController {
  final AuthRepository _authRepo = Get.find<AuthRepository>();
  final PayoutRepository _payoutRepo = Get.find<PayoutRepository>();

  final accountController = TextEditingController();
  final amountController = TextEditingController();

  var selectedBank = 'Access Bank'.obs;
  var isLoading = false.obs;

  final List<String> banks = [
    'Access Bank',
    'First Bank',
    'GTBank',
    'Zenith Bank',
    'UBA',
    'Kuda Bank',
    'Moniepoint',
    'Opay',
  ];

  void handleWithdraw() async {
    final user = _authRepo.currentUser.value;
    if (user == null) return;

    final amount = double.tryParse(amountController.text) ?? 0.0;
    if (amount <= 0 || !amount.isFinite) {
      Get.snackbar(
        'Error',
        'Please enter a valid finite amount',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (amount > user.walletBalance) {
      Get.snackbar(
        'Error',
        'Insufficient balance',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (accountController.text.length != 10) {
      Get.snackbar(
        'Error',
        'Invalid account number',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isLoading.value = true;

    final security = Get.find<SecurityService>();
    if (security.is2FAEnabled.value) {
      isLoading.value = false;
      _show2FAChallenge(amount);
    } else {
      await _processWithdrawal(amount);
    }
  }

  void _show2FAChallenge(double amount) {
    final codeController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('2-Factor Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the 6-digit code sent to your device.'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(hintText: '000000'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final security = Get.find<SecurityService>();
              bool valid = await security.verify2FACode(codeController.text);
              if (valid) {
                Get.back();
                isLoading.value = true;
                await _processWithdrawal(amount);
              } else {
                Get.snackbar(
                  'Error',
                  'Invalid 2FA code. Hint: Use 123456',
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(16),
                );
              }
            },
            child: const Text('Verify & Withdraw'),
          ),
        ],
      ),
    );
  }

  Future<void> _processWithdrawal(double amount) async {
    final user = _authRepo.currentUser.value!;

    await Future.delayed(const Duration(seconds: 1));

    final request = PayoutRequest(
      id: 'po_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      amount: amount,
      bankName: selectedBank.value,
      accountNumber: accountController.text,
      timestamp: DateTime.now(),
    );

    await _payoutRepo.requestPayout(request);

    // Deduct from wallet
    _authRepo.updateWalletBalance(-amount);

    isLoading.value = false;
    Get.back();
    Get.snackbar(
      'Success',
      'Withdrawal of ₦$amount initiated! It will reach your bank shortly.',
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
