import 'package:flutter/material.dart';

/// Tokens d'icônes — source unique des glyphes de l'application.
/// Style : icônes arrondies, trait régulier, tailles standardisées.
class AppIcons {
  const AppIcons._();

  static const double sizeS = 18;
  static const double sizeM = 22;
  static const double sizeL = 28;

  // Navigation
  static const IconData home = Icons.home_outlined;
  static const IconData homeFilled = Icons.home_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData library = Icons.auto_stories_outlined;
  static const IconData libraryFilled = Icons.auto_stories_rounded;
  static const IconData downloads = Icons.download_outlined;
  static const IconData downloadsFilled = Icons.download_rounded;
  static const IconData settings = Icons.tune_rounded;

  // Actions livre
  static const IconData favorite = Icons.favorite_outline_rounded;
  static const IconData favoriteFilled = Icons.favorite_rounded;
  static const IconData bookmark = Icons.bookmark_outline_rounded;
  static const IconData bookmarkFilled = Icons.bookmark_rounded;
  static const IconData annotate = Icons.edit_note_rounded;
  static const IconData download = Icons.arrow_downward_rounded;
  static const IconData read = Icons.menu_book_rounded;
  static const IconData collection = Icons.folder_outlined;
  static const IconData add = Icons.add_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData more = Icons.more_horiz_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData share = Icons.ios_share_rounded;

  // Reader
  static const IconData fontSize = Icons.format_size_rounded;
  static const IconData brightness = Icons.wb_sunny_outlined;
  static const IconData theme = Icons.contrast_rounded;
  static const IconData toc = Icons.format_list_bulleted_rounded;
  static const IconData searchInBook = Icons.manage_search_rounded;
  static const IconData chapterPrev = Icons.chevron_left_rounded;
  static const IconData chapterNext = Icons.chevron_right_rounded;

  // États
  static const IconData offline = Icons.wifi_off_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData empty = Icons.inventory_2_outlined;
  static const IconData history = Icons.schedule_rounded;
  static const IconData stats = Icons.bar_chart_rounded;
  static const IconData language = Icons.translate_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData pause = Icons.pause_rounded;
  static const IconData play = Icons.play_arrow_rounded;
  static const IconData cancel = Icons.cancel_outlined;
}
