import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class Helpers {
  // Format currency
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '₨${formatter.format(amount)}';
  }

  // Format date
  static String formatDate(DateTime date) {
    final formatter = DateFormat('MMM dd, yyyy');
    return formatter.format(date);
  }

  // Launch WhatsApp with pre-filled message
  static Future<void> launchWhatsApp(String phoneNumber, String message) async {
    // Clean and format phone number
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Remove leading zeros and add country code if not present
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '+92' + cleanPhone.substring(1);
    } else if (!cleanPhone.startsWith('+')) {
      cleanPhone = '+92' + cleanPhone;
    }
    
    // Validate phone number
    if (!_isValidWhatsAppNumber(cleanPhone)) {
      throw 'Invalid phone number format';
    }
    
    final Uri whatsappUri = Uri.parse(
        'https://wa.me/${cleanPhone.substring(1)}?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      throw 'Could not launch WhatsApp. Please make sure WhatsApp is installed.';
    }
  }
  
  // Validate WhatsApp number format
  static bool _isValidWhatsAppNumber(String phoneNumber) {
    // Remove + sign for validation
    String cleanPhone = phoneNumber.replaceAll('+', '');
    
    // Check if it's a valid Pakistani number (92 followed by 9-10 digits)
    if (cleanPhone.startsWith('92') && cleanPhone.length >= 11 && cleanPhone.length <= 12) {
      return RegExp(r'^92[0-9]{9,10}$').hasMatch(cleanPhone);
    }
    
    return false;
  }

  // Validate email
  static bool isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Validate phone number (simple validation)
  static bool isValidPhone(String phone) {
    // Simple validation for Pakistani phone numbers
    final RegExp phoneRegex = RegExp(r'^(\+92|0)[0-9]{10}$');
    return phoneRegex.hasMatch(phone);
  }
}