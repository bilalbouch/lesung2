// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Lesung';

  @override
  String get appTagline => 'Deine Bibliothek. Privat. Lokal.';

  @override
  String get greetingMorning => 'Guten Morgen.';

  @override
  String get greetingDay => 'Guten Tag.';

  @override
  String get greetingEvening => 'Guten Abend.';

  @override
  String get tabHome => 'Start';

  @override
  String get tabSearch => 'Suche';

  @override
  String get tabLibrary => 'Bibliothek';

  @override
  String get tabDownloads => 'Downloads';

  @override
  String get tabMore => 'Mehr';

  @override
  String get searchPromptTitle => 'Wonach suchst du?';

  @override
  String get searchPromptSubtitle => 'Titel, Autor oder ISBN eingeben.';

  @override
  String get searchLoading => 'Suche läuft…';

  @override
  String searchNoResults(Object query) {
    return 'Keine Ergebnisse für $query';
  }

  @override
  String get searchInBookHint => 'Suchbegriff…';

  @override
  String get searchInBookNoHits => 'Keine Treffer.';

  @override
  String get searchInBookTitle => 'Suche im Buch';

  @override
  String get formatAll => 'Alle';

  @override
  String get formatEpub => 'EPUB';

  @override
  String get formatPdf => 'PDF';

  @override
  String get libraryTitle => 'Bibliothek';

  @override
  String get libraryEmpty => 'Deine Bibliothek ist leer.';

  @override
  String get libraryExplore => 'Bücher suchen';

  @override
  String get libraryContinueReading => 'Weiterlesen';

  @override
  String get libraryRecentlyAdded => 'Zuletzt hinzugefügt';

  @override
  String get libraryDownloaded => 'Heruntergeladen';

  @override
  String get libraryFavorites => 'Favoriten';

  @override
  String get libraryCollections => 'Sammlungen';

  @override
  String get libraryHistory => 'Verlauf';

  @override
  String get bookDetailsDownload => 'Herunterladen';

  @override
  String get bookDetailsDownloading => 'Wird geladen…';

  @override
  String get bookDetailsDescription => 'Beschreibung';

  @override
  String get bookDetailsAddedToFavorites => 'Zu Favoriten hinzugefügt';

  @override
  String get bookDetailsRemovedFromFavorites => 'Aus Favoriten entfernt';

  @override
  String get bookDetailsDownloadStarted => 'Download gestartet.';

  @override
  String bookDetailsDownloadFailed(Object error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String get readerTocTitle => 'Inhaltsverzeichnis';

  @override
  String get readerTocEmpty => 'Kein Inhaltsverzeichnis verfügbar.';

  @override
  String get readerSettingsTitle => 'Leseinstellungen';

  @override
  String get readerSettingsTheme => 'Design';

  @override
  String get readerSettingsFontSize => 'Schriftgröße';

  @override
  String get readerSettingsLineHeight => 'Zeilenabstand';

  @override
  String get readerSettingsMargins => 'Ränder';

  @override
  String get readerSettingsFontFamily => 'Schriftart';

  @override
  String get readerThemeLight => 'Hell';

  @override
  String get readerThemeDark => 'Dunkel';

  @override
  String get readerThemeSepia => 'Sepia';

  @override
  String get readerThemeBlack => 'Schwarz';

  @override
  String get settingsTitle => 'Mehr';

  @override
  String get settingsLibrarySection => 'Bibliothek';

  @override
  String get settingsReadingStyle => 'Lesestil';

  @override
  String get settingsStatistics => 'Statistik';

  @override
  String get settingsBooks => 'Bücher';

  @override
  String get settingsFinished => 'Beendet';

  @override
  String get settingsReadingTime => 'Lesezeit';

  @override
  String settingsHoursMinutes(Object hours, Object minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String settingsMinutesOnly(Object minutes) {
    return '$minutes Min.';
  }

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get downloadsActive => 'Aktiv';

  @override
  String get downloadsCompleted => 'Abgeschlossen';

  @override
  String get downloadsFailed => 'Fehlgeschlagen';

  @override
  String get downloadsEmpty => 'Keine Downloads';

  @override
  String get collectionsTitle => 'Sammlungen';

  @override
  String get favoritesTitle => 'Favoriten';

  @override
  String get historyTitle => 'Verlauf';

  @override
  String get actionRetry => 'Erneut versuchen';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionClose => 'Schließen';

  @override
  String get actionBack => 'Zurück';

  @override
  String get actionNext => 'Weiter';

  @override
  String get actionPrevious => 'Zurück';

  @override
  String get actionAll => 'Alle';

  @override
  String get errorNetwork => 'Netzwerkfehler';

  @override
  String get errorUnknown => 'Ein unbekannter Fehler ist aufgetreten';

  @override
  String get errorFileNotFound => 'Datei nicht gefunden';

  @override
  String get errorInvalidFile => 'Ungültiges Dateiformat';

  @override
  String get importTitle => 'Buch importieren';

  @override
  String get importSelectFile => 'Datei auswählen';

  @override
  String get importAddToLibrary => 'Zur Bibliothek hinzufügen';

  @override
  String get importFileEpub => 'EPUB-Datei';

  @override
  String get importFilePdf => 'PDF-Datei';

  @override
  String get importExtractingMetadata => 'Metadaten werden extrahiert…';

  @override
  String get importSuccess => 'Buch zur Bibliothek hinzugefügt';

  @override
  String get importPermissionDenied => 'Berechtigung verweigert. Bitte erlaube den Zugriff auf Dateien.';
}
