import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitracare_app/core/theme/design_system.dart';
import 'package:mitracare_app/services/api_service.dart';
import 'package:mitracare_app/features/auth/welcome_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // Redirection happens automatically via routerProvider watch authProvider
      } else {
        setState(() {
          _errorMessage = ref.read(authProvider).error ?? "Login failed. Please check credentials.";
        });
      }
    }
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
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const MitraCareLogo(size: 50),
                    const SizedBox(height: 16),
                    Text(
                      "Welcome Back",
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Login to continue your journey\nof care and connection",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DesignSystem.textSubtle,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade800),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Username Field (Email or Phone)
                    TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: "Email or Phone Number",
                        hintText: "Enter email or phone number",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter your email or phone number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your password";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Remember me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                if (val != null) setState(() => _rememberMe = val);
                              },
                              activeColor: DesignSystem.primaryGreen,
                            ),
                            const Text("Remember me", style: TextStyle(fontSize: 13)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => context.push('/forgot-password'),
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: DesignSystem.secondaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _submit,
                            child: const Text("Login"),
                          ),
                    const SizedBox(height: 24),

                    // Or continue with
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text("or continue with", style: TextStyle(color: DesignSystem.textSubtle, fontSize: 13)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Social login placeholders
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {}, // Placeholder
                            icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                            label: const Text("Google"),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {}, // Placeholder
                            icon: const Icon(Icons.apple, size: 22, color: Colors.black),
                            label: const Text("Apple"),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Don't have an account? Sign Up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(color: DesignSystem.textSubtle)),
                        GestureDetector(
                          onTap: () => context.push('/role-selection'),
                          child: const Text(
                            "Sign Up",
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
        ),
      ),
    );
  }
}
