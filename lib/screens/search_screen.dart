import 'package:flutter/material.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/screens/house_detail_screen.dart';
import 'package:renthouse/screens/map_view_screen.dart';
import 'package:renthouse/services/database_service.dart';
import 'package:renthouse/widgets/house_card.dart';

class SearchScreen extends StatefulWidget {
  final UserModel? currentUser;

  const SearchScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  // Filter states
  double? _minPrice;
  double? _maxPrice;
  String? _propertyType;
  int? _rooms;
  List<String> _selectedAmenities = [];
  String _sortBy = 'newest'; // newest, price_low, price_high
  
  bool _showFilters = false;
  bool _isGridView = false;

  final List<String> _commonAmenities = [
    'Parking',
    'WiFi',
    'Air Conditioning',
    'Furnished',
    'Security',
    'Garden',
    'Pool',
    'Gym',
  ];

  final List<String> _propertyTypes = [
    'House',
    'Apartment',
    'Villa',
    'Studio',
    'Townhouse',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _showFilters = false;
    });
  }

  void _resetFilters() {
    setState(() {
      _minPrice = null;
      _maxPrice = null;
      _propertyType = null;
      _rooms = null;
      _selectedAmenities = [];
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Properties'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MapViewScreen(currentUser: widget.currentUser),
                ),
              );
            },
            tooltip: 'View on map',
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: 'Toggle view',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by location, title...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),

          // Filter Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                    icon: Icon(
                      _showFilters ? Icons.filter_alt_off : Icons.filter_list,
                      size: 20,
                    ),
                    label: Text(_showFilters ? 'Hide Filters' : 'Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showFilters
                          ? Theme.of(context).primaryColor
                          : Colors.white,
                      foregroundColor: _showFilters
                          ? Colors.white
                          : Colors.black87,
                      elevation: 0,
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ],
            ),
          ),

          // Filters Panel
          if (_showFilters)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Type
                  const Text(
                    'Property Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _propertyType,
                    hint: const Text('Select type'),
                    items: _propertyTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _propertyType = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Number of Rooms
                  const Text(
                    'Number of Rooms',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [1, 2, 3, 4, 5].map((rooms) {
                      final isSelected = _rooms == rooms;
                      return ChoiceChip(
                        label: Text('$rooms'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _rooms = selected ? rooms : null;
                          });
                        },
                        selectedColor: Theme.of(context).primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Price Range
                  const Text(
                    'Price Range',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Min Price',
                            prefixText: '₨ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _minPrice = value.isNotEmpty
                                  ? double.tryParse(value)
                                  : null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Max Price',
                            prefixText: '₨ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _maxPrice = value.isNotEmpty
                                  ? double.tryParse(value)
                                  : null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amenities
                  const Text(
                    'Amenities',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonAmenities.map((amenity) {
                      final isSelected = _selectedAmenities.contains(amenity);
                      return FilterChip(
                        label: Text(amenity),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAmenities.add(amenity);
                            } else {
                              _selectedAmenities.remove(amenity);
                            }
                          });
                        },
                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        checkmarkColor: Theme.of(context).primaryColor,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Sort By
                  const Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Newest', style: TextStyle(fontSize: 14)),
                          value: 'newest',
                          groupValue: _sortBy,
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Price: Low', style: TextStyle(fontSize: 14)),
                          value: 'price_low',
                          groupValue: _sortBy,
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Price: High', style: TextStyle(fontSize: 14)),
                          value: 'price_high',
                          groupValue: _sortBy,
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: StreamBuilder<List<HouseModel>>(
              stream: _databaseService.searchHouses(
                query: _searchController.text.isEmpty ? null : _searchController.text,
                minPrice: _minPrice,
                maxPrice: _maxPrice,
                propertyType: _propertyType,
                rooms: _rooms,
                amenities: _selectedAmenities.isEmpty ? null : _selectedAmenities,
                status: AppConstants.propertyStatusAvailable,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var houses = snapshot.data!;
                  
                  // Apply sorting
                  if (_sortBy == 'price_low') {
                    houses.sort((a, b) => a.price.compareTo(b.price));
                  } else if (_sortBy == 'price_high') {
                    houses.sort((a, b) => b.price.compareTo(a.price));
                  }
                  // 'newest' is already sorted by createdAt descending

                  return Text(
                    '${houses.length} properties found',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // Results List/Grid
          Expanded(
            child: StreamBuilder<List<HouseModel>>(
              stream: _databaseService.searchHouses(
                query: _searchController.text.isEmpty ? null : _searchController.text,
                minPrice: _minPrice,
                maxPrice: _maxPrice,
                propertyType: _propertyType,
                rooms: _rooms,
                amenities: _selectedAmenities.isEmpty ? null : _selectedAmenities,
                status: AppConstants.propertyStatusAvailable,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No properties found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var houses = snapshot.data!;
                
                // Apply sorting
                if (_sortBy == 'price_low') {
                  houses.sort((a, b) => a.price.compareTo(b.price));
                } else if (_sortBy == 'price_high') {
                  houses.sort((a, b) => b.price.compareTo(a.price));
                }

                if (_isGridView) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
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
                                currentUser: widget.currentUser,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: houses.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: HouseCard(
                          house: houses[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HouseDetailScreen(
                                  house: houses[index],
                                  currentUser: widget.currentUser,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
