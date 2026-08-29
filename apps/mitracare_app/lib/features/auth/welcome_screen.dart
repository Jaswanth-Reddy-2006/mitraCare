import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mitracare_app/core/theme/design_system.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Logo & Branding
                const MitraCareLogo(size: 60),
                const SizedBox(height: 12),
                Text(
                  "MitraCare",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: DesignSystem.primaryGreen,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                ),
                Text(
                  "Together in Every Memory, Every Day.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DesignSystem.textSubtle,
                        fontStyle: FontStyle.italic,
                      ),
                ),
                const SizedBox(height: 32),
                
                // Friendly Care Illustration Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9), // Light soothing green
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.face_retouching_natural, size: 64, color: Colors.green.shade800),
                          const SizedBox(width: 16),
                          Icon(Icons.favorite, size: 36, color: Colors.red.shade400),
                          const SizedBox(width: 16),
                          Icon(Icons.assignment_ind, size: 64, color: Colors.blue.shade800),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Connecting Hearts & Minds",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DesignSystem.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Key Features List
                _featureItem(
                  context,
                  icon: Icons.psychology,
                  iconColor: Colors.green.shade700,
                  title: "Cognitive Activities",
                  subtitle: "Engaging exercises to keep the mind active.",
                ),
                _featureItem(
                  context,
                  icon: Icons.notifications_active,
                  iconColor: Colors.blue.shade700,
                  title: "Smart Reminders",
                  subtitle: "Timely alerts for medications, tasks & more.",
                ),
                _featureItem(
                  context,
                  icon: Icons.insights,
                  iconColor: Colors.purple.shade700,
                  title: "Caregiver Insights",
                  subtitle: "Track progress and important insights.",
                ),
                _featureItem(
                  context,
                  icon: Icons.verified_user,
                  iconColor: Colors.teal.shade700,
                  title: "Secure & Trusted",
                  subtitle: "Your data is safe, private and protected.",
                ),
                const SizedBox(height: 32),
                
                // Bottom Buttons
                ElevatedButton(
                  onPressed: () => context.push('/role-selection'),
                  child: const Text("Get Started"),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => context.push('/language'),
                  icon: const Icon(Icons.language, color: DesignSystem.secondaryBlue),
                  label: const Text(
                    "Choose Language",
                    style: TextStyle(
                      color: DesignSystem.secondaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MitraCareLogo extends StatelessWidget {
  final double size;
  const MitraCareLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: DesignSystem.softShadow,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: size * 0.15,
              child: Icon(
                Icons.favorite,
                size: size * 0.7,
                color: DesignSystem.primaryGreen.withOpacity(0.85),
              ),
            ),
            Positioned(
              right: size * 0.15,
              child: Icon(
                Icons.volunteer_activism,
                size: size * 0.65,
                color: DesignSystem.secondaryBlue.withOpacity(0.85),
              ),
            ),
            Positioned(
              top: size * 0.1,
              child: Icon(
                Icons.spa, // leaf symbol
                size: size * 0.35,
                color: Colors.lightGreenAccent.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
