class AppConstants {
  static const String appName = 'Smart House Rent';
  // Asset images - used for app logos and default images
  static const String splashImage = 'assets/images/image1.png';
  static const String defaultProfileImage = 'assets/images/image1.png';
  
  // Default image for houses when no Cloudinary URL is available
  static const String defaultHouseImage = 'assets/images/image1.png';
  
  // Collection names in Firestore
  static const String usersCollection = 'users';
  static const String housesCollection = 'houses';
  static const String ordersCollection = 'orders';
  static const String notificationsCollection = 'notifications';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String favoritesCollection = 'favorites';
  static const String reviewsCollection = 'reviews';
  
  // User types
  static const String userTypeTenant = 'tenant';
  static const String userTypeLandlord = 'landlord';
  static const String userTypeAdmin = 'admin';
  
  // Order statuses
  static const String orderStatusPending = 'pending';
  static const String orderStatusAccepted = 'accepted';
  static const String orderStatusRejected = 'rejected';
  
  // Property statuses
  static const String propertyStatusAvailable = 'available';
  static const String propertyStatusRented = 'rented';
  static const String propertyStatusUnavailable = 'unavailable';
}