import 'package:lesung/features/reader/domain/reader_settings.dart';
import 'package:test/test.dart';

void main() {
  group('ReaderSettings', () {
    test('bornes appliquées (police, interligne, marges, luminosité)',
        () {
      const base = ReaderSettings();
      expect(base.copyWith(fontSize: 500).fontSize, 32);
      expect(base.copyWith(fontSize: 1).fontSize, 10);
      expect(base.copyWith(lineHeight: 9).lineHeight, 2.5);
      expect(base.copyWith(lineHeight: 0.1).lineHeight, 1.0);
      expect(base.copyWith(marginHorizontal: -5).marginHorizontal, 0);
      expect(base.copyWith(marginVertical: 500).marginVertical, 64);
      expect(base.copyWith(brightness: 2).brightness, 1.0);
    });

    test('police et thème inconnus rejetés en conservant la valeur actuelle',
        () {
      const base = ReaderSettings();
      expect(base.copyWith(fontFamily: 'comic-sans').fontFamily, 'lora');
      expect(base.copyWith(themeId: 'matrix').themeId, 'light');
      expect(base.copyWith(fontFamily: 'inter').fontFamily, 'inter');
      expect(base.copyWith(themeId: 'night').themeId, 'night');
    });

    test('brightness nullable et effaçable', () {
      const base = ReaderSettings();
      expect(base.brightness, isNull);
      final set = base.copyWith(brightness: 0.4);
      expect(set.brightness, 0.4);
      expect(set.copyWith(clearBrightness: true).brightness, isNull);
    });

    test('JSON round-trip + valeurs par défaut sur JSON partiel/pourri',
        () {
      final custom = const ReaderSettings().copyWith(
          fontSize: 22,
          textAlign: ReaderTextAlign.left,
          orientation: ReaderOrientation.landscape,
          themeId: 'sepia');
      final restored = ReaderSettings.fromJson(custom.toJson());
      expect(restored.fontSize, 22);
      expect(restored.textAlign, ReaderTextAlign.left);
      expect(restored.orientation, ReaderOrientation.landscape);
      expect(restored.themeId, 'sepia');

      final partial = ReaderSettings.fromJson({'fontSize': 'pas un nombre'});
      expect(partial.fontSize, 18); // défaut
      expect(partial.textAlign, ReaderTextAlign.justify);
      final rotten = ReaderSettings.fromJson(
          {'themeId': 'inconnu', 'fontFamily': 'inconnue', 'textAlign': 'x'});
      expect(rotten.themeId, 'light');
      expect(rotten.fontFamily, 'lora');
      expect(rotten.textAlign, ReaderTextAlign.justify);
    });
  });

  group('ReaderTheme', () {
    test('les quatre thèmes existent avec couleurs cohérentes', () {
      expect(ReaderTheme.presets.keys, {'light', 'dark', 'sepia', 'night'});
      expect(ReaderTheme.light.isDark, isFalse);
      expect(ReaderTheme.dark.isDark, isTrue);
      expect(ReaderTheme.sepia.backgroundColor, 0xFFF5EBDD);
      expect(ReaderTheme.night.backgroundColor, 0xFF000000);
      expect(ReaderTheme.night.textColor, isNot(0xFFFFFFFF)); // adouci
    });

    test('byId avec repli sur light', () {
      expect(ReaderTheme.byId('sepia').id, 'sepia');
      expect(ReaderTheme.byId('nope').id, 'light');
    });
  });
}
