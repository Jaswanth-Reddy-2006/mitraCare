import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitracare_app/core/theme/design_system.dart';
import 'package:mitracare_app/features/patient/patient_providers.dart';
import 'package:mitracare_app/services/localization_service.dart';
import '../models/cognitive_game_models.dart';
import 'cognitive_game_screen.dart';

class ChooseGameScreen extends ConsumerWidget {
  const ChooseGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textScale = MediaQuery.of(context).textScaleFactor;
    final activitiesAsync = ref.watch(activitiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignSystem.textDark),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined, color: DesignSystem.primaryGreen),
            onPressed: () {
              final voice = ref.read(voiceServiceProvider);
              voice.speak("Choose a game. Find the Pair or Find the Triplet.");
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Brain Icon Logo
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text("🧠", style: TextStyle(fontSize: 36)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Choose Game",
                      style: TextStyle(
                        fontSize: 26 * textScale,
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Let's exercise your memory!",
                      style: TextStyle(
                        fontSize: 16 * textScale,
                        color: DesignSystem.textSubtle,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Game Card 1: Find the Pair
                    _buildGameCard(
                      context,
                      title: "Find the Pair",
                      subtitle: "Match two same cards",
                      iconBadge: "🎴",
                      bgColor: const Color(0xFFF3E5F5),
                      borderColor: const Color(0xFFE1BEE7),
                      iconColor: const Color(0xFF8E24AA),
                      onTap: () {
                        final pairActId = _findActivityId(activitiesAsync, "Find the Pair");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CognitiveGameScreen(
                              activityId: pairActId,
                              gameMode: GameMode.pair,
                            ),
                          ),
                        );
                      },
                      textScale: textScale,
                    ),

                    const SizedBox(height: 16),

                    // Game Card 2: Find the Triplet
                    _buildGameCard(
                      context,
                      title: "Find the Triplet",
                      subtitle: "Match three same cards",
                      iconBadge: "🎴",
                      bgColor: const Color(0xFFE8F5E9),
                      borderColor: const Color(0xFFA5D6A7),
                      iconColor: const Color(0xFF2E7D32),
                      onTap: () {
                        final tripletActId = _findActivityId(activitiesAsync, "Find the Triplet");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CognitiveGameScreen(
                              activityId: tripletActId,
                              gameMode: GameMode.triplet,
                            ),
                          ),
                        );
                      },
                      textScale: textScale,
                    ),

                    const SizedBox(height: 16),

                    // Game Card 3: Picture Puzzle (Placeholder/Future Game)
                    _buildGameCard(
                      context,
                      title: "Picture Puzzle",
                      subtitle: "Complete the picture",
                      iconBadge: "🧩",
                      bgColor: const Color(0xFFFFF8E1),
                      borderColor: const Color(0xFFFFE082),
                      iconColor: const Color(0xFFF57F17),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Picture Puzzle coming soon! Try Find the Pair or Find the Triplet.")),
                        );
                      },
                      textScale: textScale,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom hill/flowers decorative footer bar
            Container(
              height: 60,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFC8E6C9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text("🌸", style: TextStyle(fontSize: 24)),
                  Text("🌻", style: TextStyle(fontSize: 24)),
                  Text("🌷", style: TextStyle(fontSize: 24)),
                  Text("🌺", style: TextStyle(fontSize: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _findActivityId(AsyncValue<List<dynamic>> activitiesAsync, String titleMatch) {
    return activitiesAsync.maybeWhen(
      data: (list) {
        final match = list.firstWhere(
          (act) => (act['title'] as String).toLowerCase().contains(titleMatch.toLowerCase()),
          orElse: () => null,
        );
        return match != null ? match['id'] : 'default_act_id';
      },
      orElse: () => 'default_act_id',
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String iconBadge,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required VoidCallback onTap,
    required double textScale,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: DesignSystem.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Text(iconBadge, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18 * textScale,
                          fontWeight: FontWeight.bold,
                          color: DesignSystem.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14 * textScale,
                          color: DesignSystem.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: iconColor,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
