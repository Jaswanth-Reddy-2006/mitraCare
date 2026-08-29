import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitracare_app/core/theme/design_system.dart';
import 'package:mitracare_app/services/api_service.dart';

final pendingConnectionTokenProvider = StateProvider<String?>((ref) => null);

class ConnectDeepLinkHandler extends ConsumerStatefulWidget {
  final String? token;
  const ConnectDeepLinkHandler({super.key, this.token});

  @override
  ConsumerState<ConnectDeepLinkHandler> createState() => _ConnectDeepLinkHandlerState();
}

class _ConnectDeepLinkHandlerState extends ConsumerState<ConnectDeepLinkHandler> {
  bool _isValidating = false;
  bool _isConnecting = false;
  String? _errorMessage;
  String? _patientName;
  String? _patientId;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      // Store token as pending in Riverpod
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pendingConnectionTokenProvider.notifier).state = widget.token;
      });
      _validateToken();
    }
  }

  Future<void> _validateToken() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.role != 'CAREGIVER') {
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.inspectConnectionCode(widget.token!);
      setState(() {
        _patientName = data["patient_name"];
        _patientId = data["patient_id"];
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "").replaceAll("DioException: ", "");
        if (e.toString().contains("404")) {
          _errorMessage = "Invalid connection code.";
        } else if (e.toString().contains("400")) {
          if (e.toString().contains("expired")) {
            _errorMessage = "This connection code has expired.";
          } else if (e.toString().contains("used")) {
            _errorMessage = "This connection code has already been used.";
          }
        }
      });
    } finally {
      setState(() => _isValidating = false);
    }
  }

  Future<void> _connectPatient() async {
    if (widget.token == null) return;
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      await api.joinConnection(widget.token!);
      
      // Clear pending token
      ref.read(pendingConnectionTokenProvider.notifier).state = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Connected successfully!"),
            backgroundColor: DesignSystem.primaryGreen,
          ),
        );
        context.go('/caregiver-dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final double textScale = MediaQuery.of(context).textScaleFactor;

    if (widget.token == null || widget.token!.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Connection Error")),
        body: const Center(
          child: Text("No valid connection code or token was detected."),
        ),
      );
    }

    // 1. If not logged in
    if (!authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: DesignSystem.backgroundLight,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2, size: 80, color: DesignSystem.primaryGreen),
                  const SizedBox(height: 24),
                  Text(
                    "MitraCare Connection Request",
                    style: TextStyle(fontSize: 22 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "To connect with this patient, please login or register a caregiver account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: DesignSystem.textSubtle),
                  ),
                  const SizedBox(height: 36),
                  ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignSystem.primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Login", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.push('/register?role=CAREGIVER'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(color: DesignSystem.primaryGreen, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      "Create Caregiver Account",
                      style: TextStyle(color: DesignSystem.primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 2. If logged in as Patient
    if (authState.role == 'PATIENT') {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  "Connection scanner is only for caregivers.\nPlease show your connection ID to your caregiver.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/patient-home'),
                  child: const Text("Go to Home"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Logged in as Caregiver
    return Scaffold(
      backgroundColor: DesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text("Confirm Patient Connection"),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isValidating) ...[
                const CircularProgressIndicator(color: DesignSystem.primaryGreen),
                const SizedBox(height: 16),
                const Text("Validating connection token...", style: TextStyle(color: DesignSystem.textSubtle)),
              ] else if (_errorMessage != null) ...[
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/caregiver-dashboard'),
                  style: ElevatedButton.styleFrom(backgroundColor: DesignSystem.primaryGreen),
                  child: const Text("Go to Dashboard"),
                ),
              ] else if (_patientName != null) ...[
                const Icon(Icons.people_outline, size: 80, color: DesignSystem.primaryGreen),
                const SizedBox(height: 24),
                Text(
                  "Connect with ${_patientName}?",
                  style: TextStyle(fontSize: 22 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                ),
                const SizedBox(height: 12),
                Text(
                  "Connection Code: ${widget.token}",
                  style: const TextStyle(fontSize: 16, color: DesignSystem.textSubtle),
                ),
                const SizedBox(height: 36),
                ElevatedButton(
                  onPressed: _isConnecting ? null : _connectPatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignSystem.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isConnecting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Connect Patient", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    ref.read(pendingConnectionTokenProvider.notifier).state = null;
                    context.go('/caregiver-dashboard');
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Cancel", style: TextStyle(color: DesignSystem.textDark)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
