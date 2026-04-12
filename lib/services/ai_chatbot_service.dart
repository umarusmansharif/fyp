// ignore: unused_import
import 'dart:convert';
// ignore: unused_import
import 'package:http/http.dart' as http;

class AIChatbotService {
  // You can replace this with your preferred AI API
  // For now, using a rule-based system with predefined responses
  
  // ignore: unused_field
  static const String _apiKey = 'YOUR_API_KEY'; // Replace with actual API key
  // ignore: unused_field
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  // Predefined responses for common questions
  static final Map<String, String> _predefinedResponses = {
    'hello': 'Hello! Welcome to RentHouse. How can I help you today?',
    'hi': 'Hi there! I\'m here to help you with rental-related questions.',
    'how to use': 'To use RentHouse:\n\n1. **Tenants**: Browse properties, save favorites, and contact landlords\n2. **Landlords**: Add property listings, manage requests, and chat with tenants\n\nWhat would you like to know more about?',
    'search': 'You can search for properties by:\n• Location\n• Price range\n• Property type\n• Number of rooms\n• Amenities\n\nUse the Search tab to apply filters!',
    'add property': 'To add a property listing:\n1. Go to your Profile\n2. Tap "Add House" button\n3. Fill in property details\n4. Upload photos\n5. Submit the listing\n\nMake sure to provide accurate information!',
    'contact landlord': 'You can contact landlords in two ways:\n1. **In-app Chat**: Tap the Chat button on the property page\n2. **WhatsApp**: Use the WhatsApp button for direct messaging\n\nWhich would you prefer?',
    'favorite': 'To save a property to favorites:\n• Tap the heart icon on any property card\n• View all favorites in the Favorites tab\n• Remove anytime by tapping the heart again',
    'price': 'Property prices are listed in Pakistani Rupees (₨).\n\nYou can filter by price range in the Search screen to find properties within your budget.',
    'location': 'You can find properties by:\n• Browsing the map view\n• Searching by location name\n• Filtering by area\n\nEnable location services for nearby properties!',
    'safety': 'Safety tips:\n• Always verify property before payment\n• Meet landlords in person\n• Check property documents\n• Use in-app chat for records\n• Report suspicious listings',
    'payment': 'Payment arrangements should be discussed directly with the landlord.\n\nWe recommend:\n• Getting a receipt\n• Using bank transfers\n• Avoiding cash payments\n• Reading the lease carefully',
    'lease': 'A lease agreement should include:\n• Rent amount and due date\n• Lease duration\n• Security deposit\n• Maintenance responsibilities\n• Termination conditions\n\nAlways read carefully before signing!',
    'help': 'I can help you with:\n• Finding properties\n• Adding listings\n• Using app features\n• Rental tips\n• Safety guidelines\n\nWhat do you need help with?',
  };

  Future<String> getResponse(String userMessage) async {
    try {
      // First check for predefined responses
      final lowerMessage = userMessage.toLowerCase();
      
      for (final entry in _predefinedResponses.entries) {
        if (lowerMessage.contains(entry.key)) {
          return entry.value;
        }
      }

      // If no predefined response, try AI API (if configured)
      // For now, return a helpful default message
      return _getDefaultResponse(userMessage);
      
      // Uncomment below to use OpenAI API when you have an API key
      /*
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant for a house rental mobile app called RentHouse. Help users with property searches, listings, and rental-related questions. Keep responses concise and friendly.'
            },
            {
              'role': 'user',
              'content': userMessage
            }
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        return _getDefaultResponse(userMessage);
      }
      */
    } catch (e) {
      return 'Sorry, I encountered an error. Please try again or contact support.';
    }
  }

  String _getDefaultResponse(String message) {
    final responses = [
      'That\'s a great question! For specific inquiries, you can contact our support team or browse the help section in the app.',
      'I\'m here to help! Could you please rephrase that? I can assist with property searches, listings, and general rental questions.',
      'Thanks for your message! I specialize in helping with RentHouse app features. Try asking about searching, adding properties, or contacting landlords.',
      'I appreciate your question! For detailed assistance, please check the app\'s help section or contact customer support.',
    ];
    
    return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
  }

  // Get suggested questions
  List<String> getSuggestedQuestions() {
    return [
      'How do I search for properties?',
      'How to add a property listing?',
      'How to contact a landlord?',
      'What are the safety tips?',
      'How to save favorites?',
      'Tell me about lease agreements',
    ];
  }
}
