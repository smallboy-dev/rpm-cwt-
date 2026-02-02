import 'package:get/get.dart';
import '../models/bid_model.dart';
import '../providers/mock_database.dart';

class BidRepository extends GetxService {
  final MockDatabase _db = MockDatabase();
  final String _key = 'project_bids';

  List<BidModel> getBidsForProject(String projectId) {
    List<BidModel> allBids = _db.getList(_key, BidModel.fromJson);
    return allBids.where((b) => b.projectId == projectId).toList();
  }

  void submitBid(BidModel bid) {
    List<BidModel> allBids = _db.getList(_key, BidModel.fromJson);
    allBids.add(bid);
    _db.saveList(_key, allBids, (b) => b.toJson());
  }

  void acceptBid(String bidId) {
    List<BidModel> allBids = _db.getList(_key, BidModel.fromJson);
    final index = allBids.indexWhere((b) => b.id == bidId);

    if (index != -1) {
      final acceptedBid = allBids[index];
      allBids[index] = BidModel(
        id: acceptedBid.id,
        projectId: acceptedBid.projectId,
        developerId: acceptedBid.developerId,
        developerName: acceptedBid.developerName,
        amount: acceptedBid.amount,
        proposedTime: acceptedBid.proposedTime,
        coverLetter: acceptedBid.coverLetter,
        status: BidStatus.accepted,
        timestamp: acceptedBid.timestamp,
      );

      // Reject all other bids for this project
      for (int i = 0; i < allBids.length; i++) {
        if (allBids[i].projectId == acceptedBid.projectId &&
            allBids[i].id != bidId) {
          final otherBid = allBids[i];
          allBids[i] = BidModel(
            id: otherBid.id,
            projectId: otherBid.projectId,
            developerId: otherBid.developerId,
            developerName: otherBid.developerName,
            amount: otherBid.amount,
            proposedTime: otherBid.proposedTime,
            coverLetter: otherBid.coverLetter,
            status: BidStatus.rejected,
            timestamp: otherBid.timestamp,
          );
        }
      }

      _db.saveList(_key, allBids, (b) => b.toJson());
    }
  }

  Future<List<String>> fetchProjectIdsWithBids() async => [];
}
