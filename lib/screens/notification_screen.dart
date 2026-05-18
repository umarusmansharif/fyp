import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:renthouse/models/chat_model.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/screens/house_detail_screen.dart';
import 'package:renthouse/screens/chat_detail_screen.dart';
import 'package:renthouse/screens/profile_screen.dart';
import 'package:renthouse/screens/visit_requests_screen.dart';
import 'package:renthouse/services/notification_service.dart';
import 'package:renthouse/services/database_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _notificationService.markAllNotificationsAsRead(user.uid);
    }
  }

  Future<void> _clearAllNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _notificationService.clearAllNotifications(user.uid);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing notifications: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all notifications',
            onPressed: _clearAllNotifications,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationService.getUserNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(notification);
            },
          );
        },
      ),
    );
  }

  Widget _getIconForNotification(String? type) {
    switch (type) {
      case 'property_request':
        return const Icon(Icons.home, color: Colors.blue);
      case 'request_response':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'chat_message':
        return const Icon(Icons.chat, color: Colors.purple);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  Widget _buildNotificationItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return const SizedBox.shrink();

    final notificationData = data['data'] as Map<String, dynamic>?;
    final type = notificationData?['type'] ?? '';

    if (kDebugMode) {
      print('========== BUILDING NOTIFICATION ITEM ==========');
      print('Document ID: ${doc.id}');
      print('Firestore Data: $data');
      print('Notification Data: $notificationData');
      print('Type: $type');
      print('Target Role from Firestore: ${notificationData?['targetRole']}');
      print('Property ID from Firestore: ${notificationData?['propertyId']}');
      print('================================================');
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _getIconForNotification(type),
        title: Text(
          data['title'] ?? 'Notification',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(data['body'] ?? ''),
        trailing: _formatTimestamp(data['createdAt']),
        onTap: () => _handleNotificationTap(type, notificationData ?? {}),
      ),
    );
  }

  Future<void> _handleNotificationTap(String type, Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (kDebugMode) {
        print('========== NOTIFICATION TAP ERROR ==========');
        print('User is null - cannot handle notification tap');
        print('===========================================');
      }
      return;
    }

    final targetRole = data['targetRole'];

    if (kDebugMode) {
      print('========== NOTIFICATION TAP HANDLER ==========');
      print('Type: $type');
      print('Target Role: $targetRole');
      print('Full Data: $data');
      print('Property ID: ${data['propertyId']}');
      print('Chat ID: ${data['chatId']}');
      print('User ID: ${user.uid}');
      print('================================================');
    }

    switch (type) {
      case 'chat_message':
        if (kDebugMode) {
          print('Branch: chat_message');
        }
        final chatId = data['chatId'];
        if (chatId != null) {
          await _navigateToChat(chatId, user.uid);
        } else {
          if (kDebugMode) {
            print('ERROR: chatId is null');
          }
        }
        break;
      case 'property_request':
        if (kDebugMode) {
          print('Branch: property_request');
          print('Target Role check: $targetRole');
        }
        // Landlord receiving request - navigate to Visit Requests screen
        // property_request is always for landlords - if targetRole is null, it's an old notification
        if (targetRole == 'landlord' || targetRole == null) {
          if (kDebugMode) {
            print('Navigating to Visit Requests screen');
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VisitRequestsScreen()),
          );
        } else {
          if (kDebugMode) {
            print('ERROR: targetRole is not landlord, it is: $targetRole');
          }
        }
        break;
      case 'request_response':
        if (kDebugMode) {
          print('Branch: request_response');
        }
        // Tenant receiving accept/reject - navigate to related property
        if (targetRole == 'tenant') {
          final propertyId = data['propertyId'];
          if (propertyId != null) {
            await _navigateToProperty(propertyId);
          } else {
            if (kDebugMode) {
              print('ERROR: propertyId is null');
            }
          }
        }
        break;
      default:
        if (kDebugMode) {
          print('ERROR: Unknown notification type: $type');
        }
    }
  }

  Future<void> _navigateToLandlordRequests() async {
    try {
      if (kDebugMode) {
        print('Navigating to landlord profile screen');
      }
      
      if (mounted) {
        // Pop all routes to go back to dashboard
        Navigator.popUntil(context, (route) => route.isFirst);
        
        // Navigate to profile screen directly
        final user = _auth.currentUser;
        if (user != null) {
          final userModel = await _databaseService.getUser(user.uid);
          if (userModel != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen(user: userModel)),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error navigating to landlord requests: $e');
      }
    }
  }

  Future<void> _navigateToChat(String chatId, String currentUserId) async {
    try {
      final chat = await _databaseService.getChatById(chatId);
      if (chat != null && mounted) {
        final otherUserId = chat.participants.firstWhere((id) => id != currentUserId);
        // Get user models from Firestore
        final currentUser = await _databaseService.getUser(currentUserId);
        final otherUser = await _databaseService.getUser(otherUserId);
        
        if (currentUser != null && otherUser != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                chat: chat,
                currentUser: currentUser,
                otherUser: otherUser,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error navigating to chat: $e');
      }
    }
  }

  Future<void> _navigateToProperty(String propertyId) async {
    try {
      final house = await _databaseService.getHouseById(propertyId);
      if (house != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HouseDetailScreen(house: house, currentUser: null),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error navigating to property: $e');
      }
    }
  }

  Widget _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return const Text('Just now');
      } else if (difference.inMinutes < 60) {
        return Text('${difference.inMinutes}m ago');
      } else if (difference.inHours < 24) {
        return Text('${difference.inHours}h ago');
      } else {
        return Text('${difference.inDays}d ago');
      }
    }
    return const SizedBox.shrink();
  }
}
