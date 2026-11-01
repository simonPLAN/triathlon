import 'package:flutter/material.dart';

import '../../../domain/entities/statut_competition.dart';

class BadgeStatutCompetition extends StatelessWidget {
  const BadgeStatutCompetition({super.key, required this.statut});

  final StatutCompetition statut;

  @override
  Widget build(BuildContext context) {
    final configuration = _configurationPour(statut);

    return Semantics(
      label: 'Statut : ${configuration.libelle}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: configuration.couleurFond,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: configuration.couleurTexte.withValues(alpha: 0.35),
          ),
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ConfigurationBadge _configurationPour(StatutCompetition statut) {
    switch (statut) {
      case StatutCompetition.brouillon:
        return const _ConfigurationBadge(
          libelle: 'Brouillon',
          icone: Icons.edit_note,
          couleurFond: Color(0xFFECEFF1),
          couleurTexte: Color(0xFF455A64),
        );

      case StatutCompetition.ouverte:
        return const _ConfigurationBadge(
          libelle: 'Ouverte',
          icone: Icons.how_to_reg,
          couleurFond: Color(0xFFE3F2FD),
          couleurTexte: Color(0xFF1565C0),
        );

      case StatutCompetition.enCours:
        return const _ConfigurationBadge(
          libelle: 'En cours',
          icone: Icons.play_circle_outline,
          couleurFond: Color(0xFFFFF3E0),
          couleurTexte: Color(0xFFEF6C00),
        );

      case StatutCompetition.terminee:
        return const _ConfigurationBadge(
          libelle: 'Terminée',
          icone: Icons.check_circle_outline,
          couleurFond: Color(0xFFE8F5E9),
          couleurTexte: Color(0xFF2E7D32),
        );

      case StatutCompetition.annulee:
        return const _ConfigurationBadge(
          libelle: 'Annulée',
          icone: Icons.cancel_outlined,
          couleurFond: Color(0xFFFFEBEE),
          couleurTexte: Color(0xFFC62828),
        );
    }
  }
}

class _ConfigurationBadge {
  const _ConfigurationBadge({
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
