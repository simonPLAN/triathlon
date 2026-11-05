import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';

Future<bool> confirmerInscriptionAthlete(
  BuildContext context,
  Competition competition, {
  required bool inscrire,
}) async {
  final resultat = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        inscrire ? 'Confirmer l’inscription' : 'Confirmer la désinscription',
      ),
      content: Text(
        'Souhaites-tu ${inscrire ? 't’inscrire à' : 'te désinscrire de'} '
        'la compétition « ${competition.nom} » ?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: inscrire
              ? null
              : FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
          icon: Icon(
            inscrire ? Icons.how_to_reg : Icons.person_remove_outlined,
          ),
          label: Text(inscrire ? 'S’inscrire' : 'Se désinscrire'),
        ),
      ],
    ),
  );
  return resultat ?? false;
}
