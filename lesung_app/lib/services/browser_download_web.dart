// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void startBrowserDownload(Uri url, String fileName) {
  final anchor = html.AnchorElement(href: url.toString())
    ..download = fileName
    ..target = '_blank'
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
