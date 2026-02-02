import 'package:get/get.dart';
import '../models/user_model.dart';

class AuthRepository extends GetxService {
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  Future<UserModel?> getUserById(String id) async {
    return null;
  }

  Future<bool> signUp(UserModel user, String password) async {
    return false;
  }

  Future<bool> login(String email, String password) async {
    return false;
  }

  Future<void> refreshProfile() async {}

  void setCurrentUser(UserModel? user) {
    currentUser.value = user;
  }

  void logout() {
    setCurrentUser(null);
  }

  void updateUser(UserModel user) {
    if (currentUser.value?.id == user.id) {
      currentUser.value = user;
    }
  }

  void updateWalletBalance(double amount) {
    if (currentUser.value != null) {
      final updatedUser = currentUser.value!.copyWith(
        walletBalance: currentUser.value!.walletBalance + amount,
      );
      updateUser(updatedUser);
    }
  }
}
