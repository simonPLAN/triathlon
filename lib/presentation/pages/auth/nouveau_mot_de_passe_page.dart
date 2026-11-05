import 'package:flutter/material.dart';

import '../../controllers/recuperation_compte_controller.dart';
import '../../widgets/commun/bouton_action_principale.dart';
import '../../widgets/commun/carte_section.dart';

class NouveauMotDePassePage extends StatefulWidget {
  const NouveauMotDePassePage({super.key, required this.controller});
  final RecuperationCompteController controller;

  @override
  State<NouveauMotDePassePage> createState() => _NouveauMotDePassePageState();
}

class _NouveauMotDePassePageState extends State<NouveauMotDePassePage> {
  final _form = GlobalKey<FormState>();
  final _motDePasse = TextEditingController();
  final _confirmation = TextEditingController();
  bool _masque = true;

  @override
  void dispose() {
    _motDePasse.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_form.currentState!.validate()) return;
    await widget.controller.enregistrer(_motDePasse.text, _confirmation.text);
    if (!mounted) return;
    if (widget.controller.etape == EtapeRecuperation.succes) {
      _motDePasse.clear();
      _confirmation.clear();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final succes = c.etape == EtapeRecuperation.succes;
      final formulaire = c.etape == EtapeRecuperation.nouveauMotDePasse;
      return PopScope(
        canPop: !c.active,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Nouveau mot de passe'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: CarteSection(
                    titre: succes
                        ? 'Mot de passe modifié'
                        : 'Réinitialiser le mot de passe',
                    icone: succes
                        ? Icons.check_circle_outline
                        : Icons.lock_reset,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (c.etape == EtapeRecuperation.verification) ...[
                          const Center(child: CircularProgressIndicator()),
                          const SizedBox(height: 16),
                          const Text(
                            'Vérification du lien…',
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (succes)
                          const Text(
                            'Ton nouveau mot de passe est enregistré. '
                            'Reconnecte-toi pour accéder à ton compte.',
                          ),
                        if (formulaire)
                          Form(
                            key: _form,
                            child: AutofillGroup(
                              child: Column(
                                children: [
                                  TextFormField(
                                    key: const ValueKey('nouveau-mot-de-passe'),
                                    controller: _motDePasse,
                                    enabled: !c.operationEnCours,
                                    obscureText: _masque,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Nouveau mot de passe',
                                      helperText: '8 caractères minimum',
                                      suffixIcon: IconButton(
                                        tooltip: _masque
                                            ? 'Afficher le mot de passe'
                                            : 'Masquer le mot de passe',
                                        onPressed: () =>
                                            setState(() => _masque = !_masque),
                                        icon: Icon(
                                          _masque
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                      ),
                                    ),
                                    validator: (value) =>
                                        (value?.length ?? 0) >= 8
                                        ? null
                                        : 'Utilise au moins 8 caractères.',
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    key: const ValueKey(
                                      'confirmation-mot-de-passe',
                                    ),
                                    controller: _confirmation,
                                    enabled: !c.operationEnCours,
                                    obscureText: _masque,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Confirmer le mot de passe',
                                    ),
                                    validator: (value) =>
                                        value == _motDePasse.text ? null : 'Les deux mots de passe doivent être identiques.',
                                    onFieldSubmitted: (_) => _enregistrer(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (c.erreur != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            c.erreur!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (formulaire)
                          BoutonActionPrincipale(
                            libelle: 'Enregistrer le nouveau mot de passe',
                            icone: Icons.save_outlined,
                            enCours: c.operationEnCours,
                            onPressed: _enregistrer,
                          ),
                        if (c.etape != EtapeRecuperation.verification)
                          TextButton(
                            onPressed: c.operationEnCours ? null : c.fermer,
                            child: Text(
                              succes
                                  ? 'Retour à la connexion'
                                  : formulaire
                                  ? 'Annuler la récupération'
                                  : 'Fermer et demander un nouveau lien',
                            ),
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
    },
  );
}
