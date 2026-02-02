import 'package:get/get.dart';
import '../models/project_model.dart';
import '../models/milestone_model.dart';

class ProjectRepository extends GetxService {
  Stream<List<ProjectModel>> getProjectStream() {
    return Stream.value([]);
  }

  List<ProjectModel> getAllProjects() {
    return [];
  }

  Future<List<ProjectModel>> fetchProjects() async => [];

  Future<void> createProject(ProjectModel project) async {}

  Future<void> updateProject(ProjectModel updatedProject) async {}

  Future<void> deleteProject(String projectId) async {}

  Future<void> updateMilestoneStatus(
    String milestoneId,
    MilestoneStatus status, {
    String? proofUrl,
  }) async {}

  Stream<List<MilestoneModel>> getMilestonesStream(String projectId) {
    return Stream.value([]);
  }

  List<MilestoneModel> generateAutoMilestones(double totalBudget) {
    return [
      MilestoneModel(
        id: 'm1',
        title: 'Planning',
        description: 'Project scoping and requirements gathering',
        percentage: 15,
        amount: totalBudget * 0.15,
      ),
      MilestoneModel(
        id: 'm2',
        title: 'Design',
        description: 'UI/UX Design and system architecture',
        percentage: 25,
        amount: totalBudget * 0.25,
      ),
      MilestoneModel(
        id: 'm3',
        title: 'Development',
        description: 'Core functionality implementation',
        percentage: 40,
        amount: totalBudget * 0.40,
      ),
      MilestoneModel(
        id: 'm4',
        title: 'Testing',
        description: 'QA, bug fixes and deployment',
        percentage: 20,
        amount: totalBudget * 0.20,
      ),
    ];
  }
}
