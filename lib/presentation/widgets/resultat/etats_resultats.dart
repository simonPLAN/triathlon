import 'package:flutter/material.dart';

import '../commun/etat_vide.dart';
import '../commun/message_erreur.dart';

class ChargementResultats extends StatelessWidget {
  const ChargementResultats({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Chargement des résultats...'),
      ],
    ),
  );
}

class ErreurResultats extends StatelessWidget {
  const ErreurResultats({
    super.key,
    required this.message,
    required this.onReessayer,
  });
  final String message;
  final Future<void> Function() onReessayer;

  @override
  Widget build(BuildContext context) => MessageErreur(
    titre: 'Impossible de charger les résultats',
    message: message,
    onReessayer: onReessayer,
  );
}

class AucunAthleteInscrit extends StatelessWidget {
  const AucunAthleteInscrit({super.key});

  @override
  Widget build(BuildContext context) => const EtatVide(
    titre: 'Aucun athlète inscrit',
    description: 'Ajoute les participants à la compétition avant de saisir les arrivées.',
    icone: Icons.groups_outlined,
  );
}
