import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, system }

class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final List<String> readBy; // Array of user IDs who have read this message
  final MessageType type;

  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    List<String>? readBy,
    this.type = MessageType.text,
  }) : readBy = readBy ?? [];

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'readBy': readBy,
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
      readBy: List<String>.from(map['readBy'] ?? []),
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
