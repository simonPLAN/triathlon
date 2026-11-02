import 'package:flutter/material.dart';

import '../commun/etat_vide.dart';

class ListeManchesVide extends StatelessWidget {
  const ListeManchesVide({
    super.key,
    required this.generationAutorisee,
    required this.nombreManches,
    required this.onGenerer,
  });
  final bool generationAutorisee;
  final int nombreManches;
  final VoidCallback onGenerer;

  @override
  Widget build(BuildContext context) => EtatVide(
    titre: 'Aucune manche',
    description: generationAutorisee
        ? '$nombreManches manche(s) doivent être générées pour cette épreuve.'
        : 'Les manches ne sont pas encore disponibles.',
    icone: Icons.timer_outlined,
    libelleAction: generationAutorisee ? 'Générer les manches' : null,
    onAction: generationAutorisee ? onGenerer : null,
  );
}
