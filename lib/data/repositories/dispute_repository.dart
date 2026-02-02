import 'package:get/get.dart';
import '../models/dispute_model.dart';
import '../providers/mock_database.dart';

class DisputeRepository extends GetxService {
  final MockDatabase _db = MockDatabase();
  final String _key = 'project_disputes';

  void raiseDispute(DisputeModel dispute) {
    List<DisputeModel> allDisputes = _db.getList(_key, DisputeModel.fromJson);
    allDisputes.add(dispute);
    _db.saveList(_key, allDisputes, (d) => d.toJson());
  }

  List<DisputeModel> getDisputesForProject(String projectId) {
    List<DisputeModel> allDisputes = _db.getList(_key, DisputeModel.fromJson);
    return allDisputes.where((d) => d.projectId == projectId).toList();
  }

  List<DisputeModel> getAllDisputes() {
    return _db.getList(_key, DisputeModel.fromJson);
  }

  void updateDispute(DisputeModel dispute) {
    List<DisputeModel> allDisputes = _db.getList(_key, DisputeModel.fromJson);
    int index = allDisputes.indexWhere((d) => d.id == dispute.id);
    if (index != -1) {
      allDisputes[index] = dispute;
      _db.saveList(_key, allDisputes, (d) => d.toJson());
    }
  }

  bool isMilestoneDisputed(String milestoneId) {
    List<DisputeModel> allDisputes = _db.getList(_key, DisputeModel.fromJson);
    return allDisputes.any(
      (d) => d.milestoneId == milestoneId && d.status == DisputeStatus.open,
    );
  }
}
