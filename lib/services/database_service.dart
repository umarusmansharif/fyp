import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/models/order_model.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/models/notification_model.dart';
import 'package:renthouse/core/constants.dart';

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
}