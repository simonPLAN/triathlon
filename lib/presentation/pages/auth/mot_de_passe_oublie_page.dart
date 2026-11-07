import 'package:flutter/material.dart';

import '../../controllers/recuperation_compte_controller.dart';
import '../../widgets/commun/bouton_action_principale.dart';
import '../../widgets/commun/carte_section.dart';

class MotDePasseOubliePage extends StatefulWidget {
  const MotDePasseOubliePage({
    super.key,
    required this.controller,
    this.emailInitial = '',
  });
  final RecuperationCompteController controller;
  final String emailInitial;

  @override
  State<MotDePasseOubliePage> createState() => _MotDePasseOubliePageState();
}

class _MotDePasseOubliePageState extends State<MotDePasseOubliePage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email;
  bool _enCours = false;
  bool _envoye = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.emailInitial);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_enCours || !_form.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await widget.controller.envoyerLien(_email.text);
      if (mounted) setState(() => _envoye = true);
    } catch (e) {
      if (mounted) {
        setState(
          () => _erreur = e
              .toString()
              .replaceFirst('Bad state: ', '')
              .replaceFirst('Invalid argument(s): ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mot de passe oublié')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CarteSection(
              titre: 'Retrouver ton compte',
              sousTitre: 'Reçois un lien pour choisir un nouveau mot de passe.',
              icone: Icons.lock_reset,
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _email,
                      enabled: !_enCours,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Adresse e-mail',
                      ),
                      validator: (value) =>
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(value?.trim() ?? '')
                          ? null
                          : 'Saisis une adresse e-mail valide.',
                      onFieldSubmitted: (_) => _envoyer(),
                    ),
                    if (_envoye) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Si un compte existe avec cette adresse, un e-mail de récupération a été envoyé. '
                        'Vérifie aussi les courriers indésirables.',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ouvre le lien sur cet appareil, dans cette application. '
                        'Utilise le lien le plus récent.',
                      ),
                    ],
                    if (_erreur != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _erreur!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    BoutonActionPrincipale(
                      libelle: _envoye ? 'Renvoyer un lien' : 'Envoyer le lien',
                      icone: Icons.mail_outline,
                      enCours: _enCours,
                      onPressed: _envoyer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
