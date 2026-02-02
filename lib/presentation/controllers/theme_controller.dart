import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  final _key = 'isDarkMode';

  RxBool isDarkMode = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Force Dark Mode
    isDarkMode.value = true;
    Get.changeThemeMode(ThemeMode.dark);
  }

  void toggleTheme() {
    // Disable toggling - always keep dark mode
    isDarkMode.value = true;
    Get.changeThemeMode(ThemeMode.dark);
    _box.write(_key, true);
  }

  ThemeMode get themeMode => ThemeMode.dark;
}
