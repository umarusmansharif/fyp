import 'package:renthouse/services/n8n_ai_service.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/services/auth_service.dart';
import 'package:renthouse/services/database_service.dart';

class AIChatbotService {
  final N8NAIService _n8nService = N8NAIService();
  final AuthService _authService = AuthService();
  
  // Fallback responses for when N8N is not available
  static final Map<String, String> _fallbackResponses = {
    'hello': 'Hello! Welcome to RentHouse. How can I help you today?',
    'hi': 'Hi there! I\'m here to help you with rental-related questions.',
    'help': 'I can help you with:\n• Finding properties\n• Adding listings\n• Using app features\n• Rental tips\n• Safety guidelines\n\nWhat do you need help with?',
  };

  Future<String> getResponse(String userMessage) async {
    try {
      // Get current user info
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        return 'Please sign in to use the AI assistant.';
      }

      // Check if N8N service is configured
      if (_n8nService.isConfigured) {
        // Get user type for context
        String userType = AppConstants.userTypeTenant; // default
        try {
          final databaseService = DatabaseService();
          final userModel = await databaseService.getUser(currentUser.uid);
          userType = userModel?.userType ?? AppConstants.userTypeTenant;
        } catch (e) {
          // Use default if user type retrieval fails
        }
        
        // Use N8N AI service
        final response = await _n8nService.sendMessage(
          message: userMessage,
          userId: currentUser.uid,
          userType: userType,
        );
        return response;
      } else {
        // Fallback to basic responses
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      // Return fallback response if N8N fails
      return _getFallbackResponse(userMessage);
    }
  }

  String _getFallbackResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Check for basic fallback responses
    for (final entry in _fallbackResponses.entries) {
      if (lowerMessage.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default fallback responses
    final responses = [
      'I\'m here to help! For specific assistance, please check the app\'s help section or contact customer support.',
      'Thanks for your message! I can assist with basic RentHouse app features. Try asking about searching properties or managing listings.',
      'I appreciate your question! For detailed assistance, please explore the app or contact our support team.',
    ];
    
    return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
  }

  // Get role-based suggested questions
  Future<List<String>> getSuggestedQuestions() async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      return [
        'How do I use the RentHouse app?',
        'What are the safety tips for renting?',
        'How to create a good listing?',
      ];
    }

    // Try to get user type from database
    try {
      // Import DatabaseService here to avoid circular dependency
      final databaseService = DatabaseService();
      final userModel = await databaseService.getUser(currentUser.uid);
      final userType = userModel?.userType ?? AppConstants.userTypeTenant;
      
      return _n8nService.getSuggestedQuestions(userType);
    } catch (e) {
      // Fallback to tenant suggestions
      return _n8nService.getSuggestedQuestions(AppConstants.userTypeTenant);
    }
  }

  // Get configuration status
  Map<String, dynamic> getConfigurationStatus() {
    return _n8nService.getConfigurationStatus();
  }
}
