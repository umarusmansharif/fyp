import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String landlordId;
  final String tenantId;
  final String houseId;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.landlordId,
    required this.tenantId,
    required this.houseId,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'landlordId': landlordId,
      'tenantId': tenantId,
      'houseId': houseId,
      'message': message,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      landlordId: map['landlordId'] ?? '',
      tenantId: map['tenantId'] ?? '',
      houseId: map['houseId'] ?? '',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
    );
  }
}