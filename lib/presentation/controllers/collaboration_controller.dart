// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/collaboration_models.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../../data/repositories/auth_repository.dart';

class CollaborationController extends GetxController {
  final CollaborationRepository _repo = Get.find<CollaborationRepository>();
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  var files = <FileModel>[].obs;
  var activityFeed = <ActivityItemModel>[].obs;
  var isUploading = false.obs;

  String? projectId;

  void init(String id) {
    projectId = id;
    loadData();
  }

  void loadData() {
    if (projectId == null) return;
    refreshFiles();
    refreshActivity();
  }

  Future<void> refreshFiles() async {
    try {
      files.assignAll(await _repo.fetchFiles(projectId!));
    } catch (e) {
      print('Error refreshing files: $e');
    }
  }

  Future<void> refreshActivity() async {
    try {
      activityFeed.assignAll(await _repo.fetchActivityFeed(projectId!));
    } catch (e) {
      print('Error refreshing activity: $e');
    }
  }

  Future<void> pickAndUploadFile() async {
    try {
      final currentUser = _authRepo.currentUser.value;
      if (currentUser == null || projectId == null) {
        Get.snackbar('Error', 'User not authenticated or project ID missing');
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        isUploading.value = true;
        final platformFile = result.files.single;

        final fileName = platformFile.name;
        final fileBytes = platformFile.bytes!;
        final fileSize = _formatBytes(platformFile.size);
        final fileType = _getFileType(fileName);

        Get.snackbar(
          'Uploading',
          'Sending "$fileName" to secure storage...',
          showProgressIndicator: true,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.withOpacity(0.1),
          colorText: Colors.white,
        );

        try {
          // 1. Upload to Storage
          final publicUrl = await _repo.uploadFileToStorage(
            projectId!,
            fileName,
            fileBytes,
          );

          // 2. Save Metadata
          final newFile = FileModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            projectId: projectId!,
            uploaderId: currentUser.id,
            fileName: fileName,
            fileUrl: publicUrl,
            fileSize: fileSize,
            uploadDate: DateTime.now(),
            fileType: fileType,
          );

          await _repo.saveFileMetadata(newFile);

          // 3. Log Activity
          final activity = ActivityItemModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            projectId: projectId!,
            userId: currentUser.id,
            type: ActivityType.upload,
            description: 'uploaded a file: $fileName',
            timestamp: DateTime.now(),
          );
          await _repo.logActivity(activity);

          await refreshFiles();
          await refreshActivity();

          Get.snackbar(
            'Success',
            'File "$fileName" uploaded successfully',
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            'Upload Failed',
            e.toString().contains('Exception: ')
                ? e.toString().split('Exception: ').last
                : e.toString(),
            backgroundColor: Colors.red.withOpacity(0.1),
            colorText: Colors.white,
            duration: const Duration(seconds: 10),
          );
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: $e');
    } finally {
      isUploading.value = false;
    }
  }

  String _formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return ((bytes / math.pow(1024, i)).toStringAsFixed(decimals)) +
        ' ' +
        suffixes[i];
  }

  String _getFileType(String fileName) {
    if (!fileName.contains('.')) return 'unknown';
    return fileName.split('.').last.toLowerCase();
  }
}
