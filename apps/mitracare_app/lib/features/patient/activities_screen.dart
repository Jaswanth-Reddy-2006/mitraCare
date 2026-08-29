import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_system.dart';
import 'patient_providers.dart';
import 'package:mitracare_app/widgets/patient_bottom_nav_bar.dart';
import 'package:mitracare_app/services/localization_service.dart';
import 'package:mitracare_app/features/patient/game_play_screen.dart';
import 'package:mitracare_app/features/patient/games/screens/cognitive_game_screen.dart';
import 'package:mitracare_app/features/patient/games/models/cognitive_game_models.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesProvider);
    final textScale = MediaQuery.of(context).textScaleFactor;
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Back Arrow and Brain Mascot Illustration
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 8),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Back button top left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 22),
                      ),
                    ),
                  ),

                  // Title & Brain mascot row
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Play Game",
                              style: TextStyle(
                                fontSize: 28 * textScale,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E1B4B),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Brain holding puzzle piece emoji character
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Text("🧠🧩", style: TextStyle(fontSize: 32)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            "Choose a fun activity to exercise your memory and keep your mind active!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5 * textScale,
                              color: const Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Sparkle Let's do something great today! Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("✦", style: TextStyle(fontSize: 18, color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(
                      "Let's do something great today!",
                      style: TextStyle(
                        fontSize: 15 * textScale,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6D28D9),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Activities List View
            Expanded(
              child: activitiesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: DesignSystem.primaryGreen),
                ),
                error: (err, stack) => _buildFallbackList(context, textScale, lang),
                data: (activities) {
                  if (activities.isEmpty) {
                    return _buildFallbackList(context, textScale, lang);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                    physics: const BouncingScrollPhysics(),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final act = activities[index];
                      return _buildCustomActivityCard(
                        context: context,
                        title: act['title'] ?? 'Activity',
                        subtitle: act['description'] ?? '',
                        difficulty: act['difficulty'] ?? 'MEDIUM',
                        activityId: act['id'],
                        index: index,
                        textScale: textScale,
                        lang: lang,
                      );
                    },
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

  Widget _buildFallbackList(BuildContext context, double textScale, String lang) {
    // Default 6 activity cards matching media_1788023955213.png
    final defaultGames = [
      {"id": "act_match", "title": "Find the Match", "sub": "Match two similar pictures", "difficulty": "EASY"},
      {"id": "act_remember", "title": "Remember Pictures", "sub": "Look, remember and recall", "difficulty": "MEDIUM"},
      {"id": "act_spot", "title": "Spot the Difference", "sub": "Find what's different", "difficulty": "HARD"},
      {"id": "act_sort", "title": "Sort and Arrange", "sub": "Arrange items in the right order", "difficulty": "EASY"},
      {"id": "act_name", "title": "Name That Object", "sub": "Recall names of common objects", "difficulty": "EASY"},
      {"id": "act_recall", "title": "Recall Daily Events", "sub": "Remember what happened today", "difficulty": "EASY"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      physics: const BouncingScrollPhysics(),
      itemCount: defaultGames.length,
      itemBuilder: (context, index) {
        final item = defaultGames[index];
        return _buildCustomActivityCard(
          context: context,
          title: item['title']!,
          subtitle: item['sub']!,
          difficulty: item['difficulty']!,
          activityId: item['id']!,
          index: index,
          textScale: textScale,
          lang: lang,
        );
      },
    );
  }

  Widget _buildCustomActivityCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String difficulty,
    required String activityId,
    required int index,
    required double textScale,
    required String lang,
  }) {
    // Theme colors and icons matching reference design media_1788023955213.png
    final List<Map<String, dynamic>> themeConfigs = [
      {
        "icon": "🎴",
        "bgColor": const Color(0xFFE0F2FE),
        "buttonColor": const Color(0xFF0284C7),
      },
      {
        "icon": "🖼️",
        "bgColor": const Color(0xFFDCFCE7),
        "buttonColor": const Color(0xFF16A34A),
      },
      {
        "icon": "🔍",
        "bgColor": const Color(0xFFFEF3C7),
        "buttonColor": const Color(0xFFD97706),
      },
      {
        "icon": "🧊",
        "bgColor": const Color(0xFFF3E8FF),
        "buttonColor": const Color(0xFF9333EA),
      },
      {
        "icon": "🎮",
        "bgColor": const Color(0xFFFCE7F3),
        "buttonColor": const Color(0xFFDB2777),
      },
      {
        "icon": "📅",
        "bgColor": const Color(0xFFCCFBF1),
        "buttonColor": const Color(0xFF0D9488),
      },
    ];

    final theme = themeConfigs[index % themeConfigs.length];

    final String iconEmoji = theme["icon"];
    final Color bgColor = theme["bgColor"];
    final Color buttonColor = theme["buttonColor"];

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            final lowerTitle = title.toLowerCase();
            if (lowerTitle.contains('triplet')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CognitiveGameScreen(
                    activityId: activityId,
                    gameMode: GameMode.triplet,
                    difficulty: difficulty,
                  ),
                ),
              );
            } else if (lowerTitle.contains('match') || lowerTitle.contains('pair')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CognitiveGameScreen(
                    activityId: activityId,
                    gameMode: GameMode.pair,
                    difficulty: difficulty,
                  ),
                ),
              );
            } else {
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
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                // Left Colored Icon Rectangle Box
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(iconEmoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),

                const SizedBox(width: 16),

                // Title and Subtitle Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17 * textScale,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13 * textScale,
                          color: const Color(0xFF64748B),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Trailing Solid Colored Circular Chevron Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: buttonColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
