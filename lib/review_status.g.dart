// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReviewStatusAdapter extends TypeAdapter<ReviewStatus> {
  @override
  final int typeId = 0;

  @override
  ReviewStatus read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReviewStatus(
      questionId: fields[0] as String,
      lastReviewed: fields[1] as DateTime,
      nextReview: fields[2] as DateTime,
      reviewCount: fields[3] as int,
      isMastered: fields[4] as bool,
      moduleType: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ReviewStatus obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.questionId)
      ..writeByte(1)
      ..write(obj.lastReviewed)
      ..writeByte(2)
      ..write(obj.nextReview)
      ..writeByte(3)
      ..write(obj.reviewCount)
      ..writeByte(4)
      ..write(obj.isMastered)
      ..writeByte(5)
      ..write(obj.moduleType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
