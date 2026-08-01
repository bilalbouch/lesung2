// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Lesung';

  @override
  String get appTagline => 'Your library. Private. Local.';

  @override
  String get greetingMorning => 'Good morning.';

  @override
  String get greetingDay => 'Good afternoon.';

  @override
  String get greetingEvening => 'Good evening.';

  @override
  String get tabHome => 'Home';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabLibrary => 'Library';

  @override
  String get tabDownloads => 'Downloads';

  @override
  String get tabMore => 'More';

  @override
  String get searchPromptTitle => 'What are you looking for?';

  @override
  String get searchPromptSubtitle => 'Enter title, author or ISBN.';

  @override
  String get searchLoading => 'Searching…';

  @override
  String searchNoResults(Object query) {
    return 'No results for $query';
  }

  @override
  String get searchInBookHint => 'Search term…';

  @override
  String get searchInBookNoHits => 'No matches.';

  @override
  String get searchInBookTitle => 'Search in book';

  @override
  String get formatAll => 'All';

  @override
  String get formatEpub => 'EPUB';

  @override
  String get formatPdf => 'PDF';

  @override
  String get libraryTitle => 'Library';

  @override
  String get libraryEmpty => 'Your library is empty.';

  @override
  String get libraryExplore => 'Search books';

  @override
  String get libraryContinueReading => 'Continue reading';

  @override
  String get libraryRecentlyAdded => 'Recently added';

  @override
  String get libraryDownloaded => 'Downloaded';

  @override
  String get libraryFavorites => 'Favorites';

  @override
  String get libraryCollections => 'Collections';

  @override
  String get libraryHistory => 'History';

  @override
  String get bookDetailsDownload => 'Download';

  @override
  String get bookDetailsDownloading => 'Downloading…';

  @override
  String get bookDetailsDescription => 'Description';

  @override
  String get bookDetailsAddedToFavorites => 'Added to favorites';

  @override
  String get bookDetailsRemovedFromFavorites => 'Removed from favorites';

  @override
  String get bookDetailsDownloadStarted => 'Download started.';

  @override
  String bookDetailsDownloadFailed(Object error) {
    return 'Download failed: $error';
  }

  @override
  String get readerTocTitle => 'Table of contents';

  @override
  String get readerTocEmpty => 'No table of contents available.';

  @override
  String get readerSettingsTitle => 'Reading settings';

  @override
  String get readerSettingsTheme => 'Theme';

  @override
  String get readerSettingsFontSize => 'Font size';

  @override
  String get readerSettingsLineHeight => 'Line spacing';

  @override
  String get readerSettingsMargins => 'Margins';

  @override
  String get readerSettingsFontFamily => 'Font';

  @override
  String get readerThemeLight => 'Light';

  @override
  String get readerThemeDark => 'Dark';

  @override
  String get readerThemeSepia => 'Sepia';

  @override
  String get readerThemeBlack => 'Black';

  @override
  String get settingsTitle => 'More';

  @override
  String get settingsLibrarySection => 'Library';

  @override
  String get settingsReadingStyle => 'Reading style';

  @override
  String get settingsStatistics => 'Statistics';

  @override
  String get settingsBooks => 'Books';

  @override
  String get settingsFinished => 'Finished';

  @override
  String get settingsReadingTime => 'Reading time';

  @override
  String settingsHoursMinutes(Object hours, Object minutes) {
    return '${hours}h ${minutes}min';
  }

  @override
  String settingsMinutesOnly(Object minutes) {
    return '${minutes}min';
  }

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get downloadsActive => 'Active';

  @override
  String get downloadsCompleted => 'Completed';

  @override
  String get downloadsFailed => 'Failed';

  @override
  String get downloadsEmpty => 'No downloads';

  @override
  String get collectionsTitle => 'Collections';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get historyTitle => 'History';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionSave => 'Save';

  @override
  String get actionClose => 'Close';

  @override
  String get actionBack => 'Back';

  @override
  String get actionNext => 'Next';

  @override
  String get actionPrevious => 'Previous';

  @override
  String get actionAll => 'All';

  @override
  String get errorNetwork => 'Network error';

  @override
  String get errorUnknown => 'An unknown error occurred';

  @override
  String get errorFileNotFound => 'File not found';

  @override
  String get errorInvalidFile => 'Invalid file format';

  @override
  String get importTitle => 'Import book';

  @override
  String get importSelectFile => 'Select a file';

  @override
  String get importAddToLibrary => 'Add to library';

  @override
  String get importFileEpub => 'EPUB file';

  @override
  String get importFilePdf => 'PDF file';

  @override
  String get importExtractingMetadata => 'Extracting metadata…';

  @override
  String get importSuccess => 'Book added to library';

  @override
  String get importPermissionDenied => 'Permission denied. Please allow access to files.';
}
