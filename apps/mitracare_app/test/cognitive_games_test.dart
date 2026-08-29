import 'package:flutter_test/flutter_test.dart';
import 'package:mitracare_app/features/patient/games/models/cognitive_game_models.dart';
import 'package:mitracare_app/features/patient/games/controllers/cognitive_game_controller.dart';
import 'package:mitracare_app/features/patient/patient_repository.dart';

class FakeActivityRepository implements ActivityRepository {
  @override
  Future<List<dynamic>> getActivities() async => [];

  @override
  Future<List<dynamic>> getHistory() async => [];

  @override
  Future<Map<String, dynamic>> startSession(String activityId, {String? difficulty}) async {
    return {'id': 'test_session_123', 'status': 'STARTED'};
  }

  @override
  Future<Map<String, dynamic>> submitResult({
    required String sessionId,
    required int score,
    required double accuracy,
    int? responseTime,
    int mistakes = 0,
    int hintsUsed = 0,
    String? metadata,
  }) async {
    return {'id': 'test_result_123', 'score': score};
  }
}

void main() {
  group('Cognitive Games Logic Tests', () {
    late FakeActivityRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeActivityRepository();
    });

    test('Find the Pair configuration and initial state', () {
      final config = CognitiveGameConfig.findThePair(difficulty: 'EASY');
      expect(config.mode, GameMode.pair);
      expect(config.totalGroups, 4);
      expect(config.cardsPerGroup, 2);
      expect(config.totalCards, 8);

      final notifier = CognitiveGameNotifier(config: config, repository: fakeRepo);
      expect(notifier.debugState.cards.length, 8);
      expect(notifier.debugState.status, GameStatus.ready);
      expect(notifier.debugState.matchedGroups, 0);
    });

    test('Find the Triplet configuration and initial state', () {
      final config = CognitiveGameConfig.findTheTriplet(difficulty: 'EASY');
      expect(config.mode, GameMode.triplet);
      expect(config.totalGroups, 3);
      expect(config.cardsPerGroup, 3);
      expect(config.totalCards, 9);

      final notifier = CognitiveGameNotifier(config: config, repository: fakeRepo);
      expect(notifier.debugState.cards.length, 9);
      expect(notifier.debugState.status, GameStatus.ready);
    });

    test('Find the Pair match logic', () async {
      final config = CognitiveGameConfig.findThePair(difficulty: 'EASY');
      final notifier = CognitiveGameNotifier(config: config, repository: fakeRepo);
      notifier.startGame();
      expect(notifier.debugState.status, GameStatus.playing);

      // Find indices of first matching pair
      final group0Symbol = notifier.debugState.cards.first.groupIndex;
      final matchingIndices = <int>[];
      for (int i = 0; i < notifier.debugState.cards.length; i++) {
        if (notifier.debugState.cards[i].groupIndex == group0Symbol) {
          matchingIndices.add(i);
        }
      }

      expect(matchingIndices.length, 2);

      // Select first card
      notifier.selectCard(matchingIndices[0]);
      expect(notifier.debugState.cards[matchingIndices[0]].state, CardState.flipped);

      // Select second matching card
      notifier.selectCard(matchingIndices[1]);
      expect(notifier.debugState.cards[matchingIndices[1]].state, CardState.matched);
      expect(notifier.debugState.matchedGroups, 1);
    });

    test('Find the Triplet match logic', () async {
      final config = CognitiveGameConfig.findTheTriplet(difficulty: 'EASY');
      final notifier = CognitiveGameNotifier(config: config, repository: fakeRepo);
      notifier.startGame();
      expect(notifier.debugState.status, GameStatus.playing);

      // Find indices of first matching triplet
      final group0Symbol = notifier.debugState.cards.first.groupIndex;
      final matchingIndices = <int>[];
      for (int i = 0; i < notifier.debugState.cards.length; i++) {
        if (notifier.debugState.cards[i].groupIndex == group0Symbol) {
          matchingIndices.add(i);
        }
      }

      expect(matchingIndices.length, 3);

      // Select first card
      notifier.selectCard(matchingIndices[0]);
      expect(notifier.debugState.cards[matchingIndices[0]].state, CardState.flipped);

      // Select second card
      notifier.selectCard(matchingIndices[1]);
      expect(notifier.debugState.cards[matchingIndices[1]].state, CardState.flipped);

      // Select third matching card
      notifier.selectCard(matchingIndices[2]);
      expect(notifier.debugState.cards[matchingIndices[2]].state, CardState.matched);
      expect(notifier.debugState.matchedGroups, 1);
    });

    test('Hint highlights valid unmatched group', () {
      final config = CognitiveGameConfig.findThePair(difficulty: 'EASY');
      final notifier = CognitiveGameNotifier(config: config, repository: fakeRepo);
      notifier.startGame();

      notifier.showHint();
      expect(notifier.debugState.hintsUsed, 1);

      final hintedCards = notifier.debugState.cards.where((c) => c.isHinted).toList();
      expect(hintedCards.length, 2);
      expect(hintedCards[0].groupIndex, hintedCards[1].groupIndex);
    });
  });
}
