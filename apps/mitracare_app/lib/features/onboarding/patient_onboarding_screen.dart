import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitracare_app/core/theme/design_system.dart';
import 'package:mitracare_app/services/api_service.dart';

class PatientOnboardingScreen extends ConsumerStatefulWidget {
  const PatientOnboardingScreen({super.key});

  @override
  ConsumerState<PatientOnboardingScreen> createState() => _PatientOnboardingScreenState();
}

class _PatientOnboardingScreenState extends ConsumerState<PatientOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _isLoading = false;
  bool _isGeneratingCode = false;
  String? _errorMessage;
  String? _pairingCode;
  int _countdownSeconds = 600; // 10 minutes
  Timer? _timer;
  Timer? _statusCheckTimer;
  bool _stepOneCompleted = false;

  @override
  void dispose() {
    _ageController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _timer?.cancel();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiService = ref.read(apiServiceProvider);

    try {
      final ageVal = int.tryParse(_ageController.text.trim());
      await apiService.updatePatientProfile(
        age: ageVal,
        emergencyName: _emergencyNameController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim(),
      );

      // Save profile and immediately complete onboarding
      await _completeOnboarding();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generatePairingCode() async {
    setState(() {
      _isGeneratingCode = true;
      _errorMessage = null;
    });
    try {
      final apiService = ref.read(apiServiceProvider);
      final res = await apiService.generateConnectionCode();
      setState(() {
        _pairingCode = res["code"];
        _countdownSeconds = 600;
      });
      _startTimer();
      _startStatusCheck();
    } catch (e) {
      setState(() {
        _errorMessage = "Could not generate code: ${e.toString()}";
      });
    } finally {
      setState(() => _isGeneratingCode = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
      } else {
        _timer?.cancel();
        _statusCheckTimer?.cancel();
      }
    });
  }

  void _startStatusCheck() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 4), (t) async {
      try {
        final apiService = ref.read(apiServiceProvider);
        final connections = await apiService.getConnections();
        if (connections.isNotEmpty) {
          // Caregiver connected! Automatically complete onboarding.
          _completeOnboarding();
        }
      } catch (_) {
        // Ignore background polling errors
      }
    });
  }

  Future<void> _completeOnboarding() async {
    _timer?.cancel();
    _statusCheckTimer?.cancel();
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).checkAuth();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Widget _buildQRMock(String code) {
    final int seed = code.hashCode;
    final List<List<bool>> grid = List.generate(13, (r) {
      return List.generate(13, (c) {
        if ((r < 3 && c < 3) || (r < 3 && c >= 10) || (r >= 10 && c < 3)) {
          if (r == 0 || r == 2 || c == 0 || c == 2) return true;
          if (r == 0 || r == 2 || c == 10 || c == 12) return true;
          if (r == 10 || r == 12 || c == 0 || c == 2) return true;
          return false;
        }
        final int hashVal = (r * 31 + c * 17 + seed) % 100;
        return hashVal % 2 == 0;
      });
    });

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
      child: SizedBox(
        height: 150,
        width: 150,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 13,
          ),
          itemCount: 169,
          itemBuilder: (context, index) {
            final r = index ~/ 13;
            final c = index % 13;
            final isFilled = grid[r][c];
            return Container(
              margin: const EdgeInsets.all(0.5),
              decoration: BoxDecoration(
                color: isFilled ? DesignSystem.textDark : Colors.white,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: DesignSystem.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/logo.png', // Fallback to icon
                      height: 48,
                      errorBuilder: (context, _, __) => Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: DesignSystem.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "MitraCare",
                      style: TextStyle(
                        fontSize: 26.0 * textScale,
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.primaryGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade800),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800, fontSize: 15.0 * textScale),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (!_stepOneCompleted) ...[
                  Text(
                    "Welcome, let's get set up!",
                    style: TextStyle(
                      fontSize: 28.0 * textScale,
                      fontWeight: FontWeight.bold,
                      color: DesignSystem.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "These basic details help personalize your day-to-day care experience.",
                    style: TextStyle(
                      fontSize: 16.0 * textScale,
                      color: DesignSystem.textSubtle,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "How old are you?",
                          style: TextStyle(fontSize: 18.0 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 18.0 * textScale),
                          decoration: InputDecoration(
                            hintText: "Enter your age",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return "Please enter your age";
                            if (int.tryParse(val.trim()) == null) return "Please enter a valid age";
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        Text(
                          "Emergency Contact Details",
                          style: TextStyle(fontSize: 18.0 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emergencyNameController,
                          style: TextStyle(fontSize: 18.0 * textScale),
                          decoration: InputDecoration(
                            hintText: "Contact person's name",
                            prefixIcon: const Icon(Icons.person, color: DesignSystem.primaryGreen),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? "Please enter contact name" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emergencyPhoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(fontSize: 18.0 * textScale),
                          decoration: InputDecoration(
                            hintText: "Contact person's phone number",
                            prefixIcon: const Icon(Icons.phone, color: DesignSystem.primaryGreen),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? "Please enter contact phone" : null,
                        ),
                        const SizedBox(height: 48),

                        _isLoading
                            ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryGreen))
                            : ElevatedButton(
                                onPressed: _submitProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DesignSystem.primaryGreen,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 64),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Text("Save & Next", style: TextStyle(fontSize: 20.0 * textScale, fontWeight: FontWeight.bold)),
                              ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Step 2: QR & Code display
                  Text(
                    "Connect to Caregiver",
                    style: TextStyle(
                      fontSize: 28.0 * textScale,
                      fontWeight: FontWeight.bold,
                      color: DesignSystem.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Share this code or QR with your caregiver to connect accounts.",
                    style: TextStyle(
                      fontSize: 16.0 * textScale,
                      color: DesignSystem.textSubtle,
                    ),
                  ),
                  const SizedBox(height: 36),

                  Center(
                    child: Column(
                      children: [
                        if (_isGeneratingCode)
                          const CircularProgressIndicator(color: DesignSystem.primaryGreen)
                        else if (_pairingCode != null) ...[
                          Text(
                            "Valid for ${_formatTime(_countdownSeconds)}",
                            style: TextStyle(
                              fontSize: 18 * textScale,
                              fontWeight: FontWeight.bold,
                              color: _countdownSeconds < 60 ? Colors.red : DesignSystem.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200, width: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: _pairingCode!
                                  .split("")
                                  .map((char) => Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        child: Text(
                                          char == ' ' ? "" : char,
                                          style: TextStyle(
                                            fontSize: 24 * textScale,
                                            fontWeight: FontWeight.bold,
                                            color: DesignSystem.textDark,
                                            letterSpacing: char == '-' ? 6 : 2,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _buildQRMock(_pairingCode!),
                        ] else ...[
                          Text(
                            "Code Expired",
                            style: TextStyle(fontSize: 18 * textScale, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                        const SizedBox(height: 32),
                        Text(
                          "Checking for connection status...",
                          style: TextStyle(fontSize: 15 * textScale, fontStyle: FontStyle.italic, color: DesignSystem.textSubtle),
                        ),
                        const SizedBox(height: 24),
                        if (_countdownSeconds == 0)
                          ElevatedButton(
                            onPressed: _generatePairingCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: DesignSystem.primaryGreen,
                              side: const BorderSide(color: DesignSystem.primaryGreen, width: 2),
                              minimumSize: const Size(200, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text("Generate New Code", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignSystem.primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 64),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text("Finish & Go to Home", style: TextStyle(fontSize: 20.0 * textScale, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
