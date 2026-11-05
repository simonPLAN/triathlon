import 'package:flutter/material.dart';

import '../../../application/use_cases/auth/supprimer_mon_compte.dart';
import '../../controllers/suppression_compte_controller.dart';
import '../../widgets/commun/carte_section.dart';
import '../../widgets/commun/bouton_action_principale.dart';

class SupprimerComptePage extends StatefulWidget {
  const SupprimerComptePage({super.key, required this.supprimerMonCompte});
  final SupprimerMonCompte supprimerMonCompte;
  @override
  State<SupprimerComptePage> createState() => _SupprimerComptePageState();
}

class _SupprimerComptePageState extends State<SupprimerComptePage> {
  late final _controller = SuppressionCompteController(
    widget.supprimerMonCompte,
  );
  final _motDePasse = TextEditingController();
  bool _confirmation = false;

  @override
  void dispose() {
    _controller.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  Future<void> _supprimer() async {
    await _controller.confirmer(_motDePasse.text, _confirmation);
    if (!mounted) return;
    if (_controller.supprime) _motDePasse.clear();
    if (_controller.termine) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ton compte et tes données personnelles ont été supprimés.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => PopScope(
      canPop: !_controller.enCours && !_controller.supprime,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Supprimer mon compte'),
          automaticallyImplyLeading:
              !_controller.enCours && !_controller.supprime,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: CarteSection(
                  titre: 'Suppression définitive',
                  icone: Icons.person_remove_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Ton compte, ton profil, tes inscriptions et tes résultats seront supprimés. Cette action est irréversible.',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Si tu es coach, tes compétitions seront archivées sans ton identité. Les épreuves, manches, invités et données des autres participants seront conservés. Les classements ne contiendront plus tes résultats.',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Les sauvegardes techniques peuvent subsister jusqu’à leur rotation. Les délais de conservation sont précisés sur la page publique de suppression.',
                      ),
                      const SizedBox(height: 24),
                      if (!_controller.supprime) ...[
                        TextField(
                          key: const ValueKey('mot-de-passe-suppression'),
                          controller: _motDePasse,
                          enabled: !_controller.enCours,
                          obscureText: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: const [AutofillHints.password],
                          decoration: const InputDecoration(
                            labelText: 'Mot de passe actuel',
                          ),
                        ),
                        CheckboxListTile(
                          value: _confirmation,
                          onChanged: _controller.enCours
                              ? null
                              : (value) => setState(
                                  () => _confirmation = value ?? false,
                                ),
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Je comprends et je confirme la suppression définitive de mon compte.',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                      if (_controller.erreur != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _controller.erreur!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      BoutonActionPrincipale(
                        libelle: _controller.supprime
                            ? 'Terminer le nettoyage'
                            : 'Supprimer définitivement mon compte',
                        icone: Icons.delete_forever,
                        enCours: _controller.enCours,
                        onPressed: (_confirmation || _controller.supprime)
                            ? _supprimer
                            : null,
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
