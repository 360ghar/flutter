import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/utils/theme.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgotPasswordController());
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            switch (controller.step.value) {
              case 0:
                return _phoneStep(context, controller);
              case 1:
                return _otpStep(context, controller);
              case 2:
                return _passwordStep(context, controller);
              default:
                return _phoneStep(context, controller);
            }
          }),
        ),
      ),
    );
  }

  Widget _phoneStep(BuildContext context, ForgotPasswordController c) {
    return Form(
      key: c.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Reset via phone OTP',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Enter your registered Indian mobile number'),
          const SizedBox(height: 24),
          TextFormField(
            controller: c.phoneController,
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
              if (raw.isEmpty) return 'Please enter your phone number';
              final cleaned = raw.replaceAll(RegExp(r"\s+"), "");
              final tenDigits = RegExp(r"^[0-9]{10}$");
              final e164IN = RegExp(r"^\+91[0-9]{10}$");
              if (!(tenDigits.hasMatch(cleaned) || e164IN.hasMatch(cleaned))) {
                return 'Enter 10 digits or +91 followed by 10 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Obx(() => ElevatedButton(
                onPressed: c.isLoading.value ? null : c.sendOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: c.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Send OTP',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              )),
        ],
      ),
    );
  }

  Widget _otpStep(BuildContext context, ForgotPasswordController c) {
    return Form(
      key: c.otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text('Verify OTP', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('OTP sent to ${c.phoneController.text}'),
          const SizedBox(height: 24),
          TextFormField(
            controller: c.otpController,
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
          const SizedBox(height: 16),
          Obx(() => ElevatedButton(
                onPressed: c.isLoading.value ? null : c.verifyOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: c.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )),
          const SizedBox(height: 8),
          Obx(() => TextButton(
                onPressed: c.canResendOtp.value ? c.resendOtp : null,
                child: Text(
                  c.canResendOtp.value ? 'Resend Code' : 'Resend in ${c.otpCountdown.value}s',
                ),
              )),
        ],
      ),
    );
  }

  Widget _passwordStep(BuildContext context, ForgotPasswordController c) {
    return Form(
      key: c.passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text('Set New Password', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          TextFormField(
            controller: c.passwordController,
            decoration: const InputDecoration(
              labelText: 'New Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a new password';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: c.confirmPasswordController,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please confirm your new password';
              if (value != c.passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),
          Obx(() => ElevatedButton(
                onPressed: c.isLoading.value ? null : c.updatePassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: c.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )),
        ],
      ),
    );
  }
}

