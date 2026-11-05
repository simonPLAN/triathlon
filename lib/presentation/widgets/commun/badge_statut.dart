import 'package:flutter/material.dart';

enum TonBadgeStatut { neutre, information, actif, succes, erreur }

class BadgeStatut extends StatelessWidget {
  const BadgeStatut({
    super.key,
    required this.libelle,
    required this.icone,
    this.ton = TonBadgeStatut.neutre,
  });
  final String libelle;
  final IconData icone;
  final TonBadgeStatut ton;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final sombre = c.brightness == Brightness.dark;
    final (fond, texte) = switch (ton) {
      TonBadgeStatut.neutre => (c.surfaceContainerHighest, c.onSurfaceVariant),
      TonBadgeStatut.information => (
        c.secondaryContainer,
        c.onSecondaryContainer,
      ),
      TonBadgeStatut.actif => (
        sombre ? const Color(0xFF493514) : const Color(0xFFFFEAC2),
        sombre ? const Color(0xFFFFD998) : const Color(0xFF634000),
      ),
      TonBadgeStatut.succes => (c.primaryContainer, c.onPrimaryContainer),
      TonBadgeStatut.erreur => (c.errorContainer, c.onErrorContainer),
    };
    return Semantics(
      label: 'Statut : $libelle',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 16, color: texte),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                libelle,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: texte, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
