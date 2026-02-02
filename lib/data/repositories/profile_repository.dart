import '../models/user_model.dart';

abstract class ProfileRepository {
  Future<List<UserModel>> getAllProfiles();
  Future<void> updateProfile(UserModel user);
  Future<UserModel?> getProfileById(String id);
}
