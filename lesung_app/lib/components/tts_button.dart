import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tts_service.dart';
import '../features/reader/reader_text_provider.dart';

class TtsButton extends ConsumerWidget {
  const TtsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(ttsStateProvider);
    final pageText = ref.watch(readerTextProvider);

    final isPlaying = tts.isPlaying;
    final hasText = pageText != null && pageText.trim().isNotEmpty;

    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          isPlaying ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
          key: ValueKey<bool>(isPlaying),
        ),
      ),
      color: isPlaying
          ? Theme.of(context).colorScheme.primary
          : (hasText ? null : Colors.grey),
      onPressed: hasText
          ? () {
              final notifier = ref.read(ttsStateProvider.notifier);
              if (isPlaying) {
                notifier.stop();
              } else {
                notifier.speak(pageText);
              }
            }
          : null,
      tooltip: isPlaying ? 'Arrêter' : 'Lire à haute voix',
    );
  }
}