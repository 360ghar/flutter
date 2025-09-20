import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/mixins/theme_mixin.dart';
import '../controllers/edit_profile_controller.dart';
import 'package:ghar360/core/widgets/common/robust_network_image.dart';

class EditProfileView extends GetView<EditProfileController> with ThemeMixin {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return buildThemeAwareScaffold(
      title: 'edit_profile'.tr,
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.loadingIndicator),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: controller.formKey,
            child: Column(
              children: [
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      Obx(() {
                        return controller.profileImageUrl.value.isNotEmpty
                            ? RobustNetworkImageExtension.circular(
                                imageUrl: controller.profileImageUrl.value,
                                radius: 60,
                                errorWidget: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: AppColors.primaryYellow,
                                  child: Text(
                                    controller.nameController.text.isNotEmpty
                                        ? controller.nameController.text[0]
                                              .toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.buttonText,
                                    ),
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                radius: 60,
                                backgroundColor: AppColors.primaryYellow,
                                child: Text(
                                  controller.nameController.text.isNotEmpty
                                      ? controller.nameController.text[0]
                                            .toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.buttonText,
                                  ),
                                ),
                              );
                      }),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 3,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.camera_alt,
                              color: AppColors.buttonText,
                              size: 20,
                            ),
                            onPressed: controller.pickProfileImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Form Fields
                buildThemeAwareCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildSectionTitle('personal_information'.tr),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: controller.nameController,
                        label: 'full_name'.tr,
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'name_required'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: controller.emailController,
                        label: 'email_address'.tr,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              !GetUtils.isEmail(value)) {
                            return 'valid_email_required'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: controller.locationController,
                        label: 'location'.tr,
                        icon: Icons.location_on_outlined,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Date of Birth Section
                buildThemeAwareCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildSectionTitle('additional_information'.tr),
                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () => controller.selectDateOfBirth(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppColors.iconColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Obx(
                                  () => Text(
                                    controller.dateOfBirth.value != null
                                        ? controller.formatDate(
                                            controller.dateOfBirth.value!,
                                          )
                                        : 'select_your_date_of_birth'.tr,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          controller.dateOfBirth.value != null
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              if (controller.dateOfBirth.value != null)
                                GestureDetector(
                                  onTap: controller.clearDateOfBirth,
                                  child: Icon(
                                    Icons.clear,
                                    color: AppColors.iconColor,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonBackground,
                      foregroundColor: AppColors.buttonText,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      controller.isLoading.value
                          ? 'saving'.tr
                          : 'save_changes'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.iconColor),
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryYellow, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
