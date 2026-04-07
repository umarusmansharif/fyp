import 'package:flutter/material.dart';
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

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  UserModel? _currentUser;
  int _currentIndex = 0;
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      final userData = await _databaseService.getUser(user.uid);
      setState(() {
        _currentUser = userData;
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(user: _currentUser),
              ),
            );
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
                  : const AssetImage(AppConstants.defaultProfileImage) as ImageProvider,
              backgroundColor: Colors.grey[200],
              child: _currentUser?.profileImage == null || _currentUser!.profileImage!.isEmpty
                  ? Icon(Icons.person, color: Colors.grey[500])
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
              // Welcome text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${_currentUser?.name ?? 'User'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Find your home here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Search bar
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
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        'Search houses...',
                        style: TextStyle(color: Colors.grey[500]),
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
                    _buildCategoryTab('Top Recommended', 0),
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
                'Recommended For You',
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
                  stream: _databaseService.getHouses(),
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

                    // Show first few houses in the main gallery
                    final mainHouses = houses.take(5).toList();

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
              // Best Offer section
              const Text(
                'Best Offer',
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
                  stream: _databaseService.getHouses(),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIChatbotScreen()),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text(
          'AI Assistant',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCategoryTab(String title, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = index;
        });
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
}