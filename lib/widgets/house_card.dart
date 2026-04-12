import 'package:flutter/material.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/services/auth_service.dart';
import 'package:renthouse/services/database_service.dart';

class HouseCard extends StatefulWidget {
  final HouseModel house;
  final VoidCallback? onTap;

  const HouseCard({
    Key? key,
    required this.house,
    this.onTap,
  }) : super(key: key);

  @override
  State<HouseCard> createState() => _HouseCardState();
}

class _HouseCardState extends State<HouseCard> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) return;

    try {
      final isFav = await _databaseService.isFavorite(userId, widget.house.houseId);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    } catch (e) {
      print('Error checking favorite: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFavorite) {
        await _databaseService.removeFromFavorites(userId, widget.house.houseId);
      } else {
        await _databaseService.addToFavorites(userId, widget.house.houseId);
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: widget.house.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.house.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 50),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.house, size: 50),
                      ),
              ),
              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Favorite button
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _isLoading ? null : _toggleFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                  ),
                ),
              ),
              // Status badge
              if (widget.house.status.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.house.status == 'available'
                          ? Colors.green
                          : widget.house.status == 'rented'
                              ? Colors.orange
                              : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.house.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Info container
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        widget.house.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Price
                      Text(
                        '${widget.house.price.toStringAsFixed(0)} PKR',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.house.location.isNotEmpty
                                  ? widget.house.location
                                  : 'Location not specified',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
