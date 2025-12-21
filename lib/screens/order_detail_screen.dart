import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/models/order_model.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/services/database_service.dart';
import 'package:renthouse/utils/helpers.dart';
import 'package:renthouse/widgets/custom_app_bar.dart';
import 'package:renthouse/widgets/custom_button.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();

  Future<void> _updateOrderStatus(String status) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.ordersCollection)
          .doc(widget.order.orderId)
          .update({'status': status});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated successfully!')),
      );
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
        title: 'Order Details',
        onBackPress: () {
          Navigator.pop(context);
        },
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order info
              const Text(
                'Order Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              _buildInfoCard('Order ID', widget.order.orderId),
              const SizedBox(height: 10),
              _buildInfoCard(
                  'Status', widget.order.status.toUpperCase()),
              const SizedBox(height: 10),
              _buildInfoCard(
                  'Created At', Helpers.formatDate(widget.order.createdAt)),
              const SizedBox(height: 30),
              // House info
              const Text(
                'House Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              FutureBuilder<HouseModel?>(
                future: _databaseService.getHouseById(widget.order.houseId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text('House information not available');
                  }

                  final house = snapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard('Title', house.title),
                      const SizedBox(height: 10),
                      _buildInfoCard(
                          'Price', Helpers.formatCurrency(house.price)),
                      const SizedBox(height: 10),
                      _buildInfoCard('Location', house.location),
                      const SizedBox(height: 10),
                      _buildInfoCard('Area', '${house.area} Marla'),
                      const SizedBox(height: 10),
                      _buildInfoCard('Type', house.houseType),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
              // Tenant info
              const Text(
                'Tenant Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              FutureBuilder<UserModel?>(
                future: _databaseService.getUser(widget.order.tenantId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text('Tenant information not available');
                  }

                  final tenant = snapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard('Name', tenant.name),
                      const SizedBox(height: 10),
                      _buildInfoCard('Email', tenant.email),
                      const SizedBox(height: 10),
                      _buildInfoCard('Phone', tenant.phone),
                      const SizedBox(height: 10),
                      _buildInfoCard(
                          'Member Since', Helpers.formatDate(tenant.createdAt)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
              // Action buttons for landlords
              FutureBuilder<UserModel?>(
                future: _databaseService.getUser(widget.order.landlordId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox();
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox();
                  }

                  final landlord = snapshot.data!;
                  final currentUser = FirebaseAuth.instance.currentUser;

                  if (currentUser != null && currentUser.uid == landlord.uid) {
                    return Column(
                      children: [
                        const Text(
                          'Manage Request',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Accept',
                                onPressed: () {
                                  _updateOrderStatus(AppConstants.orderStatusAccepted);
                                },
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomButton(
                                text: 'Reject',
                                onPressed: () {
                                  _updateOrderStatus(AppConstants.orderStatusRejected);
                                },
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}