import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contient le texte de la page courante.
/// Le reader ecrit ici via : ref.read(readerTextProvider.notifier).state = texte;
final readerTextProvider = StateProvider<String?>((ref) => null);

