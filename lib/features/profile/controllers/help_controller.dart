import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelpController extends GetxController {
  
  void contactSupport() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'How would you like to contact us?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildContactOption(
              'Email Support',
              'Get help via email',
              Icons.email,
              sendEmail,
            ),
            _buildContactOption(
              'Phone Support',
              'Call our support team',
              Icons.phone,
              callSupport,
            ),
            _buildContactOption(
              'Live Chat',
              'Chat with an agent',
              Icons.chat,
              startLiveChat,
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildContactOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Get.theme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        Get.back();
        onTap();
      },
    );
  }

  void startLiveChat() {
    Get.dialog(
      AlertDialog(
        title: const Text('Live Chat'),
        content: const Text(
          'Live chat is currently unavailable. Please contact us via email or phone for immediate assistance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              sendEmail();
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void reportProblem() {
    Get.dialog(
      AlertDialog(
        title: const Text('Report a Problem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Problem Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Describe the problem',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Success', 'Problem report submitted successfully');
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void sendEmail() {
    Get.snackbar(
      'Email',
      'Opening email app to contact support@ghar360.com',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void callSupport() {
    Get.snackbar(
      'Phone',
      'Calling support at +91-9876543210',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void openHelpCenter() {
    Get.snackbar(
      'Help Center',
      'Opening help center in browser',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void showGettingStarted() {
    Get.dialog(
      AlertDialog(
        title: const Text('Getting Started'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Search Properties',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Use the search bar to find properties by location, price, and other filters.'),
              SizedBox(height: 12),
              Text(
                '2. Save Favorites',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Tap the heart icon to save properties you like.'),
              SizedBox(height: 12),
              Text(
                '3. Schedule Tours',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Book property visits directly through the app.'),
              SizedBox(height: 12),
              Text(
                '4. Contact Agents',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Connect with property agents for more information.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void showSearchTips() {
    Get.dialog(
      AlertDialog(
        title: const Text('Property Search Tips'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• Use specific locations',
                style: TextStyle(fontSize: 14),
              ),
              Text('Search for specific neighborhoods or areas for better results.'),
              SizedBox(height: 8),
              Text(
                '• Set realistic price ranges',
                style: TextStyle(fontSize: 14),
              ),
              Text('Use the price filter to narrow down to your budget.'),
              SizedBox(height: 8),
              Text(
                '• Use multiple filters',
                style: TextStyle(fontSize: 14),
              ),
              Text('Combine location, price, size, and amenity filters.'),
              SizedBox(height: 8),
              Text(
                '• Save your searches',
                style: TextStyle(fontSize: 14),
              ),
              Text('Get notifications when new properties match your criteria.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void showAccountManagement() {
    Get.dialog(
      AlertDialog(
        title: const Text('Account Management'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Settings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Update your personal information in Edit Profile.'),
              SizedBox(height: 12),
              Text(
                'Preferences',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Customize app behavior in My Preferences.'),
              SizedBox(height: 12),
              Text(
                'Notifications',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Control what notifications you receive.'),
              SizedBox(height: 12),
              Text(
                'Privacy & Security',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Manage your privacy settings and account security.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void showPrivacyHelp() {
    Get.dialog(
      AlertDialog(
        title: const Text('Privacy & Security'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Protection',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('We use industry-standard encryption to protect your data.'),
              SizedBox(height: 12),
              Text(
                'Privacy Controls',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('You can control what information is shared and with whom.'),
              SizedBox(height: 12),
              Text(
                'Account Security',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Enable two-factor authentication for added security.'),
              SizedBox(height: 12),
              Text(
                'Data Rights',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('You can download, modify, or delete your data at any time.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void rateApp() {
    Get.dialog(
      AlertDialog(
        title: const Text('Rate Ghar360'),
        content: const Text(
          'Enjoying Ghar360? Please take a moment to rate us on the app store. Your feedback helps us improve!',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Thank you', 'Opening app store...');
            },
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }
}