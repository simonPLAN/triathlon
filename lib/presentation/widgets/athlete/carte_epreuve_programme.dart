import 'package:flutter/material.dart';

import '../../../domain/entities/programme_competition.dart';
import '../../../domain/entities/type_discipline.dart';
import '../commun/carte_section.dart';
import '../manche/badge_statut_manche.dart';

class CarteEpreuveProgramme extends StatelessWidget {
  const CarteEpreuveProgramme({
    super.key,
    required this.epreuve,
    this.onVoirAffiches,
  });

  final EpreuveProgramme epreuve;
  final VoidCallback? onVoirAffiches;

  @override
  Widget build(BuildContext context) {
    final discipline = switch (epreuve.discipline) {
      TypeDiscipline.natation => 'Natation',
      TypeDiscipline.velo => 'Vélo',
      TypeDiscipline.courseAPied => 'Course à pied',
    };
    return CarteSection(
      titre: '${epreuve.ordre}. ${epreuve.nom}',
      sousTitre: '$discipline • ${epreuve.distanceMetres} m',
      icone: switch (epreuve.discipline) {
        TypeDiscipline.natation => Icons.pool,
        TypeDiscipline.velo => Icons.directions_bike,
        TypeDiscipline.courseAPied => Icons.directions_run,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onVoirAffiches != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onVoirAffiches,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Voir les affiches'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (epreuve.manches.isEmpty)
            const Text('Les manches ne sont pas encore définies.'),
          for (final manche in epreuve.manches)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Manche ${manche.numero}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      BadgeStatutManche(statut: manche.statut),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(switch (manche.participe) {
                    true => 'Tu participes à cette manche.',
                    false => 'Tu n’es pas affecté à cette manche.',
                    null => 'Participation à cette manche non définie.',
                  }),
                  Text(
                    manche.ordreDepart == null
                        ? 'Ordre de départ non défini.'
                        : 'Ton ordre de départ : ${manche.ordreDepart}',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
