import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

import 'annas_archive_dto.dart';

/// Parser HTML d'Anna's Archive — SEUL fichier couplé au markup du site.
///
/// Si Anna's Archive change son HTML, seul ce fichier est à modifier.
///
/// Stratégie anti-fragilité : le parsing s'appuie sur des repères
/// STRUCTURELS (ancres `a[href*="/md5/"]`, microdata éventuelle, contenu
/// textuel analysé par regex) et NON sur les classes CSS utilitaires
/// (Tailwind), qui changent à chaque refonte. Les classes ne servent
/// qu'en dernier recours, jamais comme clé primaire.
///
/// Toutes les méthodes sont pures : testables sur fixtures, aucun réseau.
class AnnaArchiveParser {
  // ------------------------------------------------------------------
  // Page de recherche
  // ------------------------------------------------------------------

  /// Parse une page /search en DTO brut.
  RawSearchPage parseSearchPage(String html, {int currentPage = 1}) {
    final document = html_parser.parse(html);
    final hits = <RawSearchHit>[];
    final seenMd5 = <String>{};

    // Repère structurel primaire : toute ancre vers une page /md5/.
    for (final anchor in document.querySelectorAll('a[href*="/md5/"]')) {
      final md5 = extractMd5(anchor.attributes['href'] ?? '');
      if (md5 == null || !seenMd5.add(md5)) continue;

      final container = _findResultContainer(anchor);
      if (container == null) continue;

      final hit = _parseHit(anchor, container, md5);
      if (hit != null) hits.add(hit);
    }

    return RawSearchPage(
      hits: hits,
      hasNextPage: detectNextPage(document, currentPage),
    );
  }

  /// Remonte depuis l'ancre titre jusqu'au conteneur de la carte
  /// résultat : le plus petit ancêtre (max 6 niveaux) contenant à la
  /// fois du texte substantiel et l'ancre.
  Element? _findResultContainer(Element anchor) {
    Element? current = anchor.parent;
    for (var depth = 0; depth < 6 && current != null; depth++) {
      final textLength = current.text.trim().length;
      if (textLength > anchor.text.trim().length + 10) {
        return current;
      }
      current = current.parent;
    }
    return anchor.parent;
  }

  RawSearchHit? _parseHit(Element anchor, Element container, String md5) {
    final title = anchor.text.trim();
    if (title.isEmpty) return null;

    final href = anchor.attributes['href'] ?? '/md5/$md5';

    // Lignes de texte du conteneur, titre exclu.
    final lines = container.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l != title)
        .toList();

    String? author;
    String? publisher;
    String infoLine = '';
    String? languageHint;
    int? yearHint;

    for (final line in lines) {
      final hasFormat = RegExp(
              r'\b(epub|pdf|cbr|cbz|azw3|mobi|fb2|djvu)\b',
              caseSensitive: false)
          .hasMatch(line);
      final hasSize = RegExp(r'\d+(?:[.,]\d+)?\s*(kb|mb|gb|kib|mib|gib)\b',
              caseSensitive: false)
          .hasMatch(line);

      if (hasFormat || hasSize) {
        // Ligne d'infos fichier : conservée brute pour le Mapper.
        infoLine = infoLine.isEmpty ? line : '$infoLine $line';
        languageHint ??= extractLanguageHint(line);
        yearHint ??= extractYear(line);
        continue;
      }
      if (author == null && _looksLikeAuthor(line)) {
        author = line;
        continue;
      }
      if (publisher == null && _looksLikePublisher(line)) {
        publisher = line;
        continue;
      }
      yearHint ??= extractYear(line);
    }

    // Couverture : première image du conteneur.
    String? coverUrl;
    final img = container.querySelector('img');
    final src = img?.attributes['src'];
    if (src != null && src.startsWith('http')) coverUrl = src;

