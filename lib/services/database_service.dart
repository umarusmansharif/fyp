import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/models/order_model.dart';
import 'package:renthouse/models/chat_model.dart';
import 'package:renthouse/models/message_model.dart';
import 'package:renthouse/models/user_chat_model.dart';
import 'package:renthouse/models/favorite_model.dart';
import 'package:renthouse/models/review_model.dart';
import 'package:renthouse/models/notification_model.dart';
import 'package:renthouse/services/cloudinary_service.dart';
import 'package:renthouse/services/notification_service.dart';
import 'package:renthouse/utils/helpers.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

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
  Stream<List<HouseModel>> getHouses({String? userId, String? userType}) {
    Query query = _firestore
        .collection(AppConstants.housesCollection)
        .orderBy('createdAt', descending: true);
    
    // Filter out rented properties for tenants at query level
    if (userType == AppConstants.userTypeTenant) {
      query = query.where('status', isEqualTo: AppConstants.propertyStatusAvailable);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => HouseModel.fromMap(doc.data() as Map<String, dynamic>))
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

  // Update house status
  Future<void> updateHouseStatus(String houseId, String status) async {
    try {
      await _firestore
          .collection(AppConstants.housesCollection)
          .doc(houseId)
          .update({'status': status});
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

  // Create or get chat between two users for a property
  Future<ChatModel> createOrGetChat({
    required String tenantId,
    required String landlordId,
    required String propertyId,
    required String propertyTitle,
    required String propertyLocation,
    required double propertyPrice,
  }) async {
    try {
      final chatId = ChatModel.generateChatId(tenantId, landlordId, propertyId);
      
      // Check if user has deleted this chat
      final userChatDoc = await _firestore
          .collection('userChats')
          .doc(tenantId)
          .collection('chats')
          .doc(chatId)
          .get();
      
      if (userChatDoc.exists) {
        final userChatData = userChatDoc.data()!;
        final isDeleted = userChatData['isDeleted'] ?? false;
        
        if (isDeleted) {
          // Chat was deleted by this user, create a new one with timestamp
          return await _createNewChatWithTimestamp(
            tenantId, landlordId, propertyId,
            propertyTitle, propertyLocation, propertyPrice,
          );
        }
        
        // Chat exists and not deleted, return it
        final chatDoc = await _firestore
            .collection(AppConstants.chatsCollection)
            .doc(chatId)
            .get();
        
        if (chatDoc.exists) {
          return ChatModel.fromMap(chatDoc.data()!);
        }
      }
      
      // Check if chat document exists (for other user)
      final existingChat = await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .get();
      
      if (existingChat.exists) {
        // Chat exists but user hasn't deleted it, create userChats entry
        await _createUserChatEntries(chatId, tenantId, landlordId);
        return ChatModel.fromMap(existingChat.data()!);
      }
      
      // Create new chat
      final now = DateTime.now();
      final newChat = ChatModel(
        chatId: chatId,
        participants: [tenantId, landlordId],
        propertyId: propertyId,
        lastMessage: '',
        createdAt: now,
        lastMessageAt: now,
      );
      
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .set(newChat.toMap());
      
      // Create userChats entries for both users
      await _createUserChatEntries(chatId, tenantId, landlordId);
      
      // Send default first message
      await _sendDefaultFirstMessage(
        chatId: chatId,
        senderId: tenantId,
        propertyTitle: propertyTitle,
        propertyLocation: propertyLocation,
        propertyPrice: propertyPrice,
      );
      
      return newChat;
    } catch (e) {
      rethrow;
    }
  }

  // Create userChats entries for both participants
  Future<void> _createUserChatEntries(String chatId, String tenantId, String landlordId) async {
    final now = DateTime.now();
    
    // Create entry for tenant
    await _firestore
        .collection('userChats')
        .doc(tenantId)
        .collection('chats')
        .doc(chatId)
        .set(UserChatModel(
          chatId: chatId,
          lastMessage: '',
          lastMessageTime: now,
          unreadCount: 0,
          isDeleted: false,
        ).toMap());
    
    // Create entry for landlord
    await _firestore
        .collection('userChats')
        .doc(landlordId)
        .collection('chats')
        .doc(chatId)
        .set(UserChatModel(
          chatId: chatId,
          lastMessage: '',
          lastMessageTime: now,
          unreadCount: 0,
          isDeleted: false,
        ).toMap());
  }

  // Send default first message
  Future<void> _sendDefaultFirstMessage({
    required String chatId,
    required String senderId,
    required String propertyTitle,
    required String propertyLocation,
    required double propertyPrice,
  }) async {
    final message = MessageModel(
      messageId: const Uuid().v4(),
      chatId: chatId,
      senderId: senderId,
      content: 'Hi, I\'m interested in this property and would like to discuss further.\n\nProperty: $propertyTitle\nLocation: $propertyLocation\nPrice: ${Helpers.formatCurrency(propertyPrice)}',
      timestamp: DateTime.now(),
      type: MessageType.text,
      readBy: [senderId], // Sender has read their own message
    );
    
    await sendMessage(message, currentActiveChatId: chatId);
  }

  // Create new chat with timestamp-based ID (for re-chat after delete)
  Future<ChatModel> _createNewChatWithTimestamp(
    String tenantId,
    String landlordId,
    String propertyId,
    String propertyTitle,
    String propertyLocation,
    double propertyPrice,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newChatId = '${tenantId}_${landlordId}_$propertyId$timestamp';
    
    final now = DateTime.now();
    final newChat = ChatModel(
      chatId: newChatId,
      participants: [tenantId, landlordId],
      propertyId: propertyId,
      lastMessage: '',
      createdAt: now,
      lastMessageAt: now,
    );
    
    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(newChatId)
        .set(newChat.toMap());
    
    // Create userChats entries for both users
    await _createUserChatEntries(newChatId, tenantId, landlordId);
    
    // Send default first message
    await _sendDefaultFirstMessage(
      chatId: newChatId,
      senderId: tenantId,
      propertyTitle: propertyTitle,
      propertyLocation: propertyLocation,
      propertyPrice: propertyPrice,
    );
    
    return newChat;
  }

  // Delete chat for current user (per-user delete)
  Future<void> deleteChat(String chatId, String userId) async {
    try {
      // Set isDeleted flag in userChats
      await _firestore
          .collection('userChats')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .update({'isDeleted': true});
    } catch (e) {
      rethrow;
    }
  }

  // Get user chats - Uses userChats collection for proper per-user control
  // Falls back to old chats collection if userChats doesn't exist (migration path)
  Stream<List<ChatModel>> getUserChats(String userId) async* {
    try {
      final userChatsStream = _firestore
          .collection('userChats')
          .doc(userId)
          .collection('chats')
          .where('isDeleted', isEqualTo: false)
          .orderBy('lastMessageTime', descending: true)
          .snapshots();

      await for (final userChatsSnapshot in userChatsStream) {
        try {
          final userChats = userChatsSnapshot.docs
              .map((doc) => UserChatModel.fromMap(doc.data()))
              .toList();

          // Fetch actual chat documents
          final chatIds = userChats.map((uc) => uc.chatId).toList();
          if (chatIds.isEmpty) {
            yield [];
            continue;
          }

          final chatsSnapshot = await _firestore
              .collection(AppConstants.chatsCollection)
              .where(FieldPath.documentId, whereIn: chatIds)
              .get();

          final chats = chatsSnapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data()))
              .toList();

          // Sort by lastMessageTime from userChats
          chats.sort((a, b) {
            final aTime = userChats.firstWhere((uc) => uc.chatId == a.chatId).lastMessageTime;
            final bTime = userChats.firstWhere((uc) => uc.chatId == b.chatId).lastMessageTime;
            return bTime.compareTo(aTime);
          });

          yield chats;
        } catch (e) {
          if (kDebugMode) {
            print('Error processing userChats: $e');
          }
          yield [];
        }
      }
    } catch (e) {
      // Fallback: Query old chats collection where user is a participant
      if (kDebugMode) {
        print('userChats collection not found, falling back to old format: $e');
      }
      
      // Query both new format (participants) and old format (tenantId/landlordId)
      // We need to do this without rxdart by combining the results
      
      yield* _firestore
          .collection(AppConstants.chatsCollection)
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageAt', descending: true)
          .snapshots()
          .asyncMap((participantsSnapshot) async {
            final participantsChats = participantsSnapshot.docs
                .map((doc) => ChatModel.fromMap(doc.data()))
                .toList();
            
            // Also query old format chats
            final tenantSnapshot = await _firestore
                .collection(AppConstants.chatsCollection)
                .where('tenantId', isEqualTo: userId)
                .get();
            
            final landlordSnapshot = await _firestore
                .collection(AppConstants.chatsCollection)
                .where('landlordId', isEqualTo: userId)
                .get();
            
            final tenantChats = tenantSnapshot.docs
                .map((doc) => ChatModel.fromMap(doc.data()))
                .toList();
            
            final landlordChats = landlordSnapshot.docs
                .map((doc) => ChatModel.fromMap(doc.data()))
                .toList();
            
            // Combine and deduplicate by chatId
            final allChats = <String, ChatModel>{};
            for (final chat in participantsChats) {
              allChats[chat.chatId] = chat;
            }
            for (final chat in tenantChats) {
              allChats[chat.chatId] = chat;
            }
            for (final chat in landlordChats) {
              allChats[chat.chatId] = chat;
            }
            
            return allChats.values.toList()
              ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
          });
    }
  }
  
  // Update chat with last message
  Future<void> updateChatLastMessage(String chatId, String message) async {
    try {
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .update({
        'lastMessage': message,
        'lastMessageAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
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

  // Send message - Updates chat last message and userChats unread count
  Future<void> sendMessage(MessageModel message, {String? currentActiveChatId}) async {
    try {
      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(message.messageId)
          .set(message.toMap());

      // Get chat to determine participants
      final chatDoc = await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(message.chatId)
          .get();
      
      if (chatDoc.exists) {
        final chatData = chatDoc.data()!;
        final participants = List<String>.from(chatData['participants'] ?? []);
        
        // Determine recipient (the other user) with fallback
        String? recipientId;
        try {
          recipientId = participants.firstWhere((id) => id != message.senderId);
        } catch (e) {
          // Fallback to old format if participants array is not working
          if (chatData['tenantId'] != null && chatData['landlordId'] != null) {
            recipientId = message.senderId == chatData['tenantId'] 
                ? chatData['landlordId']?.toString() 
                : chatData['tenantId']?.toString();
          }
        }
        
        if (recipientId == null) {
          if (kDebugMode) {
            print('Could not determine recipient for message');
          }
          return;
        }
        
        // Update chat document
        await _firestore
            .collection(AppConstants.chatsCollection)
            .doc(message.chatId)
            .update({
          'lastMessage': message.content,
          'lastMessageAt': Timestamp.fromDate(message.timestamp),
        });

        // Update userChats for sender (unreadCount = 0)
        await _firestore
            .collection('userChats')
            .doc(message.senderId)
            .collection('chats')
            .doc(message.chatId)
            .update({
          'lastMessage': message.content,
          'lastMessageTime': Timestamp.fromDate(message.timestamp),
          'unreadCount': 0,
        });

        // Update userChats for recipient (unreadCount += 1)
        final recipientUserChatRef = _firestore
            .collection('userChats')
            .doc(recipientId)
            .collection('chats')
            .doc(message.chatId);
        
        // Check if recipient has deleted this chat
        final recipientUserChatDoc = await recipientUserChatRef.get();
        if (recipientUserChatDoc.exists && recipientUserChatDoc.data()?['isDeleted'] == true) {
          // Re-enable chat for recipient (delete = hide history, not block future messages)
          await recipientUserChatRef.update({
            'isDeleted': false,
            'unreadCount': 1,
            'lastMessage': message.content,
            'lastMessageTime': Timestamp.fromDate(message.timestamp),
          });
        } else {
          // Normal update
          await recipientUserChatRef.update({
            'lastMessage': message.content,
            'lastMessageTime': Timestamp.fromDate(message.timestamp),
            'unreadCount': FieldValue.increment(1),
          });
        }

        // Send push notification to recipient (only if they're not in the same chat)
        if (currentActiveChatId != message.chatId) {
          await _notificationService.sendNotification(
            recipientId: recipientId,
            title: 'New Message',
            body: 'You have received a new message',
            data: {
              'type': 'chat_message',
              'chatId': message.chatId,
              'senderId': message.senderId,
            },
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Mark all messages in chat as read for a user
  Future<void> markAllMessagesAsRead(String chatId, String userId) async {
    try {
      // Add userId to readBy for all messages not yet read by this user
      final snapshot = await _firestore
          .collection(AppConstants.messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('readBy', arrayContains: userId)
          .get();

      final readMessageIds = snapshot.docs.map((doc) => doc.id).toSet();

      final unreadSnapshot = await _firestore
          .collection(AppConstants.messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .get();

      for (var doc in unreadSnapshot.docs) {
        if (!readMessageIds.contains(doc.id)) {
          await doc.reference.update({
            'readBy': FieldValue.arrayUnion([userId])
          });
        }
      }

      // Reset unread count in userChats
      await _firestore
          .collection('userChats')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .update({'unreadCount': 0});
    } catch (e) {
      rethrow;
    }
  }

  // Get total unread count for a user across all chats (for dashboard badge)
  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection('userChats')
        .doc(userId)
        .collection('chats')
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + (doc.data()['unreadCount'] as int? ?? 0),
      );
    });
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