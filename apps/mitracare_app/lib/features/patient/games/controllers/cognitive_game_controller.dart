import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cognitive_game_models.dart';
import 'package:mitracare_app/features/patient/patient_repository.dart';
import 'package:mitracare_app/features/patient/patient_providers.dart';

final cognitiveGameProvider = StateNotifierProvider.autoDispose
    .family<CognitiveGameNotifier, CognitiveGameState, CognitiveGameConfig>((ref, config) {
  final repo = ref.watch(activityRepositoryProvider);
  return CognitiveGameNotifier(config: config, repository: repo);
});

class CognitiveGameNotifier extends StateNotifier<CognitiveGameState> {
  final CognitiveGameConfig config;
  final ActivityRepository repository;
  Timer? _gameTimer;
  Timer? _evaluationTimer;
  Timer? _hintTimer;
  Timer? _inactivityTimer;

  static const List<String> _availableSymbols = [
    '🍎', '🚗', '🌸', '☕', '⚽', '🌳', '☂️', '🕒', '🦋', '🎩',
    '🎁', '🐱', '🔔', '🌻', '🍦', '⛵', '🏀', '🎈', '🔑', '🍇'
  ];

  CognitiveGameNotifier({
    required this.config,
    required this.repository,
  }) : super(
          CognitiveGameState(
            mode: config.mode,
            config: config,
            cards: [],
          ),
        ) {
    _initBoard();
  }

  CognitiveGameState get debugState => state;

  void _initBoard() {
    final random = Random();
    final shuffledSymbols = List<String>.from(_availableSymbols)..shuffle(random);
    final selectedSymbols = shuffledSymbols.take(config.totalGroups).toList();

    List<GameCard> cardList = [];
    int cardId = 0;

    for (int groupIdx = 0; groupIdx < config.totalGroups; groupIdx++) {
      final symbol = selectedSymbols[groupIdx];
      for (int c = 0; c < config.cardsPerGroup; c++) {
        cardList.add(
          GameCard(
            id: 'card_${cardId++}',
            symbol: symbol,
            groupIndex: groupIdx,
            state: CardState.hidden,
          ),
        );
      }
    }

    cardList.shuffle(random);

    state = CognitiveGameState(
      mode: config.mode,
      config: config,
      status: GameStatus.ready,
      cards: cardList,
      matchedGroups: 0,
      elapsedSeconds: 0,
      attempts: 0,
      incorrectMatches: 0,
      hintsUsed: 0,
      score: 0,
      accuracy: 1.0,
      feedbackMessage: null,
    );
  }

  Future<void> startSession(String activityId) async {
    try {
      final session = await repository.startSession(
        activityId,
        difficulty: config.difficulty,
      );
      state = state.copyWith(sessionId: session['id']);
    } catch (e) {
      debugPrint("Offline or fallback session initialization: $e");
      state = state.copyWith(sessionId: "local_session_${DateTime.now().millisecondsSinceEpoch}");
    }
  }

