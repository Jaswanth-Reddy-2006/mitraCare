import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:mitracare_app/core/theme/design_system.dart';
import 'package:mitracare_app/services/api_service.dart';
import 'package:mitracare_app/features/caregiver/qr_scanner_screen.dart';
import 'package:mitracare_app/features/auth/connect_handler_screen.dart';

class CaregiverDashboardScreen extends ConsumerStatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  ConsumerState<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends ConsumerState<CaregiverDashboardScreen> {
  int _currentTab = 0;
  String? _selectedPatientId;
  List<dynamic> _connectedPatients = [];
  bool _isLoadingPatients = false;
  String? _error;

  // Dashboard Summary Data
  Map<String, dynamic>? _dashboardData;
  bool _isLoadingSummary = false;

  // Cognitive Reports Data
  Map<String, dynamic>? _reportData;
  int _reportRangeDays = 30;
  bool _isLoadingReports = false;

  // Alerts
  List<dynamic> _alerts = [];
  bool _isLoadingAlerts = false;

  // Connection text controller
  final _codeController = TextEditingController();
  bool _isConnecting = false;

  // Page controller for sub-views or manual modal states
  bool _isEditingProfile = false;
  bool _isManagingReminders = false;

  // Reminders/Tasks manager state
  List<dynamic> _patientTasks = [];
  List<dynamic> _patientReminders = [];
  bool _isLoadingSchedule = false;

  // Add Task form state
  final _taskTitleController = TextEditingController();
  final _taskDescController = TextEditingController();
  String _selectedTaskType = "MEDICATION";
  TimeOfDay _selectedTaskTime = const TimeOfDay(hour: 9, minute: 0);

