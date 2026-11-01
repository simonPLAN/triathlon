import 'package:flutter/material.dart';

class CarteActionCoach extends StatelessWidget {
  const CarteActionCoach({
    super.key,
    required this.titre,
    required this.description,
    required this.icone,
    required this.couleur,
    required this.onTap,
  });

  final String titre;
  final String description;
  final IconData icone;
  final Color couleur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 42, color: couleur),
              const SizedBox(height: 12),
              Text(
                titre,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
