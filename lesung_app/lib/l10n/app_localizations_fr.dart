// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Lesung';

  @override
  String get appTagline => 'Votre bibliothèque. Privée. Locale.';

  @override
  String get greetingMorning => 'Bonjour.';

  @override
  String get greetingDay => 'Bonjour.';

  @override
  String get greetingEvening => 'Bonsoir.';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabSearch => 'Recherche';

  @override
  String get tabLibrary => 'Bibliothèque';

  @override
  String get tabDownloads => 'Téléchargements';

  @override
  String get tabMore => 'Plus';

  @override
  String get searchPromptTitle => 'Que recherchez-vous ?';

  @override
  String get searchPromptSubtitle => 'Entrez un titre, un auteur ou un ISBN.';

  @override
  String get searchLoading => 'Recherche en cours…';

  @override
  String searchNoResults(Object query) {
    return 'Aucun résultat pour $query';
  }

  @override
  String get searchInBookHint => 'Terme recherché…';

  @override
  String get searchInBookNoHits => 'Aucune correspondance.';

  @override
  String get searchInBookTitle => 'Rechercher dans le livre';

  @override
  String get formatAll => 'Tous';

  @override
  String get formatEpub => 'EPUB';

  @override
  String get formatPdf => 'PDF';

  @override
  String get libraryTitle => 'Bibliothèque';

  @override
  String get libraryEmpty => 'Votre bibliothèque est vide.';

  @override
  String get libraryExplore => 'Rechercher des livres';

  @override
  String get libraryContinueReading => 'Continuer la lecture';

  @override
  String get libraryRecentlyAdded => 'Récemment ajoutés';

  @override
  String get libraryDownloaded => 'Téléchargés';

  @override
  String get libraryFavorites => 'Favoris';

  @override
  String get libraryCollections => 'Collections';

  @override
  String get libraryHistory => 'Historique';

  @override
  String get bookDetailsDownload => 'Télécharger';

  @override
  String get bookDetailsDownloading => 'Téléchargement…';

  @override
  String get bookDetailsDescription => 'Description';

  @override
  String get bookDetailsAddedToFavorites => 'Ajouté aux favoris';

  @override
  String get bookDetailsRemovedFromFavorites => 'Retiré des favoris';

  @override
  String get bookDetailsDownloadStarted => 'Téléchargement démarré.';

  @override
  String bookDetailsDownloadFailed(Object error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get readerTocTitle => 'Table des matières';

  @override
  String get readerTocEmpty => 'Aucune table des matières disponible.';

  @override
  String get readerSettingsTitle => 'Paramètres de lecture';

  @override
  String get readerSettingsTheme => 'Thème';

  @override
  String get readerSettingsFontSize => 'Taille de police';

  @override
  String get readerSettingsLineHeight => 'Interligne';

  @override
  String get readerSettingsMargins => 'Marges';

  @override
  String get readerSettingsFontFamily => 'Police';

  @override
  String get readerThemeLight => 'Clair';

  @override
  String get readerThemeDark => 'Sombre';

  @override
  String get readerThemeSepia => 'Sépia';

  @override
  String get readerThemeBlack => 'Noir';

  @override
  String get settingsTitle => 'Plus';

  @override
  String get settingsLibrarySection => 'Bibliothèque';

  @override
  String get settingsReadingStyle => 'Style de lecture';

  @override
  String get settingsStatistics => 'Statistiques';

  @override
  String get settingsBooks => 'Livres';

  @override
  String get settingsFinished => 'Terminés';

  @override
  String get settingsReadingTime => 'Temps de lecture';

  @override
  String settingsHoursMinutes(Object hours, Object minutes) {
    return '${hours}h ${minutes}min';
  }

  @override
  String settingsMinutesOnly(Object minutes) {
    return '${minutes}min';
  }

  @override
  String get downloadsTitle => 'Téléchargements';

  @override
  String get downloadsActive => 'Actifs';

  @override
  String get downloadsCompleted => 'Terminés';

  @override
  String get downloadsFailed => 'Échoués';

  @override
  String get downloadsEmpty => 'Aucun téléchargement';

  @override
  String get collectionsTitle => 'Collections';

  @override
  String get favoritesTitle => 'Favoris';

  @override
  String get historyTitle => 'Historique';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionBack => 'Retour';

  @override
  String get actionNext => 'Suivant';

  @override
  String get actionPrevious => 'Précédent';

  @override
  String get actionAll => 'Tous';

  @override
  String get errorNetwork => 'Erreur réseau';

  @override
  String get errorUnknown => 'Une erreur inconnue s\'est produite';

  @override
  String get errorFileNotFound => 'Fichier introuvable';

  @override
  String get errorInvalidFile => 'Format de fichier invalide';

  @override
  String get importTitle => 'Importer un livre';

  @override
  String get importSelectFile => 'Sélectionner un fichier';

  @override
  String get importAddToLibrary => 'Ajouter à la bibliothèque';

  @override
  String get importFileEpub => 'Fichier EPUB';

  @override
  String get importFilePdf => 'Fichier PDF';

  @override
  String get importExtractingMetadata => 'Extraction des métadonnées…';

  @override
  String get importSuccess => 'Livre ajouté à la bibliothèque';

  @override
  String get importPermissionDenied => 'Permission refusée. Veuillez autoriser l\'accès aux fichiers.';
}
