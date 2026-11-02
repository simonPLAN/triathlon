import 'package:flutter/material.dart';

import '../../../domain/entities/manche.dart';

class InformationsManche extends StatelessWidget {
  const InformationsManche({super.key, required this.manche});

  final Manche manche;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _Information(
            icone: Icons.play_arrow,
            titre: 'Départ',
            valeur: _formaterDate(manche.heureDepart),
          ),
          const Divider(height: 1),
          _Information(
            icone: Icons.emoji_events_outlined,
            titre: 'Première arrivée',
            valeur: _formaterDate(manche.heurePremiereArrivee),
          ),
          const Divider(height: 1),
          _Information(
            icone: Icons.timer_off_outlined,
            titre: 'Fin du délai',
            valeur: _formaterDate(manche.heureFinDelai),
          ),
          const Divider(height: 1),
          _Information(
            icone: Icons.publish_outlined,
            titre: 'Résultats',
            valeur: manche.resultatsPublies ? 'Publiés' : 'Non publiés',
          ),
        ],
      ),
    );
  }

  String _formaterDate(DateTime? date) {
    if (date == null) {
      return 'Non renseigné';
    }

    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final seconde = date.second.toString().padLeft(2, '0');

    return '$heure:$minute:$seconde';
  }
}

class _Information extends StatelessWidget {
  const _Information({
    required this.icone,
    required this.titre,
    required this.valeur,
  });

  final IconData icone;
  final String titre;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icone, color: Theme.of(context).colorScheme.primary),
      title: Text(titre),
      subtitle: Text(valeur),
    );
  }
}
