import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final List<String> participants; // [userA, userB]
  final String propertyId; // Each chat tied to a property
  final String lastMessage; // Last message preview
  final DateTime createdAt;
  final DateTime lastMessageAt;

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.propertyId,
    this.lastMessage = '',
    required this.createdAt,
    required this.lastMessageAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'propertyId': propertyId,
      'lastMessage': lastMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    // Handle backward compatibility with old chat format
    List<String> participants = [];
    if (map['participants'] != null) {
      participants = List<String>.from(map['participants']);
    } else if (map['tenantId'] != null && map['landlordId'] != null) {
      // Old format: migrate tenantId and landlordId to participants
      participants = [map['tenantId'].toString(), map['landlordId'].toString()];
    }

    return ChatModel(
      chatId: map['chatId']?.toString() ?? '',
      participants: participants,
      propertyId: map['propertyId']?.toString() ?? '',
      lastMessage: map['lastMessage']?.toString() ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate() ?? (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  // Helper to generate unique chat ID based on participants + property
  static String generateChatId(String userId1, String userId2, String propertyId) {
    final sortedUsers = [userId1, userId2]..sort();
    return '${sortedUsers[0]}_${sortedUsers[1]}_$propertyId';
  }
}
