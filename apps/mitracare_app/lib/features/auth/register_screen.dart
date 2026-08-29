import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mitracare_app/core/theme/design_system.dart';
import 'package:mitracare_app/services/api_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String role; // "CAREGIVER" or "PATIENT"
  const RegisterScreen({super.key, required this.role});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController(); // Only for Patient
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _selectedDob;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1960),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: DesignSystem.primaryGreen,
              onPrimary: Colors.white,
              onSurface: DesignSystem.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('dd / MM / yyyy').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      setState(() => _errorMessage = "You must agree to the Terms of Service & Privacy Policy.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    int? calculatedAge;
    if (widget.role == 'PATIENT' && _selectedDob != null) {
      calculatedAge = DateTime.now().year - _selectedDob!.year;
    }

    final success = await ref.read(authProvider.notifier).register(
      name: _nameController.text.trim(),
      role: widget.role,
      password: _passwordController.text,
      email: widget.role == 'CAREGIVER' ? _emailController.text.trim() : null,
      phone: _phoneController.text.trim(),
      age: calculatedAge,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/register-success');
      } else {
        setState(() {
          _errorMessage = ref.read(authProvider).error ?? "Registration failed. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = widget.role == 'PATIENT';

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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    "Create Account",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPatient ? "Patient Details" : "Caregiver Details",
                    style: const TextStyle(
                      fontSize: 16,
                      color: DesignSystem.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? "Please enter full name" : null,
                  ),
                  const SizedBox(height: 16),

                  // Email (Caregiver only)
                  if (!isPatient) ...[
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email Address",
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Please enter email address";
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                          return "Please enter a valid email address";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Date of Birth (Patient only)
                  if (isPatient) ...[
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: () => _selectDob(context),
                      decoration: InputDecoration(
                        labelText: "Date of Birth",
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) => val == null || val.isEmpty ? "Please select your date of birth" : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? "Please enter phone number" : null,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (val) => val == null || val.length < 6 ? "Password must be at least 6 characters" : null,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (val) {
                      if (val != _passwordController.text) return "Passwords do not match";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Agree to terms checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (val) {
                          if (val != null) setState(() => _agreeToTerms = val);
                        },
                        activeColor: DesignSystem.primaryGreen,
                      ),
                      const Expanded(
                        child: Text(
                          "I agree to the Terms of Service and Privacy Policy",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Register Button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submit,
                          child: const Text("Register"),
                        ),
                  const SizedBox(height: 24),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? ", style: TextStyle(color: DesignSystem.textSubtle)),
                      GestureDetector(
                        onTap: () => context.push('/login'),
                        child: const Text(
                          "Login",
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
    );
  }
}
