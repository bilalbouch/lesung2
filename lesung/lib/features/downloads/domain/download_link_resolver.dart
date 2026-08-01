import '../../search/domain/entities/download_link.dart';

/// Contrat du résolveur de liens intermédiaires.
///
/// Certains liens (kind = intermediatePage, ex. pages slow_download)
/// doivent être transformés en URL directes — opération qui peut exiger
/// une WebView ou du scraping côté application/source. Le moteur ne
/// connaît QUE ce contrat : il reste totalement indépendant des sources.
abstract class DownloadLinkResolver {
  /// Résout une page intermédiaire en URL(s) directement
  /// téléchargeable(s). Liste vide si la résolution échoue.
  Future<List<Uri>> resolve(DownloadLink link);
}
