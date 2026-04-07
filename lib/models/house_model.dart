import 'package:cloud_firestore/cloud_firestore.dart';

class HouseModel {
  final String houseId;
  final String landlordId;
  final String title;
  final double price;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final double area; // in marla
  final String houseType;
  final int numberOfRooms;
  final List<String> images;
  final List<String> amenities;
  final String status; // available, rented, unavailable
  final DateTime createdAt;
  final DateTime? updatedAt;

  HouseModel({
    required this.houseId,
    required this.landlordId,
    required this.title,
    required this.price,
    required this.description,
    required this.location,
    this.latitude = 0.0,
    this.longitude = 0.0,
    required this.area,
    required this.houseType,
    this.numberOfRooms = 0,
    this.images = const [],
    this.amenities = const [],
    this.status = 'available',
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'houseId': houseId,
      'landlordId': landlordId,
      'title': title,
      'price': price,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'area': area,
      'houseType': houseType,
      'numberOfRooms': numberOfRooms,
      'images': images,
      'amenities': amenities,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory HouseModel.fromMap(Map<String, dynamic> map) {
    return HouseModel(
      houseId: map['houseId']?.toString() ?? '',
      landlordId: map['landlordId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      price: (map['price'] != null) ? (map['price'] as num).toDouble() : 0.0,
      description: map['description']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      latitude: (map['latitude'] != null) ? (map['latitude'] as num).toDouble() : 0.0,
      longitude: (map['longitude'] != null) ? (map['longitude'] as num).toDouble() : 0.0,
      area: (map['area'] != null) ? (map['area'] as num).toDouble() : 0.0,
      houseType: map['houseType']?.toString() ?? '',
      numberOfRooms: map['numberOfRooms'] ?? 0,
      images: map['images'] != null ? List<String>.from(map['images']) : [],
      amenities: map['amenities'] != null ? List<String>.from(map['amenities']) : [],
      status: map['status']?.toString() ?? 'available',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Helper method to get primary image (for backward compatibility)
  String get imageUrl => images.isNotEmpty ? images.first : '';
}