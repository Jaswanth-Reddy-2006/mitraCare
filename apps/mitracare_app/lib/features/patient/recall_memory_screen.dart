import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitracare_app/core/theme/design_system.dart';
import 'package:mitracare_app/widgets/patient_bottom_nav_bar.dart';
import 'package:mitracare_app/services/localization_service.dart';

class RecallMemoryScreen extends ConsumerWidget {
  const RecallMemoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double textScale = MediaQuery.of(context).textScaleFactor;
    final lang = ref.watch(languageProvider);

    final exercises = [
      {
        "title": LocalizationService.translate('recall_daily_events', lang),
        "description": LocalizationService.translate('recall_daily_events_sub', lang),
        "icon": Icons.calendar_month,
        "iconColor": Colors.deepPurple,
        "bgColor": Colors.purple.shade50,
      },
      {
        "title": LocalizationService.translate('name_that_object', lang),
        "description": LocalizationService.translate('name_that_object_sub', lang),
        "icon": Icons.apple,
        "iconColor": Colors.red,
        "bgColor": Colors.red.shade50,
      },
      {
        "title": LocalizationService.translate('sequence_memory', lang),
        "description": LocalizationService.translate('sequence_memory_sub', lang),
        "icon": Icons.pin,
        "iconColor": Colors.indigo,
        "bgColor": Colors.indigo.shade50,
      },
      {
        "title": LocalizationService.translate('word_recall', lang),
        "description": LocalizationService.translate('word_recall_sub', lang),
        "icon": Icons.chat_bubble,
        "iconColor": Colors.blue,
        "bgColor": Colors.blue.shade50,
      },
    ];

    return Scaffold(
      backgroundColor: DesignSystem.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignSystem.textDark),
          onPressed: () => context.go('/patient-home'),
        ),
        title: Text(
          LocalizationService.translate('recall_memory', lang),
          style: TextStyle(
            fontSize: 22 * textScale,
            fontWeight: FontWeight.bold,
            color: DesignSystem.textDark,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle
                      Text(
                        LocalizationService.translate('recall_memory_sub', lang),
                        style: TextStyle(
                          fontSize: 18 * textScale,
                          color: DesignSystem.textSubtle,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Exercises List
                      ...exercises.map((ex) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  title: Text(ex['title'] as String),
                                  content: Text("${LocalizationService.translate('play_btn', lang)}: ${ex['title']}..."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(LocalizationService.translate('close_btn', lang)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: DesignSystem.softShadow,
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Row(
                                children: [
                                  // Leading Colored Icon Container
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: ex['bgColor'] as Color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      ex['icon'] as IconData,
                                      color: ex['iconColor'] as Color,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ex['title'] as String,
                                          style: TextStyle(
                                            fontSize: 18 * textScale,
                                            fontWeight: FontWeight.bold,
                                            color: DesignSystem.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          ex['description'] as String,
                                          style: TextStyle(
                                            fontSize: 14 * textScale,
                                            color: DesignSystem.textSubtle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Trailing Arrow Action
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: Colors.purple,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            const PatientBottomNavBar(currentTab: 'none'),
          ],
        ),
      ),
    );
  }
}
