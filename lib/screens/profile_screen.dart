import 'package:flutter/material.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/models/order_model.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/screens/house_detail_screen.dart';
import 'package:renthouse/screens/order_detail_screen.dart';
import 'package:renthouse/services/database_service.dart';
import 'package:renthouse/utils/helpers.dart';
import 'package:renthouse/widgets/custom_app_bar.dart';
import 'package:renthouse/widgets/house_card.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profile',
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
              // Profile header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(AppConstants.defaultProfileImage),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      widget.user?.name ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.user?.email ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.user?.userType == AppConstants.userTypeTenant
                          ? 'Tenant'
                          : 'Landlord',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Member since ${Helpers.formatDate(widget.user?.createdAt ?? DateTime.now())}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // User details
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              _buildInfoCard('Phone', widget.user?.phone ?? ''),
              const SizedBox(height: 15),
              _buildInfoCard('Email', widget.user?.email ?? ''),
              const SizedBox(height: 15),
              _buildInfoCard(
                  'User Type',
                  widget.user?.userType == AppConstants.userTypeTenant
                      ? 'Tenant'
                      : 'Landlord'),
              const SizedBox(height: 30),
              // Conditional content based on user type
              if (widget.user?.userType == AppConstants.userTypeLandlord) ...[
                const Text(
                  'My Listings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                StreamBuilder<List<HouseModel>>(
                  stream: _databaseService.getHousesByLandlord(widget.user!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'You have no listings yet',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    final houses = snapshot.data!;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: houses.length,
                      itemBuilder: (context, index) {
                        return HouseCard(
                          house: houses[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HouseDetailScreen(
                                  house: houses[index],
                                  currentUser: widget.user,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 30),
                const Text(
                  'Received Requests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                StreamBuilder<List<OrderModel>>(
                  stream: _databaseService.getOrdersForLandlord(widget.user!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'You have no requests yet',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    final orders = snapshot.data!;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return FutureBuilder<HouseModel?>(
                          future: _databaseService.getHouseById(orders[index].houseId),
                          builder: (context, houseSnapshot) {
                            if (houseSnapshot.connectionState == ConnectionState.waiting) {
                              return const ListTile(
                                title: Text('Loading...'),
                                subtitle: CircularProgressIndicator(),
                              );
                            }

                            if (houseSnapshot.hasError || !houseSnapshot.hasData) {
                              return const ListTile(
                                title: Text('House information not available'),
                              );
                            }

                            final house = houseSnapshot.data!;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: Text(house.title),
                                subtitle: Text(
                                    '${Helpers.formatCurrency(house.price)} • ${Helpers.formatDate(orders[index].createdAt)}'),
                                trailing: Text(
                                  orders[index].status.toUpperCase(),
                                  style: TextStyle(
                                    color: orders[index].status ==
                                            AppConstants.orderStatusPending
                                        ? Colors.orange
                                        : orders[index].status ==
                                                AppConstants.orderStatusAccepted
                                            ? Colors.green
                                            : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderDetailScreen(
                                        order: orders[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ] else ...[
                const Text(
                  'My Requests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                StreamBuilder<List<OrderModel>>(
                  stream: _databaseService.getOrdersForTenant(widget.user!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'You have no requests yet',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    final orders = snapshot.data!;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return FutureBuilder<HouseModel?>(
                          future: _databaseService.getHouseById(orders[index].houseId),
                          builder: (context, houseSnapshot) {
                            if (houseSnapshot.connectionState == ConnectionState.waiting) {
                              return const ListTile(
                                title: Text('Loading...'),
                                subtitle: CircularProgressIndicator(),
                              );
                            }

                            if (houseSnapshot.hasError || !houseSnapshot.hasData) {
                              return const ListTile(
                                title: Text('House information not available'),
                              );
                            }

                            final house = houseSnapshot.data!;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: Text(house.title),
                                subtitle: Text(
                                    '${Helpers.formatCurrency(house.price)} • ${Helpers.formatDate(orders[index].createdAt)}'),
                                trailing: Text(
                                  orders[index].status.toUpperCase(),
                                  style: TextStyle(
                                    color: orders[index].status ==
                                            AppConstants.orderStatusPending
                                        ? Colors.orange
                                        : orders[index].status ==
                                                AppConstants.orderStatusAccepted
                                            ? Colors.green
                                            : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderDetailScreen(
                                        order: orders[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
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
        child: Row(
          children: [
            Text(
              '$label: ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
      ),
    );
  }
}