import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final String tenantId;
  final String landlordId;
  final String? propertyId;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int unreadCount;

  ChatModel({
    required this.chatId,
    required this.tenantId,
    required this.landlordId,
    this.propertyId,
    required this.createdAt,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'tenantId': tenantId,
      'landlordId': landlordId,
      'propertyId': propertyId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'unreadCount': unreadCount,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId']?.toString() ?? '',
      tenantId: map['tenantId']?.toString() ?? '',
      landlordId: map['landlordId']?.toString() ?? '',
      propertyId: map['propertyId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: map['unreadCount'] ?? 0,
    );
  }
}
