with open('lib/components/book_cover.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remplacer imports
content = content.replace(
    "import '../design_system/tokens/app_colors.dart';",
    "import '../design_system/tokens/lumina_colors.dart';"
)
content = content.replace(
    "import '../design_system/tokens/app_radius.dart';",
    "import '../design_system/tokens/lumina_radius.dart';"
)
content = content.replace(
    "import '../design_system/tokens/app_shadows.dart';",
    ""
)

# 2. Remplacer AppColors par Theme
content = content.replace(
    'final colors = AppColors.of(context);',
    'final colors = Theme.of(context).colorScheme;'
)

# 3. Mapper couleurs
content = content.replace('colors.accentSubtle', 'colors.primaryContainer')
content = content.replace('colors.accent', 'colors.primary')

# 4. Mapper radius
content = content.replace('AppRadius.cover', 'BorderRadius.circular(LuminaRadius.l)')

# 5. Supprimer AppShadows.cover et remplacer par LuminaShadows
content = content.replace(
    'boxShadow: AppShadows.cover(colors),',
    'boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],'
)

# 6. Ajouter heroTag au constructeur
old_ctor = '''  const BookCover({
    super.key,
    required this.title,
    this.coverUrl,
    this.width = 120,
  });'''

new_ctor = '''  const BookCover({
    super.key,
    required this.title,
    this.coverUrl,
    this.width = 120,
    this.heroTag,
  });'''

content = content.replace(old_ctor, new_ctor)

# 7. Ajouter le champ heroTag
old_field = '''  double get height => width / aspectRatio;'''

new_field = '''  final String? heroTag;

  double get height => width / aspectRatio;'''

content = content.replace(old_field, new_field)

# 8. Modifier build pour wrapper avec Hero si heroTag != null
old_build = '''  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final borderRadius = AppRadius.cover;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: AppShadows.cover(colors),
        color: colors.accentSubtle,
      ),
      clipBehavior: Clip.antiAlias,
      child: coverUrl != null && coverUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: coverUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => _Monogram(title: title),
              errorWidget: (_, __, ___) => _Monogram(title: title),
            )
          : _Monogram(title: title),
    );
  }'''

new_build = '''  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(LuminaRadius.l);
    final cover = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
        color: colors.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: coverUrl != null && coverUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: coverUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => _Monogram(title: title),
              errorWidget: (_, __, ___) => _Monogram(title: title),
            )
          : _Monogram(title: title),
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: cover,
      );
    }
    return cover;
  }'''

content = content.replace(old_build, new_build)

# 9. Fix _Monogram
content = content.replace(
    'final colors = AppColors.of(context);',
    'final colors = Theme.of(context).colorScheme;'
)
content = content.replace('colors.accent', 'colors.primary')

with open('lib/components/book_cover.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK - BookCover migre + Hero')
