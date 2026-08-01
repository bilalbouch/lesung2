import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _isInitialized = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _flutterTts.setLanguage('fr-FR');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _flutterTts.setCompletionHandler(() => _isSpeaking = false);
    _flutterTts.setErrorHandler((msg) => _isSpeaking = false);
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    await initialize();
    if (_isSpeaking) await stop();
    _isSpeaking = true;
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  Future<void> setLanguage(String languageCode) async {
    await _flutterTts.setLanguage(languageCode);
  }

  void dispose() {
    _flutterTts.stop();
  }
}
