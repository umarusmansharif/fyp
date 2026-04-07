import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:renthouse/models/chat_model.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/screens/chat_detail_screen.dart';
import 'package:renthouse/services/auth_service.dart';
import 'package:renthouse/services/database_service.dart';

class ChatListScreen extends StatefulWidget {
  final UserModel? currentUser;

  const ChatListScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.getCurrentUser()?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        body: const Center(
          child: Text('Please login to view messages'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: _databaseService.getUserChats(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation with a landlord or tenant',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat.tenantId == userId
                  ? chat.landlordId
                  : chat.tenantId;

              return FutureBuilder<UserModel?>(
                future: _databaseService.getUser(otherUserId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      title: Text('Loading...'),
                      subtitle: CircularProgressIndicator(),
                    );
                  }

                  final otherUser = userSnapshot.data!;

                  return StreamBuilder<int>(
                    stream: _getUnreadCount(chat.chatId, userId),
                    builder: (context, unreadSnapshot) {
                      final unreadCount = unreadSnapshot.data ?? 0;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage: otherUser.profileImage != null &&
                                  otherUser.profileImage!.isNotEmpty
                              ? NetworkImage(otherUser.profileImage!)
                                  as ImageProvider
                              : const AssetImage('assets/images/image1.png'),
                          backgroundColor: Colors.grey[200],
                          child: otherUser.profileImage == null ||
                                  otherUser.profileImage!.isEmpty
                              ? Icon(
                                  Icons.person,
                                  color: Colors.grey[500],
                                )
                              : null,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                otherUser.name,
                                style: TextStyle(
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          'Tap to start chatting',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          DateFormat('hh:mm a').format(chat.lastMessageAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                chat: chat,
                                currentUser: widget.currentUser,
                                otherUser: otherUser,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Stream<int> _getUnreadCount(String chatId, String userId) {
    return _databaseService.getChatMessages(chatId).map((messages) {
      return messages
          .where((msg) => msg.senderId != userId && !msg.isRead)
          .length;
    });
  }
}
