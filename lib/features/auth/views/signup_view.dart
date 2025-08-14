import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/signup_controller.dart';
import '../../../core/utils/theme.dart';

class SignupView extends StatelessWidget {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignupController());
    
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          switch (controller.currentStep.value) {
            case 0:
              return _buildSignupForm(controller);
            case 1:
              return _buildEmailOtpVerification(controller);
            case 2:
              return _buildPhoneOtpVerification(controller);
            default:
              return _buildSignupForm(controller);
          }
        }),
      ),
    );
  }

  Widget _buildSignupForm(SignupController controller) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Join 360Ghar to find your perfect home',
                style: Theme.of(Get.context!).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Full Name Field
              TextFormField(
                controller: controller.fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Email Field
              TextFormField(
                controller: controller.emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!GetUtils.isEmail(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Phone Field
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.trim().length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Password Field
              Obx(() => TextFormField(
                controller: controller.passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: controller.togglePasswordVisibility,
                    icon: Icon(
                      controller.isPasswordVisible.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                obscureText: !controller.isPasswordVisible.value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              )),
              const SizedBox(height: 16),
              
              // Confirm Password Field
              Obx(() => TextFormField(
                controller: controller.confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: controller.toggleConfirmPasswordVisibility,
                    icon: Icon(
                      controller.isConfirmPasswordVisible.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                obscureText: !controller.isConfirmPasswordVisible.value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != controller.passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              )),
              const SizedBox(height: 24),
              
              // Terms and Privacy
              Text(
                'By creating an account, you agree to our Terms of Service and Privacy Policy',
                style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Sign Up Button
              Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.signUp,
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
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              )),
              const SizedBox(height: 16),
              
              // Login Link
              TextButton(
                onPressed: controller.goToLogin,
                child: const Text('Already have an account? Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailOtpVerification(SignupController controller) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton(
                onPressed: controller.goBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text(
                  'Verify Email',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 32),
          
          const Icon(
            Icons.email_outlined,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),
          
          Text(
            'We\'ve sent a verification code to',
            style: Theme.of(Get.context!).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            controller.emailController.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // OTP Input
          TextFormField(
            controller: controller.emailOtpController,
            decoration: const InputDecoration(
              labelText: 'Enter 6-digit code',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.security),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, letterSpacing: 2),
          ),
          const SizedBox(height: 24),
          
          // Verify Button
          Obx(() => ElevatedButton(
            onPressed: controller.isLoading.value ? null : controller.verifyEmailOtp,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryColor,
            ),
            child: controller.isLoading.value
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Verify Email',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          )),
          const SizedBox(height: 16),
          
          // Resend Code
          Obx(() => TextButton(
            onPressed: controller.canResendEmailOtp.value 
                ? controller.resendEmailOtp 
                : null,
            child: Text(
              controller.canResendEmailOtp.value
                  ? 'Resend Code'
                  : 'Resend in ${controller.emailOtpCountdown.value}s',
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPhoneOtpVerification(SignupController controller) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton(
                onPressed: controller.goBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text(
                  'Verify Phone',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 32),
          
          const Icon(
            Icons.phone_android,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),
          
          Text(
            'We\'ve sent a verification code to',
            style: Theme.of(Get.context!).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            controller.phoneController.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // OTP Input
          TextFormField(
            controller: controller.phoneOtpController,
            decoration: const InputDecoration(
              labelText: 'Enter 6-digit code',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.security),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, letterSpacing: 2),
          ),
          const SizedBox(height: 24),
          
          // Verify Button
          Obx(() => ElevatedButton(
            onPressed: controller.isLoading.value ? null : controller.verifyPhoneOtp,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryColor,
            ),
            child: controller.isLoading.value
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Verify Phone',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          )),
          const SizedBox(height: 16),
          
          // Skip Phone Verification
          TextButton(
            onPressed: controller.skipPhoneVerification,
            child: const Text(
              'Skip Phone Verification',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          
          // Resend Code
          Obx(() => TextButton(
            onPressed: controller.canResendPhoneOtp.value 
                ? controller.resendPhoneOtp 
                : null,
            child: Text(
              controller.canResendPhoneOtp.value
                  ? 'Resend Code'
                  : 'Resend in ${controller.phoneOtpCountdown.value}s',
            ),
          )),
        ],
      ),
    );
  }
}