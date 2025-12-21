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
      'createdAt': createdAt,
    };
  }

  factory HouseModel.fromMap(Map<String, dynamic> map) {
    return HouseModel(
      houseId: map['houseId'] ?? '',
      landlordId: map['landlordId'] ?? '',
      title: map['title'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      area: (map['area'] ?? 0).toDouble(),
      houseType: map['houseType'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}