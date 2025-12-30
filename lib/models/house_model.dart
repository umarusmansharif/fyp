import 'package:cloud_firestore/cloud_firestore.dart';

class HouseModel {
  final String houseId;
  final String landlordId;
  final String title;
  final double price;
  final String description;
  final String location;
  final double area; // in marla
  final String houseType;
  final String imageUrl;
  final DateTime createdAt;

  HouseModel({
    required this.houseId,
    required this.landlordId,
    required this.title,
    required this.price,
    required this.description,
    required this.location,
    required this.area,
    required this.houseType,
    required this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'houseId': houseId,
      'landlordId': landlordId,
      'title': title,
      'price': price,
      'description': description,
      'location': location,
      'area': area,
      'houseType': houseType,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
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
      area: (map['area'] != null) ? (map['area'] as num).toDouble() : 0.0,
      houseType: map['houseType']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}