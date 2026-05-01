import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/models/order_model.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/screens/house_detail_screen.dart';
import 'package:renthouse/screens/order_detail_screen.dart';
import 'package:renthouse/screens/edit_house_screen.dart';
import 'package:renthouse/services/database_service.dart';
import 'package:renthouse/services/cloudinary_service.dart';
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
  UserModel? _currentUser;
  bool _isUploadingImage = false;
  bool _profileUpdated = false;
  
  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    // Fetch fresh user data to ensure latest profile image
    if (widget.user != null) {
      _fetchFreshUserData();
    }
  }

  Future<void> _fetchFreshUserData() async {
    try {
      final freshUser = await _databaseService.getUser(widget.user!.uid);
      if (freshUser != null && mounted) {
        setState(() {
          _currentUser = freshUser;
        });
      }
    } catch (e) {
      // If fetch fails, keep using widget.user as fallback
      print('Error fetching fresh user data: $e');
    }
  }
  
  Future<void> _uploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (image == null) return;
    
    if (widget.user == null) return;
    
    setState(() {
      _isUploadingImage = true;
    });
    
    try {
      // Upload image to Cloudinary using the same service as property images
      File imageFile = File(image.path);
      String? imageUrl = await CloudinaryService.uploadImageToCloudinary(imageFile);
      
      if (imageUrl != null && imageUrl.isNotEmpty) {
        // Update user profile in database
        await _databaseService.updateUserProfileImage(widget.user!.uid, imageUrl);
        
        // Fetch updated user data to refresh UI immediately
        final updatedUser = await _databaseService.getUser(widget.user!.uid);
        if (updatedUser != null && mounted) {
          setState(() {
            _currentUser = updatedUser;
            _profileUpdated = true;
          });
        }
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Failed to upload image to cloud storage');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading profile image: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profile',
        onBackPress: () {
          Navigator.pop(context, _profileUpdated);
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
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _currentUser?.profileImage != null && _currentUser!.profileImage!.isNotEmpty
                              ? NetworkImage(_currentUser!.profileImage!)
                              : null,
                          backgroundColor: Colors.grey[200],
                          child: _currentUser?.profileImage == null || _currentUser!.profileImage!.isEmpty
                              ? Icon(Icons.person, size: 50, color: Colors.grey[500])
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploadingImage ? null : _uploadProfileImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A237E),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: _isUploadingImage
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _currentUser?.name ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _currentUser?.email ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _currentUser?.userType == AppConstants.userTypeTenant
                          ? 'Tenant'
                          : 'Landlord',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Member since ${Helpers.formatDate(_currentUser?.createdAt ?? DateTime.now())}',
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
              _buildInfoCard('Phone', _currentUser?.phone ?? ''),
              const SizedBox(height: 15),
              _buildInfoCard('Email', _currentUser?.email ?? ''),
              const SizedBox(height: 15),
              _buildInfoCard(
                  'User Type',
                  _currentUser?.userType == AppConstants.userTypeTenant
                      ? 'Tenant'
                      : 'Landlord'),
              const SizedBox(height: 30),
              // Conditional content based on user type
              if (_currentUser?.userType == AppConstants.userTypeLandlord) ...[
                const Text(
                  'My Listings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                StreamBuilder<List<HouseModel>>(
                  stream: _databaseService.getHousesByLandlord(_currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      // Check if it's a Firestore index error
                      if (snapshot.error.toString().contains('[cloud_firestore/failed-precondition]')) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                              const SizedBox(height: 16),
                              const Text(
                                'Index Required',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'A composite index is required for this query. Please create the index in Firebase console.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
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
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220, // Maximum width for each card
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.7, // Prevent vertical overflow
                      ),
                      itemCount: houses.length,
                      itemBuilder: (context, index) {
                        return _buildHouseCardWithActions(houses[index]);
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
                  stream: _databaseService.getOrdersForLandlord(_currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      // Check if it's a Firestore index error
                      if (snapshot.error.toString().contains('[cloud_firestore/failed-precondition]')) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                              const SizedBox(height: 16),
                              const Text(
                                'Index Required',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'A composite index is required for this query. Please create the index in Firebase console.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
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

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                    house.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                      '${Helpers.formatCurrency(house.price)} • ${Helpers.formatDate(orders[index].createdAt)}',
                                      overflow: TextOverflow.ellipsis,
                                  ),
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
                                    overflow: TextOverflow.ellipsis,
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
                      // Check if it's a Firestore index error
                      if (snapshot.error.toString().contains('[cloud_firestore/failed-precondition]')) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                              const SizedBox(height: 16),
                              const Text(
                                'Index Required',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'A composite index is required for this query. Please create the index in Firebase console.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
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

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                    house.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                      '${Helpers.formatCurrency(house.price)} • ${Helpers.formatDate(orders[index].createdAt)}',
                                      overflow: TextOverflow.ellipsis,
                                  ),
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
                                    overflow: TextOverflow.ellipsis,
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

  Widget _buildHouseCardWithActions(HouseModel house) {
    // Only show edit/delete options if the current user is the owner of the house
    bool isOwner = widget.user?.uid == house.landlordId;
    
    return Stack(
      children: [
        HouseCard(
          house: house,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HouseDetailScreen(
                  house: house,
                  currentUser: widget.user,
                ),
              ));
            },


        // Menu button for edit/delete options (only for owner)
        ),
        if (isOwner) Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white, size: 20),
              onSelected: (String action) {
                if (action == 'edit') {
                  _editHouse(house);
                } else if (action == 'delete') {
                  _confirmDeleteHouse(house);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ) else Container(), // Empty container if not owner
      ],
    );
  }

  Future<void> _editHouse(HouseModel house) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditHouseScreen(house: house),
      ),
    ).then((value) {
      // Refresh the list after editing
      setState(() {});
    });
  }

  Future<void> _confirmDeleteHouse(HouseModel house) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete House'),
          content: Text('Are you sure you want to delete "${house.title}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteHouse(house);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteHouse(HouseModel house) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting house...')),
      );
      
      await _databaseService.deleteHouse(house.houseId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('House deleted successfully!')),
      );
      
      // Refresh the UI to reflect the deletion
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting house: ${e.toString()}')),
      );
    }
  }
}