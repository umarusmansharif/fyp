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
    // Clean phone number - remove all non-numeric characters
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Convert 11-digit format (03XXXXXXXXX) to international format (923XXXXXXXXX)
    if (cleanPhone.startsWith('0') && cleanPhone.length == 11) {
      cleanPhone = '92' + cleanPhone.substring(1);
    }
    
    // Validate phone number (should be 12 digits starting with 92)
    if (cleanPhone.length != 12 || !cleanPhone.startsWith('92')) {
      throw 'Invalid phone number format. Expected 11 digits starting with 0';
    }
    
    // Create WhatsApp URL (format: https://wa.me/923XXXXXXXXX)
    final Uri whatsappUri = Uri.parse(
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    
    // Launch directly without canLaunchUrl check to avoid false negatives
    await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
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