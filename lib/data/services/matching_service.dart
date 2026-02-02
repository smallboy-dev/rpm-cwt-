import 'package:get/get.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';

class MatchingService extends GetxService {
  double calculateMatchScore(UserModel developer, ProjectModel project) {
    double score = 0.0;

    // 1. Skills Overlap (50%)
    if (project.requiredSkills.isNotEmpty) {
      int matchCount = 0;
      for (var skill in project.requiredSkills) {
        if ((developer.skills ?? []).any(
          (s) => s.toLowerCase().contains(skill.toLowerCase()),
        )) {
          matchCount++;
        }
      }
      score += (matchCount / project.requiredSkills.length) * 0.5;
    }

    // 2. Industry/Role Match (20%)
    if (project.category != null && developer.industry != null) {
      if (developer.industry!.toLowerCase() ==
          project.category!.toLowerCase()) {
        score += 0.2;
      }
    } else if (developer.role == UserRole.developer) {
      score += 0.1;
    }

    // 3. Status & Profile Verification (15%)
    if (developer.isVerified) score += 0.1;
    if (developer.verifiedSkills.isNotEmpty) score += 0.05;

    // 4. Budget Compatibility (15%) - Mock Logic
    score += 0.15;

    return score.clamp(0.0, 1.0);
  }

  String getMatchReason(double score) {
    if (score >= 0.8) return 'Top Talent Match: Expert skill overlap detected.';
    if (score >= 0.5) {
      return 'Strong Contender: Verified expertise in similar projects.';
    }
    return 'Potential Fit: Core skills align with requirements.';
  }

  List<ProjectModel> getRecommendations(
    UserModel developer,
    List<ProjectModel> allProjects,
  ) {
    final scored = allProjects
        .where((p) => p.status == ProjectStatus.open)
        .map((p) => MapEntry(p, calculateMatchScore(developer, p)))
        .where((entry) => entry.value > 0.3)
        .toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.map((e) => e.key).toList();
  }
}
