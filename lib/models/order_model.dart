import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String houseId;
  final String tenantId;
  final String landlordId;
  final String status;
  final DateTime createdAt;

  OrderModel({
    required this.orderId,
    required this.houseId,
    required this.tenantId,
    required this.landlordId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'houseId': houseId,
      'tenantId': tenantId,
      'landlordId': landlordId,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['orderId'] ?? '',
      houseId: map['houseId'] ?? '',
      tenantId: map['tenantId'] ?? '',
      landlordId: map['landlordId'] ?? '',
      status: map['status'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}