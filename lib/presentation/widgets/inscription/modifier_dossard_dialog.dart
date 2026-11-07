import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/inscription.dart';

class ModifierDossardDialog extends StatefulWidget {
  const ModifierDossardDialog({super.key, required this.inscription});

  final Inscription inscription;

  @override
  State<ModifierDossardDialog> createState() {
    return _ModifierDossardDialogState();
  }
}

class ResultatModificationDossard {
  const ResultatModificationDossard({
    required this.confirme,
    this.numeroDossard,
  });

  const ResultatModificationDossard.annule()
    : confirme = false,
      numeroDossard = null;

  final bool confirme;
  final int? numeroDossard;
}

class _ModifierDossardDialogState extends State<ModifierDossardDialog> {
  final _cleFormulaire = GlobalKey<FormState>();

  late final TextEditingController _numeroDossardController;

  @override
  void initState() {
    super.initState();

    final numeroDossard = widget.inscription.numeroDossard;

    _numeroDossardController = TextEditingController(
      text: numeroDossard?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _numeroDossardController.dispose();
    super.dispose();
  }

  void _valider() {
    final formulaireValide = _cleFormulaire.currentState?.validate() ?? false;

    if (!formulaireValide) {
      return;
    }

    final texte = _numeroDossardController.text.trim();

    final numeroDossard = texte.isEmpty ? null : int.parse(texte);

    Navigator.of(context).pop(
      ResultatModificationDossard(confirme: true, numeroDossard: numeroDossard),
    );
  }

  void _retirerDossard() {
    Navigator.of(context).pop(
      const ResultatModificationDossard(confirme: true, numeroDossard: null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final possedeDossard = widget.inscription.numeroDossard != null;

    return AlertDialog(
      title: Text(
        possedeDossard ? 'Modifier le dossard' : 'Attribuer un dossard',
      ),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _cleFormulaire,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.inscription.athlete.nomComplet,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numeroDossardController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onFieldSubmitted: (_) {
                  _valider();
                },
                decoration: const InputDecoration(
                  labelText: 'Numéro de dossard',
                  hintText: 'Exemple : 12',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                  helperText:
                      'Laisse le champ vide pour ne pas attribuer de dossard.',
                  border: OutlineInputBorder(),
                ),
                validator: (valeur) {
                  final texte = valeur?.trim() ?? '';

                  if (texte.isEmpty) {
                    return null;
                  }

                  final numero = int.tryParse(texte);

                  if (numero == null || numero <= 0) {
                    return 'Le numéro doit être supérieur à zéro.';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (possedeDossard)
          TextButton.icon(
            onPressed: _retirerDossard,
            icon: const Icon(Icons.remove_circle_outline),
            label: const Text('Retirer le dossard'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context)
                .pop(const ResultatModificationDossard.annule());
          },
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _valider, child: const Text('Enregistrer')),
      ],
    );
  }
}
