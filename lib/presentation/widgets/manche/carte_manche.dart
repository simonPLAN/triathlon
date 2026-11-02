import 'package:flutter/material.dart';

import '../../../domain/entities/manche.dart';
import 'badge_statut_manche.dart';

class CarteManche extends StatelessWidget {
  const CarteManche({super.key, required this.manche, required this.onTap});

  final Manche manche;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(radius: 24, child: Text('${manche.numero}')),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manche ${manche.numero}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    BadgeStatutManche(statut: manche.statut),
                    const SizedBox(height: 8),
                    Text(
                      manche.resultatsPublies
                          ? 'Résultats publiés'
                          : 'Résultats non publiés',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
