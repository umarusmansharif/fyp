import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:renthouse/core/constants.dart';

class N8NAIService {
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _retryDelay = Duration(seconds: 2);
  static const int _maxRetries = 3;

  // N8N Production Webhook URL
  static const String _n8nWebhookUrl =
      'https://zair786.app.n8n.cloud/webhook/makandost_cutomer_support';

  // Prevent duplicate requests
  static final Set<String> _pendingRequests = <String>{};

  static DateTime? _lastRequestTime;

  static const Duration _minRequestInterval =
  Duration(milliseconds: 500);

  /// Send message to N8N AI Agent
  Future<String> sendMessage({
    required String message,
    required String userId,
    required String userType,
    Map<String, dynamic>? context,
  }) async {
    // Validate message
    if (message.trim().isEmpty) {
      return 'Please enter a message.';
    }

    final requestKey =
        '${userId}_${message.trim().hashCode}';

    // Prevent duplicate request
    if (_pendingRequests.contains(requestKey)) {
      return 'Please wait for the previous response...';
    }

    // Basic rate limiting
    if (_lastRequestTime != null) {
      final difference =
      DateTime.now().difference(_lastRequestTime!);

      if (difference < _minRequestInterval) {
        await Future.delayed(
          _minRequestInterval - difference,
        );
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
      print('FINAL ERROR: $e');

      return _handleError(e);
    } finally {
      _pendingRequests.remove(requestKey);
    }
  }

  /// Send request with retry logic
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
      };

      print('==============================');
      print('N8N REQUEST START');
      print('URL: $_n8nWebhookUrl');
      print('Payload: ${jsonEncode(payload)}');

      final response = await http
          .post(
        Uri.parse(_n8nWebhookUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      )
          .timeout(_defaultTimeout);

      print('STATUS CODE: ${response.statusCode}');
      print('RAW RESPONSE: ${response.body}');
      print('==============================');

      // Success
      if (response.statusCode == 200) {
        // Empty response check
        if (response.body.trim().isEmpty) {
          return 'Empty response received from AI.';
        }

        dynamic data;

        try {
          data = jsonDecode(response.body);
        } catch (e) {
          print('JSON PARSE ERROR: $e');

          return 'Invalid JSON response from server.';
        }

        print('DECODED RESPONSE: $data');

        String? botReply;

        // Case 1: Object response
        if (data is Map<String, dynamic>) {
          botReply =
              data['reply']?.toString() ??
                  data['output']?.toString() ??
                  data['response']?.toString() ??
                  data['text']?.toString();
        }

        // Case 2: List response
        else if (data is List && data.isNotEmpty) {
          final firstItem = data.first;

          if (firstItem is Map<String, dynamic>) {
            botReply =
                firstItem['reply']?.toString() ??
                    firstItem['output']?.toString() ??
                    firstItem['response']?.toString() ??
                    firstItem['text']?.toString();
          }
        }

        // Final validation
        if (botReply != null &&
            botReply.trim().isNotEmpty) {
          return botReply.trim();
        }

        return 'AI response format is invalid.';
      }

      // HTTP Errors
      print(
        'HTTP ERROR => ${response.statusCode}: ${response.body}',
      );

      throw HttpException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        uri: Uri.parse(_n8nWebhookUrl),
      );
    }

    // Internet issue
    on SocketException catch (e) {
      print('SOCKET ERROR: $e');

      if (retryCount < _maxRetries) {
        await Future.delayed(
          _retryDelay * (retryCount + 1),
        );

        return _sendRequestWithRetry(
          message: message,
          userId: userId,
          userType: userType,
          context: context,
          retryCount: retryCount + 1,
        );
      }

      return 'No internet connection. Please check your network.';
    }

    // Timeout
    on TimeoutException catch (e) {
      print('TIMEOUT ERROR: $e');

      if (retryCount < _maxRetries) {
        await Future.delayed(
          _retryDelay * (retryCount + 1),
        );

        return _sendRequestWithRetry(
          message: message,
          userId: userId,
          userType: userType,
          context: context,
          retryCount: retryCount + 1,
        );
      }

      return 'Request timeout. Please try again.';
    }

    // Other issues
    catch (e) {
      print('UNEXPECTED ERROR: $e');

      if (retryCount < _maxRetries) {
        await Future.delayed(
          _retryDelay * (retryCount + 1),
        );

        return _sendRequestWithRetry(
          message: message,
          userId: userId,
          userType: userType,
          context: context,
          retryCount: retryCount + 1,
        );
      }

      return 'Unexpected error: ${e.toString()}';
    }
  }

  /// Error messages
  String _handleError(dynamic error) {
    print('HANDLE ERROR => $error');

    if (error is HttpException) {
      return 'Server error. Please try again later.';
    }

    if (error is SocketException) {
      return 'No internet connection.';
    }

    if (error is TimeoutException) {
      return 'Request timeout.';
    }

    return error.toString();
  }

  /// Suggested questions
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

  /// Configuration check
  bool get isConfigured {
    return _n8nWebhookUrl.isNotEmpty;
  }

  /// Status
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