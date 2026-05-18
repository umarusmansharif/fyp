import 'dart:async';

import 'package:flutter/material.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/core/property_types.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/models/user_model.dart';
import 'package:renthouse/screens/house_detail_screen.dart';
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
  final TextEditingController _maxPriceController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounceTimer;
  String _searchQuery = '';
  double? _maxPrice;
  String? _propertyType;
  bool _showFilters = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _maxPriceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value.trim();
        _hasSearched = value.trim().isNotEmpty;
      });
    });
  }

  void _applyFilters() {
    FocusScope.of(context).unfocus();
    setState(() {
      _showFilters = false;
      _maxPrice = double.tryParse(_maxPriceController.text.trim());
      _hasSearched = true;
    });
  }

  void _clearFilters() {
    FocusScope.of(context).unfocus();
    setState(() {
      _searchController.clear();
      _maxPriceController.clear();
      _searchQuery = '';
      _maxPrice = null;
      _propertyType = null;
      _showFilters = false;
      _hasSearched = false;
    });
  }

  int get _activeFilterCount {
    var count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_maxPrice != null) count++;
    if (_propertyType != null && _propertyType!.isNotEmpty) count++;
    return count;
  }

  Widget _buildFilterChip(String label, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        setState(() {
          _propertyType = value ? label : null;
          _hasSearched = true;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Search Properties'),
        actions: [
          IconButton(
            tooltip: 'Clear filters',
            onPressed: _clearFilters,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                           MediaQuery.of(context).padding.top - 
                           kToolbarHeight,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search by title, location, description',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _hasSearched = false;
                                  });
                                },
                                icon: const Icon(Icons.clear),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showFilters = !_showFilters;
                              });
                            },
                            icon: Badge(
                              isLabelVisible: _activeFilterCount > 0,
                              label: Text('$_activeFilterCount'),
                              child: Icon(
                                _showFilters ? Icons.filter_alt_off : Icons.filter_alt,
                              ),
                            ),
                            label: Text(_showFilters ? 'Hide Filters' : 'Filters'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('Reset'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    child: _showFilters
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Card(
                              elevation: 0,
                              color: theme.colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Property Type',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    DropdownButtonFormField<String>(
                                      value: _propertyType,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                      hint: const Text('Select property type'),
                                      items: [
                                        ...PropertyTypes.values.map(
                                          (type) => DropdownMenuItem<String>(
                                            value: type,
                                            child: Text(type),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _propertyType = value;
                                          _hasSearched = true;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Maximum Price',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _maxPriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        prefixText: '₨ ',
                                        border: OutlineInputBorder(),
                                        hintText: 'Enter maximum budget',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: PropertyTypes.values
                                          .map((type) => _buildFilterChip(
                                                type,
                                                _propertyType == type,
                                              ))
                                          .toList(),
                                    ),
                                    const SizedBox(height: 16),
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
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 
                           MediaQuery.of(context).padding.top - 
                           kToolbarHeight - 
                           280,
                    child: StreamBuilder<List<HouseModel>>(
                      stream: _databaseService.searchHouses(
                        query: _searchQuery,
                        maxPrice: _maxPrice,
                        propertyType: _propertyType,
                        status: AppConstants.propertyStatusAvailable,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Unable to load search results.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          );
                        }

                        final houses = snapshot.data ?? const <HouseModel>[];

                        if (!_hasSearched) {
                          return ListView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 60),
                              Icon(Icons.search,
                                  size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 20),
                              Text(
                                'Search to find the perfect property for you.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Use search and filters to discover listings.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          );
                        }

                        if (houses.isEmpty) {
                          return ListView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 40),
                              Icon(Icons.search_off,
                                  size: 72, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No properties found',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search or filters.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: houses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final house = houses[index];
                            return HouseCard(
                              house: house,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HouseDetailScreen(
                                      house: house,
                                      currentUser: widget.currentUser,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
