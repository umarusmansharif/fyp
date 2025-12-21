class AppConstants {
  static const String appName = 'Smart House Rent';
  static const String splashImage = 'assets/images/image2.png';
  static const String houseImage = 'assets/images/image1.png';
  static const String defaultProfileImage = 'assets/images/image1.png';
  
  // Collection names in Firestore
  static const String usersCollection = 'users';
  static const String housesCollection = 'houses';
  static const String ordersCollection = 'orders';
  static const String notificationsCollection = 'notifications';
  
  // User types
  static const String userTypeTenant = 'tenant';
  static const String userTypeLandlord = 'landlord';
  
  // Order statuses
  static const String orderStatusPending = 'pending';
  static const String orderStatusAccepted = 'accepted';
  static const String orderStatusRejected = 'rejected';
}