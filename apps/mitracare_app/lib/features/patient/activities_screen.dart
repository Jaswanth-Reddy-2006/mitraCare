import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_system.dart';
import 'patient_providers.dart';
import 'package:mitracare_app/widgets/patient_bottom_nav_bar.dart';
import 'package:mitracare_app/services/localization_service.dart';
import 'package:mitracare_app/features/patient/game_play_screen.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesProvider);
    final textScale = MediaQuery.of(context).textScaleFactor;
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: DesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text(
          LocalizationService.translate('play_game', lang),
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
        child: Column(
          children: [
            Expanded(
              child: activitiesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: DesignSystem.primaryGreen),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, size: 64 * textScale, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          "Could not load activities.\nYou are offline or the server is down.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18 * textScale, color: DesignSystem.textSubtle),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.refresh(activitiesProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignSystem.primaryGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text("Try Again", style: TextStyle(fontSize: 16 * textScale)),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (activities) {
                  if (activities.isEmpty) {
                    return Center(
                      child: Text(
                        "No activities available right now.",
                        style: TextStyle(fontSize: 18 * textScale, color: DesignSystem.textSubtle),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18.0, 16.0, 18.0, 8.0),
                        child: Text(
                          LocalizationService.translate('choose_activity', lang),
                          style: TextStyle(
                            fontSize: 18 * textScale,
                            color: DesignSystem.textSubtle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                          itemCount: activities.length,
                          itemBuilder: (context, index) {
                            return _buildActivityCard(context, ref, activities[index], textScale, lang);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PatientBottomNavBar(currentTab: 'none'),
    );
  }

  Widget _buildActivityCard(BuildContext context, WidgetRef ref, Map<String, dynamic> activity, double textScale, String lang) {
    final title = activity['title'] ?? 'Activity';
    final desc = activity['description'] ?? '';
    final difficulty = activity['difficulty'] ?? 'MEDIUM';
    final activityId = activity['id'];

    IconData typeIcon = Icons.sports_esports;
    Color themeColor = Colors.blue.shade600;
    Color iconBgColor = Colors.blue.shade50;

    final cleanTitle = title.trim().toLowerCase();
    if (cleanTitle.contains("match")) {
      typeIcon = Icons.apps;
      themeColor = const Color(0xFF1976D2);
      iconBgColor = const Color(0xFFE3F2FD);
    } else if (cleanTitle.contains("remember")) {
      typeIcon = Icons.image;
      themeColor = const Color(0xFF1976D2);
      iconBgColor = const Color(0xFFE3F2FD);
    } else if (cleanTitle.contains("difference")) {
      typeIcon = Icons.search;
      themeColor = const Color(0xFF1976D2);
      iconBgColor = const Color(0xFFE3F2FD);
    } else if (cleanTitle.contains("sort") || cleanTitle.contains("arrange")) {
      typeIcon = Icons.star;
      themeColor = const Color(0xFF1976D2);
      iconBgColor = const Color(0xFFE3F2FD);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: DesignSystem.softShadow,
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GamePlayScreen(
                    activityId: activityId,
                    title: title,
                    difficulty: difficulty,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  // Circular Left Icon Container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(typeIcon, color: themeColor, size: 28 * textScale),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocalizationService.translateDynamic(title, lang),
                          style: TextStyle(
                            fontSize: 18 * textScale,
                            fontWeight: FontWeight.bold,
                            color: DesignSystem.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LocalizationService.translateDynamic(desc, lang),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14 * textScale,
                            color: DesignSystem.textSubtle,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Trailing blue chevron circle
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 20 * textScale,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
