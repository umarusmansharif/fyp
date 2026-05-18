import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:renthouse/core/constants.dart';

class N8NAIService {
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _retryDelay = Duration(seconds: 2);
  static const int _maxRetries = 3;
  
  // N8N Configuration - Replace with your actual N8N webhook URL
  static const String _n8nWebhookUrl = 'YOUR_N8N_WEBHOOK_URL';
  
  // Request tracking to prevent duplicates
  static final Set<String> _pendingRequests = <String>{};
  static DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(milliseconds: 500);

  /// Send message to N8N AI Agent and get response
  Future<String> sendMessage({
    required String message,
    required String userId,
    required String userType,
    Map<String, dynamic>? context,
  }) async {
    // Validate inputs
    if (message.trim().isEmpty) {
      return 'Please enter a message.';
    }

    // Prevent duplicate requests
    final requestKey = '${userId}_${message.hashCode}';
    if (_pendingRequests.contains(requestKey)) {
      return 'Please wait for the previous response...';
    }

    // Rate limiting
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - timeSinceLastRequest);
      }
    }

    _pendingRequests.add(requestKey);
    _lastRequestTime = DateTime.now();

    try {
      final response = await _sendRequestWithRetry(
        message: message,
        userId: userId,
        userType: userType,
        context: context,
      );
      
      return response;
    } catch (e) {
      return _handleError(e);
    } finally {
      _pendingRequests.remove(requestKey);
    }
  }

  /// Send HTTP request with retry logic
  Future<String> _sendRequestWithRetry({
    required String message,
    required String userId,
    required String userType,
    Map<String, dynamic>? context,
    int retryCount = 0,
  }) async {
    try {
      final payload = {
        'message': message.trim(),
        'userId': userId,
        'userType': userType,
        'timestamp': DateTime.now().toIso8601String(),
        'app': 'renthouse',
        'context': context ?? {},
      };

      final response = await http
          .post(
            Uri.parse(_n8nWebhookUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'RentHouse-App/1.0',
            },
            body: jsonEncode(payload),
          )
          .timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Handle different response formats
        if (responseData is Map<String, dynamic>) {
          return responseData['response'] ?? 
                 responseData['message'] ?? 
                 responseData['text'] ?? 
                 'Sorry, I could not process your request.';
        } else if (responseData is String) {
          return responseData;
        } else {
          return 'Received an unexpected response format.';
        }
      } else {
        throw HttpException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _sendRequestWithRetry(
          message: message,
          userId: userId,
          userType: userType,
          context: context,
          retryCount: retryCount + 1,
        );
      }
      throw 'No internet connection. Please check your network and try again.';
    } on TimeoutException {
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _sendRequestWithRetry(
          message: message,
          userId: userId,
          userType: userType,
          context: context,
          retryCount: retryCount + 1,
        );
      }
      throw 'Request timed out. Please try again.';
    } on HttpException {
      rethrow;
    } catch (e) {
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _sendRequestWithRetry(
          message: message,
          userId: userId,
          userType: userType,
          context: context,
          retryCount: retryCount + 1,
        );
      }
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }

  /// Handle different types of errors
  String _handleError(dynamic error) {
    if (error is HttpException) {
      switch (error.statusCode) {
        case 400:
          return 'Invalid request. Please try again.';
        case 401:
          return 'Authentication failed. Please contact support.';
        case 403:
          return 'Access denied. Please contact support.';
        case 404:
          return 'Service not available. Please try again later.';
        case 429:
          return 'Too many requests. Please wait and try again.';
        case 500:
          return 'Server error. Please try again later.';
        case 503:
          return 'Service temporarily unavailable. Please try again later.';
        default:
          return 'Service error (${error.statusCode}). Please try again.';
      }
    } else if (error is String) {
      return error;
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get role-based suggested questions
  List<String> getSuggestedQuestions(String userType) {
    switch (userType.toLowerCase()) {
      case AppConstants.userTypeLandlord:
        return [
          'How do I add a new property listing?',
          'How to manage rental requests?',
          'How to update property details?',
          'What are the best pricing strategies?',
          'How to handle tenant inquiries?',
          'Tell me about property maintenance',
        ];
      case AppConstants.userTypeTenant:
        return [
          'How do I search for properties?',
          'How to contact a landlord?',
          'What are the rental requirements?',
          'How to schedule a property visit?',
          'What should I check before renting?',
          'Tell me about lease agreements',
        ];
      default:
        return [
          'How do I use the RentHouse app?',
          'What are the safety tips for renting?',
          'How to create a good listing?',
          'What are the rental best practices?',
          'How to handle rental disputes?',
          'Tell me about the app features',
        ];
    }
  }

  /// Check if N8N service is configured
  bool get isConfigured {
    return _n8nWebhookUrl != 'YOUR_N8N_WEBHOOK_URL' && 
           _n8nWebhookUrl.isNotEmpty;
  }

  /// Get configuration status
  Map<String, dynamic> getConfigurationStatus() {
    return {
      'isConfigured': isConfigured,
      'webhookUrl': _n8nWebhookUrl,
      'timeout': _defaultTimeout.inSeconds,
      'maxRetries': _maxRetries,
      'retryDelay': _retryDelay.inSeconds,
    };
  }
}

/// Custom exceptions for better error handling
class HttpException implements Exception {
  final String message;
  final int statusCode;
  
  const HttpException(this.message, {required this.statusCode});
  
  @override
  String toString() => message;
}

class SocketException implements Exception {
  final String message;
  const SocketException(this.message);
  
  @override
  String toString() => message;
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);
  
  @override
  String toString() => message;
}
