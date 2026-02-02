import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/collaboration_models.dart';
import 'collaboration_repository.dart';

class SupabaseCollaborationRepository extends CollaborationRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<List<FileModel>> fetchFiles(String projectId) async {
    try {
      final response = await _supabase
          .from('project_files')
          .select()
          .eq('project_id', projectId)
          .order('upload_date', ascending: false);

      return (response as List)
          .map((json) => FileModel.fromJson(json))
          .toList();
    } catch (e) {
      print('DEBUG: Supabase fetchFiles Error: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadFileToStorage(
    String projectId,
    String fileName,
    List<int> bytes,
  ) async {
    try {
      final path = '$projectId/$fileName';
      await _supabase.storage
          .from('project-files')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(upsert: true),
          );
      return _supabase.storage.from('project-files').getPublicUrl(path);
    } catch (e) {
      print('Supabase Storage Error: $e');
      throw Exception('Storage Error: $e');
    }
  }

  @override
  Future<bool> saveFileMetadata(FileModel file) async {
    try {
      final data = file.toJson();
      if (data['id'] != null && data['id'].length < 32) {
        data.remove('id');
      }
      await _supabase.from('project_files').insert(data);
      return true;
    } catch (e) {
      print('DEBUG: Supabase saveFileMetadata Error: $e');
      rethrow;
    }
  }

  @override
  Future<List<ActivityItemModel>> fetchActivityFeed(String projectId) async {
    try {
      final response = await _supabase
          .from('project_activity')
          .select()
          .eq('project_id', projectId)
          .order('timestamp', ascending: false);

      return (response as List)
          .map((json) => ActivityItemModel.fromJson(json))
          .toList();
    } catch (e) {
      print('DEBUG: Supabase fetchActivityFeed Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> logActivity(ActivityItemModel activity) async {
    try {
      final data = activity.toJson();
      if (data['id'] != null && data['id'].length < 32) {
        data.remove('id');
      }
      await _supabase.from('project_activity').insert(data);
    } catch (e) {
      print('DEBUG: Supabase logActivity Error: $e');
      rethrow;
    }
  }
}
