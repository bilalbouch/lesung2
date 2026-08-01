import 'package:flutter/material.dart';
import '../design_system/tokens/app_colors.dart';
import '../services/tts_service.dart';

class TtsButton extends StatefulWidget {
  final String text;
  final String? languageCode;
  const TtsButton({super.key, required this.text, this.languageCode});

  @override
  State<TtsButton> createState() => _TtsButtonState();
}

class _TtsButtonState extends State<TtsButton> {
  final TtsService _tts = TtsService();
  bool _speaking = false;

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_speaking) {
      await _tts.stop();
      setState(() => _speaking = false);
    } else {
      if (widget.languageCode != null) await _tts.setLanguage(widget.languageCode!);
      await _tts.speak(widget.text);
      setState(() => _speaking = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return FloatingActionButton.small(
      onPressed: _toggle,
      backgroundColor: _speaking ? colors.accent : colors.surface,
      child: Icon(_speaking ? Icons.stop : Icons.volume_up, color: _speaking ? Colors.white : colors.ink),
    );
  }
}
