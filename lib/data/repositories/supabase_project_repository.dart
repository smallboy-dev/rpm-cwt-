// ignore_for_file: avoid_print, unnecessary_overrides, avoid_renaming_method_parameters

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import '../models/milestone_model.dart';
import 'project_repository.dart';

class SupabaseProjectRepository extends ProjectRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Stream<List<ProjectModel>> getProjectStream() {
    return _supabase
        .from('projects')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (data) => data.map((json) => ProjectModel.fromJson(json)).toList(),
        );
  }

  List<ProjectModel> _cache = [];

  @override
  List<ProjectModel> getAllProjects() {
    return _cache;
  }

  @override
  Future<List<ProjectModel>> fetchProjects() async {
    try {
      final response = await _supabase
          .from('projects')
          .select('*, milestones(*)');

      final projects = (response as List)
          .map((json) => ProjectModel.fromJson(json))
          .toList();

      _cache = projects;
      return projects;
    } catch (e) {
      print('DEBUG: Supabase fetchProjects Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> createProject(ProjectModel project) async {
    try {
      final projectData = await _supabase
          .from('projects')
          .insert({
            'client_id': project.clientId,
            'title': project.title,
            'description': project.description,
            'timeline': project.timeline,
            'total_budget': project.totalBudget,
            'status': project.status.name,
            'skills_required': project.requiredSkills,
          })
          .select()
          .single();

      final newProjectId = projectData['id'];

      if (project.milestones.isNotEmpty) {
        final milestonesJson = project.milestones
            .map(
              (m) => {
                'project_id': newProjectId,
                'title': m.title,
                'amount': m.amount,
                'percentage': m.percentage,
                'status': m.status.name,
              },
            )
            .toList();

        await _supabase.from('milestones').insert(milestonesJson);
      }
    } catch (e) {
      print('DEBUG: Supabase createProject Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateProject(ProjectModel project) async {
    try {
      await _supabase
          .from('projects')
          .update({
            'status': project.status.name,
            'escrow_balance': project.escrowBalance,
            'developer_id': project.developerId,
            'developer_rating': project.developerRating,
            'client_rating': project.clientRating,
          })
          .eq('id', project.id);
    } catch (e) {
      print('DEBUG: Supabase updateProject Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProject(String projectId) async {
    try {
      await _supabase.from('milestones').delete().eq('project_id', projectId);

      await _supabase.from('bids').delete().eq('project_id', projectId);

      await _supabase.from('messages').delete().eq('project_id', projectId);

      await _supabase
          .from('project_activity')
          .delete()
          .eq('project_id', projectId);

      await _supabase
          .from('project_files')
          .delete()
          .eq('project_id', projectId);

      await _supabase.from('projects').delete().eq('id', projectId);
    } catch (e) {
      print('DEBUG: Supabase deleteProject Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateMilestoneStatus(
    String milestoneId,
    MilestoneStatus status, {
    String? proofUrl,
  }) async {
    try {
      await _supabase
          .from('milestones')
          .update({
            'status': status.name,
            'proof_url': proofUrl,
            'proof_link': proofUrl,
          })
          .eq('id', milestoneId);
    } catch (e) {
      print('Error updating milestone: $e');
    }
  }

  @override
  Stream<List<MilestoneModel>> getMilestonesStream(String projectId) {
    return _supabase
        .from('milestones')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .map(
          (data) => data.map((json) => MilestoneModel.fromJson(json)).toList(),
        );
  }
}
