import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/profile_completion_controller.dart';
import '../../../core/utils/theme.dart';

class ProfileCompletionView extends StatelessWidget {
  const ProfileCompletionView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileCompletionController>(
      builder: (controller) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: controller.formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Header
                      const Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Help us personalize your property search experience',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Progress Indicator
                      LinearProgressIndicator(
                        value: controller.currentStep.value / 3,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Step ${controller.currentStep.value + 1} of 3',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Step Content
                      _buildStepContent(controller),
                      
                      const SizedBox(height: 32),
                      
                      // Navigation Buttons
                      _buildNavigationButtons(controller),
                      
                      const SizedBox(height: 16),
                      
                      // Skip Button
                      TextButton(
                        onPressed: controller.skipToHome,
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(ProfileCompletionController controller) {
    switch (controller.currentStep.value) {
      case 0:
        return _buildPersonalInfoStep(controller);
      case 1:
        return _buildPropertyPreferencesStep(controller);
      case 2:
        return _buildLocationPreferencesStep(controller);
      default:
        return _buildPersonalInfoStep(controller);
    }
  }

  Widget _buildNavigationButtons(ProfileCompletionController controller) {
    return Row(
      children: [
        if (controller.currentStep.value > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: controller.previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Back'),
            ),
          ),
        if (controller.currentStep.value > 0) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: controller.isLoading.value 
                ? null 
                : (controller.currentStep.value < 2 
                    ? controller.nextStep 
                    : controller.completeProfile),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    controller.currentStep.value < 2 ? 'Next' : 'Complete',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep(ProfileCompletionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Date of Birth
        TextFormField(
          controller: controller.dateOfBirthController,
          decoration: const InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: Icon(Icons.cake_outlined),
            border: OutlineInputBorder(),
            hintText: 'DD/MM/YYYY',
          ),
          readOnly: true,
          onTap: () => controller.selectDateOfBirth(),
        ),
        const SizedBox(height: 16),
        
        // Phone Number (if not already provided)
        if (controller.phoneController.text.isEmpty) ...[
          TextFormField(
            controller: controller.phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
              hintText: '+91 98765 43210',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        // Occupation
        TextFormField(
          controller: controller.occupationController,
          decoration: const InputDecoration(
            labelText: 'Occupation',
            prefixIcon: Icon(Icons.work_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        
        // Annual Income
        DropdownButtonFormField<String>(
          value: controller.selectedIncome.value.isEmpty 
              ? null 
              : controller.selectedIncome.value,
          decoration: const InputDecoration(
            labelText: 'Annual Income',
            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            border: OutlineInputBorder(),
          ),
          items: controller.incomeRanges.map((String income) {
            return DropdownMenuItem<String>(
              value: income,
              child: Text(income),
            );
          }).toList(),
          onChanged: (String? value) {
            if (value != null) {
              controller.selectedIncome.value = value;
              controller.update();
            }
          },
        ),
      ],
    );
  }

  Widget _buildPropertyPreferencesStep(ProfileCompletionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Property Preferences',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Property Purpose
        const Text('What are you looking for?'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: controller.propertyPurposes.map((purpose) {
            final isSelected = controller.selectedPropertyPurpose.value == purpose;
            return ChoiceChip(
              label: Text(purpose.capitalize ?? purpose),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  controller.selectedPropertyPurpose.value = purpose;
                  controller.update();
                }
              },
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        
        // Property Types
        const Text('Property Types'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: controller.propertyTypes.map((type) {
            final isSelected = controller.selectedPropertyTypes.contains(type);
            return FilterChip(
              label: Text(type.capitalize ?? type),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  controller.selectedPropertyTypes.add(type);
                } else {
                  controller.selectedPropertyTypes.remove(type);
                }
                controller.update();
              },
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        
        // Budget Range
        const Text('Budget Range'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.budgetMinController,
                decoration: const InputDecoration(
                  labelText: 'Min Budget',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controller.budgetMaxController,
                decoration: const InputDecoration(
                  labelText: 'Max Budget',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Bedrooms
        const Text('Number of Bedrooms'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: controller.selectedBedroomsMin.value == 0 
                    ? null 
                    : controller.selectedBedroomsMin.value,
                decoration: const InputDecoration(
                  labelText: 'Min',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(6, (index) => index).map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value == 0 ? 'Any' : value.toString()),
                  );
                }).toList(),
                onChanged: (int? value) {
                  if (value != null) {
                    controller.selectedBedroomsMin.value = value;
                    controller.update();
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: controller.selectedBedroomsMax.value == 0 
                    ? null 
                    : controller.selectedBedroomsMax.value,
                decoration: const InputDecoration(
                  labelText: 'Max',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(6, (index) => index).map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value == 0 ? 'Any' : value.toString()),
                  );
                }).toList(),
                onChanged: (int? value) {
                  if (value != null) {
                    controller.selectedBedroomsMax.value = value;
                    controller.update();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationPreferencesStep(ProfileCompletionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location Preferences',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Current Location Button
        ElevatedButton.icon(
          onPressed: controller.getCurrentLocation,
          icon: const Icon(Icons.my_location),
          label: const Text('Use Current Location'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentOrange,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Preferred Cities
        const Text('Preferred Cities'),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.preferredCitiesController,
          decoration: const InputDecoration(
            labelText: 'Enter cities (comma-separated)',
            prefixIcon: Icon(Icons.location_city),
            border: OutlineInputBorder(),
            hintText: 'e.g., Gurgaon, Delhi, Noida',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        
        // Max Distance
        const Text('Maximum Distance'),
        const SizedBox(height: 8),
        Column(
          children: [
            Slider(
              value: controller.maxDistance.value,
              min: 1,
              max: 50,
              divisions: 49,
              label: '${controller.maxDistance.value.round()} km',
              onChanged: (value) {
                controller.maxDistance.value = value;
                controller.update();
              },
              activeColor: AppTheme.primaryColor,
            ),
            Text(
              '${controller.maxDistance.value.round()} km from preferred locations',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Preferred Amenities
        const Text('Preferred Amenities'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: controller.amenities.map((amenity) {
            final isSelected = controller.selectedAmenities.contains(amenity);
            return FilterChip(
              label: Text(amenity.replaceAll('_', ' ').capitalize ?? amenity),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  controller.selectedAmenities.add(amenity);
                } else {
                  controller.selectedAmenities.remove(amenity);
                }
                controller.update();
              },
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}