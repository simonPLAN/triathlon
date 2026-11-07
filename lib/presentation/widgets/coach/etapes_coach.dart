import 'package:flutter/material.dart';

class EtapesCoach extends StatelessWidget {
  const EtapesCoach({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _EtapeCoach(
              numero: 1,
              titre: 'Créer une compétition',
              description: 'Définir le nom, la date et le lieu.',
            ),
            Divider(),
            _EtapeCoach(
              numero: 2,
              titre: 'Configurer les épreuves',
              description: 'Choisir les disciplines et les manches.',
            ),
            Divider(),
            _EtapeCoach(
              numero: 3,
              titre: 'Inscrire les athlètes',
              description: 'Associer les participants à la compétition.',
            ),
            Divider(),
            _EtapeCoach(
              numero: 4,
              titre: 'Lancer la compétition',
              description: 'Saisir et publier les résultats.',
            ),
          ],
        ),
      ),
    );
  }
}

class _EtapeCoach extends StatelessWidget {
  const _EtapeCoach({
    required this.numero,
    required this.titre,
    required this.description,
  });

  final int numero;
  final String titre;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text('$numero')),
      title: Text(titre),
      subtitle: Text(description),
    );
  }
}
