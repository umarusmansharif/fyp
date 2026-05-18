import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:renthouse/core/constants.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Callback for notification tap
  Function(Map<String, dynamic>? data)? onNotificationTap;

  // Initialize FCM and get token
  Future<String?> initializeFCM() async {
    try {
      if (_isInitialized) {
        return await _fcm.getToken();
      }

      if (kDebugMode) {
        print('========== FCM INITIALIZATION START ==========');
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        providesAppNotificationSettings: false,
      );

      if (kDebugMode) {
        print('FCM Permission Status: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get token
        final token = await _fcm.getToken();
        if (kDebugMode) {
          print('========== FCM TOKEN ==========');
          print('FCM Token: $token');
          print('================================');
        }
        
        // Setup foreground message handler
        _setupForegroundMessageHandler();
        setupNotificationTapHandler();
        onTokenRefresh(FirebaseAuth.instance.currentUser?.uid ?? '');
        _isInitialized = true;
        
        return token;
      } else {
        if (kDebugMode) {
          print('FCM permission denied');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing FCM: $e');
      }
      return null;
    }
  }

  // Initialize local notifications for Android
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_ic_notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print('Local notification tapped: ${response.payload}');
        }
      },
    );

    // Create notification channel (Android 8.0+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      description: 'This channel is used for important notifications.',
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    if (kDebugMode) {
      print('Notification channel created: high_importance_channel');
    }
  }

  // Setup foreground message handler
  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('========== FOREGROUND MESSAGE RECEIVED ==========');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');
        print('=================================================');
      }

      // Show local notification when app is in foreground
      _showLocalNotification(message);
    });
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Listen to token refresh
  void onTokenRefresh(String userId) {
    if (userId.isEmpty) return;
    _fcm.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('========== FCM TOKEN REFRESHED ==========');
        print('New Token: $newToken');
        print('========================================');
      }
      saveFCMToken(userId, newToken);
    });
  }

  // Handle notification tap (deep linking)
  void setupNotificationTapHandler() {
    // Handle notification tap when app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notification tapped: ${message.data}');
      }
      if (onNotificationTap != null) {
        onNotificationTap!(message.data);
      }
    });

    // Handle notification tap when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('Initial notification: ${message.data}');
        }
        if (onNotificationTap != null) {
          onNotificationTap!(message.data);
        }
      }
    });
  }

  // Save FCM token to Firestore
  Future<void> saveFCMToken(String userId, String? token) async {
    if (token == null || token.isEmpty) return;

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .set({'fcmToken': token}, SetOptions(merge: true));
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

  // Send notification via FCM Cloud Function (NOT direct HTTP from client)
  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (kDebugMode) {
        print('========== SENDING NOTIFICATION ==========');
        print('Recipient ID: $recipientId');
        print('Title: $title');
        print('Body: $body');
        print('Data: $data');
        print('Target Role: ${data?['targetRole']}');
      }

      final recipientToken = await getUserFCMToken(recipientId);
      
      if (recipientToken == null || recipientToken.isEmpty) {
        if (kDebugMode) {
          print('No FCM token found for user: $recipientId - skipping notification');
        }
        return;
      }

      if (kDebugMode) {
        print('FCM token found for user: $recipientId');
      }

      // Save notification to Firestore for count tracking
      await _saveNotificationToFirestore(
        recipientId: recipientId,
        title: title,
        body: body,
        data: data,
      );

      // Trigger Cloud Function to send push notification
      await _triggerCloudFunctionSend(
        recipientToken: recipientToken,
        title: title,
        body: body,
        data: data,
      );

      if (kDebugMode) {
        print('Notification sent successfully to: $recipientId');
        print('========================================');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
    }
  }

  // Trigger Cloud Function to send push notification via Firestore
  Future<void> _triggerCloudFunctionSend({
    required String recipientToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (kDebugMode) {
        print('========== TRIGGERING CLOUD FUNCTION ==========');
        print('Token: $recipientToken');
        print('Title: $title');
        print('Body: $body');
        print('Data: $data');
      }

      // Create a document in a dedicated collection to trigger Cloud Function
      await _firestore.collection('fcm_triggers').add({
        'token': recipientToken,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      if (kDebugMode) {
        print('Cloud Function trigger created');
        print('================================================');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error triggering Cloud Function: $e');
      }
    }
  }

  // ==================== SPECIFIC NOTIFICATION METHODS ====================

  // Property Request Notification (Tenant → Landlord)
  Future<void> sendPropertyRequestNotification({
    required String landlordId,
    required String propertyId,
    String? propertyTitle,
    String? tenantName,
    String? requestId,
  }) async {
    final data = {
      'type': 'property_request',
      'targetRole': 'landlord',
      'propertyId': propertyId,
      if (requestId != null) 'requestId': requestId,
      if (propertyTitle != null) 'propertyTitle': propertyTitle,
      if (tenantName != null) 'tenantName': tenantName,
    };
    
    if (kDebugMode) {
      print('========== PROPERTY REQUEST NOTIFICATION CREATED ==========');
      print('Landlord ID: $landlordId');
      print('Property ID: $propertyId');
      print('FULL PAYLOAD: $data');
      print('Target Role: ${data['targetRole']}');
      print('Type: ${data['type']}');
      print('==========================================================');
    }
    
    await sendNotification(
      recipientId: landlordId,
      title: 'New Visit Request',
      body: tenantName != null && propertyTitle != null
          ? '$tenantName requested to visit $propertyTitle'
          : 'Someone requested to visit your property',
      data: data,
    );
  }

  // Request Response Notification (Landlord → Tenant)
  Future<void> sendRequestResponseNotification({
    required String tenantId,
    required bool isAccepted,
    required String propertyId,
    String? propertyTitle,
  }) async {
    if (kDebugMode) {
      print('sendRequestResponseNotification called for tenant: $tenantId, accepted: $isAccepted');
    }
    await sendNotification(
      recipientId: tenantId,
      title: isAccepted ? 'Request Accepted' : 'Request Update',
      body: isAccepted
          ? (propertyTitle != null
              ? 'Your visit request for $propertyTitle has been accepted'
              : 'Your visit request has been accepted')
          : (propertyTitle != null
              ? 'Your visit request for $propertyTitle was declined'
              : 'Your request was declined'),
      data: {
        'type': 'request_response',
        'targetRole': 'tenant',
        'status': isAccepted ? 'accepted' : 'rejected',
        'propertyId': propertyId,
        if (propertyTitle != null) 'propertyTitle': propertyTitle,
      },
    );
  }

  // Chat Message Notification (User → Other User)
  Future<void> sendChatMessageNotification({
    required String recipientId,
    required String chatId,
  }) async {
    if (kDebugMode) {
      print('sendChatMessageNotification called for recipient: $recipientId, chat: $chatId');
    }
    await sendNotification(
      recipientId: recipientId,
      title: 'New Message',
      body: 'You have received a new message',
      data: {
        'type': 'chat_message',
        'chatId': chatId,
      },
    );
  }

  // Save notification to Firestore for count tracking
  Future<void> _saveNotificationToFirestore({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (kDebugMode) {
        print('========== SAVING NOTIFICATION TO FIRESTORE ==========');
        print('Recipient ID: $recipientId');
        print('Title: $title');
        print('Body: $body');
        print('Data: $data');
        print('Target Role: ${data?['targetRole']}');
      }

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
        print('=======================================================');
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

  // Clear all notifications for a user
  Future<void> clearAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('recipientId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all notifications: $e');
      }
      rethrow;
    }
  }
}
