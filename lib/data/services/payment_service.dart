import 'package:get/get.dart';

class PaymentService extends GetxService {
  Future<bool> initiatePaystackPayment({
    required double amount,
    required String email,
  }) async {
    // 1. Show processing snackbar
    Get.snackbar(
      'Payment Gateway',
      'Connecting to Paystack for ₦$amount...',
      showProgressIndicator: true,
      duration: const Duration(seconds: 2),
    );

    // 2. Simulate network delay
    await Future.delayed(const Duration(seconds: 3));

    // 3. Simulate success (90% success rate)
    bool isSuccess = DateTime.now().millisecond % 10 != 0;

    if (isSuccess) {
      Get.snackbar(
        'Success',
        '₦$amount successfully deposited into your wallet!',
        duration: const Duration(seconds: 2),
      );
      return true;
    } else {
      Get.snackbar(
        'Failed',
        'Payment was cancelled or failed. Please try again.',
        duration: const Duration(seconds: 2),
      );
      return false;
    }
  }
}
