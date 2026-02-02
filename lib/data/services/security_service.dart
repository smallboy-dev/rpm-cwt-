import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SecurityService extends GetxService {
  final _storage = GetStorage();

  var isBiometricsEnabled = false.obs;
  var is2FAEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    isBiometricsEnabled.value = _storage.read('biometrics_enabled') ?? false;
    is2FAEnabled.value = _storage.read('2fa_enabled') ?? false;
  }

  Future<bool> authenticateWithBiometrics() async {
    // Simulate biometric authentication delay
    await Future.delayed(const Duration(milliseconds: 800));

    // For MVP simulation, we'll assume it succeeds if enabled
    // ในแอปจริงจะใช้ package: local_auth
    return true;
  }

  void toggleBiometrics(bool value) {
    isBiometricsEnabled.value = value;
    _storage.write('biometrics_enabled', value);
  }

  void toggle2FA(bool value) {
    is2FAEnabled.value = value;
    _storage.write('2fa_enabled', value);
  }

  Future<bool> verify2FACode(String code) async {
    // Mock 2FA verification (using '123456' as the correct code for simulation)
    await Future.delayed(const Duration(milliseconds: 500));
    return code == '123456';
  }
}
