import 'package:hive/hive.dart';
import 'review_status.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final Box<ReviewStatus> _box = Hive.box<ReviewStatus>('reviewBox');

  ReviewStatus? get(String questionId, String moduleType) {
    return _box.get('$moduleType::$questionId');
  }

  Future<void> save(ReviewStatus status) async {
    await _box.put('${status.moduleType}::${status.questionId}', status);
  }

  List<ReviewStatus> getDue(String moduleType) {
    final now = DateTime.now();
    return _box.values.where((e) =>
      e.moduleType == moduleType &&
      !e.isMastered &&
      now.isAfter(e.nextReview)
    ).toList();
  }
}
