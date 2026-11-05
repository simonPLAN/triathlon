import 'package:flutter/material.dart';

import '../../../domain/entities/resultat_publie.dart';
import '../../../domain/services/calcul_classement_global.dart';

class ClassementGeneralAthlete extends StatelessWidget {
  const ClassementGeneralAthlete({
    super.key,
    required this.resultats,
    required this.athleteId,
    this.uniquementMoi = false,
  });

  final List<ResultatPublie> resultats;
  final String athleteId;
  final bool uniquementMoi;

  @override
  Widget build(BuildContext context) {
    final classement = const CalculClassementGlobal()
        .calculer(resultats)
        .where((ligne) => !uniquementMoi || ligne.athleteId == athleteId);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Classement général', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Total des points sur toutes les épreuves et manches publiées. '
          'Les athlètes à égalité de points partagent le même rang.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        for (final ligne in classement)
          Card(
            key: ValueKey('global-${ligne.athleteId}'),
            color: ligne.athleteId == athleteId
                ? theme.colorScheme.primaryContainer
                : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: ligne.rang == 1
                    ? theme.colorScheme.tertiaryContainer
                    : null,
                foregroundColor: ligne.rang == 1
                    ? theme.colorScheme.onTertiaryContainer
                    : null,
                child: Text('${ligne.rang}'),
              ),
              title: Text(ligne.nom),
              subtitle: Text('${ligne.nombreManches} manche(s) publiée(s)'),
              trailing: Text(
                '${ligne.points} pt',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
      ],
    );
  }
}
