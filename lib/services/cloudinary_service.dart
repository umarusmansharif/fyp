import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart';

class CloudinaryService {
  // Cloudinary credentials
  static const String _cloudName = 'dg7f5ssue';
  static const String _uploadPreset = 'flutter_unsigned'; // Updated preset name for security
  
  // Upload image to Cloudinary with proper error handling
  static Future<String?> uploadImageToCloudinary(File image) async {
    try {
      // Validate file exists
      if (!await image.exists()) {
        print('Error: File does not exist at path: ${image.path}');
        return null;
      }
      
      // Validate file is not too large (Cloudinary free tier limit is 10MB)
      int fileSize = await image.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        print('Error: File size ${fileSize ~/ 1024} KB exceeds 10MB limit');
        return null;
      }
      
      print('Starting upload of file: ${basename(image.path)}, size: ${fileSize ~/ 1024} KB');
      
      // Create multipart request to the correct endpoint
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );
      
      // Add required fields for unsigned upload
      request.fields['upload_preset'] = _uploadPreset;
      
      // Optional: Add folder parameter to organize images
      request.fields['folder'] = 'new_app';
      
      // Additional parameters that might help with debugging
      request.fields['resource_type'] = 'image';
      
      // Add the image file with correct MIME type
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
          filename: basename(image.path),
        ),
      );
      
      // Send the request and get response
      print('About to send request to Cloudinary...');
      var response = await request.send();
      print('Request sent, getting response...');
      var responseString = await response.stream.bytesToString();
      
      print('Cloudinary upload response status: ${response.statusCode}');
      print('Cloudinary upload response headers: ${response.headers}');
      print('Content-Type header: ${response.headers['content-type']}');
      print('Cloudinary upload response body: $responseString');
      
      // Additional logging for debugging
      print('Raw response bytes length: ${responseString.length}');
      
      if (response.statusCode == 200) {
        // Parse the successful response
        dynamic responseData;
        try {
          responseData = json.decode(responseString);
          print('Parsed response data: $responseData');
        } catch (e) {
          print('Error parsing JSON response: $e');
          print('Raw response: $responseString');
          return null;
        }
        
        String? secureUrl = responseData['secure_url'];
        
        if (secureUrl != null) {
          print('Successfully uploaded image to Cloudinary: $secureUrl');
          return secureUrl;
        } else {
          print('Error: Response did not contain secure_url');
          print('Available keys in response: ${responseData.keys}');
          print('Full response: $responseData');
          
          // Check if there's an error field in the response
          if (responseData.containsKey('error')) {
            print('Error in response: ${responseData['error']}');
          }
          return null;
        }
      } else {
        // Handle different error status codes
        print('Cloudinary upload failed with status: ${response.statusCode}');
        print('Response body: $responseString');
        
        // Check for specific error messages
        if (responseString.contains('Invalid upload preset')) {
          print('ERROR: The upload preset "$_uploadPreset" does not exist or is not configured for unsigned uploads');
          print('SOLUTION: Go to Cloudinary Dashboard > Settings > Upload > Upload presets and create an unsigned preset named "$_uploadPreset"');
        } else if (responseString.contains('forbidden')) {
          print('ERROR: Upload forbidden - check Cloudinary account settings');
        } else if (responseString.contains('file size')) {
          print('ERROR: File size exceeds Cloudinary limits');
        } else {
          // Try to parse the error from JSON response
          try {
            var errorResponse = json.decode(responseString);
            if (errorResponse.containsKey('error') && errorResponse['error'].containsKey('message')) {
              print('Cloudinary Error: ${errorResponse['error']['message']}');
            }
          } catch (e) {
            print('Could not parse error response as JSON');
            print('Raw error response: $responseString');
          }
        }
        
        return null;
      }
    } catch (e) {
      print('Exception during Cloudinary upload: $e');
      print('Stack trace:');
      print(e.toString());
      
      // More specific error handling
      if (e is http.ClientException) {
        print('Network error: Failed to connect to Cloudinary server');
      } else if (e is SocketException) {
        print('Network error: No internet connection');
      } else {
        print('Unexpected error: $e');
      }
      
      return null;
    }
  }

  // Delete image from Cloudinary
  static Future<bool> deleteImageFromCloudinary(String imageUrl) async {
    try {
      // Extract public ID from the image URL
      // Cloudinary URLs typically follow the format: https://res.cloudinary.com/cloudName/image/upload/folder/publicId
      // or https://res.cloudinary.com/cloudName/image/upload/publicId
      String publicId = _extractPublicIdFromUrl(imageUrl);
      
      if (publicId.isEmpty) {
        print('Could not extract public ID from URL: $imageUrl');
        return false;
      }
      
      // For unsigned deletion, we would typically need an API key and secret
      // Since we're using unsigned upload, we might not be able to delete without proper credentials
      // This is a limitation of unsigned uploads - they're typically used for client-side uploads
      // but deletion requires server-side authentication
      
      // In a real implementation, you'd need to call the Cloudinary API to delete the image
      // This would typically be done server-side, not from the client app
      print('Note: Actual deletion from Cloudinary requires server-side API call');
      print('Public ID to delete: $publicId');
      
      // For now, we'll just return true to indicate that the process would happen
      return true;
    } catch (e) {
      print('Error extracting public ID or preparing for deletion: $e');
      return false;
    }
  }
  
  // Helper method to extract public ID from Cloudinary URL
  static String _extractPublicIdFromUrl(String url) {
    try {
      if (url.contains('cloudinary.com')) {
        // Example URL: https://res.cloudinary.com/dg7f5ssue/image/upload/new_app/abc123.jpg
        // We want to extract 'new_app/abc123' or 'abc123' depending on the structure
        var uri = Uri.parse(url);
        var pathSegments = uri.path.split('/');
        
        // Find the position after 'upload'
        int uploadIndex = pathSegments.indexOf('upload');
        if (uploadIndex != -1 && uploadIndex < pathSegments.length - 1) {
          // Join all segments after 'upload' to get the public ID
          String publicId = pathSegments.sublist(uploadIndex + 1).join('/');
          // Remove file extension if present
          if (publicId.contains('.')) {
            publicId = publicId.substring(0, publicId.lastIndexOf('.'));
          }
          return publicId;
        }
      }
      return '';
    } catch (e) {
      print('Error parsing Cloudinary URL: $e');
      return '';
    }
  }
}