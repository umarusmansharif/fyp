import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/models/order_model.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/models/notification_model.dart';
import 'package:renthouse/models/chat_model.dart';
import 'package:renthouse/models/message_model.dart';
import 'package:renthouse/models/favorite_model.dart';
import 'package:renthouse/models/review_model.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/services/cloudinary_service.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get all houses
  Stream<List<HouseModel>> getHouses() {
    return _firestore
        .collection(AppConstants.housesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HouseModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Get houses by landlord
  Stream<List<HouseModel>> getHousesByLandlord(String landlordId) {
    return _firestore
        .collection(AppConstants.housesCollection)
        .where('landlordId', isEqualTo: landlordId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HouseModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Add a new house
  Future<void> addHouse(HouseModel house) async {
    try {
      await _firestore
          .collection(AppConstants.housesCollection)
          .doc(house.houseId)
          .set(house.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Get house by ID
  Future<HouseModel?> getHouseById(String houseId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(AppConstants.housesCollection).doc(houseId).get();
      
      if (doc.exists) {
        return HouseModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Create order
  Future<void> createOrder(OrderModel order) async {
    try {
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(order.orderId)
          .set(order.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Get orders for a landlord
  Stream<List<OrderModel>> getOrdersForLandlord(String landlordId) {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .where('landlordId', isEqualTo: landlordId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Get orders for a tenant
  Stream<List<OrderModel>> getOrdersForTenant(String tenantId) {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Create notification
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Get notifications for a landlord
  Stream<List<NotificationModel>> getNotificationsForLandlord(String landlordId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('landlordId', isEqualTo: landlordId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      rethrow;
    }
  }

  // Update house
  Future<void> updateHouse(HouseModel house) async {
    try {
      await _firestore
          .collection(AppConstants.housesCollection)
          .doc(house.houseId)
          .update({
            'title': house.title,
            'price': house.price,
            'description': house.description,
            'location': house.location,
            'latitude': house.latitude,
            'longitude': house.longitude,
            'area': house.area,
            'houseType': house.houseType,
            'numberOfRooms': house.numberOfRooms,
            'images': house.images,
            'imageUrl': house.images.isNotEmpty ? house.images.first : '',
            'amenities': house.amenities,
            'status': house.status,
            'updatedAt': house.updatedAt,
            // Note: We don't update landlordId, houseId, or createdAt as these shouldn't change
          });
    } catch (e) {
      rethrow;
    }
  }

  // Delete house
  Future<void> deleteHouse(String houseId) async {
    try {
      // First get the house to retrieve the image URL
      final house = await getHouseById(houseId);
      if (house != null && house.imageUrl.isNotEmpty) {
        // Check if it's a Cloudinary URL (not the default asset image)
        if (house.imageUrl.contains('cloudinary.com')) {
          // Attempt to delete the image from Cloudinary
          bool imageDeleted = await CloudinaryService.deleteImageFromCloudinary(house.imageUrl);
          if (!imageDeleted) {
            print('Warning: Could not delete image from Cloudinary: ${house.imageUrl}');
          }
        }
      }
      
      // Delete the house document from Firestore
      await _firestore
          .collection(AppConstants.housesCollection)
          .doc(houseId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile image
  Future<void> updateUserProfileImage(String userId, String profileImageUrl) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'profileImage': profileImageUrl});
    } catch (e) {
      rethrow;
    }
  }

  // ==================== SEARCH & FILTER METHODS ====================

  // Search houses with filters
  Stream<List<HouseModel>> searchHouses({
    String? query,
    double? minPrice,
    double? maxPrice,
    String? propertyType,
    int? rooms,
    List<String>? amenities,
    String? status,
  }) {
    Query queryRef = _firestore
        .collection(AppConstants.housesCollection)
        .orderBy('createdAt', descending: true);

    // Apply filters
    if (minPrice != null) {
      queryRef = queryRef.where('price', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      queryRef = queryRef.where('price', isLessThanOrEqualTo: maxPrice);
    }
    if (propertyType != null && propertyType.isNotEmpty) {
      queryRef = queryRef.where('houseType', isEqualTo: propertyType);
    }
    if (rooms != null && rooms > 0) {
      queryRef = queryRef.where('numberOfRooms', isEqualTo: rooms);
    }
    if (status != null && status.isNotEmpty) {
      queryRef = queryRef.where('status', isEqualTo: status);
    }

    return queryRef.snapshots().map((snapshot) {
      List<HouseModel> houses = snapshot.docs
          .map((doc) => HouseModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply client-side filters for text search and amenities
      if (query != null && query.isNotEmpty) {
        houses = houses.where((house) {
          final searchText = query.toLowerCase();
          return house.title.toLowerCase().contains(searchText) ||
              house.description.toLowerCase().contains(searchText) ||
              house.location.toLowerCase().contains(searchText);
        }).toList();
      }

      if (amenities != null && amenities.isNotEmpty) {
        houses = houses.where((house) {
          return amenities.every((amenity) => house.amenities.contains(amenity));
        }).toList();
      }

      return houses;
    });
  }

  // Get available houses only
  Stream<List<HouseModel>> getAvailableHouses() {
    return _firestore
        .collection(AppConstants.housesCollection)
        .where('status', isEqualTo: AppConstants.propertyStatusAvailable)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HouseModel.fromMap(doc.data()))
          .toList();
    });
  }

  // ==================== FAVORITES METHODS ====================

  // Add to favorites
  Future<void> addToFavorites(String userId, String propertyId) async {
    try {
      final favoriteId = const Uuid().v4();
      final favorite = FavoriteModel(
        id: favoriteId,
        userId: userId,
        propertyId: propertyId,
        addedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.favoritesCollection)
          .doc(favoriteId)
          .set(favorite.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String userId, String propertyId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.favoritesCollection)
          .where('userId', isEqualTo: userId)
          .where('propertyId', isEqualTo: propertyId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get user favorites
  Stream<List<HouseModel>> getUserFavorites(String userId) {
    return _firestore
        .collection(AppConstants.favoritesCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<HouseModel> favorites = [];
      for (var doc in snapshot.docs) {
        final favorite = FavoriteModel.fromMap(doc.data(), doc.id);
        final house = await getHouseById(favorite.propertyId);
        if (house != null) {
          favorites.add(house);
        }
      }
      return favorites;
    });
  }

  // Check if property is favorited
  Future<bool> isFavorite(String userId, String propertyId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.favoritesCollection)
          .where('userId', isEqualTo: userId)
          .where('propertyId', isEqualTo: propertyId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ==================== CHAT METHODS ====================

  // Create or get existing chat
  Future<String> createOrGetChat(String tenantId, String landlordId, String? propertyId) async {
    try {
      // Check if chat already exists
      final existingChat = await _firestore
          .collection(AppConstants.chatsCollection)
          .where('tenantId', isEqualTo: tenantId)
          .where('landlordId', isEqualTo: landlordId)
          .limit(1)
          .get();

      if (existingChat.docs.isNotEmpty) {
        return existingChat.docs.first.id;
      }

      // Create new chat
      final chatId = const Uuid().v4();
      final chat = ChatModel(
        chatId: chatId,
        tenantId: tenantId,
        landlordId: landlordId,
        propertyId: propertyId,
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .set(chat.toMap());

      return chatId;
    } catch (e) {
      rethrow;
    }
  }

  // Get user chats
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .where('tenantId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .asyncMap((tenantSnapshot) async {
      final tenantChats = tenantSnapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data()))
          .toList();

      // Also get chats where user is landlord
      final landlordSnapshot = await _firestore
          .collection(AppConstants.chatsCollection)
          .where('landlordId', isEqualTo: userId)
          .orderBy('lastMessageAt', descending: true)
          .get();

      final landlordChats = landlordSnapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data()))
          .toList();

      // Combine and sort
      final allChats = [...tenantChats, ...landlordChats];
      allChats.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

      return allChats;
    });
  }

  // Get chat messages
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection(AppConstants.messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Send message
  Future<void> sendMessage(MessageModel message) async {
    try {
      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(message.messageId)
          .set(message.toMap());

      // Update chat's last message time
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(message.chatId)
          .update({
        'lastMessageAt': Timestamp.fromDate(message.timestamp),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      rethrow;
    }
  }

  // Mark all messages in chat as read
  Future<void> markAllMessagesAsRead(String chatId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }

      // Reset unread count in chat
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .update({'unreadCount': 0});
    } catch (e) {
      rethrow;
    }
  }

  // ==================== REVIEWS METHODS ====================

  // Add review
  Future<void> addReview(ReviewModel review) async {
    try {
      await _firestore
          .collection(AppConstants.reviewsCollection)
          .doc(review.reviewId)
          .set(review.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Get property reviews
  Stream<List<ReviewModel>> getPropertyReviews(String propertyId) {
    return _firestore
        .collection(AppConstants.reviewsCollection)
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Get property average rating
  Future<double> getPropertyAverageRating(String propertyId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.reviewsCollection)
          .where('propertyId', isEqualTo: propertyId)
          .get();

      if (snapshot.docs.isEmpty) {
        return 0.0;
      }

      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();

      final totalRating = reviews.fold(0, (currentSum, review) => currentSum + review.rating);
      return totalRating / reviews.length;
    } catch (e) {
      return 0.0;
    }
  }

  // Get review count for a property
  Stream<int> getReviewCount(String propertyId) {
    return _firestore
        .collection(AppConstants.reviewsCollection)
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ==================== PROPERTY STATUS METHODS ====================

  // Update property status
  Future<void> updatePropertyStatus(String propertyId, String status) async {
    try {
      await _firestore
          .collection(AppConstants.housesCollection)
          .doc(propertyId)
          .update({
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==================== ADMIN METHODS ====================

  // Get all users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Block/unblock user
  Future<void> updateUserBlockStatus(String userId, bool isBlocked) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'isBlocked': isBlocked});
    } catch (e) {
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get all properties
  Stream<List<HouseModel>> getAllProperties() {
    return _firestore
        .collection(AppConstants.housesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HouseModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Get system statistics
  Future<Map<String, int>> getSystemStats() async {
    try {
      final usersSnapshot = await _firestore.collection(AppConstants.usersCollection).count().get();
      final housesSnapshot = await _firestore.collection(AppConstants.housesCollection).count().get();
      final ordersSnapshot = await _firestore.collection(AppConstants.ordersCollection).count().get();

      return {
        'totalUsers': usersSnapshot.count ?? 0,
        'totalProperties': housesSnapshot.count ?? 0,
        'totalOrders': ordersSnapshot.count ?? 0,
      };
    } catch (e) {
      return {
        'totalUsers': 0,
        'totalProperties': 0,
        'totalOrders': 0,
      };
    }
  }
}