import 'package:flutter/material.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/services/auth_service.dart';
import 'package:renthouse/services/database_service.dart';
import 'package:renthouse/widgets/custom_app_bar.dart';
import 'package:renthouse/widgets/custom_button.dart';
import 'package:renthouse/widgets/custom_text_field.dart';
import 'package:uuid/uuid.dart';
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
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  XFile? _selectedImage;
  String? _imagePreviewUrl;

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
    _imagePreviewUrl = widget.house.imageUrl;
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

        String imageUrl = widget.house.imageUrl; // Keep existing image URL by default
        
        // Upload new image to Cloudinary if selected
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
        }

        final updatedHouse = HouseModel(
          houseId: widget.house.houseId,
          landlordId: widget.house.landlordId,
          title: _titleController.text.trim(),
          price: double.tryParse(_priceController.text.trim()) ?? widget.house.price,
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          area: double.tryParse(_areaController.text.trim()) ?? widget.house.area,
          houseType: _houseTypeController.text.trim(),
          imageUrl: imageUrl,
          createdAt: widget.house.createdAt,
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
                                    'New image selected',
                                    style: TextStyle(
                                      color: Colors.green[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            : _imagePreviewUrl != null && _imagePreviewUrl!.isNotEmpty
                                ? Column(
                                    children: [
                                      Container(
                                        height: 150,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Colors.grey[100],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            _imagePreviewUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                AppConstants.defaultHouseImage,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Current image',
                                        style: TextStyle(
                                          color: Colors.grey[600],
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
                                          'No image available',
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
                          label: Text(_selectedImage != null ? 'Change Image' : 'Select New Image'),
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