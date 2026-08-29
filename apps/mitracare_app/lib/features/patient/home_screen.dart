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

    final patientName = authState.name ?? 'Amma';
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    final currentLangName = LocalizationService.languages
        .firstWhere((l) => l['code'] == lang, orElse: () => {'native': 'English'})['native']!;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            // Green Leaf/Heart Logo Icon
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volunteer_activism,
                color: Color(0xFF2E7D32),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Mindful Care",
                  style: TextStyle(
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 20 * textScale,
                    height: 1.1,
                  ),
                ),
                Text(
                  "Care. Connect. Remember.",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11 * textScale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Language Dropdown Pill Button
          GestureDetector(
            onTap: () => _showLanguageSelector(context, ref),
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 18, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 6),
                  Text(
                    currentLangName,
                    style: TextStyle(
                      fontSize: 14 * textScale,
                      fontWeight: FontWeight.w600,
                      color: DesignSystem.textDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Hero Greeting Banner Card
                    _buildHeroGreetingCard(patientName, formattedDate, textScale, lang),

                    const SizedBox(height: 14),

                    // 2. Active Task / Medicine Alert Banner Card
                    remindersAsync.when(
                      loading: () => _buildMedicineTimeBanner(
                        id: null,
                        title: "morning medicine",
                        time: "9:00 AM",
                        textScale: textScale,
                        lang: lang,
                      ),
                      error: (_, __) => _buildMedicineTimeBanner(
                        id: null,
                        title: "morning medicine",
                        time: "9:00 AM",
                        textScale: textScale,
                        lang: lang,
                      ),
                      data: (reminders) {
                        final pendingMeds = reminders.where((r) => r['type'] == 'MEDICINE' && r['status'] == 'PENDING').toList();
                        if (pendingMeds.isEmpty) {
                          return _buildMedicineTimeBanner(
                            id: null,
                            title: "morning medicine",
                            time: "9:00 AM",
                            textScale: textScale,
                            lang: lang,
                          );
                        }

                        final activeMed = pendingMeds.first;
                        DateTime? scheduledAt;
                        try {
                          scheduledAt = DateTime.parse(activeMed['scheduled_at']).toLocal();
                        } catch (_) {}
                        final timeFormatted = scheduledAt != null
                            ? DateFormat('h:mm a').format(scheduledAt)
                            : '9:00 AM';

                        return _buildMedicineTimeBanner(
                          id: activeMed['id'],
                          title: activeMed['title'] ?? "morning medicine",
                          time: timeFormatted,
                          textScale: textScale,
                          lang: lang,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // 3. 2x2 Feature Grid Tiles
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.82,
                      children: [
                        // Tile 1: Play Game
                        _buildGridFeatureTile(
                          bgColor: const Color(0xFFEFF6FF),
                          borderColor: const Color(0xFFDBEAFE),
                          iconWidget: const Text("🎮", style: TextStyle(fontSize: 44)),
                          title: "Play Game",
                          subtitle: "Fun games for\nyour brain",
                          titleColor: const Color(0xFF1E3A8A),
                          subtitleColor: const Color(0xFF475569),
                          arrowColor: const Color(0xFF1D4ED8),
                          onTap: () => context.push('/patient/activities'),
                          textScale: textScale,
                        ),

                        // Tile 2: Recall Memory
                        _buildGridFeatureTile(
                          bgColor: const Color(0xFFF6F0FF),
                          borderColor: const Color(0xFFE9D5FF),
                          iconWidget: const Text("🧠", style: TextStyle(fontSize: 44)),
                          title: "Recall Memory",
                          subtitle: "Improve your memory\nand thinking",
                          titleColor: const Color(0xFF581C87),
                          subtitleColor: const Color(0xFF475569),
                          arrowColor: const Color(0xFF7E22CE),
                          onTap: () => context.push('/patient/recall-memory'),
                          textScale: textScale,
                        ),

                        // Tile 3: My Day (Schedule)
                        _buildGridFeatureTile(
                          bgColor: const Color(0xFFFFF8EC),
                          borderColor: const Color(0xFFFEF08A),
                          iconWidget: const Text("📅", style: TextStyle(fontSize: 44)),
                          title: "My Day (Schedule)",
                          subtitle: "See your today's\nplan and activities",
                          titleColor: const Color(0xFF78350F),
                          subtitleColor: const Color(0xFF475569),
                          arrowColor: const Color(0xFFD97706),
                          onTap: () => context.push('/patient/my-day'),
                          textScale: textScale,
                        ),

                        // Tile 4: Reminders
                        _buildGridFeatureTile(
                          bgColor: const Color(0xFFEFF9F1),
                          borderColor: const Color(0xFFDCFCE7),
                          iconWidget: const Text("🔔", style: TextStyle(fontSize: 44)),
                          title: "Reminders",
                          subtitle: "Medicines, water,\nactivities and more",
                          titleColor: const Color(0xFF14532D),
                          subtitleColor: const Color(0xFF475569),
                          arrowColor: const Color(0xFF15803D),
                          onTap: () => context.push('/patient/reminders'),
                          textScale: textScale,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PatientBottomNavBar(currentTab: 'home'),
    );
  }

  // --- Hero Greeting Banner ---
  Widget _buildHeroGreetingCard(String name, String dateStr, double textScale, String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F9F4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2F0E5), width: 1.5),
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Good Morning,\n$name! ☀️",
                          style: TextStyle(
                            fontSize: 22 * textScale,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B4D27),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 14 * textScale,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Speech Assistant Pill Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.volume_up, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "I'm here to help you.",
                                  style: TextStyle(
                                    fontSize: 12.5 * textScale,
                                    fontWeight: FontWeight.bold,
                                    color: DesignSystem.textDark,
                                  ),
                                ),
                                Text(
                                  "How can I help you today?",
                                  style: TextStyle(
                                    fontSize: 11.5 * textScale,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right Character Avatar Illustration
              Column(
                children: [
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(62),
                    child: Image.asset(
                      "assets/images/grandma.jpg",
                      height: 125,
                      width: 125,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Green Heart Icon at Top-Right
          const Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.favorite,
              color: Color(0xFF4CAF50),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // --- Medicine Alert Banner Card ---
  Widget _buildMedicineTimeBanner({
    required String? id,
    required String title,
    required String time,
    required double textScale,
    required String lang,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD4ECD8), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Pill Icon Container
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text("💊", style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Medicine Time",
                          style: TextStyle(
                            fontSize: 18 * textScale,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B4D27),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 13 * textScale,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "It's time for your morning medicine.",
                      style: TextStyle(
                        fontSize: 13.5 * textScale,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (id != null) {
                      ref.read(remindersProvider.notifier).completeReminder(id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Medicine marked as taken!")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    "TAKE NOW",
                    style: TextStyle(
                      fontSize: 16 * textScale,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.volume_up, size: 14, color: Color(0xFF2E7D32)),
              const SizedBox(width: 6),
              Text(
                "Tap TAKE NOW after you take your medicine.",
                style: TextStyle(
                  fontSize: 12 * textScale,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Grid Feature Tile Component ---
  Widget _buildGridFeatureTile({
    required Color bgColor,
    required Color borderColor,
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required Color titleColor,
    required Color subtitleColor,
    required Color arrowColor,
    required VoidCallback onTap,
    required double textScale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Center Icon
            iconWidget,

            // Title & Subtitle
            Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18 * textScale,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5 * textScale,
                    color: subtitleColor,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            // Bottom White Circular Arrow Button
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.chevron_right,
                color: arrowColor,
                size: 28,
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
                    final langItem = LocalizationService.languages[index];
                    final isSelected = currentLang == langItem['code'];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                      leading: Icon(
                        Icons.check,
                        color: isSelected ? DesignSystem.primaryGreen : Colors.transparent,
                      ),
                      title: Text(
                        langItem['native']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? DesignSystem.primaryGreen : DesignSystem.textDark,
                        ),
                      ),
                      trailing: Text(
                        langItem['name']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: DesignSystem.textSubtle,
                        ),
                      ),
                      onTap: () {
                        ref.read(languageProvider.notifier).setLanguage(langItem['code']!);
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
