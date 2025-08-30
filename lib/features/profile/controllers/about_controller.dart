import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AboutController extends GetxController {
  void openPrivacyPolicy() {
    Get.snackbar(
      'Privacy Policy',
      'Opening privacy policy in browser',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void openTermsOfService() {
    Get.snackbar(
      'Terms of Service',
      'Opening terms of service in browser',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void openLicenseAgreement() {
    Get.snackbar(
      'License Agreement',
      'Opening license agreement in browser',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void openOpenSourceLicenses() {
    Get.dialog(
      AlertDialog(
        title: const Text('Open Source Licenses'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This app uses the following open source libraries:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('• Flutter Framework (BSD-3-Clause)'),
              Text('• GetX (MIT License)'),
              Text('• Google Fonts (Apache License 2.0)'),
              Text('• Cached Network Image (MIT License)'),
              Text('• Get Storage (MIT License)'),
              Text('• Flutter SVG (MIT License)'),
              Text('• Shimmer (MIT License)'),
              Text('• Geolocator (MIT License)'),
              Text('• Flutter Map (BSD-3-Clause)'),
              Text('• WebView Flutter (BSD-3-Clause)'),
              SizedBox(height: 16),
              Text(
                'For full license texts, visit:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('https://ghar360.com/licenses'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  void openFacebook() {
    Get.snackbar(
      'Facebook',
      'Opening Facebook page',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void openTwitter() {
    Get.snackbar(
      'Twitter',
      'Opening Twitter profile',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void openInstagram() {
    Get.snackbar(
      'Instagram',
      'Opening Instagram profile',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void openLinkedIn() {
    Get.snackbar(
      'LinkedIn',
      'Opening LinkedIn company page',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
