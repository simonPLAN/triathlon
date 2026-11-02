import 'package:flutter/material.dart';

import '../../../domain/entities/statut_manche.dart';

class BadgeStatutManche extends StatelessWidget {
  const BadgeStatutManche({super.key, required this.statut});

  final StatutManche statut;

  @override
  Widget build(BuildContext context) {
    final configuration = _configuration();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: configuration.couleurFond,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            configuration.icone,
            size: 16,
            color: configuration.couleurTexte,
          ),
          const SizedBox(width: 6),
          Text(
            configuration.libelle,
            style: TextStyle(
              color: configuration.couleurTexte,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  _ConfigurationStatut _configuration() {
    switch (statut) {
      case StatutManche.aVenir:
        return const _ConfigurationStatut(
          libelle: 'À venir',
          icone: Icons.schedule,
          couleurFond: Color(0xFFECEFF1),
          couleurTexte: Color(0xFF455A64),
        );

      case StatutManche.enCours:
        return const _ConfigurationStatut(
          libelle: 'En cours',
          icone: Icons.play_circle_outline,
          couleurFond: Color(0xFFFFF3E0),
          couleurTexte: Color(0xFFEF6C00),
        );

      case StatutManche.terminee:
        return const _ConfigurationStatut(
          libelle: 'Terminée',
          icone: Icons.check_circle_outline,
          couleurFond: Color(0xFFE8F5E9),
          couleurTexte: Color(0xFF2E7D32),
        );

      case StatutManche.annulee:
        return const _ConfigurationStatut(
          libelle: 'Annulée',
          icone: Icons.cancel_outlined,
          couleurFond: Color(0xFFFFEBEE),
          couleurTexte: Color(0xFFC62828),
        );
    }
  }
}

class _ConfigurationStatut {
  const _ConfigurationStatut({
    required this.libelle,
    required this.icone,
    required this.couleurFond,
    required this.couleurTexte,
  });

  final String libelle;
  final IconData icone;
  final Color couleurFond;
  final Color couleurTexte;
}
