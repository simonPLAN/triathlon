import 'package:flutter/material.dart';

import '../../controllers/confirmation_email_controller.dart';
import '../../widgets/commun/carte_section.dart';

class ConfirmationEmailPage extends StatefulWidget {
  const ConfirmationEmailPage({
    super.key,
    required this.controller,
    this.emailInitial = '',
  });
  final ConfirmationEmailController controller;
  final String emailInitial;
  @override
  State<ConfirmationEmailPage> createState() => _ConfirmationEmailPageState();
}

class _ConfirmationEmailPageState extends State<ConfirmationEmailPage> {
  late final TextEditingController _email = TextEditingController(
    text: widget.emailInitial,
  );
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _retour() {
    widget.controller.fermerLien();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      return PopScope(
        canPop: !c.operationEnCours,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) c.fermerLien();
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Confirmation de l’e-mail')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    CarteSection(
                      titre: c.confirme
                          ? 'Adresse confirmée'
                          : 'Confirme ton adresse e-mail',
                      icone: c.confirme
                          ? Icons.mark_email_read_outlined
                          : Icons.mark_email_unread_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (c.operationEnCours)
                            const LinearProgressIndicator(),
                          Text(
                            c.confirme
                                ? 'Tu peux maintenant revenir à la connexion.'
                                : 'Ouvre le lien reçu par e-mail sur le téléphone qui a demandé la confirmation. Après confirmation, connecte-toi avec ton e-mail et ton mot de passe.',
                          ),
                          const SizedBox(height: 20),
                          if (!c.confirme) ...[
                            TextField(
                              controller: _email,
                              enabled: !c.operationEnCours,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'Adresse e-mail',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed:
                                  c.operationEnCours ||
                                      c.secondesAvantRenvoi > 0
                                  ? null
                                  : () => c.renvoyer(_email.text),
                              icon: const Icon(Icons.send_outlined),
                              label: Text(
                                c.secondesAvantRenvoi > 0
                                    ? 'Renvoyer dans ${c.secondesAvantRenvoi} s'
                                    : 'Renvoyer l’e-mail',
                              ),
                            ),
                          ],
                          if (c.message != null) ...[
                            const SizedBox(height: 12),
                            Semantics(
                              liveRegion: true,
                              child: Text(c.message!),
                            ),
                          ],
                          if (c.erreur != null) ...[
                            const SizedBox(height: 12),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                c.erreur!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: c.operationEnCours ? null : _retour,
                            child: const Text('Revenir à la connexion'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
