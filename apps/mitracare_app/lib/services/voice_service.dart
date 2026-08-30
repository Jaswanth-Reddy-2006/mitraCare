import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastRecognizedIntent = '';
  String _speechText = '';

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get lastRecognizedIntent => _lastRecognizedIntent;
  String get speechText => _speechText;

  VoiceService() {
    _initTts();
  }

  void _initTts() async {
    try {
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint("Mitra Voice TTS error: $msg");
        _isSpeaking = false;
        notifyListeners();
      });

      await _flutterTts.setSpeechRate(0.45).catchError((_) {});
      await _flutterTts.setVolume(1.0).catchError((_) {});
      await _flutterTts.setPitch(1.0).catchError((_) {});
    } catch (e) {
      debugPrint("TTS init fallback: $e");
    }
  }

  Future<void> startListening() async {
    _isListening = true;
    _speechText = 'Listening...';
    notifyListeners();

    // Mock speech recognition delay for voice command UI
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

  /// Speaks [text] in the requested language [langCode].
  /// Stops any currently playing speech first to prevent overlapping audio streams.
  Future<void> speak(String text, {String langCode = 'en'}) async {
    try {
      await stop();

      String ttsLang = 'en-US';
      if (langCode == 'hi') {
        ttsLang = 'hi-IN';
      } else if (langCode == 'bn') {
        ttsLang = 'bn-IN';
      } else if (langCode == 'as') {
        ttsLang = 'as-IN';
      }

      await _flutterTts.setLanguage(ttsLang).catchError((_) {});
      debugPrint("Mitra Voice speaking ($ttsLang): $text");
      _isSpeaking = true;
      notifyListeners();
      await _flutterTts.speak(text).catchError((_) {});
    } catch (e) {
      debugPrint("VoiceService speak fallback error: $e");
      _isSpeaking = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop().catchError((_) {});
    } catch (e) {
      debugPrint("VoiceService stop error: $e");
    } finally {
      _isSpeaking = false;
      notifyListeners();
    }
  }

  Future<void> reset() async {
    _isListening = false;
    _isSpeaking = false;
    _speechText = '';
    _lastRecognizedIntent = '';
    await stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
