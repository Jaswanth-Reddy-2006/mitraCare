import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitracare_app/core/theme/design_system.dart';
import 'package:mitracare_app/features/patient/patient_providers.dart';
import 'package:mitracare_app/services/localization_service.dart';
import '../models/cognitive_game_models.dart';
import '../controllers/cognitive_game_controller.dart';

enum ScreenStep { howToPlay, hearInstructions, gamePlay, gameCompleted }

class CognitiveGameScreen extends ConsumerStatefulWidget {
  final String activityId;
  final GameMode gameMode;
  final String difficulty;

  const CognitiveGameScreen({
    super.key,
    required this.activityId,
    required this.gameMode,
    this.difficulty = 'EASY',
  });

  @override
  ConsumerState<CognitiveGameScreen> createState() => _CognitiveGameScreenState();
}

class _CognitiveGameScreenState extends ConsumerState<CognitiveGameScreen> {
  ScreenStep _currentStep = ScreenStep.howToPlay;
  late CognitiveGameConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.gameMode == GameMode.pair
        ? CognitiveGameConfig.findThePair(difficulty: widget.difficulty)
        : CognitiveGameConfig.findTheTriplet(difficulty: widget.difficulty);

    // Initialize session asynchronously
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cognitiveGameProvider(_config).notifier).startSession(widget.activityId);
    });
  }

  void _onBackTap() {
    if (_currentStep == ScreenStep.gamePlay) {
      ref.read(cognitiveGameProvider(_config).notifier).pauseGame();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Leave this game?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Your current progress will not be saved."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(cognitiveGameProvider(_config).notifier).resumeGame();
              },
              child: const Text("Continue Playing", style: TextStyle(color: DesignSystem.primaryGreen, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
              child: const Text("Leave Game", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(cognitiveGameProvider(_config));
    final controller = ref.read(cognitiveGameProvider(_config).notifier);
    final textScale = MediaQuery.of(context).textScaleFactor;
    final lang = ref.watch(languageProvider);

    final title = widget.gameMode == GameMode.pair ? "Find the Pair" : "Find the Triplet";

    // Trigger step transition if game completes automatically
    if (gameState.status == GameStatus.completed && _currentStep == ScreenStep.gamePlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentStep = ScreenStep.gameCompleted;
        });
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: _currentStep == ScreenStep.gamePlay
          ? _buildGamePlayAppBar(gameState, textScale)
          : AppBar(
              title: Text(
                title,
                style: TextStyle(color: DesignSystem.textDark, fontWeight: FontWeight.bold, fontSize: 20 * textScale),
              ),
              backgroundColor: Colors.white,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: DesignSystem.textDark),
                onPressed: _onBackTap,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.volume_up_outlined, color: DesignSystem.primaryGreen),
                  onPressed: () {
                    final voice = ref.read(voiceServiceProvider);
                    voice.speak(
                      widget.gameMode == GameMode.pair
                          ? "Find the Pair. Match two same cards."
                          : "Find the Triplet. Match three same cards.",
                    );
                  },
                ),
              ],
            ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentStepView(gameState, controller, textScale, lang),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGamePlayAppBar(CognitiveGameState state, double textScale) {
    final isPair = widget.gameMode == GameMode.pair;
    final targetLabel = isPair ? "Pairs" : "Triplets";
    final countStr = "${state.matchedGroups} / ${_config.totalGroups}";

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: DesignSystem.textDark),
        onPressed: _onBackTap,
      ),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: DesignSystem.textDark, size: 22),
          const SizedBox(width: 6),
          Text(
            _formatTime(state.elapsedSeconds),
            style: TextStyle(color: DesignSystem.textDark, fontWeight: FontWeight.bold, fontSize: 18 * textScale),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                targetLabel,
                style: TextStyle(fontSize: 12 * textScale, color: DesignSystem.textSubtle, fontWeight: FontWeight.bold),
              ),
              Text(
                countStr,
                style: TextStyle(fontSize: 16 * textScale, color: DesignSystem.textDark, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepView(
    CognitiveGameState state,
    CognitiveGameNotifier controller,
    double textScale,
    String lang,
  ) {
    switch (_currentStep) {
      case ScreenStep.howToPlay:
        return _buildHowToPlayView(controller, textScale, lang);
      case ScreenStep.hearInstructions:
        return _buildHearInstructionsView(controller, textScale, lang);
      case ScreenStep.gamePlay:
        return _buildGameBoardView(state, controller, textScale, lang);
      case ScreenStep.gameCompleted:
        return _buildGameCompletedView(state, controller, textScale, lang);
    }
  }

  // --- Step 1: How To Play ---
  Widget _buildHowToPlayView(CognitiveGameNotifier controller, double textScale, String lang) {
    final isPair = widget.gameMode == GameMode.pair;
    final cardCountText = isPair ? "any two cards" : "any three cards";
    final matchConditionText = isPair ? "If both cards are the same, they stay open." : "If all three cards are the same, they stay open.";
    final winText = isPair ? "Find all pairs to complete the game!" : "Find all triplets to complete the game!";

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Text(
            "How to Play",
            style: TextStyle(fontSize: 24 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildInstructionRow(Icons.remove_red_eye_outlined, Colors.blue.shade600, "Look at the cards on the screen.", textScale),
                  const SizedBox(height: 20),
                  _buildInstructionRow(Icons.touch_app_outlined, Colors.orange.shade600, "Tap on $cardCountText to flip them.", textScale),
                  const SizedBox(height: 20),
                  _buildInstructionRow(Icons.check_circle_outline, Colors.green.shade600, matchConditionText, textScale),
                  const SizedBox(height: 20),
                  _buildInstructionRow(Icons.cancel_outlined, Colors.red.shade400, "If not same, they flip back automatically.", textScale),
                  const SizedBox(height: 20),
                  _buildInstructionRow(Icons.emoji_events_outlined, Colors.amber.shade700, winText, textScale),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = ScreenStep.hearInstructions;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primaryGreen,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            child: Text(
              "Got it!",
              style: TextStyle(fontSize: 18 * textScale, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              final voice = ref.read(voiceServiceProvider);
              voice.speak(
                isPair
                    ? "Look at the cards. Tap two cards to flip them. If they match, they stay open. Find all pairs!"
                    : "Look at the cards. Tap three cards to flip them. If all three match, they stay open. Find all triplets!",
              );
              setState(() {
                _currentStep = ScreenStep.hearInstructions;
              });
            },
            icon: const Icon(Icons.volume_up, color: DesignSystem.primaryGreen),
            label: Text(
              "Hear Instructions",
              style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.primaryGreen),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(IconData icon, Color color, String text, double textScale) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16 * textScale,
              fontWeight: FontWeight.w600,
              color: DesignSystem.textDark,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 2: Hear Instructions Screen ---
  Widget _buildHearInstructionsView(CognitiveGameNotifier controller, double textScale, String lang) {
    final isPair = widget.gameMode == GameMode.pair;
    final gameTitle = isPair ? "Find the Pair" : "Find the Triplet";
    final countWord = isPair ? "two" : "three";

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Character illustration avatar container
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
              border: Border.all(color: DesignSystem.primaryGreen, width: 3),
              boxShadow: DesignSystem.softShadow,
            ),
            child: const Center(
              child: Text(
                "👵",
                style: TextStyle(fontSize: 70),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Speech bubble container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: DesignSystem.softShadow,
            ),
            child: Column(
              children: [
                Text(
                  "This is $gameTitle game.",
                  style: TextStyle(fontSize: 17 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "In this game, you have to select $countWord cards.\n"
                  "If all $countWord cards are the same, they will stay open.\n"
                  "Find all ${isPair ? 'pairs' : 'triplets'} to win the game!",
                  style: TextStyle(fontSize: 15 * textScale, color: DesignSystem.textSubtle, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const Spacer(),

          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = ScreenStep.gamePlay;
              });
              controller.startGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primaryGreen,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            child: Text(
              "Okay, let's play!",
              style: TextStyle(fontSize: 18 * textScale, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --- Step 3: Game Board Screen ---
  Widget _buildGameBoardView(
    CognitiveGameState state,
    CognitiveGameNotifier controller,
    double textScale,
    String lang,
  ) {
    final isPair = widget.gameMode == GameMode.pair;
    final crossAxisCount = isPair ? 3 : 3;

    return Column(
      children: [
        // Main Board Grid Area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: state.cards.length,
              itemBuilder: (context, index) {
                return _buildCardWidget(state.cards[index], () {
                  controller.selectCard(index);
                }, textScale);
              },
            ),
          ),
        ),

        // Feedback Banner Toast (If active)
        if (state.feedbackMessage != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: state.feedbackMessage!.contains("Not a match")
                  ? Colors.orange.shade50
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: state.feedbackMessage!.contains("Not a match")
                    ? Colors.orange.shade300
                    : DesignSystem.primaryGreen.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.feedbackMessage!.contains("Not a match") ? "⚠️" : "😊",
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.feedbackMessage!,
                    style: TextStyle(
                      fontSize: 15 * textScale,
                      fontWeight: FontWeight.bold,
                      color: state.feedbackMessage!.contains("Not a match")
                          ? Colors.orange.shade900
                          : const Color(0xFF1B5E20),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

        // Bottom Hint Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: DesignSystem.softShadow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              const Text("💡", style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Need a hint?",
                      style: TextStyle(fontSize: 15 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                    ),
                    Text(
                      "You can use hint if you want.",
                      style: TextStyle(fontSize: 12 * textScale, color: DesignSystem.textSubtle),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  controller.showHint();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  "Show Hint",
                  style: TextStyle(fontSize: 14 * textScale, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardWidget(GameCard card, VoidCallback onTap, double textScale) {
    final isFlipped = card.state == CardState.flipped || card.state == CardState.matched;
    final isMatched = card.state == CardState.matched;
    final isHinted = card.isHinted;

    Color cardBgColor = const Color(0xFFD6C7FF); // Soft purple card back
    Color borderColor = const Color(0xFFB39DDB);

    if (isFlipped) {
      cardBgColor = Colors.white;
      borderColor = isMatched ? DesignSystem.primaryGreen : Colors.grey.shade300;
    }

    if (isHinted) {
      borderColor = Colors.amber.shade600;
      cardBgColor = Colors.amber.shade50;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isHinted || isMatched ? 3.0 : 1.5,
          ),
          boxShadow: DesignSystem.softShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!isFlipped)
              // Card back floral emblem pattern icon
              const Icon(
                Icons.local_florist,
                size: 36,
                color: Color(0xFF7E57C2),
              )
            else
              // Card face symbol
              Text(
                card.symbol,
                style: const TextStyle(fontSize: 42),
              ),

            // Checkmark indicator for matched state at bottom of card
            if (isMatched)
              Positioned(
                bottom: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: DesignSystem.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Step 4: Game Completed Screen ---
  Widget _buildGameCompletedView(
    CognitiveGameState state,
    CognitiveGameNotifier controller,
    double textScale,
    String lang,
  ) {
    final isPair = widget.gameMode == GameMode.pair;
    final groupLabel = isPair ? "Pairs" : "Triplets";

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Trophy illustration icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.shade400, width: 3),
            ),
            child: const Center(
              child: Text(
                "🏆",
                style: TextStyle(fontSize: 64),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            "Excellent!",
            style: TextStyle(fontSize: 28 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            "You completed the game.",
            style: TextStyle(fontSize: 16 * textScale, color: DesignSystem.textSubtle),
          ),

          const SizedBox(height: 28),

          // Result Summary Stat Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: DesignSystem.softShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text("Time", style: TextStyle(fontSize: 14 * textScale, color: DesignSystem.textSubtle)),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(state.elapsedSeconds),
                      style: TextStyle(fontSize: 22 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                    ),
                  ],
                ),
                Container(height: 36, width: 1, color: Colors.grey.shade300),
                Column(
                  children: [
                    Text(groupLabel, style: TextStyle(fontSize: 14 * textScale, color: DesignSystem.textSubtle)),
                    const SizedBox(height: 4),
                    Text(
                      "${state.matchedGroups} / ${_config.totalGroups}",
                      style: TextStyle(fontSize: 22 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          ElevatedButton(
            onPressed: () {
              controller.restartGame();
              setState(() {
                _currentStep = ScreenStep.gamePlay;
              });
              controller.startGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primaryGreen,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            child: Text(
              "Play Again",
              style: TextStyle(fontSize: 18 * textScale, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              context.pop();
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              "Back to Activities",
              style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
