import 'package:flutter/material.dart';

import '../../controllers/affiches_epreuve_controller.dart';
import '../../models/affiche_epreuve_en_attente.dart';

class SelectionAffichesEpreuve extends StatefulWidget {
  const SelectionAffichesEpreuve({
    super.key,
    required this.controller,
    required this.valeurs,
    required this.onChanged,
    this.active = true,
  });

  final AffichesEpreuveController controller;
  final List<AfficheEpreuveEnAttente> valeurs;
  final ValueChanged<List<AfficheEpreuveEnAttente>> onChanged;
  final bool active;

  @override
  State<SelectionAffichesEpreuve> createState() =>
      _SelectionAffichesEpreuveState();
}

class _SelectionAffichesEpreuveState extends State<SelectionAffichesEpreuve> {
  Future<void> _ajouter() async {
    final fichier = await widget.controller.selectionnerFichier();
    if (!mounted || fichier == null) return;
    widget.onChanged([
      ...widget.valeurs,
      AfficheEpreuveEnAttente(fichier: fichier, texteAlternatif: ''),
    ]);
  }

  void _modifierTexte(int index, String texte) {
    final valeurs = [...widget.valeurs];
    valeurs[index] = valeurs[index].copierAvec(texteAlternatif: texte);
    widget.onChanged(valeurs);
  }

  void _retirer(int index) {
    final valeurs = [...widget.valeurs]..removeAt(index);
    widget.onChanged(valeurs);
  }

  void _principale(int index) {
    if (index == 0) return;
    final valeurs = [...widget.valeurs];
    final valeur = valeurs.removeAt(index);
    valeurs.insert(0, valeur);
    widget.onChanged(valeurs);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final bloque = !widget.active || widget.controller.operationEnCours;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Affiches — facultatif, 2 maximum',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text('JPEG, PNG ou WebP • 5 Mo maximum • 4096 px maximum.'),
            const SizedBox(height: 12),
            for (var i = 0; i < widget.valeurs.length; i++) ...[
              _AfficheLocale(
                key: ValueKey(widget.valeurs[i].fichier),
                valeur: widget.valeurs[i],
                position: i + 1,
                active: !bloque,
                onTexte: (texte) => _modifierTexte(i, texte),
                onRetirer: () => _retirer(i),
                onPrincipale: i == 0 ? null : () => _principale(i),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.valeurs.length < 2)
              OutlinedButton.icon(
                onPressed: bloque ? null : _ajouter,
                icon: widget.controller.operationEnCours
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  widget.controller.operationEnCours
                      ? 'Lecture de l’image…'
                      : 'Ajouter une affiche',
                ),
              ),
            if (widget.controller.erreur != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.controller.erreur!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AfficheLocale extends StatelessWidget {
  const _AfficheLocale({
    super.key,
    required this.valeur,
    required this.position,
    required this.active,
    required this.onTexte,
    required this.onRetirer,
    this.onPrincipale,
  });

  final AfficheEpreuveEnAttente valeur;
  final int position;
  final bool active;
  final ValueChanged<String> onTexte;
  final VoidCallback onRetirer;
  final VoidCallback? onPrincipale;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              image: true,
              label: valeur.texteAlternatif.trim().isEmpty
                  ? 'Aperçu de l’affiche $position'
                  : valeur.texteAlternatif.trim(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: Image.memory(
                  valeur.fichier.contenu,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              position == 1 ? 'Affiche principale' : 'Affiche 2',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: valeur.texteAlternatif,
              enabled: active,
              minLines: 2,
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Description pour les lecteurs d’écran',
                hintText: 'Décris les informations utiles visibles.',
                border: OutlineInputBorder(),
              ),
              onChanged: onTexte,
              validator: (texte) {
                final longueur = texte?.trim().length ?? 0;
                if (longueur < 3 || longueur > 300) {
                  return 'Saisis une description de 3 à 300 caractères.';
                }
                return null;
              },
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                if (onPrincipale != null)
                  TextButton.icon(
                    onPressed: active ? onPrincipale : null,
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Définir comme principale'),
                  ),
                TextButton.icon(
                  onPressed: active ? onRetirer : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Retirer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
