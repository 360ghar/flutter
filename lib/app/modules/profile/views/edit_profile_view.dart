import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/edit_profile_controller.dart';
import '../../../utils/theme.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Obx(() => TextButton(
            onPressed: controller.isLoading.value ? null : () => controller.saveProfile(),
            child: Text(
              'Save',
              style: TextStyle(
                color: controller.isLoading.value ? Colors.grey : AppTheme.primaryYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.nameController.text.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryYellow,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      Obx(() => CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryYellow,
                        backgroundImage: controller.profileImageUrl.value.isNotEmpty
                            ? NetworkImage(controller.profileImageUrl.value)
                            : null,
                        child: controller.profileImageUrl.value.isEmpty
                            ? Text(
                                controller.nameController.text.isNotEmpty 
                                    ? controller.nameController.text[0].toUpperCase() 
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              )
                            : null,
                      )),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => controller.pickProfileImage(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryYellow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Name Field (Required)
                _buildSectionTitle('Name *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.nameController,
                  decoration: _buildInputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: Icons.person,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email Field
                _buildSectionTitle('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.emailController,
                  decoration: _buildInputDecoration(
                    hintText: 'Enter your email address',
                    prefixIcon: Icons.email,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !GetUtils.isEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Phone Field (Required)
                _buildSectionTitle('Phone Number *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.phoneController,
                  decoration: _buildInputDecoration(
                    hintText: 'Enter your phone number',
                    prefixIcon: Icons.phone,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Location Field
                _buildSectionTitle('Location'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.locationController,
                  decoration: _buildInputDecoration(
                    hintText: 'Enter your city/location',
                    prefixIcon: Icons.location_on,
                  ),
                ),
                const SizedBox(height: 20),

                // Date of Birth Field
                _buildSectionTitle('Date of Birth'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => controller.selectDateOfBirth(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(() => Text(
                            controller.dateOfBirth.value != null
                                ? controller.formatDate(controller.dateOfBirth.value!)
                                : 'Select your date of birth',
                            style: TextStyle(
                              fontSize: 16,
                              color: controller.dateOfBirth.value != null 
                                  ? Colors.black 
                                  : Colors.grey[600],
                            ),
                          )),
                        ),
                        if (controller.dateOfBirth.value != null)
                          GestureDetector(
                            onTap: () => controller.clearDateOfBirth(),
                            child: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : () => controller.saveProfile(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  )),
                ),
                const SizedBox(height: 20),

                // Required Fields Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Fields marked with * are required',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[600]),
      prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryYellow, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
} 