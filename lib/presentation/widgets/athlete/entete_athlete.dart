import 'package:flutter/material.dart';

import '../../../domain/entities/profil_utilisateur.dart';

class EnteteAthlete extends StatelessWidget {
  const EnteteAthlete({super.key, required this.profil});
  final ProfilUtilisateur profil;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    final initiales = [
      if (profil.prenom.isNotEmpty) profil.prenom[0],
      if (profil.nom.isNotEmpty) profil.nom[0],
    ].join().toUpperCase();
    return Container(
      width: double.infinity,
      color: couleurs.primaryContainer,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(child: Text(initiales)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour ${profil.prenom}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text('Tes compétitions et tes résultats'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
