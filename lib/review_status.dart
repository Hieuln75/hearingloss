import 'package:hive/hive.dart';

part 'review_status.g.dart';

@HiveType(typeId: 0)
class ReviewStatus extends HiveObject {
  @HiveField(0)
  String questionId;

  @HiveField(1)
  DateTime lastReviewed;

  @HiveField(2)
  DateTime nextReview;

  @HiveField(3)
  int reviewCount;

  @HiveField(4)
  bool isMastered;

  @HiveField(5)
  String moduleType; // ví dụ: 'letters'

  ReviewStatus({
    required this.questionId,
    required this.lastReviewed,
    required this.nextReview,
    required this.reviewCount,
    required this.isMastered,
    required this.moduleType,
  });
}
