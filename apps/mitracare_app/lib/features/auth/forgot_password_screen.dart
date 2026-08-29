import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mitracare_app/core/theme/design_system.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isSent = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSent = true);
  }

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  "Forgot Password",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Enter your email or phone number and we'll send you a link to reset your password.",
                  style: TextStyle(
                    color: DesignSystem.textSubtle,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                if (_isSent)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Reset link sent successfully!",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: DesignSystem.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "We've sent a instructions to your registered account. Please check your inbox.",
                          style: TextStyle(fontSize: 13, color: DesignSystem.textSubtle),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: "Email or Phone Number",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? "Please enter your email or phone number" : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text("Send Reset Link"),
                  ),
                ],
                const Spacer(),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Remember your password? ", style: TextStyle(color: DesignSystem.textSubtle)),
                      GestureDetector(
                        onTap: () => context.go('/login'),
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
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