  // Edit Profile form state
  final _ageController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingConnection();
    });
    _fetchPatients();
    _fetchAlerts();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _taskTitleController.dispose();
    _taskDescController.dispose();
    _ageController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  // --- API Integrations ---

  Future<void> _fetchPatients() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPatients = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final patientsList = await api.getConnections();
      if (!mounted) return;
      setState(() {
        _connectedPatients = patientsList;
        if (patientsList.isNotEmpty) {
          _selectedPatientId = patientsList[0]["id"];
          _fetchPatientDashboardSummary(_selectedPatientId!);
          _fetchPatientReports(_selectedPatientId!);
          _fetchPatientSchedule(_selectedPatientId!);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoadingPatients = false);
    }
  }


  Future<void> _connectPatient() async {
    final codeStr = _codeController.text.trim();
    if (codeStr.isEmpty) return;

    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      await api.joinConnection(codeStr);
      if (!mounted) return;
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connected successfully!"), backgroundColor: DesignSystem.primaryGreen),
      );
      _fetchPatients();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }


  Future<void> _checkPendingConnection() async {
    final pendingToken = ref.read(pendingConnectionTokenProvider);
    if (pendingToken != null && pendingToken.isNotEmpty) {
      _handleScannedCode(pendingToken);
    }
  }

  String? _extractCodeFromScan(String rawValue) {
    try {
      final uri = Uri.parse(rawValue.trim());
      final token = uri.queryParameters['t'] ?? uri.queryParameters['token'] ?? uri.queryParameters['code'];
      if (token != null) return token;
    } catch (_) {}
    
    final cleanValue = rawValue.trim().toUpperCase();
    if (RegExp(r"^[A-Z0-9]{4}-[A-Z0-9]{4}$").hasMatch(cleanValue)) {
      return cleanValue;
    }
    if (cleanValue.length == 8 && RegExp(r"^[A-Z0-9]{8}$").hasMatch(cleanValue)) {
      return "${cleanValue.substring(0, 4)}-${cleanValue.substring(4)}";
    }
    return null;
  }

  Future<void> _startQRScan() async {
    final scannedVal = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
    if (scannedVal != null && scannedVal.isNotEmpty) {
      final code = _extractCodeFromScan(scannedVal);
      if (code != null) {
        _handleScannedCode(code);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("That QR code is not a MitraCare connection code."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleScannedCode(String code) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: DesignSystem.primaryGreen),
      ),
    );

    String? patientName;
    String? inspectError;

    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.inspectConnectionCode(code);
      patientName = data["patient_name"];
    } catch (e) {
      inspectError = e.toString().replaceAll("Exception: ", "").replaceAll("DioException: ", "");
      if (e.toString().contains("404")) {
        inspectError = "Invalid connection code.";
      } else if (e.toString().contains("400")) {
        if (e.toString().contains("expired")) {
          inspectError = "This connection code has expired.";
        } else if (e.toString().contains("used")) {
          inspectError = "This connection code has already been used.";
        }
      }
    }


    if (mounted) {
      Navigator.pop(context);
    }

    if (inspectError != null) {
      if (mounted) {
        ref.read(pendingConnectionTokenProvider.notifier).state = null;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Connection Error"),
            content: Text(inspectError!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (patientName != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Patient Connection"),
          content: Text("Connect with this Patient?\n\nName: $patientName\nCode: $code"),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(pendingConnectionTokenProvider.notifier).state = null;
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: DesignSystem.primaryGreen),
                  ),
                );

                try {
                  final api = ref.read(apiServiceProvider);
                  await api.joinConnection(code);
                  ref.read(pendingConnectionTokenProvider.notifier).state = null;
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Connected successfully!"),
                        backgroundColor: DesignSystem.primaryGreen,
                      ),
                    );
                    _fetchPatients();
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: DesignSystem.primaryGreen),
              child: const Text("Connect Patient"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _fetchPatientDashboardSummary(String patientId) async {
    if (!mounted) return;
    setState(() => _isLoadingSummary = true);
    try {
      final api = ref.read(apiServiceProvider);
      final summary = await api.getCaregiverDashboard(patientId);
      if (!mounted) return;
      setState(() => _dashboardData = summary);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingSummary = false);
  }

  Future<void> _fetchPatientReports(String patientId) async {
    if (!mounted) return;
    setState(() => _isLoadingReports = true);
    try {
      final api = ref.read(apiServiceProvider);
      final reports = await api.getCaregiverReports(patientId, _reportRangeDays);
      if (!mounted) return;
      setState(() => _reportData = reports);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingReports = false);
  }

  Future<void> _fetchAlerts() async {
    if (!mounted) return;
    setState(() => _isLoadingAlerts = true);
    try {
      final api = ref.read(apiServiceProvider);
      final fetchedAlerts = await api.getCaregiverAlerts();
      if (!mounted) return;
      setState(() => _alerts = fetchedAlerts);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingAlerts = false);
  }

  Future<void> _fetchPatientSchedule(String patientId) async {
    if (!mounted) return;
    setState(() => _isLoadingSchedule = true);
    try {
      final api = ref.read(apiServiceProvider);
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final tasks = await api.getPatientSchedule(patientId, date);
      final reminders = await api.getPatientRemindersToday(patientId);
      if (!mounted) return;
      setState(() {
        _patientTasks = tasks;
        _patientReminders = reminders;
      });
    } catch (_) {}
    if (mounted) setState(() => _isLoadingSchedule = false);
  }


  Future<void> _addTask() async {
    if (_taskTitleController.text.trim().isEmpty || _selectedPatientId == null) return;
    try {
      final api = ref.read(apiServiceProvider);
      final timeStr = "${_selectedTaskTime.hour.toString().padLeft(2, '0')}:${_selectedTaskTime.minute.toString().padLeft(2, '0')}";
      await api.addPatientTask(_selectedPatientId!, {
        "title": _taskTitleController.text.trim(),
        "description": _taskDescController.text.trim(),
        "task_type": _selectedTaskType,
        "scheduled_time": timeStr,
        "date": DateTime.now().toIso8601String().substring(0, 10),
        "priority": "MEDIUM"
      });
      _taskTitleController.clear();
      _taskDescController.clear();
      _fetchPatientSchedule(_selectedPatientId!);
      _fetchPatientDashboardSummary(_selectedPatientId!);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _deleteTask(String taskId) async {
    if (_selectedPatientId == null) return;
    try {
      final api = ref.read(apiServiceProvider);
      await api.deletePatientTask(_selectedPatientId!, taskId);
      _fetchPatientSchedule(_selectedPatientId!);
      _fetchPatientDashboardSummary(_selectedPatientId!);
    } catch (_) {}
  }

  Future<void> _savePatientProfile() async {
    if (_selectedPatientId == null) return;
    try {
      final api = ref.read(apiServiceProvider);
      await api.updatePatientProfileByCaregiver(_selectedPatientId!, {
        "age": int.tryParse(_ageController.text.trim()),
        "emergency_contact_name": _emergencyNameController.text.trim(),
        "emergency_contact_phone": _emergencyPhoneController.text.trim(),
      });
      setState(() => _isEditingProfile = false);
      _fetchPatients();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- Sub-View Switchers ---

  Widget _buildBody(String caregiverName) {
    if (_connectedPatients.isEmpty) {
      return _buildPairingScreen();
    }

    if (_isEditingProfile) {
      return _buildEditProfileScreen();
    }

    if (_isManagingReminders) {
      return _buildRemindersManagementScreen();
    }

    switch (_currentTab) {
      case 0:
        return _buildOverviewTab(caregiverName);
      case 1:
        return _buildActivitiesTab();
      case 2:
        return _buildReportsTab();
      case 3:
        return _buildAlertsTab();
      case 4:
        return _buildMoreTab();
      default:
        return _buildOverviewTab(caregiverName);
    }
  }

  // --- Screen 0: Pairing screen (no patients yet) ---

  Widget _buildPairingScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Connect to Patient",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter the 8-character connection code or scan the QR code displayed on the patient's device onboarding screen.",
              style: TextStyle(fontSize: 15, color: DesignSystem.textSubtle),
            ),
            const SizedBox(height: 36),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
              ),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: DesignSystem.softShadow,
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Enter Code",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                          inputFormatters: [ConnectionCodeFormatter()],
                          textCapitalization: TextCapitalization.characters,
                          keyboardType: TextInputType.text,
                          maxLength: 9,
                          decoration: InputDecoration(
                            hintText: "XXXX-XXXX",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            filled: true,
                            fillColor: DesignSystem.backgroundLight,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            counterText: "",
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _startQRScan,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text("Scan"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: DesignSystem.primaryGreen,
                          side: const BorderSide(color: DesignSystem.primaryGreen, width: 2),
                          minimumSize: const Size(100, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (RegExp(r"^[A-Z0-9]{4}-[A-Z0-9]{4}$").hasMatch(_codeController.text.trim()) && !_isConnecting)
                              ? _connectPatient
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RegExp(r"^[A-Z0-9]{4}-[A-Z0-9]{4}$").hasMatch(_codeController.text.trim())
                                ? DesignSystem.primaryGreen
                                : Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isConnecting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Connect Patient", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.favorite_outline, color: DesignSystem.primaryGreen, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    "MitraCare Core Connection System",
                    style: TextStyle(color: DesignSystem.textSubtle.withOpacity(0.8), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Screen 1: Dashboard Overview Tab ---

  Widget _buildOverviewTab(String caregiverName) {
    final patient = _connectedPatients.firstWhere((p) => p["id"] == _selectedPatientId, orElse: () => null);
    final pProfile = patient != null ? patient["patient_profile"] : null;
    final name = patient != null ? patient["name"] : "Amma";
    final age = pProfile != null ? pProfile["age"] ?? 72 : 72;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Greeting
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Good Morning,",
                      style: TextStyle(fontSize: 16, color: DesignSystem.textSubtle),
                    ),
                    Text(
                      "$caregiverName 👋",
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => setState(() => _currentTab = 3), // open alerts
                  icon: const Icon(Icons.notifications_outlined, color: DesignSystem.textDark, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Active Patient Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: DesignSystem.softShadow,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: DesignSystem.primaryGreen.withOpacity(0.1),
                    child: const Icon(Icons.person, color: DesignSystem.primaryGreen, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "Connected",
                              style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text("Age: $age", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DesignSystem.primaryGreen)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Today's Overview Grid (3 Cards Row)
            const Text(
              "Today's Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _overviewMiniCard(
                    title: "Activities",
                    value: "${_dashboardData?['completed_tasks_count'] ?? 4}/${_dashboardData?['total_tasks_count'] ?? 6}",
                    subtitle: "Completed",
                    icon: Icons.check_circle_outline,
                    color: DesignSystem.primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _overviewMiniCard(
                    title: "Games",
                    value: "${_dashboardData?['games_played_today'] ?? 2}",
                    subtitle: "Played",
                    icon: Icons.psychology_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _overviewMiniCard(
                    title: "Mood",
                    value: _dashboardData?['latest_mood'] ?? "Good",
                    subtitle: "😊",
                    icon: Icons.face_outlined,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cognitive Score Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DesignSystem.primaryGreen,
                borderRadius: BorderRadius.circular(24),
                boxShadow: DesignSystem.softShadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Cognitive Score",
                          style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "${_dashboardData?['cognitive_score'] ?? 72}",
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              " / 100",
                              style: TextStyle(color: Colors.white70, fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      children: [
                        Icon(Icons.trending_up, color: Colors.white, size: 20),
                        SizedBox(width: 4),
                        Text(
                          "8% vs yesterday",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Activity Section
            const Text(
              "Recent Activity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
            ),
            const SizedBox(height: 12),
            _isLoadingSummary
                ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryGreen))
                : Column(
                    children: (_dashboardData?['recent_activities'] as List<dynamic>? ?? []).map((act) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.purple.shade50,
                              child: const Icon(Icons.extension_outlined, color: Colors.purple),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    act["title"] ?? "Cognitive Game",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Score: ${act['score']}%",
                                    style: const TextStyle(color: DesignSystem.primaryGreen, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _overviewMiniCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: DesignSystem.textDark, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: DesignSystem.textSubtle)),
            ],
          ),
        ],
      ),
    );
  }

  // --- Screen 2: Patient Activities Tab ---

  Widget _buildActivitiesTab() {
    final list = [
      {"title": "Memory Game", "time": "11:00 AM", "completed": true, "score": "80%"},
      {"title": "Recall Daily Events", "time": "02:00 PM", "completed": true, "score": "Completed"},
      {"title": "Name That Object", "time": "05:00 PM", "completed": false, "score": "Pending"},
      {"title": "Sequence Memory", "time": "Pending", "completed": false, "score": "Pending"},
      {"title": "Word Recall", "time": "Pending", "completed": false, "score": "Pending"},
    ];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Patient Activities",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            "Monitor memory practice games scheduled and played.",
            style: TextStyle(fontSize: 14, color: DesignSystem.textSubtle),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                final completed = item["completed"] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: completed ? Colors.green.shade50 : Colors.orange.shade50,
                        child: Icon(
                          completed ? Icons.psychology : Icons.hourglass_empty,
                          color: completed ? DesignSystem.primaryGreen : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item["title"] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text("Scheduled: ${item['time']}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: completed ? Colors.green.shade100 : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              completed ? "Done" : "Pending",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: completed ? Colors.green.shade800 : Colors.orange.shade800,
                              ),
                            ),
                          ),
                          if (completed) ...[
                            const SizedBox(height: 4),
                            Text(item["score"] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DesignSystem.primaryGreen)),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Screen 3: Cognitive Reports Tab ---

  Widget _buildReportsTab() {
    final trends = _reportData?["score_trends"] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cognitive Reports",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
            ),
            const SizedBox(height: 16),

            // Time Selector (mocked layout selection)
            Row(
              children: [
                _rangeButton(7, "7 Days"),
                const SizedBox(width: 8),
                _rangeButton(30, "30 Days"),
                const SizedBox(width: 8),
                _rangeButton(90, "90 Days"),
              ],
            ),
            const SizedBox(height: 24),

            // Trend Chart
            const Text(
              "Cognitive Score Trend",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: DesignSystem.softShadow,
              ),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val.toInt() >= 0 && val.toInt() < trends.length) {
                            return Text(trends[val.toInt()]["date"] ?? "", style: const TextStyle(fontSize: 10));
                          }
                          return const Text("");
                        },
                        reservedSize: 22,
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trends.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), (e.value["score"] as num).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: DesignSystem.primaryGreen,
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Domain Performance Bars
            const Text(
              "Domain Performance",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
            ),
            const SizedBox(height: 12),
            _domainRow("Memory", 0.78, Colors.green),
            _domainRow("Attention", 0.68, Colors.blue),
            _domainRow("Language", 0.72, Colors.purple),
            _domainRow("Problem Solving", 0.65, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _rangeButton(int days, String title) {
    final isSelected = _reportRangeDays == days;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _reportRangeDays = days;
          });
          if (_selectedPatientId != null) {
            _fetchPatientReports(_selectedPatientId!);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? DesignSystem.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : DesignSystem.textDark,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _domainRow(String title, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text("${(value * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  // --- Screen 4: Alerts & Notifications Tab ---

  Widget _buildAlertsTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Alerts",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            "System logs for patient tasks and care milestones.",
            style: TextStyle(fontSize: 14, color: DesignSystem.textSubtle),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoadingAlerts
                ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryGreen))
                : ListView.builder(
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final item = _alerts[index];
                      final type = item["alert_type"];

                      Color alertColor = Colors.green;
                      IconData alertIcon = Icons.check;

                      if (type == "MEDICINE_MISSED") {
                        alertColor = Colors.red;
                        alertIcon = Icons.warning;
                      } else if (type == "LOW_ACTIVITY") {
                        alertColor = Colors.orange;
                        alertIcon = Icons.info;
                      } else if (type == "APPOINTMENT_REMINDER") {
                        alertColor = Colors.blue;
                        alertIcon = Icons.calendar_today;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: alertColor.withOpacity(0.1),
                              child: Icon(alertIcon, color: alertColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item["title"] ?? "Alert",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item["description"] ?? "",
                                    style: TextStyle(color: DesignSystem.textSubtle, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- Screen 5: Settings / More Tab ---

  Widget _buildMoreTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "More",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
            ),
            const SizedBox(height: 24),

            _menuItem(
              icon: Icons.person_outline,
              title: "Patient Profile",
              onTap: () {
                final patient = _connectedPatients.firstWhere((p) => p["id"] == _selectedPatientId, orElse: () => null);
                if (patient != null) {
                  _ageController.text = (patient["patient_profile"]?["age"] ?? 72).toString();
                  _emergencyNameController.text = patient["patient_profile"]?["emergency_contact_name"] ?? "";
                  _emergencyPhoneController.text = patient["patient_profile"]?["emergency_contact_phone"] ?? "";
                }
                setState(() => _isEditingProfile = true);
              },
            ),
            _menuItem(
              icon: Icons.add_circle_outline,
              title: "Connect New Patient",
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: FractionallySizedBox(
                        heightFactor: 0.8,
                        child: Scaffold(
                          backgroundColor: Colors.white,
                          appBar: AppBar(
                            title: const Text("Connect Patient"),
                            leading: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          body: _buildPairingScreen(),
                        ),
                      ),
                    );
                  },
                ).then((_) => _fetchPatients());
              },
            ),
            _menuItem(
              icon: Icons.calendar_month_outlined,
              title: "Reminders & Schedule",
              onTap: () {
                setState(() => _isManagingReminders = true);
              },
            ),
            _menuItem(
              icon: Icons.share_outlined,
              title: "Share Reports",
              onTap: () {},
            ),
            _menuItem(
              icon: Icons.download_outlined,
              title: "Export Data",
              onTap: () {},
            ),
            _menuItem(
              icon: Icons.help_outline,
              title: "Help & Support",
              onTap: () {},
            ),
            _menuItem(
              icon: Icons.settings_outlined,
              title: "Settings",
              onTap: () {},
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: ListTile(
          leading: Icon(icon, color: DesignSystem.primaryGreen),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.textDark)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }


  // --- Sub-View: Edit Patient Profile Screen ---

  Widget _buildEditProfileScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _isEditingProfile = false),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Text("Edit Patient Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              "Patient Age",
              style: TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.textDark, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Emergency Contact Name",
              style: TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.textDark, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emergencyNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Emergency Contact Phone",
              style: TextStyle(fontWeight: FontWeight.bold, color: DesignSystem.textDark, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emergencyPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: _savePatientProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Save Updates", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Sub-View: Schedule & Reminders Screen ---

  Widget _buildRemindersManagementScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _isManagingReminders = false),
                icon: const Icon(Icons.arrow_back),
              ),
              const Text("Schedule & Tasks", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Patient Schedule", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                onPressed: () => _showAddTaskModal(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Task"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingSchedule
                ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryGreen))
                : _patientTasks.isEmpty
                    ? const Center(child: Text("No tasks scheduled for today."))
                    : ListView.builder(
                        itemCount: _patientTasks.length,
                        itemBuilder: (context, index) {
                          final task = _patientTasks[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: DesignSystem.primaryGreen.withOpacity(0.1),
                                  child: const Icon(Icons.medication, color: DesignSystem.primaryGreen),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(task["title"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text("Time: ${task['scheduled_time']}", style: TextStyle(color: DesignSystem.textSubtle, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _deleteTask(task["id"]),
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Add New Daily Task", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _taskTitleController,
                    decoration: InputDecoration(
                      labelText: "Task Name (e.g. Morning Medicine)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _taskDescController,
                    decoration: InputDecoration(
                      labelText: "Description (Optional)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Scheduled Time:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: _selectedTaskTime);
                          if (picked != null) {
                            setModalState(() => _selectedTaskTime = picked);
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(_selectedTaskTime.format(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _addTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignSystem.primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Save Task", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final caregiverName = authState.name ?? "Caregiver";

    return Scaffold(
      backgroundColor: DesignSystem.backgroundLight,
      body: SafeArea(
        child: _isLoadingPatients
            ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryGreen))
            : _buildBody(caregiverName),
      ),
      bottomNavigationBar: _connectedPatients.isEmpty || _isEditingProfile || _isManagingReminders
          ? null
          : BottomNavigationBar(
              currentIndex: _currentTab,
              onTap: (index) {
                setState(() => _currentTab = index);
                // Refresh data based on selected tab
                if (_selectedPatientId != null) {
                  if (index == 0) _fetchPatientDashboardSummary(_selectedPatientId!);
                  if (index == 2) _fetchPatientReports(_selectedPatientId!);
                  if (index == 3) _fetchAlerts();
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: DesignSystem.primaryGreen,
              unselectedItemColor: Colors.grey,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.psychology_outlined), activeIcon: Icon(Icons.psychology), label: "Activities"),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: "Reports"),
                BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: "Alerts"),
                BottomNavigationBarItem(icon: Icon(Icons.more_horiz_outlined), activeIcon: Icon(Icons.more_horiz), label: "More"),
              ],
            ),
    );
  }
}

class ConnectionCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String cleanText = newValue.text
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();

    if (cleanText.length > 8) {
      cleanText = cleanText.substring(0, 8);
    }

    String formatted = cleanText;
    if (cleanText.length > 4) {
      formatted = '${cleanText.substring(0, 4)}-${cleanText.substring(4)}';
    }

    int selectionIndex = newValue.selection.end;
    int alphaNumericBeforeCursor = 0;
    for (int i = 0; i < selectionIndex && i < newValue.text.length; i++) {
      final char = newValue.text[i];
      if (RegExp(r'[A-Za-z0-9]').hasMatch(char)) {
        alphaNumericBeforeCursor++;
      }
    }
    
    if (alphaNumericBeforeCursor > 8) {
      alphaNumericBeforeCursor = 8;
    }

    int newSelectionIndex = alphaNumericBeforeCursor;
    if (alphaNumericBeforeCursor > 4) {
      newSelectionIndex = alphaNumericBeforeCursor + 1;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newSelectionIndex),
    );
  }
}
