import 'package:flutter/material.dart';

import '../../application/use_cases/inscrire_athlete.dart';

class InscriptionAthleteDialog extends StatefulWidget {
  const InscriptionAthleteDialog({super.key, required this.inscrireAthlete});

  final InscrireAthlete inscrireAthlete;

  @override
  State<InscriptionAthleteDialog> createState() {
    return _InscriptionAthleteDialogState();
  }
}

class _InscriptionAthleteDialogState extends State<InscriptionAthleteDialog> {
  final _formKey = GlobalKey<FormState>();

  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _motDePasseController = TextEditingController();

  bool _chargement = false;
  bool _masquerMotDePasse = true;
  String? _erreur;

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      await widget.inscrireAthlete.executer(
        prenom: _prenomController.text,
        nom: _nomController.text,
        email: _emailController.text,
        motDePasse: _motDePasseController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on ArgumentError catch (exception) {
      setState(() {
        _erreur = exception.message?.toString();
      });
    } catch (exception) {
      setState(() {
        _erreur = exception.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _chargement = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer un compte athlète'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _prenomController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                  validator: (valeur) {
                    if (valeur == null || valeur.trim().isEmpty) {
                      return 'Saisis un prénom.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nomController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (valeur) {
                    if (valeur == null || valeur.trim().isEmpty) {
                      return 'Saisis un nom.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Adresse e-mail',
                  ),
                  validator: (valeur) {
                    final email = valeur?.trim() ?? '';

                    if (email.isEmpty || !email.contains('@')) {
                      return 'Saisis une adresse e-mail valide.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _motDePasseController,
                  obscureText: _masquerMotDePasse,
                  onFieldSubmitted: (_) => _inscrire(),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    helperText: '8 caractères minimum',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _masquerMotDePasse = !_masquerMotDePasse;
                        });
                      },
                      icon: Icon(
                        _masquerMotDePasse
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (valeur) {
                    if (valeur == null || valeur.length < 8) {
                      return 'Utilise au moins 8 caractères.';
                    }

                    return null;
                  },
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 16),
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
          onPressed: _chargement
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _chargement ? null : _inscrire,
          child: _chargement
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Créer le compte'),
        ),
      ],
    );
  }
}
