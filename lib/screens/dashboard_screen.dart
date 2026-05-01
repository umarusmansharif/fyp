import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/screens/add_house_screen.dart';
import 'package:renthouse/screens/ai_chatbot_screen.dart';
import 'package:renthouse/screens/auth/login_screen.dart';
import 'package:renthouse/screens/chat_list_screen.dart';
import 'package:renthouse/screens/favorites_screen.dart';
import 'package:renthouse/screens/house_detail_screen.dart';
import 'package:renthouse/screens/profile_screen.dart';
import 'package:renthouse/screens/search_screen.dart';
import 'package:renthouse/services/auth_service.dart';
import 'package:renthouse/services/database_service.dart';
import 'package:renthouse/widgets/house_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  UserModel? _currentUser;
  int _currentIndex = 0;
  int _selectedCategory = 0;
  Position? _userPosition;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh user data when app comes to foreground
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      // Always fetch fresh data from Firestore to get latest profile image
      final userData = await _databaseService.getUser(user.uid);
      setState(() {
        _currentUser = userData;
      });
    }
  }
  
  Future<void> _getUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location services'),
            backgroundColor: Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required to show nearby listings'),
              backgroundColor: Color(0xFFF59E0B),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userPosition = position;
        _selectedCategory = 1; // Switch to "Near You" tab
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(user: _currentUser),
              ),
            );
            // If profile was updated, refresh user data
            if (result == true && mounted) {
              _loadUserData();
            }
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: _currentUser?.profileImage != null && _currentUser!.profileImage!.isNotEmpty
                  ? NetworkImage(_currentUser!.profileImage!)
                  : null,
              backgroundColor: Colors.grey[200],
              child: _currentUser?.profileImage == null || _currentUser!.profileImage!.isEmpty
                  ? Icon(Icons.person, size: 20, color: Colors.grey[500])
                  : null,
            ),
          ),
        ),
        title: const Text(
          'RentHouse',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF9FAFB),
                Color(0xFFEFF3F6),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Welcome text - Role-based
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${_currentUser?.name ?? 'User'}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getRoleBasedWelcome(),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Search bar - Enhanced
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchScreen(currentUser: _currentUser),
                    ),
                  );
                },
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[600], size: 22),
                      const SizedBox(width: 14),
                      Text(
                        'Search houses by location, price...',
                        style: TextStyle(color: Colors.grey[500], fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Category tabs
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryTab('New Listings', 0),
                    const SizedBox(width: 12),
                    _buildCategoryTab('Near You', 1),
                    const SizedBox(width: 12),
                    _buildCategoryTab('Your Favorite', 2),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Horizontal house gallery
              const Text(
                'New Listings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: StreamBuilder<List<HouseModel>>(
                  stream: _databaseService.getHouses(
                    userId: _currentUser?.uid,
                    userType: _currentUser?.userType,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      if (_selectedCategory == 1 && _userPosition != null) {
                        return const Center(
                          child: Text(
                            'No houses found nearby',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      return const Center(
                        child: Text(
                          'No houses available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final houses = snapshot.data!;
                    
                    // Sort by distance if "Near You" is selected and location is available
                    List<HouseModel> sortedHouses = List.from(houses);
                    if (_selectedCategory == 1 && _userPosition != null) {
                      // Filter out houses with invalid coordinates first
                      sortedHouses = sortedHouses.where((house) {
                        return house.latitude != 0.0 && house.longitude != 0.0;
                      }).toList();
                      
                      // Sort by distance
                      sortedHouses.sort((a, b) {
                        double distanceA = _calculateDistance(
                          _userPosition!.latitude,
                          _userPosition!.longitude,
                          a.latitude,
                          a.longitude,
                        );
                        double distanceB = _calculateDistance(
                          _userPosition!.latitude,
                          _userPosition!.longitude,
                          b.latitude,
                          b.longitude,
                        );
                        return distanceA.compareTo(distanceB);
                      });
                    }

                    // Show first few houses in the main gallery
                    final mainHouses = sortedHouses.take(5).toList();

                    // Handle empty state for "Near You" section
                    if (_selectedCategory == 1 && mainHouses.isEmpty) {
                      if (_userPosition == null) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_off, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Enable location to see nearby properties',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_work, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No properties available',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Properties will be shown sorted by distance',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: mainHouses.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(right: index == mainHouses.length - 1 ? 0 : 12),
                          child: SizedBox(
                            width: 280,
                            child: HouseCard(
                              house: mainHouses[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HouseDetailScreen(
                                      house: mainHouses[index],
                                      currentUser: _currentUser,
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
                ),
              ),
              const SizedBox(height: 20),
              // Best Offers section
              const Text(
                'Best Offers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: StreamBuilder<List<HouseModel>>(
                  stream: _databaseService.getHouses(
                    userId: _currentUser?.uid,
                    userType: _currentUser?.userType,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No houses available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final houses = snapshot.data!;

                    // Show remaining houses in Best Offer section
                    final bestOfferHouses = houses.length > 5 ? houses.skip(5).toList() : houses;

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: bestOfferHouses.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(right: index == bestOfferHouses.length - 1 ? 0 : 12),
                          child: SizedBox(
                            width: 280,
                            child: HouseCard(
                              house: bestOfferHouses[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HouseDetailScreen(
                                      house: bestOfferHouses[index],
                                      currentUser: _currentUser,
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
                ),
              ),
              const SizedBox(height: 20),
              // Add House button for landlords
              if (_currentUser?.userType == AppConstants.userTypeLandlord)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddHouseScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add House',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFloatingActionButton() {
    // Show different FAB based on user role
    if (_currentUser?.userType == AppConstants.userTypeLandlord) {
      // Landlord: Show Add Listing button
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddHouseScreen()),
          );
        },
        backgroundColor: Color(0xFF1A237E),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Listing',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      // Tenant: Show AI Assistant button
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIChatbotScreen()),
          );
        },
        backgroundColor: Color(0xFF1A237E),
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text(
          'AI Assistant',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  Widget _buildCategoryTab(String title, int index) {
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          // "Near You" tab - request location
          _getUserLocation();
        } else if (index == 2) {
          // "Your Favorite" tab - navigate to favorites screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FavoritesScreen(currentUser: _currentUser),
            ),
          ).then((_) {
            // Reset to home tab when returning
            setState(() {
              _selectedCategory = 0;
            });
          });
        } else {
          setState(() {
            _selectedCategory = index;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedCategory == index ? Theme.of(context).colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedCategory == index ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: _selectedCategory == index ? Colors.white : Colors.grey[700],
            fontWeight: _selectedCategory == index ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        
        // Navigate to different screens based on tab
        switch (index) {
          case 0: // Home - stay on dashboard
            break;
          case 1: // Search
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchScreen(currentUser: _currentUser),
              ),
            ).then((_) {
              setState(() {
                _currentIndex = 0;
              });
            });
            break;
          case 2: // Notifications
            // TODO: Navigate to notifications screen when created
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon!')),
            );
            setState(() {
              _currentIndex = 0;
            });
            break;
          case 3: // Chat
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatListScreen(currentUser: _currentUser),
              ),
            ).then((_) {
              setState(() {
                _currentIndex = 0;
              });
            });
            break;
          case 4: // Favorites
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FavoritesScreen(currentUser: _currentUser),
              ),
            ).then((_) {
              setState(() {
                _currentIndex = 0;
              });
            });
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Favorite',
        ),
      ],
    );
  }

  String _getRoleBasedWelcome() {
    if (_currentUser?.userType == AppConstants.userTypeLandlord) {
      return 'Manage your properties and listings';
    } else {
      return 'Find your dream home';
    }
  }
  
  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = 
      _sin2(dLat / 2) +
      _cos(lat1) * _cos(lat2) * _sin2(dLon / 2);
    
    double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }
  
  double _sin2(double x) {
    return _sin(x) * _sin(x);
  }
  
  double _sin(double x) {
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }
  
  double _cos(double x) {
    return 1 - (x * x) / 2 + (x * x * x * x) / 24;
  }
  
  double _sqrt(double x) {
    if (x == 0) return 0;
    double result = x;
    for (int i = 0; i < 10; i++) {
      result = (result + x / result) / 2;
    }
    return result;
  }
  
  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }
  
  double _atan(double x) {
    return x - (x * x * x) / 3 + (x * x * x * x * x) / 5;
  }
}