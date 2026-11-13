import 'package:flutter/material.dart';

import '../../../domain/entities/affiche_epreuve.dart';
import '../../controllers/affiches_epreuve_controller.dart';

class GestionAffichesEpreuve extends StatefulWidget {
  const GestionAffichesEpreuve({
    super.key,
    required this.epreuveId,
    required this.controller,
  });

  final String epreuveId;
  final AffichesEpreuveController controller;

  @override
  State<GestionAffichesEpreuve> createState() => _GestionAffichesEpreuveState();
}

class _GestionAffichesEpreuveState extends State<GestionAffichesEpreuve> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_actualiser);
    widget.controller.reinitialiser();
    widget.controller.charger(widget.epreuveId);
  }

  @override
  void didUpdateWidget(covariant GestionAffichesEpreuve oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_actualiser);
      widget.controller.addListener(_actualiser);
    }
    if (oldWidget.epreuveId != widget.epreuveId) {
      widget.controller.reinitialiser();
      widget.controller.charger(widget.epreuveId);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_actualiser);
    super.dispose();
  }

  void _actualiser() {
    if (mounted) setState(() {});
  }

  Future<String?> _demanderDescription({
    required String titre,
    String initiale = '',
  }) async {
    final cle = GlobalKey<FormState>();
    final controleur = TextEditingController(text: initiale);
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(titre),
          content: Form(
            key: cle,
            child: TextFormField(
              controller: controleur,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Description pour les lecteurs d’écran',
                hintText: 'Décris les informations utiles visibles.',
                border: OutlineInputBorder(),
              ),
              validator: (texte) {
                final longueur = texte?.trim().length ?? 0;
                return longueur < 3 || longueur > 300
                    ? 'Saisis une description de 3 à 300 caractères.'
                    : null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (cle.currentState?.validate() != true) return;
                Navigator.pop(dialogContext, controleur.text.trim());
              },
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
    } finally {
      controleur.dispose();
    }
  }

  Future<void> _ajouter() async {
    final texte = await _demanderDescription(titre: 'Ajouter une affiche');
    if (texte == null || !mounted) return;
    final succes = await widget.controller.ajouterDepuisGalerie(
      epreuveId: widget.epreuveId,
      position: widget.controller.affiches.length + 1,
      texteAlternatif: texte,
    );
    if (mounted) _message(succes ? 'Affiche ajoutée.' : null);
  }

  Future<void> _remplacer(AfficheEpreuve affiche) async {
    final texte = await _demanderDescription(
      titre: 'Remplacer l’affiche',
      initiale: affiche.texteAlternatif,
    );
    if (texte == null || !mounted) return;
    final succes = await widget.controller.remplacerDepuisGalerie(
      affiche: affiche,
      texteAlternatif: texte,
    );
    if (mounted) _message(succes ? 'Affiche remplacée.' : null);
  }

  Future<void> _modifierDescription(AfficheEpreuve affiche) async {
    final texte = await _demanderDescription(
      titre: 'Modifier la description',
      initiale: affiche.texteAlternatif,
    );
    if (texte == null || !mounted) return;
    final succes = await widget.controller.modifierTexteAlternatif(
      affiche: affiche,
      texteAlternatif: texte,
    );
    if (mounted) _message(succes ? 'Description enregistrée.' : null);
  }

  Future<void> _supprimer(AfficheEpreuve affiche) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Retirer cette affiche ?'),
        content: const Text(
          'L’affiche ne sera plus visible. Cette action est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;
    final succes = await widget.controller.supprimer(affiche);
    if (mounted) _message(succes ? 'Affiche retirée.' : null);
  }

  Future<void> _inverser() async {
    final succes = await widget.controller.inverser(widget.epreuveId);
    if (mounted) _message(succes ? 'Affiche principale modifiée.' : null);
  }

  void _message(String? succes) {
    final message = succes ?? widget.controller.erreur;
    if (message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: succes == null
            ? Theme.of(context).colorScheme.error
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller.chargement && controller.affiches.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Affiches — facultatif, 2 maximum',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        const Text(
          'Elles seront visibles par les utilisateurs autorisés à consulter l’épreuve.',
        ),
        const SizedBox(height: 12),
        if (controller.affiches.isEmpty && !controller.chargement)
          const Text('Aucune affiche enregistrée.'),
        for (final affiche in controller.affiches) ...[
          _CarteAfficheEnregistree(
            affiche: affiche,
            url: controller.urlPour(affiche.id),
            active: !controller.operationEnCours,
            onRemplacer: () => _remplacer(affiche),
            onDescription: () => _modifierDescription(affiche),
            onSupprimer: () => _supprimer(affiche),
          ),
          const SizedBox(height: 12),
        ],
        if (controller.affiches.length == 2)
          OutlinedButton.icon(
            onPressed: controller.operationEnCours ? null : _inverser,
            icon: const Icon(Icons.swap_vert),
            label: const Text('Définir l’affiche 2 comme principale'),
          ),
        if (controller.affiches.length < 2)
          OutlinedButton.icon(
            onPressed: controller.operationEnCours ? null : _ajouter,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Ajouter une affiche'),
          ),
        if (controller.operationEnCours) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
          const SizedBox(height: 4),
          const Text('Opération sur l’affiche en cours…'),
        ],
        if (controller.erreur != null) ...[
          const SizedBox(height: 8),
          Text(
            controller.erreur!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _CarteAfficheEnregistree extends StatelessWidget {
  const _CarteAfficheEnregistree({
    required this.affiche,
    required this.url,
    required this.active,
    required this.onRemplacer,
    required this.onDescription,
    required this.onSupprimer,
  });

  final AfficheEpreuve affiche;
  final Uri? url;
  final bool active;
  final VoidCallback onRemplacer;
  final VoidCallback onDescription;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: url == null
                  ? const Center(child: Icon(Icons.broken_image_outlined))
                  : Image.network(
                      url.toString(),
                      fit: BoxFit.contain,
                      semanticLabel: affiche.texteAlternatif,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              affiche.estPrincipale ? 'Affiche principale' : 'Affiche 2',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(affiche.texteAlternatif),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: active ? onDescription : null,
                  child: const Text('Modifier la description'),
                ),
                TextButton(
                  onPressed: active ? onRemplacer : null,
                  child: const Text('Remplacer'),
                ),
                TextButton(
                  onPressed: active ? onSupprimer : null,
                  child: const Text('Retirer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
