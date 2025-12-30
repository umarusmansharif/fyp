import 'package:flutter/material.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/models/order_model.dart';
import 'package:renthouse/models/notification_model.dart';
import 'package:renthouse/screens/order_detail_screen.dart';
import 'package:renthouse/services/database_service.dart';
import 'package:renthouse/utils/helpers.dart';
import 'package:renthouse/widgets/custom_app_bar.dart';
import 'package:renthouse/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class HouseDetailScreen extends StatefulWidget {
  final HouseModel house;
  final UserModel? currentUser;

  const HouseDetailScreen({
    Key? key,
    required this.house,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<HouseDetailScreen> createState() => _HouseDetailScreenState();
}

class _HouseDetailScreenState extends State<HouseDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();

  Future<void> _requestHouse() async {
    if (widget.currentUser == null) return;

    try {
      // Create order
      final orderId = const Uuid().v4();
      final order = OrderModel(
        orderId: orderId,
        houseId: widget.house.houseId,
        tenantId: widget.currentUser!.uid,
        landlordId: widget.house.landlordId,
        status: AppConstants.orderStatusPending,
        createdAt: DateTime.now(),
      );

      await _databaseService.createOrder(order);

      // Create notification for landlord
      final notificationId = const Uuid().v4();
      final notification = NotificationModel(
        id: notificationId,
        landlordId: widget.house.landlordId,
        tenantId: widget.currentUser!.uid,
        houseId: widget.house.houseId,
        message: '${widget.currentUser!.name} is interested in your property',
        createdAt: DateTime.now(),
      );

      await _databaseService.createNotification(notification);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent successfully!'),
        ),
      );

      // Navigate to order detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: order),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _contactViaWhatsApp() async {
    try {
      // Get landlord details
      final landlord = await _databaseService.getUser(widget.house.landlordId);
      if (landlord == null) {
        throw 'Landlord not found';
      }

      final message = 'I am interested in your house listing.';
      await Helpers.launchWhatsApp(landlord.phone, message);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'House Details',
        onBackPress: () {
          Navigator.pop(context);
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // House image
            Container(
              width: double.infinity,
              height: 250,
              child: widget.house.imageUrl.isNotEmpty
                ? Image.network(
                    widget.house.imageUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        AppConstants.defaultHouseImage,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    AppConstants.defaultHouseImage,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // House title and price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.house.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        Helpers.formatCurrency(widget.house.price),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.house.location,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.house.description,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Additional details with icons
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildIconDetailRow(Icons.square_foot, 'Area', '${widget.house.area} Marla'),
                  _buildIconDetailRow(Icons.home, 'Type', widget.house.houseType),
                  _buildIconDetailRow(Icons.location_on, 'Location', widget.house.location),
                  const SizedBox(height: 20),
                  // Landlord info
                  const Text(
                    'Landlord',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<UserModel?>(
                    future: _databaseService.getUser(widget.house.landlordId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Text('Landlord information not available');
                      }

                      final landlord = snapshot.data!;
                      return _buildDetailRow('Name', landlord.name);
                    },
                  ),
                  const SizedBox(height: 30),
                  // Action buttons - full width, separate lines
                  if (widget.currentUser?.userType == AppConstants.userTypeTenant)
                    Column(
                      children: [
                        CustomButton(
                          text: 'Request House',
                          onPressed: _requestHouse,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          text: 'WhatsApp',
                          onPressed: _contactViaWhatsApp,
                          color: Colors.green,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}