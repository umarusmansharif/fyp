import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/models/order_model.dart';
import 'package:renthouse/models/notification_model.dart';
import 'package:renthouse/screens/chat_detail_screen.dart';
import 'package:renthouse/screens/order_detail_screen.dart';
import 'package:renthouse/screens/reviews_screen.dart';
import 'package:renthouse/services/auth_service.dart';
import 'package:renthouse/services/database_service.dart';
import 'package:renthouse/services/notification_service.dart';
import 'package:renthouse/utils/helpers.dart';
import 'package:renthouse/widgets/custom_button.dart';
import 'package:renthouse/widgets/image_carousel.dart';
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
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId != null) {
      final isFav = await _databaseService.isFavorite(userId, widget.house.houseId);
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) return;

    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      if (_isFavorite) {
        await _databaseService.addToFavorites(userId, widget.house.houseId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to favorites')),
        );
      } else {
        await _databaseService.removeFromFavorites(userId, widget.house.houseId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites')),
        );
      }
    } catch (e) {
      setState(() {
        _isFavorite = !_isFavorite; // Revert on error
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _startChat() async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to chat')),
      );
      return;
    }

    try {
      final landlord = await _databaseService.getUser(widget.house.landlordId);
      if (landlord == null || !mounted) return;

      final chat = await _databaseService.createOrGetChat(
        tenantId: currentUser.uid,
        landlordId: widget.house.landlordId,
        propertyId: widget.house.houseId,
        propertyTitle: widget.house.title,
        propertyLocation: widget.house.location,
        propertyPrice: widget.house.price,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chat: chat,
            currentUser: widget.currentUser,
            otherUser: landlord,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }

  Future<void> _requestHouse() async {
    if (widget.currentUser == null) return;

    try {
      final hasExistingRequest = await _databaseService.hasPendingVisitRequest(
        widget.currentUser!.uid,
        widget.house.houseId,
      );

      if (hasExistingRequest) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already sent a request for this property.'),
            backgroundColor: Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final requestId = await _databaseService.createVisitRequest(
        tenantId: widget.currentUser!.uid,
        ownerId: widget.house.landlordId,
        listingId: widget.house.houseId,
        tenantName: widget.currentUser!.name,
        listingTitle: widget.house.title,
      );

      await _notificationService.sendPropertyRequestNotification(
        landlordId: widget.house.landlordId,
        propertyId: widget.house.houseId,
        propertyTitle: widget.house.title,
        tenantName: widget.currentUser!.name,
        requestId: requestId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent successfully!'),
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Landlord information not available'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        return;
      }

      // Check if phone number is available
      if (landlord.phone.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Landlord has not provided a phone number'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        return;
      }

      final message = 'I am interested in your house listing: ${widget.house.title}.';
      await Helpers.launchWhatsApp(landlord.phone, message);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening WhatsApp...'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'Error contacting landlord';
      if (e.toString().contains('Invalid phone number')) {
        errorMessage = 'Invalid phone number provided by landlord';
      } else if (e.toString().contains('Could not launch WhatsApp')) {
        errorMessage = 'WhatsApp is not installed or not available';
      } else if (e.toString().contains('Landlord not found')) {
        errorMessage = 'Landlord information not available';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _shareProperty() async {
    try {
      // Prepare share content
      final String title = widget.house.title;
      final String price = Helpers.formatCurrency(widget.house.price);
      final String location = widget.house.location;
      final String description = widget.house.description;
      
      // Build share text
      String shareText = 'Check out this property for rent!\n\n';
      shareText += 'Title: $title\n';
      shareText += 'Price: $price\n';
      shareText += 'Location: $location\n';
      shareText += 'Type: ${widget.house.houseType}\n';
      shareText += 'Area: ${widget.house.area} Marla\n';
      shareText += 'Rooms: ${widget.house.numberOfRooms}\n\n';
      shareText += 'Description:\n$description\n\n';
      
      // Add amenities if available
      if (widget.house.amenities.isNotEmpty) {
        shareText += 'Amenities:\n';
        for (String amenity in widget.house.amenities) {
          shareText += 'â¢ $amenity\n';
        }
        shareText += '\n';
      }
      
      shareText += 'Shared via RentHouse App';
      
      // Share the content
      await Share.share(
        shareText,
        subject: 'Property for Rent: $title',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing property: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prepare images list
    final List<String> images = widget.house.images.isNotEmpty
        ? widget.house.images
        : (widget.house.imageUrl.isNotEmpty ? [widget.house.imageUrl] : []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('House Details'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: _shareProperty,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // House image carousel
            if (images.isNotEmpty)
              ImageCarousel(images: images)
            else
              Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[200],
                child: Icon(
                  Icons.image_not_supported,
                  size: 60,
                  color: Colors.grey[400],
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
                      Expanded(
                        child: Text(
                          widget.house.location,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                  _buildIconDetailRow(Icons.meeting_room, 'Rooms', '${widget.house.numberOfRooms}'),
                  _buildIconDetailRow(Icons.location_on, 'Location', widget.house.location),
                  
                  // Status badge
                  if (widget.house.status.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.house.status == 'available'
                              ? Colors.green.withValues(alpha: 0.1)
                              : widget.house.status == 'rented'
                                  ? Colors.orange.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.house.status == 'available'
                                ? Colors.green
                                : widget.house.status == 'rented'
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                        child: Text(
                          widget.house.status.toUpperCase(),
                          style: TextStyle(
                            color: widget.house.status == 'available'
                                ? Colors.green
                                : widget.house.status == 'rented'
                                    ? Colors.orange
                                    : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  
                  // Amenities
                  if (widget.house.amenities.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Amenities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.house.amenities.map((amenity) {
                        return Chip(
                          label: Text(
                            amenity,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          side: BorderSide(color: Theme.of(context).primaryColor),
                        );
                      }).toList(),
                    ),
                  ],
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
                  // Reviews Button
                  CustomButton(
                    text: 'View Reviews & Ratings',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewsScreen(
                            house: widget.house,
                            currentUser: widget.currentUser,
                          ),
                        ),
                      );
                    },
                    color: const Color(0xFF1A237E),
                    width: double.infinity,
                  ),
                  const SizedBox(height: 10),
                  // Action buttons - full width, separate lines
                  if (widget.currentUser?.userType == AppConstants.userTypeTenant)
                    Column(
                      children: [
                        CustomButton(
                          text: 'Chat with Landlord',
                          onPressed: _startChat,
                          color: Theme.of(context).primaryColor,
                          width: double.infinity,
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          text: 'WhatsApp',
                          onPressed: _contactViaWhatsApp,
                          color: Colors.green,
                          width: double.infinity,
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          text: 'Request Visit',
                          onPressed: _requestHouse,
                          color: Colors.blue,
                          width: double.infinity,
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
