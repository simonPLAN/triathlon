import 'package:flutter/material.dart';

import '../../../domain/entities/fichier_affiche_epreuve.dart';

class SelectionImageCompetition extends StatelessWidget {
  const SelectionImageCompetition({
    super.key,
    required this.imageSelectionnee,
    required this.imageExistante,
    required this.suppressionDemandee,
    required this.actif,
    required this.onChoisir,
    required this.onRetirer,
  });

  final FichierAfficheEpreuve? imageSelectionnee;
  final Uri? imageExistante;
  final bool suppressionDemandee;
  final bool actif;
  final Future<void> Function() onChoisir;
  final VoidCallback onRetirer;

  @override
  Widget build(BuildContext context) {
    final possedeImage =
        imageSelectionnee != null ||
        (imageExistante != null && !suppressionDemandee);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Image de la compétition',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text('Facultative • JPEG, PNG ou WebP • 5 Mo maximum'),
            if (possedeImage) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 7,
                  child: imageSelectionnee != null
                      ? Image.memory(
                          imageSelectionnee!.contenu,
                          fit: BoxFit.cover,
                          semanticLabel: 'Aperçu de la compétition',
                        )
                      : Image.network(
                          imageExistante.toString(),
                          fit: BoxFit.cover,
                          semanticLabel: 'Image actuelle de la compétition',
                          errorBuilder: (_, _, _) => const _ImageIndisponible(),
                        ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: actif ? onChoisir : null,
                  icon: Icon(
                    possedeImage ? Icons.swap_horiz : Icons.add_photo_alternate,
                  ),
                  label: Text(
                    possedeImage ? 'Remplacer l’image' : 'Choisir une image',
                  ),
                ),
                if (possedeImage)
                  TextButton.icon(
                    onPressed: actif ? onRetirer : null,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Retirer'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageIndisponible extends StatelessWidget {
  const _ImageIndisponible();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: const Center(child: Icon(Icons.broken_image_outlined, size: 44)),
  );
}
