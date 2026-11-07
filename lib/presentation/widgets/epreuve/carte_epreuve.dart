import 'package:flutter/material.dart';

import '../../../domain/entities/epreuve.dart';
import '../../../domain/entities/type_discipline.dart';

class CarteEpreuve extends StatelessWidget {
  const CarteEpreuve({super.key, required this.epreuve, required this.onTap});

  final Epreuve epreuve;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final apparence = _apparencePour(epreuve.discipline);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EnteteEpreuve(epreuve: epreuve, apparence: apparence),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InformationEpreuve(
                    icone: Icons.straighten,
                    texte: _formaterDistance(epreuve.distanceMetres),
                  ),
                  _InformationEpreuve(
                    icone: Icons.repeat,
                    texte: _formaterNombreManches(epreuve.nombreManches),
                  ),
                  _InformationEpreuve(
                    icone: Icons.timer_outlined,
                    texte: _formaterDuree(epreuve.dureeLimiteSecondes),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Voir les manches'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formaterDistance(int distanceMetres) {
    if (distanceMetres >= 1000 && distanceMetres % 1000 == 0) {
      final distanceKilometres = distanceMetres ~/ 1000;

      return '$distanceKilometres km';
    }

    if (distanceMetres >= 1000) {
      final distanceKilometres = distanceMetres / 1000;

      return '${distanceKilometres.toStringAsFixed(1)} km';
    }

    return '$distanceMetres m';
  }

  String _formaterNombreManches(int nombreManches) {
    if (nombreManches == 1) {
      return '1 manche';
    }

    return '$nombreManches manches';
  }

  String _formaterDuree(int dureeSecondes) {
    if (dureeSecondes < 60) {
      return '$dureeSecondes s';
    }

    final minutes = dureeSecondes ~/ 60;
    final secondes = dureeSecondes % 60;

    if (secondes == 0) {
      return '$minutes min';
    }

    return '$minutes min $secondes s';
  }

  _ApparenceDiscipline _apparencePour(TypeDiscipline discipline) {
    switch (discipline) {
      case TypeDiscipline.natation:
        return const _ApparenceDiscipline(
          libelle: 'Natation',
          icone: Icons.pool,
          couleur: Colors.blue,
        );

      case TypeDiscipline.velo:
        return const _ApparenceDiscipline(
          libelle: 'Vélo',
          icone: Icons.directions_bike,
          couleur: Colors.green,
        );

      case TypeDiscipline.courseAPied:
        return const _ApparenceDiscipline(
          libelle: 'Course à pied',
          icone: Icons.directions_run,
          couleur: Colors.orange,
        );
    }
  }
}

class _EnteteEpreuve extends StatelessWidget {
  const _EnteteEpreuve({required this.epreuve, required this.apparence});

  final Epreuve epreuve;
  final _ApparenceDiscipline apparence;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: apparence.couleur.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(apparence.icone, color: apparence.couleur, size: 30),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Épreuve ${epreuve.ordre}',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 4),
              Text(
                epreuve.nom,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                apparence.libelle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InformationEpreuve extends StatelessWidget {
  const _InformationEpreuve({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: couleurs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: couleurs.primary),
          const SizedBox(width: 6),
          Text(texte, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ApparenceDiscipline {
  const _ApparenceDiscipline({
    required this.libelle,
    required this.icone,
    required this.couleur,
  });

  final String libelle;
  final IconData icone;
  final Color couleur;
}
