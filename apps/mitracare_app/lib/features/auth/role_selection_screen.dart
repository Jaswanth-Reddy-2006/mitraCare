import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mitracare_app/core/theme/design_system.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _selectedRole = 'CAREGIVER'; // Default selection

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignSystem.textDark),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Illustration
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.groups,
                    size: 80,
                    color: DesignSystem.secondaryBlue.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Create Account",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Join MitraCare and stay connected with your loved ones",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DesignSystem.textSubtle,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "I am a...",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 18,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Caregiver Option Card
                _roleOptionCard(
                  title: "Caregiver",
                  description: "I want to care for my loved one",
                  roleCode: "CAREGIVER",
                  icon: Icons.favorite_border,
                  iconBg: Colors.green.shade50,
                  iconColor: DesignSystem.primaryGreen,
                ),
                const SizedBox(height: 16),
                
                // Patient Option Card
                _roleOptionCard(
                  title: "Patient",
                  description: "I need care and support",
                  roleCode: "PATIENT",
                  icon: Icons.elderly,
                  iconBg: Colors.blue.shade50,
                  iconColor: DesignSystem.secondaryBlue,
                ),
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: () {
                    context.push('/register?role=$_selectedRole');
                  },
                  child: const Text("Continue"),
                ),
                const SizedBox(height: 24),
                
                // Already have account link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: DesignSystem.textSubtle),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/login'),
                      child: const Text(
                        "Login Now",
                        style: TextStyle(
                          color: DesignSystem.secondaryBlue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleOptionCard({
    required String title,
    required String description,
    required String roleCode,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    final isSelected = _selectedRole == roleCode;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = roleCode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? DesignSystem.primaryGreen : Colors.grey.shade200,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: DesignSystem.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DesignSystem.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: DesignSystem.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? DesignSystem.primaryGreen : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
