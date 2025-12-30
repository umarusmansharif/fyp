import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/models/order_model.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/models/notification_model.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/services/cloudinary_service.dart';

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
            'area': house.area,
            'houseType': house.houseType,
            'imageUrl': house.imageUrl,
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
}