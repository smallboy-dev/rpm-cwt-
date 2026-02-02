import 'package:get/get.dart';
import '../models/collaboration_models.dart';

abstract class CollaborationRepository extends GetxService {
  Future<List<FileModel>> fetchFiles(String projectId);

  /// Returns the public URL on success, or throws an Exception on failure.
  Future<String> uploadFileToStorage(
    String projectId,
    String fileName,
    List<int> bytes,
  );

  Future<bool> saveFileMetadata(FileModel file);

  Future<List<ActivityItemModel>> fetchActivityFeed(String projectId);

  Future<void> logActivity(ActivityItemModel activity);
}
