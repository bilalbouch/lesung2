with open('lib/design_system/components/lumina_card.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remplacer _buildGridCard pour ajouter hover effect
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
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(LuminaRadius.l),
        ),'''

content = content.replace(old_grid, new_grid)

# Supprimer la fin du GestureDetector/AnimatedContainer et remplacer par la fin du Container
old_end = '''      ),
    );
  }'''

# On cherche la fin du _buildGridCard - il faut être plus précis
# Le problème c'est qu'il y a plusieurs "    );" dans le fichier
# On va chercher le pattern spécifique de la fin de _buildGridCard

old_grid_end = '''                ),
              ),
            ),
          ),
        ),
      ),
    );
  }'''

new_grid_end = '''                ),
              ),
            ),
          ),
        ),
      ),
    );
  }'''

# En fait le GestureDetector/AnimatedContainer est remplacé par _HoverCard + Container
# Il faut juste s'assurer que le Container est fermé correctement
# Le pattern de fin est le même, donc on ne change pas la fin

# 4. Ajouter la classe _HoverCard à la fin du fichier
hover_card = '''

/// Card avec effet hover (lift + ombre)
class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _HoverCard({required this.child, this.onTap});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadow = _hovered
        ? (isDark ? LuminaShadows.darkLevel2 : LuminaShadows.level2)
        : (isDark ? LuminaShadows.darkLevel1 : LuminaShadows.level1);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
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

print('OK - Hover effect sur les cartes')
