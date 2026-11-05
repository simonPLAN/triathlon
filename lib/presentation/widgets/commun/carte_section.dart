import 'package:flutter/material.dart';

import '../../theme/espacements_application.dart';

class CarteSection extends StatelessWidget {
  const CarteSection({
    super.key,
    required this.child,
    this.titre,
    this.sousTitre,
    this.icone,
    this.action,
    this.onTap,
    this.padding = const EdgeInsets.all(EspacementsApplication.grand),
  });

  final Widget child;
  final String? titre;
  final String? sousTitre;
  final IconData? icone;
  final Widget? action;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contenu = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titre != null) ...[
            Row(
              children: [
                if (icone != null) ...[
                  Icon(icone, color: theme.colorScheme.primary),
                  const SizedBox(width: EspacementsApplication.petit),
                ],
                Expanded(
                  child: Text(titre!, style: theme.textTheme.titleMedium),
                ),
                ?action,
              ],
            ),
            if (sousTitre != null) ...[
              const SizedBox(height: EspacementsApplication.xs),
              Text(
                sousTitre!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: EspacementsApplication.moyen),
          ],
          child,
        ],
      ),
    );
    return Card(
      child: onTap == null ? contenu : InkWell(onTap: onTap, child: contenu),
    );
  }
}
