import 'package:flutter/material.dart';

import '../../../domain/entities/statut_competition.dart';
import '../commun/badge_statut.dart';

class BadgeStatutCompetition extends StatelessWidget {
  const BadgeStatutCompetition({super.key, required this.statut});
  final StatutCompetition statut;

  @override
  Widget build(BuildContext context) {
    final (libelle, icone, ton) = switch (statut) {
      StatutCompetition.brouillon => (
        'Brouillon',
        Icons.edit_note,
        TonBadgeStatut.neutre,
      ),
      StatutCompetition.ouverte => (
        'Ouverte',
        Icons.how_to_reg,
        TonBadgeStatut.information,
      ),
      StatutCompetition.enCours => (
        'En cours',
        Icons.play_circle_outline,
        TonBadgeStatut.actif,
      ),
      StatutCompetition.terminee => (
        'Terminée',
        Icons.check_circle_outline,
        TonBadgeStatut.succes,
      ),
      StatutCompetition.annulee => (
        'Annulée',
        Icons.cancel_outlined,
        TonBadgeStatut.erreur,
      ),
    };
    return BadgeStatut(libelle: libelle, icone: icone, ton: ton);
  }
}
