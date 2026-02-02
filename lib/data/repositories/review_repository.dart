import 'package:get/get.dart';
import '../models/review_model.dart';
import '../providers/mock_database.dart';

class ReviewRepository extends GetxService {
  final MockDatabase _db = MockDatabase();
  static const String _key = 'reviews';

  List<ReviewModel> getAllReviews() {
    return _db.getList(_key, ReviewModel.fromJson);
  }

  Future<void> addReview(ReviewModel review) async {
    List<ReviewModel> reviews = getAllReviews();
    reviews.add(review);
    _db.saveList(_key, reviews, (r) => r.toJson());
  }

  List<ReviewModel> getReviewsForUser(String userId) {
    return getAllReviews().where((r) => r.revieweeId == userId).toList();
  }

  double getAverageRating(String userId) {
    final userReviews = getReviewsForUser(userId);
    if (userReviews.isEmpty) return 0.0;
    final total = userReviews.map((r) => r.rating).reduce((a, b) => a + b);
    return total / userReviews.length;
  }
}
