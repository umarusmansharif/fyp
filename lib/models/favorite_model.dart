import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteModel {
  final String id;
  final String userId;
  final String propertyId;
  final DateTime addedAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'propertyId': propertyId,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  factory FavoriteModel.fromMap(Map<String, dynamic> map, String id) {
    return FavoriteModel(
      id: id,
      userId: map['userId']?.toString() ?? '',
      propertyId: map['propertyId']?.toString() ?? '',
      addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
