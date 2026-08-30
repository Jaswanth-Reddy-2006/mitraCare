import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_system.dart';
import 'patient_providers.dart';
import 'package:mitracare_app/widgets/patient_bottom_nav_bar.dart';
import 'package:mitracare_app/services/localization_service.dart';
import 'package:mitracare_app/features/patient/games/screens/cognitive_game_screen.dart';
import 'package:mitracare_app/features/patient/games/models/cognitive_game_models.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakGameSelection();
    });
  }

  void _speakGameSelection() {
    final voice = ref.read(voiceServiceProvider);
    final lang = ref.read(languageProvider);
    voice.speak(
      "Choose a game. You can play Match the Pair or Match the Triplet.",
      langCode: lang,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesProvider);
    final textScale = MediaQuery.of(context).textScaleFactor;
    final lang = ref.watch(languageProvider);
    final voice = ref.watch(voiceServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Back button top left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        voice.stop();
                        context.pop();
                      },
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

                  // Speaker Voice Replay Button top right
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _speakGameSelection,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: voice.isSpeaking ? const Color(0xFFDCFCE7) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: voice.isSpeaking ? DesignSystem.primaryGreen : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          voice.isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                          color: DesignSystem.primaryGreen,
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                  // Title & Brain Mascot
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

            // Let's do something great today! Banner
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

            const SizedBox(height: 16),

            // ONLY TWO GAMES LISTED
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Game 1: Match the Pair
                  _buildGameEntryCard(
                    context: context,
                    title: "Match the Pair",
                    subtitle: "Match two same pictures",
                    iconBadge: "🎴",
                    bgColor: const Color(0xFFE0F2FE),
                    buttonColor: const Color(0xFF0284C7),
                    activityId: _findActivityId(activitiesAsync, "Pair"),
                    mode: GameMode.pair,
                    textScale: textScale,
                  ),

                  const SizedBox(height: 16),

                  // Game 2: Match the Triplet
                  _buildGameEntryCard(
                    context: context,
                    title: "Match the Triplet",
                    subtitle: "Match three same pictures",
                    iconBadge: "🃏",
                    bgColor: const Color(0xFFDCFCE7),
                    buttonColor: const Color(0xFF16A34A),
                    activityId: _findActivityId(activitiesAsync, "Triplet"),
                    mode: GameMode.triplet,
                    textScale: textScale,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PatientBottomNavBar(currentTab: 'none'),
    );
  }

  String _findActivityId(AsyncValue<List<dynamic>> activitiesAsync, String key) {
    return activitiesAsync.maybeWhen(
      data: (list) {
        final match = list.firstWhere(
          (act) => (act['title'] as String).toLowerCase().contains(key.toLowerCase()),
          orElse: () => null,
        );
        return match != null ? match['id'] : 'act_$key';
      },
      orElse: () => 'act_$key',
    );
  }

  Widget _buildGameEntryCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String iconBadge,
    required Color bgColor,
    required Color buttonColor,
    required String activityId,
    required GameMode mode,
    required double textScale,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            ref.read(voiceServiceProvider).stop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CognitiveGameScreen(
                  activityId: activityId,
                  gameMode: mode,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
            child: Row(
              children: [
                // Left Icon Box
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(iconBadge, style: const TextStyle(fontSize: 32)),
                  ),
                ),

                const SizedBox(width: 18),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 19 * textScale,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14 * textScale,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Trailing Action Button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: buttonColor,
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
      ),
    );
  }
}