    return RawSearchHit(
      title: title,
      author: author,
      publisher: publisher,
      coverUrl: coverUrl,
      infoLine: infoLine,
      md5: md5,
      detailPath: href.startsWith('/') ? href : '/md5/$md5',
      languageHint: languageHint,
      yearHint: yearHint,
    );
  }

  /// Détecte un lien de pagination vers la page suivante.
  bool detectNextPage(Document document, int currentPage) {
    return document
        .querySelectorAll('a[href*="page=${currentPage + 1}"]')
        .isNotEmpty;
  }

  // ------------------------------------------------------------------
  // Page de détail
  // ------------------------------------------------------------------

  /// Parse une page /md5/<id> en DTO brut.
  RawDetailPage parseDetailPage(String html) {
    final document = html_parser.parse(html);
    final bodyText = document.body?.text ?? '';

    // Titre : microdata ou plus grand titre textuel, jamais une classe CSS.
    String? title = document
        .querySelector('[itemprop="name"]')
        ?.text
        .trim();
    if (title == null || title.isEmpty) {
      // Repli : premier heading non vide de la zone principale.
      for (final h in document.querySelectorAll('h1, h2, h3')) {
        final t = h.text.trim();
        if (t.isNotEmpty && t.length > 3) {
          title = t;
          break;
        }
      }
    }

    // Auteur : ancre de recherche d'auteur (structurelle).
    String? author;
    for (final a in document.querySelectorAll('a[href*="/search"]')) {
      final href = a.attributes['href'] ?? '';
      if (href.contains('q=%22') || href.contains('q="')) {
        final t = a.text.trim();
        if (t.isNotEmpty && t.length < 120) {
          author = t;
          break;
        }
      }
    }

    // Synopsis : bloc de description (plusieurs repères essayés).
    String? synopsis;
    for (final selector in [
      'div.js-md5-top-box-description',
      '[itemprop="description"]',
      'div.book-description',
    ]) {
      final el = document.querySelector(selector);
      final t = el?.text.trim();
      if (t != null && t.length > 20) {
        synopsis = t;
        break;
      }
    }

    // ISBN : regex sur le texte complet (structurellement indépendant).
    String? isbn;
    final isbnMatch =
        RegExp(r'\b(97[89][\d\- ]{10,16})\b').firstMatch(bodyText);
    if (isbnMatch != null) {
      isbn = isbnMatch.group(1)!.replaceAll(RegExp(r'[\- ]'), '');
    }

    // Couverture : image de la zone principale, ou image dont l'alt
    // évoque une couverture (filtre en Dart, pas en sélecteur CSS).
    String? coverUrl;
    Element? img = document.querySelector('main img');
    if (img == null) {
      for (final candidate in document.querySelectorAll('img')) {
        final alt = (candidate.attributes['alt'] ?? '').toLowerCase();
        if (alt.contains('cover') || alt.contains('couverture')) {
          img = candidate;
          break;
        }
      }
    }
    final src = img?.attributes['src'];
    if (src != null && src.startsWith('http')) coverUrl = src;

    // Ligne d'infos fichier : ligne contenant un format + une taille.
    var infoLine = '';
    for (final line in bodyText.split('\n').map((l) => l.trim())) {
      if (RegExp(r'\b(epub|pdf|cbr|cbz|azw3|mobi)\b', caseSensitive: false)
              .hasMatch(line) &&
          RegExp(r'\d+(?:[.,]\d+)?\s*(kb|mb|gb)\b', caseSensitive: false)
              .hasMatch(line) &&
          line.length < 200) {
        infoLine = line;
        break;
      }
    }

    // Liens de téléchargement : ancres /slow_download/ (structurelles).
    final slowPaths = <String>[];
    for (final a in document.querySelectorAll('a[href*="/slow_download/"]')) {
      final href = a.attributes['href'];
      if (href != null && !slowPaths.contains(href)) slowPaths.add(href);
    }

    return RawDetailPage(
      title: title,
      author: author,
      coverUrl: coverUrl,
      synopsis: synopsis,
      isbn: isbn,
      infoLine: infoLine,
      slowDownloadPaths: slowPaths,
    );
  }

  // ------------------------------------------------------------------
  // Cloudflare
  // ------------------------------------------------------------------

  /// Détecte un challenge anti-bot Cloudflare.
  ///
  /// [headers] : en-têtes de réponse (cf-mitigated est un signal fort).
  bool isCloudflareChallenge(
      int statusCode, Map<String, String> headers, String body) {
    final cfMitigated = headers.entries.any((e) =>
        e.key.toLowerCase() == 'cf-mitigated' &&
        e.value.toLowerCase().contains('challenge'));
    if (cfMitigated) return true;

    if (statusCode == 403 || statusCode == 503) {
      final lower = body.toLowerCase();
      return lower.contains('just a moment') ||
          lower.contains('cf-chl') ||
          lower.contains('challenge-platform') ||
          lower.contains('cf-mitigated');
    }
    return false;
  }

  // ------------------------------------------------------------------
  // Extracteurs réutilisables (utilisés aussi par le Mapper)
  // ------------------------------------------------------------------

  /// Extrait un md5 depuis un href /md5/<id>.
  String? extractMd5(String href) {
    final match = RegExp(r'/md5/([0-9a-fA-F]{32})').firstMatch(href);
    return match?.group(1)?.toLowerCase();
  }

  /// Indice de langue brut depuis une ligne de texte.
  String? extractLanguageHint(String line) {
    final bracket = RegExp(r'\[([a-zA-Z]{2})\]').firstMatch(line);
    if (bracket != null) return bracket.group(1)!.toLowerCase();
    final word = RegExp(
            r'\b(english|german|french|deutsch|francais|spanish|italian|portuguese|russian|chinese|japanese|dutch|polish|turkish)\b',
            caseSensitive: false)
        .firstMatch(line);
    return word?.group(1)?.toLowerCase();
  }

  /// Année plausible (1500-2099) dans une ligne.
  int? extractYear(String line) {
    final match = RegExp(r'\b(1[5-9]\d{2}|20\d{2})\b').firstMatch(line);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  bool _looksLikeAuthor(String line) {
    if (line.length < 3 || line.length > 120) return false;
    if (line.contains('http')) return false;
    if (RegExp(r'\d+(?:[.,]\d+)?\s*(kb|mb|gb)\b', caseSensitive: false)
        .hasMatch(line)) {
      return false;
    }
    return true;
  }

  bool _looksLikePublisher(String line) {
    if (line.length < 2 || line.length > 120) return false;
    return RegExp(
            r'(verlag|press|publishing|publisher|éditions|editions|springer|wiley|penguin|hachette|random house|gallimard|suhrkamp|fischer)',
            caseSensitive: false)
        .hasMatch(line);
  }
}
