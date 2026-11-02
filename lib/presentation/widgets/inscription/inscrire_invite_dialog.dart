import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../controllers/inscription_controller.dart';

class InscrireInviteDialog extends StatefulWidget {
  const InscrireInviteDialog({
    super.key,
    required this.competition,
    required this.controller,
  });

  final Competition competition;
  final InscriptionController controller;

  @override
  State<InscrireInviteDialog> createState() => _InscrireInviteDialogState();
}

class _InscrireInviteDialogState extends State<InscrireInviteDialog> {
  final _form = GlobalKey<FormState>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _dossard = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _dossard.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (_enCours || !_form.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    final succes = await widget.controller.inscrireInvite(
      competition: widget.competition,
      prenom: _prenom.text,
      nom: _nom.text,
      numeroDossard: int.tryParse(_dossard.text.trim()),
    );
    if (!mounted) return;
    if (succes) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _enCours = false;
        _erreur = widget.controller.erreur ?? 'Inscription impossible.';
      });
    }
  }

  String? _validerNom(String? value) =>
      value == null || value.trim().isEmpty ? 'Champ obligatoire' : null;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_enCours,
      child: AlertDialog(
        title: const Text('Inscrire un athlète invité'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Aucun compte, adresse e-mail ou mot de passe nécessaire.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _prenom,
                    enabled: !_enCours,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                    validator: _validerNom,
                  ),
                  TextFormField(
                    controller: _nom,
                    enabled: !_enCours,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: _validerNom,
                  ),
                  TextFormField(
                    controller: _dossard,
                    enabled: !_enCours,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dossard (facultatif)',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final numero = int.tryParse(value.trim());
                      return numero == null ||
                              numero <= 0 ||
                              numero > 2147483647
                          ? 'Saisis un numéro de dossard valide.'
                          : null;
                    },
                  ),
                  if (_erreur != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _erreur!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _enCours ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: _enCours ? null : _enregistrer,
            child: Text(_enCours ? 'Inscription…' : 'Inscrire l’invité'),
          ),
        ],
      ),
    );
  }
}
