import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final String tenantId;
  final String landlordId;
  final String propertyId; // CRITICAL: Each chat tied to a property
  final String propertyTitle; // Property display name
  final String propertyLocation; // Short location text
  final double propertyPrice; // Rent price
  final String propertyThumbnail; // First image URL
  final String otherUserId; // For quick access to other participant
  final String otherUserName; // Dynamic chat name
  final String lastMessage; // Last message preview
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isActive; // Chat active status
  final bool deletedByTenant; // Per-user delete flag
  final bool deletedByLandlord; // Per-user delete flag

  ChatModel({
    required this.chatId,
    required this.tenantId,
    required this.landlordId,
    required this.propertyId,
    this.propertyTitle = '',
    this.propertyLocation = '',
    this.propertyPrice = 0.0,
    this.propertyThumbnail = '',
    this.otherUserId = '',
    this.otherUserName = '',
    this.lastMessage = '',
    required this.createdAt,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isActive = true,
    this.deletedByTenant = false,
    this.deletedByLandlord = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'tenantId': tenantId,
      'landlordId': landlordId,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'propertyLocation': propertyLocation,
      'propertyPrice': propertyPrice,
      'propertyThumbnail': propertyThumbnail,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'lastMessage': lastMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'deletedByTenant': deletedByTenant,
      'deletedByLandlord': deletedByLandlord,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId']?.toString() ?? '',
      tenantId: map['tenantId']?.toString() ?? '',
      landlordId: map['landlordId']?.toString() ?? '',
      propertyId: map['propertyId']?.toString() ?? '',
      propertyTitle: map['propertyTitle']?.toString() ?? '',
      propertyLocation: map['propertyLocation']?.toString() ?? '',
      propertyPrice: (map['propertyPrice'] ?? 0.0).toDouble(),
      propertyThumbnail: map['propertyThumbnail']?.toString() ?? '',
      otherUserId: map['otherUserId']?.toString() ?? '',
      otherUserName: map['otherUserName']?.toString() ?? '',
      lastMessage: map['lastMessage']?.toString() ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: map['unreadCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      deletedByTenant: map['deletedByTenant'] ?? false,
      deletedByLandlord: map['deletedByLandlord'] ?? false,
    );
  }
  
  // Helper to generate unique chat ID based on participants + property
  static String generateChatId(String userId1, String userId2, String propertyId) {
    final sortedUsers = [userId1, userId2]..sort();
    return '${sortedUsers[0]}_${sortedUsers[1]}_$propertyId';
  }
}
