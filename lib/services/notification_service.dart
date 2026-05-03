import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:renthouse/core/constants.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize FCM and get token (placeholder - requires firebase_messaging package)
  Future<String?> initializeFCM() async {
    // TODO: Implement after adding firebase_messaging to pubspec.yaml
    if (kDebugMode) {
      print('FCM initialization not implemented - add firebase_messaging package');
    }
    return null;
  }

  // Save FCM token to Firestore
  Future<void> saveFCMToken(String userId, String? token) async {
    if (token == null || token.isEmpty) return;

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'fcmToken': token});
      if (kDebugMode) {
        print('FCM Token saved for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
    }
  }

  // Get user's FCM token
  Future<String?> getUserFCMToken(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  // Send notification via Cloud Functions (this would call your backend)
  // For now, this is a placeholder - you need to implement Cloud Functions
  // or use a service like OneSignal for sending notifications
  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final recipientToken = await getUserFCMToken(recipientId);
      
      if (recipientToken == null || recipientToken.isEmpty) {
        if (kDebugMode) {
          print('No FCM token found for user: $recipientId');
        }
        return;
      }

      // Save notification to Firestore for count tracking
      await _saveNotificationToFirestore(
        recipientId: recipientId,
        title: title,
        body: body,
        data: data,
      );

      // TODO: Implement actual notification sending via Cloud Functions
      // This would typically call a Cloud Function that uses FCM API
      if (kDebugMode) {
        print('Notification prepared for $recipientId: $title - $body');
        print('Data: $data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
    }
  }

  // Save notification to Firestore for count tracking
  Future<void> _saveNotificationToFirestore({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationRef = await _firestore
          .collection(AppConstants.notificationsCollection)
          .add({
        'recipientId': recipientId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Notification saved to Firestore: ${notificationRef.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving notification to Firestore: $e');
      }
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
    }
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get user notifications
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
