import 'package:flutter/material.dart';

class ImageCouvertureCompetition extends StatelessWidget {
  const ImageCouvertureCompetition({
    super.key,
    required this.url,
    required this.nomCompetition,
  });

  final Uri url;
  final String nomCompetition;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Image de la compétition $nomCompetition',
    child: AspectRatio(
      aspectRatio: 16 / 7,
      child: Image.network(
        url.toString(),
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(
            child: Icon(Icons.broken_image_outlined, size: 40),
          ),
        ),
      ),
    ),
  );
}
