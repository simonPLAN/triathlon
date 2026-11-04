import 'package:flutter/material.dart';

enum _ActionCompte { coefficient, supprimer, deconnecter }

class MenuCompteApplication extends StatelessWidget {
  const MenuCompteApplication({
    super.key,
    required this.onDeconnecter,
    this.onSupprimerCompte,
    this.onCoefficient,
    this.operationEnCours = false,
  });
  final VoidCallback onDeconnecter;
  final VoidCallback? onSupprimerCompte, onCoefficient;
  final bool operationEnCours;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_ActionCompte>(
    tooltip: 'Mon compte',
    enabled: !operationEnCours,
    icon: operationEnCours
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.account_circle_outlined),
    onSelected: (action) {
      switch (action) {
        case _ActionCompte.coefficient:
          onCoefficient?.call();
        case _ActionCompte.supprimer:
          onSupprimerCompte?.call();
        case _ActionCompte.deconnecter:
          onDeconnecter();
      }
    },
    itemBuilder: (_) => [
      if (onCoefficient != null)
        const PopupMenuItem(
          value: _ActionCompte.coefficient,
          child: Text('Mon coefficient'),
        ),
      if (onSupprimerCompte != null)
        const PopupMenuItem(
          value: _ActionCompte.supprimer,
          child: Text('Supprimer mon compte'),
        ),
      const PopupMenuItem(
        value: _ActionCompte.deconnecter,
        child: Text('Se déconnecter'),
      ),
    ],
  );
}
