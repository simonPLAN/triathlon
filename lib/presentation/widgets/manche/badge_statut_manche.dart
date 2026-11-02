import 'package:flutter/material.dart';

import '../../../domain/entities/statut_manche.dart';
import '../commun/badge_statut.dart';

class BadgeStatutManche extends StatelessWidget {
  const BadgeStatutManche({super.key, required this.statut});
  final StatutManche statut;

  @override
  Widget build(BuildContext context) {
    final (libelle, icone, ton) = switch (statut) {
      StatutManche.aVenir => ('À venir', Icons.schedule, TonBadgeStatut.neutre),
      StatutManche.enCours => (
        'En cours',
        Icons.play_circle_outline,
        TonBadgeStatut.actif,
      ),
      StatutManche.terminee => (
        'Terminée',
        Icons.check_circle_outline,
        TonBadgeStatut.succes,
      ),
      StatutManche.annulee => (
        'Annulée',
        Icons.cancel_outlined,
        TonBadgeStatut.erreur,
      ),
    };
    return BadgeStatut(libelle: libelle, icone: icone, ton: ton);
  }
}
