with open('lib/design_system/components/lumina_card.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Modifier _buildGridCard pour wrapper _HoverCard avec GestureDetector
old_grid_start = '''    return _HoverCard(
      onTap: onTap,
      child: Container('''

new_grid_start = '''    return GestureDetector(
      onTap: onTap,
      child: _HoverCard(
        child: Container('''

content = content.replace(old_grid_start, new_grid_start)

# 2. Fermer le GestureDetector (ajouter une parenthèse fermante)
# Le pattern actuel est:
#       ),
#     );
#   }
# Il faut ajouter une parenthèse avant le point-virgule

old_grid_close = '''      ),
    );
  }'''

# On doit trouver le bon endroit - chercher la fin de _buildGridCard
# Le pattern spécifique après le Container
old_end = '''          ),
        ),
      ),
    );
  }'''

new_end = '''          ),
        ),
      ),
    ),
  );
  }'''

content = content.replace(old_end, new_end, 1)  # Remplacer seulement la première occurrence (_buildGridCard)

# 3. Supprimer onTap de _HoverCard
old_hover = '''class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _HoverCard({required this.child, this.onTap});'''

new_hover = '''class _HoverCard extends StatefulWidget {
  final Widget child;

  const _HoverCard({required this.child});'''

content = content.replace(old_hover, new_hover)

# 4. Supprimer GestureDetector de _HoverCard
old_hover_build = '''    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer('''

new_hover_build = '''    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer('''

content = content.replace(old_hover_build, new_hover_build)

# 5. Supprimer la parenthèse fermante en trop du GestureDetector
old_hover_close = '''        ),
      ),
    );'''

new_hover_close = '''      ),
    );'''

content = content.replace(old_hover_close, new_hover_close, 1)  # Seulement la première occurrence (_HoverCard)

with open('lib/design_system/components/lumina_card.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('OK')
