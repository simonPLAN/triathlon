import 'package:flutter/material.dart';

import '../../../domain/entities/inscription.dart';

class CarteInscription extends StatelessWidget {
  const CarteInscription({
    super.key,
    required this.inscription,
    required this.actionsActives,
    required this.onModifierDossard,
    required this.onDesinscrire,
  });

  final Inscription inscription;
  final bool actionsActives;
  final VoidCallback onModifierDossard;
  final VoidCallback onDesinscrire;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            _Dossard(numero: inscription.numeroDossard),
            const SizedBox(width: 16),
            Expanded(child: _InformationsAthlete(inscription: inscription)),
            PopupMenuButton<_ActionInscription>(
              tooltip: 'Actions',
              enabled: actionsActives,
              onSelected: (action) {
                switch (action) {
                  case _ActionInscription.modifierDossard:
                    onModifierDossard();

                  case _ActionInscription.desinscrire:
                    onDesinscrire();
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(
                    value: _ActionInscription.modifierDossard,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.confirmation_number_outlined),
                      title: Text('Modifier le dossard'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _ActionInscription.desinscrire,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.person_remove_outlined),
                      title: Text('Désinscrire'),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum _ActionInscription { modifierDossard, desinscrire }

class _Dossard extends StatelessWidget {
  const _Dossard({required this.numero});

  final int? numero;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;

    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: numero == null
            ? couleurs.surfaceContainerHighest
            : couleurs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: numero == null
          ? Icon(
              Icons.confirmation_number_outlined,
              color: couleurs.onSurfaceVariant,
            )
          : Text(
              '$numero',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: couleurs.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

class _InformationsAthlete extends StatelessWidget {
  const _InformationsAthlete({required this.inscription});

  final Inscription inscription;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          inscription.athlete.nomComplet,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          inscription.numeroDossard == null
              ? 'Aucun dossard attribué'
              : 'Dossard n°${inscription.numeroDossard}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 2),
        Text(
          'Inscrit le ${_formaterDate(inscription.dateInscription)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _formaterDate(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');

    return '$jour/$mois/${date.year}';
  }
}
