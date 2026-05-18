import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:renthouse/firebase_options.dart';
import 'package:renthouse/screens/splash_screen.dart';
import 'package:renthouse/screens/profile_screen.dart';
import 'package:renthouse/services/database_service.dart';
import 'package:renthouse/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:renthouse/services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final NotificationService _notificationService = NotificationService();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('========== BACKGROUND MESSAGE RECEIVED ==========');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
  print('=================================================');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await _notificationService.initializeFCM();
    
    // Initialize FCM
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('========== NOTIFICATION TAPPED (BACKGROUND) ==========');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
      print('=======================================================');
      _handleNotificationTap(message.data);
    });
    
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to initialize: $e'),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _handleTerminatedNotification();
  }

  Future<void> _handleTerminatedNotification() async {
    // Handle notification taps when app is terminated
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('========== NOTIFICATION TAPPED (TERMINATED) ==========');
      print('Title: ${initialMessage.notification?.title}');
      print('Body: ${initialMessage.notification?.body}');
      print('Data: ${initialMessage.data}');
      print('=======================================================');
      _handleNotificationTap(initialMessage.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Smart House Rent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const SplashScreen(),
    );
  }
}

void _handleNotificationTap(Map<String, dynamic> data) async {
  final type = data['type'];
  final targetRole = data['targetRole'];

  print('========== NAVIGATION HANDLER ==========');
  print('Type: $type');
  print('Target Role: $targetRole');
  print('Full Data: $data');
  print('======================================');

  if (type == 'property_request' && (targetRole == 'landlord' || targetRole == null)) {
    print('Navigating to landlord profile screen');
    
    final FirebaseAuth auth = FirebaseAuth.instance;
    final DatabaseService databaseService = DatabaseService();
    final user = auth.currentUser;
    
    if (user != null) {
      final userModel = await databaseService.getUser(user.uid);
      if (userModel != null && navigatorKey.currentState != null) {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => ProfileScreen(user: userModel)),
        );
      }
    }
  } else if (type == 'request_response' && targetRole == 'tenant') {
    final propertyId = data['propertyId'];
    if (propertyId != null) {
      print('Navigating to property: $propertyId');
      // TODO: Navigate to house detail screen
    }
  } else if (type == 'chat_message') {
    final chatId = data['chatId'];
    if (chatId != null) {
      print('Navigating to chat: $chatId');
      // TODO: Navigate to chat detail screen
    }
  }
}
