import 'package:flutter/material.dart';

class BoutonActionPrincipale extends StatelessWidget {
  const BoutonActionPrincipale({
    super.key,
    required this.libelle,
    required this.onPressed,
    this.icone = Icons.arrow_forward_rounded,
    this.enCours = false,
  });
  final String libelle;
  final VoidCallback? onPressed;
  final IconData icone;
  final bool enCours;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: enCours ? null : onPressed,
    icon: enCours
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        : Icon(icone),
    label: Text(libelle, textAlign: TextAlign.center),
  );
}
