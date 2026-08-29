import 'package:flutter/foundation.dart';

enum GameMode { pair, triplet }
enum CardState { hidden, flipped, matched }
enum GameStatus { ready, playing, evaluating, completed, paused }

class GameCard {
  final String id;
  final String symbol; // E.g., 🍎, 🚗, 🌸, ☕, ⚽, 🌳, ☂️, 🕒, 🦋, 🎩
  final int groupIndex;
  final CardState state;
  final bool isHinted;

  GameCard({
    required this.id,
    required this.symbol,
    required this.groupIndex,
    this.state = CardState.hidden,
    this.isHinted = false,
  });

  GameCard copyWith({
    CardState? state,
    bool? isHinted,
  }) {
    return GameCard(
      id: id,
      symbol: symbol,
      groupIndex: groupIndex,
      state: state ?? this.state,
      isHinted: isHinted ?? this.isHinted,
    );
  }
}

class CognitiveGameConfig {
  final GameMode mode;
  final String difficulty;
  final int totalGroups;
  final int cardsPerGroup;

  const CognitiveGameConfig({
    required this.mode,
    this.difficulty = 'EASY',
    required this.totalGroups,
    required this.cardsPerGroup,
  });

  int get totalCards => totalGroups * cardsPerGroup;

  factory CognitiveGameConfig.findThePair({String difficulty = 'EASY'}) {
    int groups = 4; // EASY: 4 pairs (8 cards)
    if (difficulty == 'MEDIUM') groups = 6; // 6 pairs (12 cards)
    if (difficulty == 'HARD') groups = 8; // 8 pairs (16 cards)
    return CognitiveGameConfig(
      mode: GameMode.pair,
      difficulty: difficulty,
      totalGroups: groups,
      cardsPerGroup: 2,
    );
  }

  factory CognitiveGameConfig.findTheTriplet({String difficulty = 'EASY'}) {
    int groups = 3; // EASY: 3 triplets (9 cards)
    if (difficulty == 'MEDIUM') groups = 4; // 4 triplets (12 cards)
    if (difficulty == 'HARD') groups = 6; // 6 triplets (18 cards)
    return CognitiveGameConfig(
      mode: GameMode.triplet,
      difficulty: difficulty,
      totalGroups: groups,
      cardsPerGroup: 3,
    );
  }
}

class CognitiveGameState {
  final GameMode mode;
  final CognitiveGameConfig config;
  final GameStatus status;
  final List<GameCard> cards;
  final List<int> selectedIndices;
  final int matchedGroups;
  final int elapsedSeconds;
  final int attempts;
  final int incorrectMatches;
  final int hintsUsed;
  final int score;
  final double accuracy;
  final String? sessionId;
  final String? feedbackMessage;

  CognitiveGameState({
    required this.mode,
    required this.config,
    this.status = GameStatus.ready,
    required this.cards,
    this.selectedIndices = const [],
    this.matchedGroups = 0,
    this.elapsedSeconds = 0,
    this.attempts = 0,
    this.incorrectMatches = 0,
    this.hintsUsed = 0,
    this.score = 0,
    this.accuracy = 1.0,
    this.sessionId,
    this.feedbackMessage,
  });

  CognitiveGameState copyWith({
    GameStatus? status,
    List<GameCard>? cards,
    List<int>? selectedIndices,
    int? matchedGroups,
    int? elapsedSeconds,
    int? attempts,
    int? incorrectMatches,
    int? hintsUsed,
    int? score,
    double? accuracy,
    String? sessionId,
    String? feedbackMessage,
  }) {
    return CognitiveGameState(
      mode: mode,
      config: config,
      status: status ?? this.status,
      cards: cards ?? this.cards,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      matchedGroups: matchedGroups ?? this.matchedGroups,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      attempts: attempts ?? this.attempts,
      incorrectMatches: incorrectMatches ?? this.incorrectMatches,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      score: score ?? this.score,
      accuracy: accuracy ?? this.accuracy,
      sessionId: sessionId ?? this.sessionId,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
    );
  }
}
