import 'package:flutter/material.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/services/auth_service.dart';
import 'package:renthouse/services/database_service.dart';
import 'package:renthouse/widgets/custom_app_bar.dart';
import 'package:renthouse/widgets/custom_button.dart';
import 'package:renthouse/widgets/custom_text_field.dart';
import 'package:renthouse/widgets/location_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:renthouse/services/cloudinary_service.dart';

class AddHouseScreen extends StatefulWidget {
  const AddHouseScreen({Key? key}) : super(key: key);

  @override
  State<AddHouseScreen> createState() => _AddHouseScreenState();
}

class _AddHouseScreenState extends State<AddHouseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _areaController = TextEditingController();
  final _houseTypeController = TextEditingController();
  final _roomsController = TextEditingController();
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  List<XFile> _selectedImages = [];
  
  // Location fields
  double? _latitude;
  double? _longitude;
  final List<String> _selectedAmenities = [];
  String _propertyStatus = AppConstants.propertyStatusAvailable;
  
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

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPicker(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          initialAddress: _locationController.text,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _locationController.text = result['address'];
      });
    }
  }

  Future<void> _pickImage() async {
    final List<XFile> pickedFiles = await ImagePicker().pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles);
      });
    }
  }
  
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _areaController.dispose();
    _houseTypeController.dispose();
    super.dispose();
  }

  Future<void> _addHouse() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = _authService.getCurrentUser();
        if (user == null) {
          throw 'User not authenticated';
        }

        // Validate location is selected
        if (_latitude == null || _longitude == null) {
          throw 'Please select a location on map';
        }
        
        // Validate at least one image is selected
        if (_selectedImages.isEmpty) {
          throw 'Please select at least one image';
        }

        List<String> imageUrls = [];
        
        // Upload all images to Cloudinary
        for (var image in _selectedImages) {
          final imageFile = File(image.path);
          print('Attempting to upload image: ${imageFile.path}');
          
          if (!await imageFile.exists()) {
            continue;
          }
          
          try {
            String? uploadedImageUrl = await CloudinaryService.uploadImageToCloudinary(imageFile);
            if (uploadedImageUrl != null) {
              imageUrls.add(uploadedImageUrl);
            }
          } catch (e) {
            print('Error uploading image: $e');
          }
        }
        
        if (imageUrls.isEmpty) {
          throw 'Image upload failed. Please try again.';
        }

        final house = HouseModel(
          houseId: const Uuid().v4(),
          landlordId: user.uid,
          title: _titleController.text.trim(),
          price: double.tryParse(_priceController.text.trim()) ?? 0.0,
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          latitude: _latitude ?? 0.0,
          longitude: _longitude ?? 0.0,
          area: double.tryParse(_areaController.text.trim()) ?? 0.0,
          houseType: _houseTypeController.text.trim(),
          numberOfRooms: int.tryParse(_roomsController.text.trim()) ?? 0,
          images: imageUrls,
          amenities: _selectedAmenities,
          status: _propertyStatus,
          createdAt: DateTime.now(),
        );

        await _databaseService.addHouse(house);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('House added successfully!')),
        );

        // Clear form
        _titleController.clear();
        _priceController.clear();
        _descriptionController.clear();
        _locationController.clear();
        _areaController.clear();
        _houseTypeController.clear();
        _roomsController.clear();
        _selectedImages.clear();
        _latitude = null;
        _longitude = null;
        _selectedAmenities.clear();
        _propertyStatus = AppConstants.propertyStatusAvailable;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Add New House',
        onBackPress: () {
          Navigator.pop(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                CustomTextField(
                  controller: _titleController,
                  labelText: 'Title',
                  prefixIcon: Icons.title,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter house title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _priceController,
                  labelText: 'Price (₨)',
                  prefixIcon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  prefixIcon: Icons.description,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Location picker
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: _locationController.text.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _locationController.text,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if (_latitude != null && _longitude != null)
                                    Text(
                                      'Coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              )
                            : Text(
                                'Tap button below to select on map',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ElevatedButton.icon(
                          onPressed: _pickLocation,
                          icon: const Icon(Icons.map),
                          label: Text(_latitude != null ? 'Change Location' : 'Select on Map'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _roomsController,
                  labelText: 'Number of Rooms',
                  prefixIcon: Icons.meeting_room,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter number of rooms';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _areaController,
                  labelText: 'Area (Marla)',
                  prefixIcon: Icons.square_foot,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter area';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _houseTypeController,
                  labelText: 'House Type',
                  prefixIcon: Icons.home,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter house type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Property Status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Property Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _propertyStatus,
                        items: [
                          DropdownMenuItem(
                            value: AppConstants.propertyStatusAvailable,
                            child: const Text('Available'),
                          ),
                          DropdownMenuItem(
                            value: AppConstants.propertyStatusRented,
                            child: const Text('Rented'),
                          ),
                          DropdownMenuItem(
                            value: AppConstants.propertyStatusUnavailable,
                            child: const Text('Unavailable'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _propertyStatus = value!;
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Amenities Selection
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Image selection
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.image,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'House Image',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: _selectedImages.isNotEmpty
                            ? Column(
                                children: [
                                  // Image Gallery
                                  SizedBox(
                                    height: 150,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _selectedImages.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Stack(
                                            children: [
                                              Container(
                                                width: 150,
                                                height: 150,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8),
                                                  color: Colors.grey[100],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.file(
                                                    File(_selectedImages[index].path),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              // Remove button
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () => _removeImage(index),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${_selectedImages.length} image(s) selected',
                                    style: TextStyle(
                                      color: Colors.blue[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                padding: const EdgeInsets.all(20),
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Tap to select images',
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_a_photo),
                          label: Text(_selectedImages.isEmpty ? 'Select Images' : 'Add More Images (${_selectedImages.length})'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                CustomButton(
                  text: 'Add House',
                  onPressed: _addHouse,
                  isLoading: _isLoading,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}