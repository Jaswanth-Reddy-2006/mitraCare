import 'package:flutter_test/flutter_test.dart';
import 'package:mitracare_app/services/voice_service.dart';
import 'package:mitracare_app/features/patient/games/models/cognitive_game_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Play Game & Voice Assistance Tests', () {
    late VoiceService voiceService;

    setUp(() {
      voiceService = VoiceService();
    });

    test('VoiceService initial state and non-overlapping speech handling', () async {
      expect(voiceService.isSpeaking, isFalse);
      expect(voiceService.isListening, isFalse);

      // Trigger speak and stop cleanly
      await voiceService.speak("Choose a game. You can play Match the Pair or Match the Triplet.");
      await voiceService.stop();
      expect(voiceService.isSpeaking, isFalse);
    });

    test('Game mode configuration validation', () {
      final pairConfig = CognitiveGameConfig.findThePair(difficulty: 'EASY');
      expect(pairConfig.mode, equals(GameMode.pair));
      expect(pairConfig.cardsPerGroup, equals(2));
      expect(pairConfig.totalGroups, greaterThan(0));

      final tripletConfig = CognitiveGameConfig.findTheTriplet(difficulty: 'EASY');
      expect(tripletConfig.mode, equals(GameMode.triplet));
      expect(tripletConfig.cardsPerGroup, equals(3));
      expect(tripletConfig.totalGroups, greaterThan(0));
    });
  });
}
