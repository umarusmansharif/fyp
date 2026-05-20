import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('Information Collection', [
                'We collect information you provide directly, such as your name, email, phone number, and profile picture.',
                'We collect information about your use of our services, including property listings you view and interactions with other users.',
                'We may collect device information and location data when you use our app.',
              ]),
              _buildSection('How We Use Your Information', [
                'To provide, maintain, and improve our services.',
                'To process transactions and send you related information.',
                'To send you technical notices and support messages.',
                'To respond to your comments and questions.',
                'To monitor and analyze trends, usage, and activities.',
              ]),
              _buildSection('Information Sharing', [
                'We do not sell your personal information to third parties.',
                'We may share information with service providers who perform services on our behalf.',
                'We may share information when required by law or to protect our rights.',
              ]),
              _buildSection('Data Security', [
                'We implement appropriate security measures to protect your personal information.',
                'However, no method of transmission over the internet is 100% secure.',
              ]),
              _buildSection('Your Rights', [
                'You can access, update, or delete your account information.',
                'You can opt out of receiving promotional communications.',
                'You can request a copy of your personal data.',
              ]),
              _buildSection('Contact Us', [
                'If you have questions about this Privacy Policy, please contact us through the Contact Us section in the app.',
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...points.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}
