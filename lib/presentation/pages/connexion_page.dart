import 'package:flutter/material.dart';

import '../controllers/recuperation_compte_controller.dart';
import 'auth/mot_de_passe_oublie_page.dart';

import '../../application/use_cases/connecter_utilisateur.dart';
import '../../application/use_cases/inscrire_athlete.dart';
import '../widgets/inscription_athlete_dialog.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({
    super.key,
    required this.connecterUtilisateur,
    required this.inscrireAthlete,
    required this.recuperationCompte,
  });

  final ConnecterUtilisateur connecterUtilisateur;
  final InscrireAthlete inscrireAthlete;
  final RecuperationCompteController recuperationCompte;

  @override
  State<ConnexionPage> createState() {
    return _ConnexionPageState();
  }
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _motDePasseController = TextEditingController();

  bool _chargement = false;
  bool _masquerMotDePasse = true;
  String? _erreur;

  @override
  void dispose() {
    _emailController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    if (_chargement || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      await widget.connecterUtilisateur.executer(
        email: _emailController.text,
        motDePasse: _motDePasseController.text,
      );
    } on ArgumentError catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        _erreur = exception.message?.toString();
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

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

  Future<void> _ouvrirInscription() async {
    final compteCree = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return InscriptionAthleteDialog(
          inscrireAthlete: widget.inscrireAthlete,
        );
      },
    );

    if (compteCree != true || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compte créé. Confirme ton e-mail, puis connecte-toi.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Connexion',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Connecte-toi pour accéder aux compétitions.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Adresse e-mail',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (valeur) {
                            final email = valeur?.trim() ?? '';

                            if (email.isEmpty || !email.contains('@')) {
                              return 'Saisis une adresse e-mail valide.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _motDePasseController,
                          obscureText: _masquerMotDePasse,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!_chargement) {
                              _connecter();
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
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
                            if (valeur == null || valeur.isEmpty) {
                              return 'Saisis ton mot de passe.';
                            }

                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _chargement
                                ? null
                                : () {
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute(
                                        builder: (_) => MotDePasseOubliePage(
                                          controller: widget.recuperationCompte,
                                          emailInitial: _emailController.text
                                              .trim(),
                                        ),
                                      ),
                                    );
                                  },
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ),
                        if (_erreur != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _erreur!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _chargement ? null : _connecter,
                          child: _chargement
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Se connecter'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _chargement ? null : _ouvrirInscription,
                          child: const Text('Créer un compte athlète'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
