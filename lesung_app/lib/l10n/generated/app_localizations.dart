import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Lesung'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your library. Private. Local.'**
  String get appTagline;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning.'**
  String get greetingMorning;

  /// No description provided for @greetingDay.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon.'**
  String get greetingDay;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening.'**
  String get greetingEvening;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// No description provided for @tabLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get tabLibrary;

  /// No description provided for @tabDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get tabDownloads;

  /// No description provided for @tabMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tabMore;

  /// No description provided for @searchPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get searchPromptTitle;

  /// No description provided for @searchPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter title, author or ISBN.'**
  String get searchPromptSubtitle;

  /// No description provided for @searchLoading.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get searchLoading;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for {query}'**
  String searchNoResults(Object query);

  /// No description provided for @searchNoResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different title or author.'**
  String get searchNoResultsMessage;

  /// No description provided for @searchInBookHint.
  ///
  /// In en, this message translates to:
  /// **'Search term…'**
  String get searchInBookHint;

  /// No description provided for @searchInBookNoHits.
  ///
  /// In en, this message translates to:
  /// **'No matches.'**
  String get searchInBookNoHits;

  /// No description provided for @searchInBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Search in book'**
  String get searchInBookTitle;

  /// No description provided for @formatAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get formatAll;

  /// No description provided for @formatEpub.
  ///
  /// In en, this message translates to:
  /// **'EPUB'**
  String get formatEpub;

  /// No description provided for @formatPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get formatPdf;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty.'**
  String get libraryEmpty;

  /// No description provided for @libraryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Search for a book and download it — it will appear here.'**
  String get libraryEmptyMessage;

  /// No description provided for @libraryExplore.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get libraryExplore;

  /// No description provided for @libraryContinueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get libraryContinueReading;

  /// No description provided for @libraryRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get libraryRecentlyAdded;

  /// No description provided for @libraryDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get libraryDownloaded;

  /// No description provided for @libraryFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get libraryFavorites;

  /// No description provided for @libraryCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get libraryCollections;

  /// No description provided for @libraryHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get libraryHistory;

  /// No description provided for @bookDetailsDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get bookDetailsDownload;

  /// No description provided for @bookDetailsDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get bookDetailsDownloading;

  /// No description provided for @bookDetailsWebDownloadUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Downloads and offline reading are available in the Android and iOS apps.'**
  String get bookDetailsWebDownloadUnavailable;

  /// No description provided for @bookDetailsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get bookDetailsDescription;

  /// No description provided for @bookDetailsAddedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get bookDetailsAddedToFavorites;

  /// No description provided for @bookDetailsRemovedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get bookDetailsRemovedFromFavorites;

  /// No description provided for @bookDetailsDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started.'**
  String get bookDetailsDownloadStarted;

  /// No description provided for @bookDetailsDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String bookDetailsDownloadFailed(Object error);

  /// No description provided for @readerTocTitle.
  ///
  /// In en, this message translates to:
  /// **'Table of contents'**
  String get readerTocTitle;

  /// No description provided for @readerTocEmpty.
  ///
  /// In en, this message translates to:
  /// **'No table of contents available.'**
  String get readerTocEmpty;

  /// No description provided for @readerSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading settings'**
  String get readerSettingsTitle;

  /// No description provided for @readerSettingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get readerSettingsTheme;

  /// No description provided for @readerSettingsFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get readerSettingsFontSize;

  /// No description provided for @readerSettingsLineHeight.
  ///
  /// In en, this message translates to:
  /// **'Line spacing'**
  String get readerSettingsLineHeight;

  /// No description provided for @readerSettingsMargins.
  ///
  /// In en, this message translates to:
  /// **'Margins'**
  String get readerSettingsMargins;

  /// No description provided for @readerSettingsFontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get readerSettingsFontFamily;

  /// No description provided for @readerThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get readerThemeLight;

  /// No description provided for @readerThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get readerThemeDark;

  /// No description provided for @readerThemeSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get readerThemeSepia;

  /// No description provided for @readerThemeBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get readerThemeBlack;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get settingsTitle;

  /// No description provided for @settingsLibrarySection.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get settingsLibrarySection;

  /// No description provided for @settingsReadingStyle.
  ///
  /// In en, this message translates to:
  /// **'Reading style'**
  String get settingsReadingStyle;

  /// No description provided for @settingsStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get settingsStatistics;

  /// No description provided for @settingsBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get settingsBooks;

  /// No description provided for @settingsFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get settingsFinished;

  /// No description provided for @settingsReadingTime.
  ///
  /// In en, this message translates to:
  /// **'Reading time'**
  String get settingsReadingTime;

  /// No description provided for @settingsHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}min'**
  String settingsHoursMinutes(Object hours, Object minutes);

  /// No description provided for @settingsMinutesOnly.
  ///
  /// In en, this message translates to:
  /// **'{minutes}min'**
  String settingsMinutesOnly(Object minutes);

  /// No description provided for @downloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsTitle;

  /// No description provided for @downloadsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get downloadsActive;

  /// No description provided for @downloadsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get downloadsCompleted;

  /// No description provided for @downloadsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get downloadsFailed;

  /// No description provided for @downloadsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No downloads'**
  String get downloadsEmpty;

  /// No description provided for @downloadsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Downloaded books will appear here.'**
  String get downloadsEmptyMessage;

  /// No description provided for @collectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collectionsTitle;

  /// No description provided for @collectionCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New collection'**
  String get collectionCreateTitle;

  /// No description provided for @collectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get collectionNameHint;

  /// No description provided for @collectionRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename collection'**
  String get collectionRenameTitle;

  /// No description provided for @collectionDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete collection?'**
  String get collectionDeleteTitle;

  /// No description provided for @collectionDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'will be deleted. The books will remain in your library.'**
  String get collectionDeleteMessage;

  /// No description provided for @collectionRemoveBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from collection?'**
  String get collectionRemoveBookTitle;

  /// No description provided for @collectionRemoveBookMessage.
  ///
  /// In en, this message translates to:
  /// **'will be removed from the collection.'**
  String get collectionRemoveBookMessage;

  /// No description provided for @collectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty collection'**
  String get collectionEmpty;

  /// No description provided for @collectionEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add books to see them here.'**
  String get collectionEmptyMessage;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorites'**
  String get favoritesEmpty;

  /// No description provided for @favoritesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Mark books with the heart to collect them here.'**
  String get favoritesEmptyMessage;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get historyEmpty;

  /// No description provided for @historyEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Read books will appear here.'**
  String get historyEmptyMessage;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get actionPrevious;

  /// No description provided for @actionAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get actionAll;

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// No description provided for @actionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get errorNetwork;

  /// No description provided for @errorNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorNetworkTitle;

  /// No description provided for @errorNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get errorNetworkMessage;

  /// No description provided for @errorOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get errorOfflineTitle;

  /// No description provided for @errorOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'No connection. Your library remains available.'**
  String get errorOfflineMessage;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get errorUnknown;

  /// No description provided for @errorFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get errorFileNotFound;

  /// No description provided for @errorInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid file format'**
  String get errorInvalidFile;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import book'**
  String get importTitle;

  /// No description provided for @importSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select a file'**
  String get importSelectFile;

  /// No description provided for @importAddToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to library'**
  String get importAddToLibrary;

  /// No description provided for @importFileEpub.
  ///
  /// In en, this message translates to:
  /// **'EPUB file'**
  String get importFileEpub;

  /// No description provided for @importFilePdf.
  ///
  /// In en, this message translates to:
  /// **'PDF file'**
  String get importFilePdf;

  /// No description provided for @importExtractingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Extracting metadata…'**
  String get importExtractingMetadata;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Book added to library'**
  String get importSuccess;

  /// No description provided for @importPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Please allow access to files.'**
  String get importPermissionDenied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
