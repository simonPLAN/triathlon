import 'package:flutter/material.dart';

import '../../theme/espacements_application.dart';
import 'bouton_action_principale.dart';
import 'carte_section.dart';

class MessageErreur extends StatelessWidget {
  const MessageErreur({
    super.key,
    required this.message,
    this.titre = 'Une erreur est survenue',
    this.onReessayer,
  });
  final String message;
  final String titre;
  final VoidCallback? onReessayer;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: EspacementsApplication.page,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: CarteSection(
            titre: titre,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.error_outline,
                    size: 36,
                    color: couleurs.error,
                  ),
                ),
                const SizedBox(height: EspacementsApplication.moyen),
                Text(
                  message,
                  style: TextStyle(color: couleurs.onSurfaceVariant),
                ),
                if (onReessayer != null) ...[
                  const SizedBox(height: EspacementsApplication.grand),
                  BoutonActionPrincipale(
                    libelle: 'Réessayer',
                    icone: Icons.refresh,
                    onPressed: onReessayer,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
