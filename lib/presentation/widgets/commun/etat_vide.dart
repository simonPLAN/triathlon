import 'package:flutter/material.dart';

import '../../theme/espacements_application.dart';
import 'bouton_action_principale.dart';

class EtatVide extends StatelessWidget {
  const EtatVide({
    super.key,
    required this.titre,
    required this.description,
    this.icone = Icons.inbox_outlined,
    this.libelleAction,
    this.onAction,
  });
  final String titre;
  final String description;
  final IconData icone;
  final String? libelleAction;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: EspacementsApplication.page,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  icone,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: EspacementsApplication.grand),
              Text(
                titre,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: EspacementsApplication.petit),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (libelleAction != null && onAction != null) ...[
                const SizedBox(height: EspacementsApplication.grand),
                BoutonActionPrincipale(
                  libelle: libelleAction!,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
