import 'package:flutter/material.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/services/auth_service.dart';
import 'package:renthouse/services/database_service.dart';
import 'package:renthouse/widgets/custom_app_bar.dart';
import 'package:renthouse/widgets/custom_button.dart';
import 'package:renthouse/widgets/custom_text_field.dart';
import 'package:renthouse/widgets/location_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:renthouse/services/cloudinary_service.dart';

class EditHouseScreen extends StatefulWidget {
  final HouseModel house;
  
  const EditHouseScreen({Key? key, required this.house}) : super(key: key);

  @override
  State<EditHouseScreen> createState() => _EditHouseScreenState();
}

class _EditHouseScreenState extends State<EditHouseScreen> {
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
  List<String> _existingImages = [];
  
  // Location and additional fields
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

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing house data
    _titleController.text = widget.house.title;
    _priceController.text = widget.house.price.toString();
    _descriptionController.text = widget.house.description;
    _locationController.text = widget.house.location;
    _areaController.text = widget.house.area.toString();
    _houseTypeController.text = widget.house.houseType;
    _roomsController.text = widget.house.numberOfRooms.toString();
    
    // Initialize location
    _latitude = widget.house.latitude;
    _longitude = widget.house.longitude;
    
    // Initialize images
    _existingImages = widget.house.images.isNotEmpty ? widget.house.images : (widget.house.imageUrl.isNotEmpty ? [widget.house.imageUrl] : []);
    
    // Initialize amenities and status
    _selectedAmenities = List.from(widget.house.amenities);
    _propertyStatus = widget.house.status;
  }

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

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await ImagePicker().pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.take(10 - _existingImages.length - _selectedImages.length));
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
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
    _roomsController.dispose();
    super.dispose();
  }

  Future<void> _updateHouse() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = _authService.getCurrentUser();
        if (user == null) {
          throw 'User not authenticated';
        }

        List<String> finalImages = List.from(_existingImages);
        
        // Upload new images to Cloudinary
        for (var imageFile in _selectedImages) {
          final file = File(imageFile.path);
          print('Uploading image: ${file.path}');
          
          if (!await file.exists()) {
            continue;
          }
          
          try {
            String? uploadedUrl = await CloudinaryService.uploadImageToCloudinary(file);
            if (uploadedUrl != null) {
              finalImages.add(uploadedUrl);
            }
          } catch (e) {
            print('Error uploading image: $e');
          }
        }

        final updatedHouse = HouseModel(
          houseId: widget.house.houseId,
          landlordId: widget.house.landlordId,
          title: _titleController.text.trim(),
          price: double.tryParse(_priceController.text.trim()) ?? widget.house.price,
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          latitude: _latitude ?? widget.house.latitude,
          longitude: _longitude ?? widget.house.longitude,
          area: double.tryParse(_areaController.text.trim()) ?? widget.house.area,
          houseType: _houseTypeController.text.trim(),
          numberOfRooms: int.tryParse(_roomsController.text.trim()) ?? widget.house.numberOfRooms,
          images: finalImages,
          amenities: _selectedAmenities,
          status: _propertyStatus,
          createdAt: widget.house.createdAt,
          updatedAt: DateTime.now(),
        );

        await _databaseService.updateHouse(updatedHouse);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('House updated successfully!')),
        );

        Navigator.pop(context); // Go back to previous screen
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
        title: 'Edit House',
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
                CustomTextField(
                  controller: _locationController,
                  labelText: 'Location',
                  prefixIcon: Icons.location_on,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter location';
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
                          label: Text('Update Location'),
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
                CustomTextField(
                  controller: _roomsController,
                  labelText: 'Number of Rooms',
                  prefixIcon: Icons.bed,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter number of rooms';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Show existing images
                            if (_existingImages.isNotEmpty) ...[
                              const Text(
                                'Existing Images:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _existingImages.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[300]!),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              _existingImages[index],
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.broken_image),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 12,
                                          child: GestureDetector(
                                            onTap: () => _removeExistingImage(index),
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
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            
                            // Show newly selected images
                            if (_selectedImages.isNotEmpty) ...[
                              const Text(
                                'New Images to Upload:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[300]!),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(
                                              File(_selectedImages[index].path),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 12,
                                          child: GestureDetector(
                                            onTap: () => _removeNewImage(index),
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
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            
                            // Add more images button
                            ElevatedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.add_a_photo),
                              label: Text('Add Photos (${_existingImages.length + _selectedImages.length}/10)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You can add up to 10 photos. Tap X to remove.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                CustomButton(
                  text: 'Update House',
                  onPressed: _updateHouse,
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