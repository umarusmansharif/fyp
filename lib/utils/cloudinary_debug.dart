import 'dart:io';
import 'package:renthouse/services/cloudinary_service.dart';

class CloudinaryDebug {
  // Test function to debug Cloudinary upload
  static Future<void> testCloudinaryUpload(String imagePath) async {
    print('=== Cloudinary Upload Debug ===');
    print('Testing upload with image path: $imagePath');
    
    File testImage = File(imagePath);
    
    if (!await testImage.exists()) {
      print('ERROR: Test image does not exist at path: $imagePath');
      return;
    }
    
    print('File exists, proceeding with upload test...');
    
    String? result = await CloudinaryService.uploadImageToCloudinary(testImage);
    
    if (result != null) {
      print('SUCCESS: Upload returned URL: $result');
    } else {
      print('FAILURE: Upload returned null - check the detailed logs above');
    }
    
    print('=== End Cloudinary Upload Debug ===');
  }
}