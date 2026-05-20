import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/screens/house_detail_screen.dart';
import 'package:renthouse/services/database_service.dart';
import 'package:renthouse/services/notification_service.dart';
import 'package:renthouse/utils/helpers.dart';

class VisitRequestsScreen extends StatefulWidget {
  const VisitRequestsScreen({Key? key}) : super(key: key);

  @override
  State<VisitRequestsScreen> createState() => _VisitRequestsScreenState();
}

class _VisitRequestsScreenState extends State<VisitRequestsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userData = await _databaseService.getUser(user.uid);
      if (mounted) {
        setState(() {
          _currentUser = userData;
        });
      }
    }
  }

  Future<void> _updateRequestStatus(String requestId, String status, String tenantId, String propertyTitle) async {
    try {
      await _databaseService.updateVisitRequestStatus(requestId, status);

      // Send notification to tenant about the response
      if (status == AppConstants.orderStatusAccepted) {
        await _notificationService.sendRequestResponseNotification(
          tenantId: tenantId,
          isAccepted: true,
          propertyId: requestId,
          propertyTitle: propertyTitle,
        );
      } else if (status == AppConstants.orderStatusRejected) {
        await _notificationService.sendRequestResponseNotification(
          tenantId: tenantId,
          isAccepted: false,
          propertyId: requestId,
          propertyTitle: propertyTitle,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request ${status.toLowerCase()}'),
          backgroundColor: status == AppConstants.orderStatusAccepted
              ? Colors.green
              : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view visit requests')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Requests'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _databaseService.getVisitRequestsForLandlord(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No visit requests yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Requests from tenants will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final data = request.data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['tenantName'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusChip(data['status'] ?? 'pending'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.home, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['listingTitle'] ?? 'Unknown Property',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Requested: ${Helpers.formatDate(data['createdAt'] != null 
                                ? (data['createdAt'] as Timestamp).toDate() 
                                : DateTime.now())}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      if (data['status'] == AppConstants.orderStatusPending) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateRequestStatus(
                                  request.id,
                                  AppConstants.orderStatusAccepted,
                                  data['tenantId'],
                                  data['listingTitle'],
                                ),
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Accept'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _updateRequestStatus(
                                  request.id,
                                  AppConstants.orderStatusRejected,
                                  data['tenantId'],
                                  data['listingTitle'],
                                ),
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status.toLowerCase()) {
      case AppConstants.orderStatusAccepted:
        color = Colors.green;
        label = 'Accepted';
        break;
      case AppConstants.orderStatusRejected:
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = Colors.orange;
        label = 'Pending';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
