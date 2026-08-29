import 'package:flutter/foundation.dart';

class VoiceService extends ChangeNotifier {
  bool _isListening = false;
  String _lastRecognizedIntent = '';
  String _speechText = '';

  bool get isListening => _isListening;
  String get lastRecognizedIntent => _lastRecognizedIntent;
  String get speechText => _speechText;

  Future<void> startListening() async {
    _isListening = true;
    _speechText = 'Listening...';
    notifyListeners();

    // Mock speech recognition delay
    await Future.delayed(const Duration(seconds: 2));
    if (_isListening) {
      _speechText = 'I need my morning medicine';
      _lastRecognizedIntent = 'TAKE_MEDICINE';
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    debugPrint("Mitra Voice speaking: $text");
  }

  Future<void> reset() async {
    _isListening = false;
    _speechText = '';
    _lastRecognizedIntent = '';
    notifyListeners();
  }
}
