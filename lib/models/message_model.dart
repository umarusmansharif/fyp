import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, system } // Added system type

class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type.name,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId']?.toString() ?? '',
      chatId: map['chatId']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      imageUrl: map['imageUrl'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
    );
  }
  
  // Helper to create system messages
  factory MessageModel.system({
    required String messageId,
    required String chatId,
    required String content,
    required DateTime timestamp,
  }) {
    return MessageModel(
      messageId: messageId,
      chatId: chatId,
      senderId: 'system',
      content: content,
      timestamp: timestamp,
      type: MessageType.system,
    );
  }
}
