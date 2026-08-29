import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mitracare_app/core/theme/design_system.dart';

class RegisterSuccessScreen extends StatelessWidget {
  const RegisterSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Checkmark Badge with stylized green circles & leaves
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 96,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Registration Successful!",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Welcome to MitraCare.\nYou can now login and start your journey\nof care and connection.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DesignSystem.textSubtle,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text("Go to Login"),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
