import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildFAQ(
                'How do I create an account?',
                'Download the app and click "Sign Up". Fill in your details, select your role (Tenant or Landlord), and follow the instructions to complete registration.',
              ),
              _buildFAQ(
                'Can I switch between Tenant and Landlord roles?',
                'No, once you select a role during signup, it cannot be changed. This ensures proper account security and data integrity.',
              ),
              _buildFAQ(
                'How do I search for properties?',
                'Use the search bar on the Dashboard to find properties by location, price, or other filters. You can also use the "Near You" feature to see properties close to your current location.',
              ),
              _buildFAQ(
                'How do I contact a landlord?',
                'Open a property listing and click the "Contact" button to start a chat with the landlord directly through our secure messaging system.',
              ),
              _buildFAQ(
                'How do I list my property?',
                'Landlords can click the "+" button on the Dashboard to add a new property listing. Fill in all required details including photos, price, and location.',
              ),
              _buildFAQ(
                'How do I schedule a property visit?',
                'After finding a property you like, click "Request Visit" to schedule a viewing. The landlord will receive your request and can confirm or reschedule.',
              ),
              _buildFAQ(
                'Are reviews and ratings reliable?',
                'Only tenants who have interacted with a property can submit reviews. Landlords cannot rate their own properties, ensuring authenticity.',
              ),
              _buildFAQ(
                'How do I reset my password?',
                'On the Login screen, click "Forgot Password" and enter your email. A password reset link will be sent to your registered email address.',
              ),
              _buildFAQ(
                'Is my personal information secure?',
                'Yes, we use industry-standard encryption and security measures to protect your data. Read our Privacy Policy for more details.',
              ),
              _buildFAQ(
                'How do I delete my account?',
                'Go to Profile > Settings > Delete Account. Note that this action is irreversible and all your data will be permanently removed.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQ(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
