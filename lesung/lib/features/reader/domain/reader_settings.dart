/// Réglages et thèmes du Reader.
library;

/// Alignement du texte.
enum ReaderTextAlign { left, justify, right }

/// Orientation de lecture demandée au système.
enum ReaderOrientation { auto, portrait, landscape }

/// Réglages de lecture — persistés globalement (pas par livre) :
/// un lecteur retrouve SES préférences quel que soit le livre.
class ReaderSettings {
  /// Taille de police en points (10..32).
  final double fontSize;

  /// Interligne multiplicateur (1.0..2.5).
  final double lineHeight;

  /// Marge horizontale en points (0..64).
  final double marginHorizontal;

  /// Marge verticale en points (0..64).
  final double marginVertical;

  final ReaderTextAlign textAlign;

  /// Identifiant de police dans le catalogue (voir [availableFonts]).
  final String fontFamily;

  /// Luminosité applicative 0..1 (null = suivre le système).
  final double? brightness;

  final ReaderOrientation orientation;

  /// Identifiant du thème actif (voir ReaderTheme.presets).
  final String themeId;

  const ReaderSettings({
    this.fontSize = 18,
    this.lineHeight = 1.5,
    this.marginHorizontal = 20,
    this.marginVertical = 16,
    this.textAlign = ReaderTextAlign.justify,
    this.fontFamily = 'lora',
    this.brightness,
    this.orientation = ReaderOrientation.auto,
    this.themeId = 'light',
  });

  /// Catalogue de polices embarquées (clés stables, labels allemands —
  /// la langue principale de l'application).
  static const availableFonts = <String, String>{
    'lora': 'Lora (Serif)',
    'inter': 'Inter (Sans)',
    'system_serif': 'System Serif',
    'system_sans': 'System Sans',
    'mono': 'Monospace',
  };

  ReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    double? marginHorizontal,
    double? marginVertical,
    ReaderTextAlign? textAlign,
    String? fontFamily,
    double? brightness,
    bool clearBrightness = false,
    ReaderOrientation? orientation,
    String? themeId,
  }) =>
      ReaderSettings(
        fontSize: (fontSize ?? this.fontSize).clamp(10, 32),
        lineHeight: (lineHeight ?? this.lineHeight).clamp(1.0, 2.5),
        marginHorizontal:
            (marginHorizontal ?? this.marginHorizontal).clamp(0, 64),
        marginVertical: (marginVertical ?? this.marginVertical).clamp(0, 64),
        textAlign: textAlign ?? this.textAlign,
        fontFamily: availableFonts.containsKey(fontFamily ?? this.fontFamily)
            ? (fontFamily ?? this.fontFamily)
            : this.fontFamily,
        brightness: clearBrightness
            ? null
            : (brightness ?? this.brightness)?.clamp(0.0, 1.0).toDouble(),
        orientation: orientation ?? this.orientation,
        themeId: ReaderTheme.presets.containsKey(themeId ?? this.themeId)
            ? (themeId ?? this.themeId)
            : this.themeId,
      );

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'lineHeight': lineHeight,
        'marginHorizontal': marginHorizontal,
        'marginVertical': marginVertical,
        'textAlign': textAlign.name,
        'fontFamily': fontFamily,
        'brightness': brightness,
        'orientation': orientation.name,
        'themeId': themeId,
      };

  factory ReaderSettings.fromJson(Map<String, dynamic> json) {
    const defaults = ReaderSettings();
    ReaderTextAlign parseAlign(String? v) => ReaderTextAlign.values
        .firstWhere((a) => a.name == v, orElse: () => defaults.textAlign);
    ReaderOrientation parseOrientation(String? v) =>
        ReaderOrientation.values.firstWhere((o) => o.name == v,
            orElse: () => defaults.orientation);
    // JSON de provenance inconnue : les valeurs non numériques tombent
    // sur les défauts au lieu de lever une erreur de cast.
    double? numOf(String key) =>
        json[key] is num ? (json[key] as num).toDouble() : null;
    return ReaderSettings(
      fontSize: (numOf('fontSize') ?? defaults.fontSize).clamp(10, 32),
      lineHeight: (numOf('lineHeight') ?? defaults.lineHeight).clamp(1.0, 2.5),
      marginHorizontal: (numOf('marginHorizontal') ?? 20).clamp(0, 64),
      marginVertical: (numOf('marginVertical') ?? 16).clamp(0, 64),
      textAlign: parseAlign(json['textAlign'] as String?),
      fontFamily:
          availableFonts.containsKey(json['fontFamily'] as String?)
              ? json['fontFamily'] as String
              : defaults.fontFamily,
      brightness: numOf('brightness')?.clamp(0.0, 1.0).toDouble(),
      orientation: parseOrientation(json['orientation'] as String?),
      themeId:
          ReaderTheme.presets.containsKey(json['themeId'] as String?)
              ? json['themeId'] as String
              : defaults.themeId,
    );
  }
}

/// Thème de lecture : couleurs ARGB entières (0xFFxxxxxx) pour rester
/// indépendant de Flutter (l'UI les convertit en Color).
class ReaderTheme {
  final String id;

  /// Nom affiché (allemand — langue principale).
  final String name;

  final int backgroundColor;
  final int textColor;
  final int surfaceColor;
  final int accentColor;

  /// Thème sombre (utile pour l'icône/l'UI).
  final bool isDark;

  const ReaderTheme({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.surfaceColor,
    required this.accentColor,
    required this.isDark,
  });

  static const light = ReaderTheme(
    id: 'light',
    name: 'Hell',
    backgroundColor: 0xFFFFFFFF,
    textColor: 0xFF1B1B1F,
    surfaceColor: 0xFFF4F2EE,
    accentColor: 0xFF4A6B57,
    isDark: false,
  );

  static const dark = ReaderTheme(
    id: 'dark',
    name: 'Dunkel',
    backgroundColor: 0xFF141416,
    textColor: 0xFFE4E1E6,
    surfaceColor: 0xFF1E1E22,
    accentColor: 0xFF9BC2A9,
    isDark: true,
  );

  static const sepia = ReaderTheme(
    id: 'sepia',
    name: 'Sepia',
    backgroundColor: 0xFFF5EBDD,
    textColor: 0xFF3E3229,
    surfaceColor: 0xFFEDE0CC,
    accentColor: 0xFF7A5C3E,
    isDark: false,
  );

  /// Night = noir profond, texte adouci (confort nocturne maximal).
  static const night = ReaderTheme(
    id: 'night',
    name: 'Nacht',
    backgroundColor: 0xFF000000,
    textColor: 0xFFB8B3AD,
    surfaceColor: 0xFF0E0E10,
    accentColor: 0xFF6E8B78,
    isDark: true,
  );

  static const presets = <String, ReaderTheme>{
    'light': light,
    'dark': dark,
    'sepia': sepia,
    'night': night,
  };

  static ReaderTheme byId(String id) => presets[id] ?? light;
}
