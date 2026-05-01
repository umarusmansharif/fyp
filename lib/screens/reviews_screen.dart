import 'package:flutter/material.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/models/review_model.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/services/database_service.dart';
import 'package:intl/intl.dart';

class ReviewsScreen extends StatefulWidget {
  final HouseModel house;
  final UserModel? currentUser;

  const ReviewsScreen({
    Key? key,
    required this.house,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _reviewController = TextEditingController();
  double _rating = 0;
  bool _isSubmitting = false;
  UserModel? _refreshedCurrentUser;

  @override
  void initState() {
    super.initState();
    _refreshedCurrentUser = widget.currentUser;
    _refreshCurrentUserData();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _refreshCurrentUserData() async {
    if (widget.currentUser != null) {
      final freshData = await _databaseService.getUser(widget.currentUser!.uid);
      if (freshData != null && mounted) {
        setState(() {
          _refreshedCurrentUser = freshData;
        });
      }
    }
  }

  String _getUserNameInitial(String? userName) {
    if (userName == null || userName.isEmpty) {
      return '?';
    }
    return userName[0].toUpperCase();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a review')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = widget.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated';
      }

      final review = ReviewModel(
        reviewId: '', // Will be set by database service
        propertyId: widget.house.houseId,
        userId: userId,
        userName: _refreshedCurrentUser?.name ?? 'Anonymous',
        userAvatar: _refreshedCurrentUser?.profileImage,
        rating: _rating.round(),
        comment: _reviewController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _databaseService.addReview(review);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );

      _reviewController.clear();
      setState(() {
        _rating = 0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews & Ratings'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Rating Summary
          FutureBuilder<double>(
            future: _databaseService.getPropertyAverageRating(widget.house.houseId),
            builder: (context, snapshot) {
              final averageRating = snapshot.data ?? 0.0;
              
              return Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < averageRating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.white,
                                size: 24,
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<int>(
                            stream: _databaseService.getReviewCount(widget.house.houseId),
                            builder: (context, countSnapshot) {
                              final reviewCount = countSnapshot.data ?? 0;
                              return Text(
                                '$reviewCount review${reviewCount != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.reviews,
                      size: 64,
                      color: Colors.white24,
                    ),
                  ],
                ),
              );
            },
          ),

          // Write Review Section
          if (widget.currentUser != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Write a Review',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Star Rating
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Review Text
                  TextField(
                    controller: _reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitReview,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isSubmitting ? 'Submitting...' : 'Submit Review'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Reviews List
          Expanded(
            child: StreamBuilder<List<ReviewModel>>(
              stream: _databaseService.getPropertyReviews(widget.house.houseId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final reviews = snapshot.data ?? [];

                if (reviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No reviews yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to review this property!',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return _buildReviewCard(review);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).primaryColor,
                backgroundImage: review.userAvatar != null
                    ? NetworkImage(review.userAvatar!)
                    : null,
                child: review.userAvatar == null
                    ? Text(
                        _getUserNameInitial(review.userName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, y').format(review.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
