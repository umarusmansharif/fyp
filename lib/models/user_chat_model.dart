import 'package:cloud_firestore/cloud_firestore.dart';

class UserChatModel {
  final String chatId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isDeleted;

  UserChatModel({
    required this.chatId,
    this.lastMessage = '',
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'isDeleted': isDeleted,
    };
  }

  factory UserChatModel.fromMap(Map<String, dynamic> map) {
    return UserChatModel(
      chatId: map['chatId']?.toString() ?? '',
      lastMessage: map['lastMessage']?.toString() ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: map['unreadCount'] ?? 0,
      isDeleted: map['isDeleted'] ?? false,
    );
  }
}
