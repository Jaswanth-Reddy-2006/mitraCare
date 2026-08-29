import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mitracare_app/core/theme/design_system.dart';
import 'package:mitracare_app/features/patient/patient_providers.dart';
import 'package:mitracare_app/widgets/patient_bottom_nav_bar.dart';
import 'package:mitracare_app/services/api_service.dart';
import 'package:mitracare_app/services/localization_service.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  String _getGreeting(String lang) {
    final hour = DateTime.now().hour;
    if (hour < 12) return LocalizationService.translate('good_morning', lang);
    if (hour < 17) return LocalizationService.translate('good_afternoon', lang);
    return LocalizationService.translate('good_evening', lang);
  }



  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final remindersAsync = ref.watch(remindersProvider);
    final lang = ref.watch(languageProvider);
    
    final double textScale = MediaQuery.of(context).textScaleFactor;
    final patientName = authState.name ?? LocalizationService.translate('default_name', lang);

    final currentLangName = LocalizationService.languages
        .firstWhere((l) => l['code'] == lang, orElse: () => {'native': 'English'})['native']!;

    return Scaffold(
      backgroundColor: DesignSystem.backgroundLight,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Icon(Icons.favorite, color: DesignSystem.primaryGreen, size: 28 * textScale),
        ),
        title: Text(
          LocalizationService.translate('mitracare', lang),
          style: TextStyle(
            color: DesignSystem.primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22.0 * textScale,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          // Language selector (Interactive InkWell)
          GestureDetector(
            onTap: () => _showLanguageSelector(context, ref),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.language, size: 16, color: DesignSystem.primaryGreen),
                  const SizedBox(width: 6),
                  Text(
                    currentLangName,
                    style: TextStyle(
                      fontSize: 13 * textScale,
                      fontWeight: FontWeight.bold,
                      color: DesignSystem.textDark,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting Banner (Restructured with avatar & emojis)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${_getGreeting(lang)}, 👋",
                                  style: TextStyle(
                                    fontSize: 20.0 * textScale,
                                    color: DesignSystem.textSubtle,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$patientName! 😊🌸",
                                  style: TextStyle(
                                    fontSize: 28.0 * textScale,
                                    fontWeight: FontWeight.bold,
                                    color: DesignSystem.textDark,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.asset(
                              "assets/images/grandma.jpg",
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Interactive Speech Assistant Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: DesignSystem.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.volume_up, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    LocalizationService.translate('here_to_help', lang),
                                    style: TextStyle(
                                      fontSize: 16 * textScale,
                                      fontWeight: FontWeight.bold,
                                      color: DesignSystem.textDark,
                                    ),
                                  ),
                                  Text(
                                    LocalizationService.translate('how_can_i_help', lang),
                                    style: TextStyle(
                                      fontSize: 14 * textScale,
                                      color: DesignSystem.textSubtle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Dynamic Medicine Alert Card (If pending medicine reminder exists)
                      remindersAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (reminders) {
                          final pendingMeds = reminders.where((r) => r['type'] == 'MEDICINE' && r['status'] == 'PENDING').toList();
                          if (pendingMeds.isEmpty) {
                            return _buildCompletedBanner(textScale, lang);
                          }
                          
                          final activeMed = pendingMeds.first;
                          DateTime? scheduledAt;
                          try {
                            scheduledAt = DateTime.parse(activeMed['scheduled_at']).toLocal();
                          } catch (_) {}
                          final timeFormatted = scheduledAt != null 
                              ? DateFormat('h:mm a').format(scheduledAt)
                              : '9:00 AM';

                          return _buildMedicineAlertCard(activeMed['id'], activeMed['title'], timeFormatted, textScale, lang);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Core Activity Buttons Grid (Matches Screen 1 of Mockup, Taller Grid Cells)
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.78,
                        children: [
                          _activityCard(
                            icon: Icons.sports_esports,
                            color: const Color(0xFF1976D2),
                            label: LocalizationService.translate('play_game', lang),
                            subLabel: LocalizationService.translate('play_game_sub', lang),
                            onTap: () => context.push('/patient/activities'),
                          ),
                          _activityCard(
                            icon: Icons.psychology,
                            color: const Color(0xFF9C27B0),
                            label: LocalizationService.translate('recall_memory', lang),
                            subLabel: LocalizationService.translate('recall_memory_sub', lang),
                            onTap: () => context.push('/patient/recall-memory'),
                          ),
                          _activityCard(
                            icon: Icons.calendar_today,
                            color: const Color(0xFFE65100),
                            label: LocalizationService.translate('my_day_label', lang),
                            subLabel: LocalizationService.translate('my_day_sub', lang),
                            onTap: () => context.push('/patient/my-day'),
                          ),
                          _activityCard(
                            icon: Icons.notifications,
                            color: const Color(0xFF2E7D32),
                            label: LocalizationService.translate('reminders_label', lang),
                            subLabel: LocalizationService.translate('reminders_sub', lang),
                            onTap: () => context.push('/patient/reminders'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PatientBottomNavBar(currentTab: 'home'),
    );
  }

  Widget _buildCompletedBanner(double textScale, String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: DesignSystem.primaryGreen, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "${LocalizationService.translate('all_medicines_taken', lang)} ${LocalizationService.translate('great_job', lang)}",
              style: TextStyle(
                fontSize: 16 * textScale,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineAlertCard(String id, String title, String time, double textScale, String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade200, width: 1.5),
        boxShadow: DesignSystem.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medication,
                  color: DesignSystem.primaryGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.translate('medicine_time', lang),
                      style: TextStyle(
                        fontSize: 18 * textScale,
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${LocalizationService.translate('time_for_medicine', lang)} ($title)",
                      style: TextStyle(
                        fontSize: 15 * textScale,
                        color: DesignSystem.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: DesignSystem.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 13 * textScale,
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(remindersProvider.notifier).completeReminder(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              LocalizationService.translate('take_now', lang),
              style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              LocalizationService.translate('tap_take_now', lang),
              style: TextStyle(
                fontSize: 13 * textScale,
                color: DesignSystem.textSubtle,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _activityCard({
    required IconData icon,
    required Color color,
    required String label,
    required String subLabel,
    required VoidCallback onTap,
  }) {
    final double textScale = MediaQuery.of(context).textScaleFactor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: DesignSystem.softShadow,
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40 * textScale),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 20.0 * textScale,
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subLabel,
                      style: TextStyle(
                        fontSize: 14.0 * textScale,
                        color: DesignSystem.textSubtle,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final currentLang = ref.watch(languageProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 8.0),
                child: Text(
                  "Choose Language / भाषा चुनें",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DesignSystem.textDark,
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: LocalizationService.languages.length,
                  itemBuilder: (context, index) {
                    final lang = LocalizationService.languages[index];
                    final isSelected = currentLang == lang['code'];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                      leading: Icon(
                        Icons.check,
                        color: isSelected ? DesignSystem.primaryGreen : Colors.transparent,
                      ),
                      title: Text(
                        lang['native']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? DesignSystem.primaryGreen : DesignSystem.textDark,
                        ),
                      ),
                      trailing: Text(
                        lang['name']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: DesignSystem.textSubtle,
                        ),
                      ),
                      onTap: () {
                        ref.read(languageProvider.notifier).setLanguage(lang['code']!);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
