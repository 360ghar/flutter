import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../controllers/login_controller.dart';
import '../../../core/utils/theme.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            return _buildUnifiedAuth(context, controller);
          }),
        ),
      ),
    );
  }

  Widget _buildUnifiedAuth(BuildContext context, LoginController controller) {
    final isLogin = controller.flow.value == 'login';
    final step = controller.currentStep.value;
    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                if (step > 0)
                  IconButton(
                    onPressed: () {
                      if (step > 0) controller.currentStep.value = step - 1;
                    },
                    icon: const Icon(Icons.arrow_back),
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    isLogin
                        ? (step == 0 ? 'Welcome Back' : 'Verify Phone')
                        : (step == 0
                            ? 'Forgot Password'
                            : (step == 1 ? 'Verify OTP' : 'Set New Password')),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isLogin
                  ? (step == 0
                      ? 'Sign in with your phone number'
                      : 'We\'ve sent a code to your phone')
                  : (step == 0
                      ? 'Reset via OTP sent to your phone'
                      : (step == 1
                          ? 'Enter the 6-digit code you received'
                          : 'Choose a new password')),
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Phone Field
            TextFormField(
              controller: controller.phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (India)',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
                hintText: '10-digit mobile or +91XXXXXXXXXX',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[0-9+\s]")),
              ],
              validator: (value) {
                final raw = (value ?? '').trim();
                if (raw.isEmpty) {
                  return 'Please enter your phone number';
                }
                final cleaned = raw.replaceAll(RegExp(r"\s+"), "");
                final tenDigits = RegExp(r"^[0-9]{10}$");
                final e164IN = RegExp(r"^\+91[0-9]{10}$");
                if (!(tenDigits.hasMatch(cleaned) || e164IN.hasMatch(cleaned))) {
                  return 'Enter 10 digits or +91 followed by 10 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password Field (login step 0 only)
            if (isLogin && step == 0)
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
                      if (!isLogin || step != 0) return null;
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  )),

            if (isLogin && step == 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Row(
                        children: [
                          Checkbox(
                            value: controller.rememberMe.value,
                            onChanged: (_) => controller.toggleRememberMe(),
                          ),
                          const Text('Remember me'),
                        ],
                      )),
                  TextButton(
                    onPressed: controller.resetPassword,
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
            ],

            // OTP Field (step 1)
            if (step == 1) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.otpController,
                decoration: const InputDecoration(
                  labelText: 'Enter 6-digit code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, letterSpacing: 2),
              ),
            ],

            // New Password Fields (forgot step 2)
            if (!isLogin && step == 2) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
            ],

            const SizedBox(height: 16),
            if (controller.errorMessage.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  controller.errorMessage.value,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // Primary Action Button
            Obx(() {
              VoidCallback? onPressed;
              String label = 'Continue';
              if (isLogin && step == 0) {
                onPressed = controller.signIn;
                label = 'Continue';
              } else if (step == 1) {
                onPressed = isLogin ? controller.verifyOtp : controller.verifyForgotOtp;
                label = 'Verify OTP';
              } else if (!isLogin && step == 0) {
                onPressed = controller.sendForgotOtp;
                label = 'Send OTP';
              } else if (!isLogin && step == 2) {
                onPressed = () {
                  final p1 = controller.newPasswordController.text;
                  final p2 = controller.confirmPasswordController.text;
                  if (p1.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a new password')),
                    );
                    return;
                  }
                  if (p1.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password must be at least 6 characters')),
                    );
                    return;
                  }
                  if (p1 != p2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match')),
                    );
                    return;
                  }
                  controller.updateForgotPassword(p1);
                };
                label = 'Set Password';
              }
              return ElevatedButton(
                onPressed: controller.isLoading.value ? null : onPressed,
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
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              );
            }),

            if (step == 1) ...[
              const SizedBox(height: 8),
              Obx(() => TextButton(
                    onPressed: controller.canResendOtp.value ? controller.resendOtp : null,
                    child: Text(
                      controller.canResendOtp.value
                          ? 'Resend Code'
                          : 'Resend in ${controller.otpCountdown.value}s',
                    ),
                  )),
            ],

            if (!isLogin) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  controller.flow.value = 'login';
                  controller.currentStep.value = 0;
                  controller.errorMessage.value = '';
                },
                child: const Text('Back to login'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