  void startGame() {
    if (state.status == GameStatus.playing) return;

    state = state.copyWith(status: GameStatus.playing);
    _startTimer();
    _resetInactivityTimer();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && state.status == GameStatus.playing) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && state.status == GameStatus.playing) {
        showHint(isAutoAI: true);
      }
    });
  }

  void pauseGame() {
    _gameTimer?.cancel();
    _inactivityTimer?.cancel();
    state = state.copyWith(status: GameStatus.paused);
  }

  void resumeGame() {
    if (state.status == GameStatus.paused) {
      state = state.copyWith(status: GameStatus.playing);
      _startTimer();
      _resetInactivityTimer();
    }
  }

  void selectCard(int index) {
    if (state.status != GameStatus.playing) return;
    if (index < 0 || index >= state.cards.length) return;

    _resetInactivityTimer();

    final targetCard = state.cards[index];

    // Prevent selecting already flipped, matched, or currently selected card
    if (targetCard.state != CardState.hidden) return;
    if (state.selectedIndices.contains(index)) return;

    // Prevent selecting beyond limit
    if (state.selectedIndices.length >= config.cardsPerGroup) return;

    final updatedCards = List<GameCard>.from(state.cards);
    updatedCards[index] = targetCard.copyWith(state: CardState.flipped);

    final updatedSelected = [...state.selectedIndices, index];

    if (updatedSelected.length < config.cardsPerGroup) {
      // Partial selection (e.g. 1st card in pair, or 1st/2nd card in triplet)
      state = state.copyWith(
        cards: updatedCards,
        selectedIndices: updatedSelected,
      );
    } else {
      // Full selection reached -> Evaluate!
      state = state.copyWith(
        cards: updatedCards,
        selectedIndices: updatedSelected,
        status: GameStatus.evaluating,
      );

      _evaluateSelection(updatedSelected);
    }
  }

  void _evaluateSelection(List<int> selectedIndices) {
    final firstGroup = state.cards[selectedIndices.first].groupIndex;
    final isMatch = selectedIndices.every((idx) => state.cards[idx].groupIndex == firstGroup);

    final newAttempts = state.attempts + 1;

    if (isMatch) {
      // Match successful!
      final updatedCards = List<GameCard>.from(state.cards);
      for (final idx in selectedIndices) {
        updatedCards[idx] = updatedCards[idx].copyWith(state: CardState.matched, isHinted: false);
      }

      final newMatchedCount = state.matchedGroups + 1;
      final isGameComplete = newMatchedCount == config.totalGroups;

      final totalAttempts = newAttempts;
      final currentAccuracy = totalAttempts > 0 ? (newMatchedCount / totalAttempts) : 1.0;

      final matchText = config.mode == GameMode.pair ? "a pair!" : "a triplet!";

      state = state.copyWith(
        cards: updatedCards,
        selectedIndices: [],
        matchedGroups: newMatchedCount,
        attempts: newAttempts,
        accuracy: currentAccuracy,
        feedbackMessage: isGameComplete
            ? (config.mode == GameMode.pair ? "Wonderful! You found all pairs!" : "Wonderful! You found all triplets!")
            : "Great! You found $matchText",
        status: isGameComplete ? GameStatus.completed : GameStatus.playing,
      );

      if (isGameComplete) {
        _finishGame();
      }
    } else {
      // Mismatch!
      final newIncorrect = state.incorrectMatches + 1;
      final totalAttempts = newAttempts;
      final currentAccuracy = totalAttempts > 0 ? (state.matchedGroups / totalAttempts) : 1.0;

      state = state.copyWith(
        attempts: newAttempts,
        incorrectMatches: newIncorrect,
        accuracy: currentAccuracy,
        feedbackMessage: "Not a match, cards will flip back.",
      );

      _evaluationTimer?.cancel();
      _evaluationTimer = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        final resetCards = List<GameCard>.from(state.cards);
        for (final idx in selectedIndices) {
          if (resetCards[idx].state == CardState.flipped) {
            resetCards[idx] = resetCards[idx].copyWith(state: CardState.hidden, isHinted: false);
          }
        }

        state = state.copyWith(
          cards: resetCards,
          selectedIndices: [],
          status: GameStatus.playing,
          feedbackMessage: null,
        );
      });
    }
  }

  void showHint({bool isAutoAI = false}) {
    if (state.status != GameStatus.playing) return;

    // Find a group that is not yet matched
    final unmatchedGroupIndices = <int>{};
    for (int i = 0; i < state.cards.length; i++) {
      if (state.cards[i].state == CardState.hidden) {
        unmatchedGroupIndices.add(state.cards[i].groupIndex);
      }
    }

    if (unmatchedGroupIndices.isEmpty) return;

    final chosenGroup = unmatchedGroupIndices.first;
    final updatedCards = List<GameCard>.from(state.cards);

    for (int i = 0; i < updatedCards.length; i++) {
      if (updatedCards[i].groupIndex == chosenGroup && updatedCards[i].state == CardState.hidden) {
        updatedCards[i] = updatedCards[i].copyWith(isHinted: true);
      }
    }

    final hintMsg = isAutoAI
        ? "🤖 AI Hint: Try tapping these highlighted cards!"
        : (config.mode == GameMode.pair
            ? "Hint: These two cards are the same."
            : "Hint: These three cards are the same.");

    state = state.copyWith(
      cards: updatedCards,
      hintsUsed: state.hintsUsed + 1,
      feedbackMessage: hintMsg,
    );

    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      final clearHintCards = List<GameCard>.from(state.cards);
      for (int i = 0; i < clearHintCards.length; i++) {
        if (clearHintCards[i].isHinted) {
          clearHintCards[i] = clearHintCards[i].copyWith(isHinted: false);
        }
      }
      state = state.copyWith(cards: clearHintCards, feedbackMessage: null);
      if (state.status == GameStatus.playing) {
        _resetInactivityTimer();
      }
    });
  }

  Future<void> _finishGame() async {
    _gameTimer?.cancel();

    // Deterministic score calculation
    int baseScore = 100;
    int mistakePenalty = state.incorrectMatches * 5;
    int hintPenalty = state.hintsUsed * 8;
    int calculatedScore = baseScore - mistakePenalty - hintPenalty;
    if (calculatedScore < 50) calculatedScore = 50;
    if (calculatedScore > 100) calculatedScore = 100;

    double accuracyVal = state.attempts > 0 ? (state.matchedGroups / state.attempts) : 1.0;
    if (accuracyVal > 1.0) accuracyVal = 1.0;
    if (accuracyVal < 0.0) accuracyVal = 0.0;

    state = state.copyWith(
      status: GameStatus.completed,
      score: calculatedScore,
      accuracy: accuracyVal,
    );

    if (state.sessionId != null) {
      try {
        await repository.submitResult(
          sessionId: state.sessionId!,
          score: calculatedScore,
          accuracy: accuracyVal,
          responseTime: state.elapsedSeconds * 1000,
          mistakes: state.incorrectMatches,
          hintsUsed: state.hintsUsed,
          metadata: '{"mode": "${config.mode.name}", "difficulty": "${config.difficulty}", "duration": ${state.elapsedSeconds}}',
        );
      } catch (e) {
        debugPrint("Error submitting result to backend (saved locally if offline): $e");
      }
    }
  }

  void restartGame() {
    _gameTimer?.cancel();
    _evaluationTimer?.cancel();
    _hintTimer?.cancel();
    _initBoard();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _evaluationTimer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }
}
