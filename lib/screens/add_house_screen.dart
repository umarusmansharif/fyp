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
  XFile? _selectedImage;
  String? _imagePreviewUrl;
  
  // Location fields
  double? _latitude;
  double? _longitude;
  List<String> _selectedAmenities = [];
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
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
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

        String imageUrl = '';
        
        // Upload image to Cloudinary if selected
        if (_selectedImage != null) {
          final imageFile = File(_selectedImage!.path);
          print('Attempting to upload image: ${imageFile.path}');
          print('File exists: ${await imageFile.exists()}');
          
          if (!await imageFile.exists()) {
            throw Exception('Selected image file does not exist');
          }
          
          try {
            String? uploadedImageUrl = await CloudinaryService.uploadImageToCloudinary(imageFile);
            print('Cloudinary service returned: $uploadedImageUrl');
            
            if (uploadedImageUrl == null) {
              throw Exception('Image upload failed - no URL returned from Cloudinary');
            }
            imageUrl = uploadedImageUrl;
          } catch (e) {
            print('Error during Cloudinary upload: $e');
            if (!mounted) return;
            throw Exception('Image upload failed: $e');
          }
        } else {
          throw 'Please select an image for the house';
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
          images: imageUrl.isNotEmpty ? [imageUrl] : [],
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
        _selectedImage = null;
        _imagePreviewUrl = null;
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
                        child: _selectedImage != null
                            ? Column(
                                children: [
                                  Container(
                                    height: 150, // Reduced height to prevent overflow
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[100],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_selectedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Image selected',
                                    style: TextStyle(
                                      color: Colors.green[600],
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
                                      'Tap to select an image',
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
                          label: Text(_selectedImage != null ? 'Change Image' : 'Select Image'),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}