import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String propertyId;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final int rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.reviewId,
    required this.propertyId,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'propertyId': propertyId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      reviewId: map['reviewId']?.toString() ?? '',
      propertyId: map['propertyId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      userName: map['userName'],
      userAvatar: map['userAvatar'],
      rating: map['rating'] ?? 0,
      comment: map['comment']?.toString() ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
