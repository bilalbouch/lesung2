with open('lib/design_system/components/lumina_card.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Modifier _buildGridCard pour ajouter hover
old_grid = '''  Widget _buildGridCard(BuildContext context, bool isDark) {
    final bg = isDark ? LuminaColorsDark.surface : LuminaColors.surface;
    final textPri = isDark ? LuminaColorsDark.textPrimary : LuminaColors.textPrimary;
    final textSec = isDark ? LuminaColorsDark.textSecondary : LuminaColors.textSecondary;
    final textTer = isDark ? LuminaColorsDark.textTertiary : LuminaColors.textTertiary;
    final shadows = isDark ? LuminaShadows.darkLevel1 : LuminaShadows.level1;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(LuminaRadius.l),
          boxShadow: shadows,
        ),'''

new_grid = '''  Widget _buildGridCard(BuildContext context, bool isDark) {
    final bg = isDark ? LuminaColorsDark.surface : LuminaColors.surface;
    final textPri = isDark ? LuminaColorsDark.textPrimary : LuminaColors.textPrimary;
    final textSec = isDark ? LuminaColorsDark.textSecondary : LuminaColors.textSecondary;
    final textTer = isDark ? LuminaColorsDark.textTertiary : LuminaColors.textTertiary;

    return _HoverCard(
      onTap: onTap,
      isDark: isDark,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(LuminaRadius.l),
        ),'''

content = content.replace(old_grid, new_grid)

# 2. Ajouter _HoverCard à la fin
hover_card = '''

class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isDark;

  const _HoverCard({required this.child, this.onTap, required this.isDark});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final shadow = _hovered
        ? (widget.isDark ? LuminaShadows.darkLevel2 : LuminaShadows.level2)
        : (widget.isDark ? LuminaShadows.darkLevel1 : LuminaShadows.level1);

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LuminaRadius.l),
            boxShadow: shadow,
          ),
          transform: _hovered ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
          child: widget.child,
        ),
      ),
    );
  }
}
'''

content = content.rstrip() + hover_card

with open('lib/design_system/components/lumina_card.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK')
