import 'search_query.dart';

/// Lien de téléchargement résolu par une source.
///
/// Le DownloadManager (feature downloads) ne connaît QUE cette entité :
/// il reste totalement indépendant des providers.
class DownloadLink {
  /// URL directe ou page intermédiaire (cf. [kind]).
  final Uri url;

  final DownloadLinkKind kind;

  final BookFormat format;

  /// Empreinte MD5 annoncée par la source, pour vérification post-download.
  final String? md5;

  /// Taille annoncée en octets, si connue.
  final int? fileSizeBytes;

  const DownloadLink({
    required this.url,
    required this.kind,
    this.format = BookFormat.unknown,
    this.md5,
    this.fileSizeBytes,
  });

  @override
  String toString() => 'DownloadLink(${kind.name}, $url)';
}

enum DownloadLinkKind {
  /// Fichier directement téléchargeable par HTTP.
  direct,

  /// Page intermédiaire à résoudre (slow_download...) : nécessite le
  /// resolveur de la source (WebView, extraction JS...).
  intermediatePage,

  /// Nécessite une clé de don (fast download).
  premium,
}
