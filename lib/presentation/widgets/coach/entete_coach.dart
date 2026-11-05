import 'package:flutter/material.dart';

import '../../../domain/entities/profil_utilisateur.dart';
import '../../theme/couleurs_application.dart';

class EnteteCoach extends StatelessWidget {
  const EnteteCoach({super.key, required this.profil});
  final ProfilUtilisateur profil;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CouleursApplication.primaire,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CouleursApplication.secondaire, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  const Icon(
                    Icons.sports_outlined,
                    color: CouleursApplication.secondaire,
                  ),
                  Text(
                    'LE MANS TRIATHLON',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Bonjour ${profil.prenom}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Préparez vos compétitions, accompagnez les athlètes '
                'et suivez leurs résultats.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
