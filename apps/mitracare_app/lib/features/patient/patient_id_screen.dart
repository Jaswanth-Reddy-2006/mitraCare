import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitracare_app/core/theme/design_system.dart';
import 'package:mitracare_app/services/api_service.dart';
import 'package:mitracare_app/services/localization_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PatientIdScreen extends ConsumerStatefulWidget {
  const PatientIdScreen({super.key});

  @override
  ConsumerState<PatientIdScreen> createState() => _PatientIdScreenState();
}

class _PatientIdScreenState extends ConsumerState<PatientIdScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _pairingCode;
  int _countdownSeconds = 600;
  Timer? _timer;
  Timer? _statusCheckTimer;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _generatePairingCode();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _generatePairingCode() async {
    setState(() {
      _isLoading = true;
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
      setState(() => _isLoading = false);
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
          setState(() {
            _isConnected = true;
          });
          _timer?.cancel();
          _statusCheckTimer?.cancel();
        }
      } catch (_) {}
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }



  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final lang = ref.watch(languageProvider);
    final double textScale = MediaQuery.of(context).textScaleFactor;

    final patientRawId = authState.userDetails?['id']?.toString() ?? '12345678';
    final patientIdDisplay = "MC-${patientRawId.substring(0, 6).toUpperCase()}";

    return Scaffold(
      backgroundColor: DesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text(
          "My MitraCare ID",
          style: TextStyle(
            color: DesignSystem.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 22.0 * textScale,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignSystem.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                
                // Card for Patient Identity
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: DesignSystem.softShadow,
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Patient Connection ID",
                        style: TextStyle(fontSize: 15 * textScale, color: DesignSystem.textSubtle, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        patientIdDisplay,
                        style: TextStyle(fontSize: 28 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.primaryGreen),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      if (_errorMessage != null)
                        Text(_errorMessage!, style: const TextStyle(color: Colors.red))
                      else if (_isConnected) ...[
                        const Icon(Icons.check_circle, color: DesignSystem.primaryGreen, size: 64),
                        const SizedBox(height: 12),
                        Text(
                          "Caregiver Connected!",
                          style: TextStyle(fontSize: 18 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                        ),
                      ] else ...[
                        Text(
                          "Valid for ${_formatTime(_countdownSeconds)}",
                          style: TextStyle(
                            fontSize: 16 * textScale,
                            fontWeight: FontWeight.bold,
                            color: _countdownSeconds < 60 ? Colors.red : DesignSystem.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_pairingCode != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: DesignSystem.backgroundLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _pairingCode!,
                              style: TextStyle(
                                fontSize: 24 * textScale,
                                fontWeight: FontWeight.bold,
                                color: DesignSystem.textDark,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200, width: 2),
                            ),
                            child: QrImageView(
                              data: "mitracare://connect?t=$_pairingCode",
                              version: QrVersions.auto,
                              size: 180.0,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: DesignSystem.textDark,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: DesignSystem.textDark,
                              ),
                            ),
                          ),
                        ] else
                          const CircularProgressIndicator(color: DesignSystem.primaryGreen),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                Text(
                  "Show this code or QR to your caregiver to connect accounts.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16 * textScale, color: DesignSystem.textSubtle, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 48),

                if (_countdownSeconds == 0 && !_isConnected)
                  ElevatedButton(
                    onPressed: _generatePairingCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignSystem.primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text("Generate New Code", style: TextStyle(fontSize: 18 * textScale, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
