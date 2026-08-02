import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ttsStateProvider = StateNotifierProvider<TtsNotifier, TtsState>((ref) {
  return TtsNotifier();
});

class TtsState {
  final bool isPlaying;
  final String? currentText;
  final String language;

  const TtsState({
    this.isPlaying = false,
    this.currentText,
    this.language = 'fr-FR',
  });

  TtsState copyWith({
    bool? isPlaying,
    String? currentText,
    String? language,
  }) {
    return TtsState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentText: currentText ?? this.currentText,
      language: language ?? this.language,
    );
  }
}

class TtsNotifier extends StateNotifier<TtsState> {
  final FlutterTts _tts = FlutterTts();

  TtsNotifier() : super(const TtsState()) {
    _tts.setCompletionHandler(() {
      state = state.copyWith(isPlaying: false);
    });
    _tts.setErrorHandler((msg) {
      state = state.copyWith(isPlaying: false);
    });
  }

  Future<void> speak(String text, {String? language}) async {
    if (text.trim().isEmpty) return;
    await stop();

    final lang = language ?? state.language;
    await _tts.setLanguage(lang);
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    state = state.copyWith(isPlaying: true, currentText: text, language: lang);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    if (state.isPlaying) {
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    await _tts.setLanguage(lang);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}