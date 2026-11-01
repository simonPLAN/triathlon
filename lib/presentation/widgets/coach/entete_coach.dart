import 'package:flutter/material.dart';

import '../../../domain/entities/profil_utilisateur.dart';

class EnteteCoach extends StatelessWidget {
  const EnteteCoach({super.key, required this.profil});

  final ProfilUtilisateur profil;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                _initiales,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour ${profil.prenom}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compte coach',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _initiales {
    final initialePrenom = profil.prenom.isEmpty ? '' : profil.prenom[0];

    final initialeNom = profil.nom.isEmpty ? '' : profil.nom[0];

    return '$initialePrenom$initialeNom'.toUpperCase();
  }
}
