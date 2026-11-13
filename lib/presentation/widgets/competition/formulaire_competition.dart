import 'package:flutter/material.dart';

import '../../../domain/entities/fichier_affiche_epreuve.dart';
import 'selection_image_competition.dart';

class DonneesFormulaireCompetition {
  const DonneesFormulaireCompetition({
    required this.nom,
    required this.dateCompetition,
    this.description,
    this.lieu,
    required this.demarrageAutomatiqueMancheSuivante,
    this.image,
    this.supprimerImage = false,
  });

  final String nom;
  final String? description;
  final String? lieu;
  final DateTime dateCompetition;
  final bool demarrageAutomatiqueMancheSuivante;
  final FichierAfficheEpreuve? image;
  final bool supprimerImage;
}

class FormulaireCompetition extends StatefulWidget {
  const FormulaireCompetition({
    super.key,
    required this.onValider,
    this.nomInitial = '',
    this.descriptionInitiale = '',
    this.lieuInitial = '',
    this.dateInitiale,
    this.demarrageAutomatiqueInitial = false,
    this.enregistrementEnCours = false,
    this.libelleBouton = 'Créer la compétition',
    this.imageInitiale,
    this.onSelectionnerImage,
  });

  final String nomInitial;
  final String descriptionInitiale;
  final String lieuInitial;
  final DateTime? dateInitiale;
  final bool demarrageAutomatiqueInitial;
  final bool enregistrementEnCours;
  final String libelleBouton;
  final Uri? imageInitiale;
  final Future<FichierAfficheEpreuve?> Function()? onSelectionnerImage;

  final Future<void> Function(DonneesFormulaireCompetition donnees) onValider;

  @override
  State<FormulaireCompetition> createState() {
    return _FormulaireCompetitionState();
  }
}

class _FormulaireCompetitionState extends State<FormulaireCompetition> {
  final _cleFormulaire = GlobalKey<FormState>();

  late final TextEditingController _nomController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _lieuController;

  DateTime? _dateSelectionnee;
  late bool _demarrageAutomatique;
  FichierAfficheEpreuve? _image;
  bool _supprimerImage = false;

  @override
  void initState() {
    super.initState();

    _nomController = TextEditingController(text: widget.nomInitial);

    _descriptionController = TextEditingController(
      text: widget.descriptionInitiale,
    );

    _lieuController = TextEditingController(text: widget.lieuInitial);

    _dateSelectionnee = widget.dateInitiale;
    _demarrageAutomatique = widget.demarrageAutomatiqueInitial;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _lieuController.dispose();

    super.dispose();
  }

  Future<void> _selectionnerDate() async {
    FocusScope.of(context).unfocus();

    final maintenant = DateTime.now();

    final premiereDate = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );

    final dateInitiale = _dateSelectionnee ?? premiereDate;

    final dateChoisie = await showDatePicker(
      context: context,
      initialDate: dateInitiale.isBefore(premiereDate)
          ? premiereDate
          : dateInitiale,
      firstDate: premiereDate,
      lastDate: DateTime(maintenant.year + 10, 12, 31),
      helpText: 'Choisir la date de la compétition',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );

    if (dateChoisie == null || !mounted) {
      return;
    }

    setState(() {
      _dateSelectionnee = dateChoisie;
    });
  }

  Future<void> _choisirImage() async {
    final selectionner = widget.onSelectionnerImage;
    if (selectionner == null) return;
    final image = await selectionner();
    if (image == null || !mounted) return;
    setState(() {
      _image = image;
      _supprimerImage = false;
    });
  }

  Future<void> _valider() async {
    FocusScope.of(context).unfocus();

    final formulaireValide = _cleFormulaire.currentState?.validate() ?? false;

    if (!formulaireValide) {
      return;
    }

    if (_dateSelectionnee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionne la date de la compétition.')),
      );

      return;
    }

    final donnees = DonneesFormulaireCompetition(
      nom: _nomController.text.trim(),
      description: _nettoyerTexteFacultatif(_descriptionController.text),
      lieu: _nettoyerTexteFacultatif(_lieuController.text),
      dateCompetition: _dateSelectionnee!,
      demarrageAutomatiqueMancheSuivante: _demarrageAutomatique,
      image: _image,
      supprimerImage: _supprimerImage,
    );

    await widget.onValider(donnees);
  }

  String? _nettoyerTexteFacultatif(String valeur) {
    final valeurNettoyee = valeur.trim();

    if (valeurNettoyee.isEmpty) {
      return null;
    }

    return valeurNettoyee;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _cleFormulaire,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nomController,
            enabled: !widget.enregistrementEnCours,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Nom de la compétition',
              hintText: 'Exemple : Triathlon du Mans',
              prefixIcon: Icon(Icons.emoji_events_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (valeur) {
              final nom = valeur?.trim() ?? '';

              if (nom.isEmpty) {
                return 'Le nom de la compétition est obligatoire.';
              }

              if (nom.length < 3) {
                return 'Le nom doit contenir au moins 3 caractères.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            enabled: !widget.enregistrementEnCours,
            textCapitalization: TextCapitalization.sentences,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Informations générales sur la compétition',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 64),
                child: Icon(Icons.description_outlined),
              ),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lieuController,
            enabled: !widget.enregistrementEnCours,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.words,
            maxLength: 150,
            decoration: const InputDecoration(
              labelText: 'Lieu',
              hintText: 'Exemple : Le Mans',
              prefixIcon: Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SelectionImageCompetition(
            imageSelectionnee: _image,
            imageExistante: widget.imageInitiale,
            suppressionDemandee: _supprimerImage,
            actif: !widget.enregistrementEnCours,
            onChoisir: _choisirImage,
            onRetirer: () => setState(() {
              _image = null;
              _supprimerImage = true;
            }),
          ),
          const SizedBox(height: 16),
          _ChampDateCompetition(
            dateSelectionnee: _dateSelectionnee,
            actif: !widget.enregistrementEnCours,
            onSelectionner: _selectionnerDate,
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            value: _demarrageAutomatique,
            onChanged: widget.enregistrementEnCours
                ? null
                : (valeur) {
                    setState(() {
                      _demarrageAutomatique = valeur;
                    });
                  },
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: const Text('Enchaîner automatiquement les manches'),
            subtitle: const Text(
              'À la fin d’une manche, la suivante démarre immédiatement.',
            ),
            secondary: const Icon(Icons.skip_next_outlined),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: widget.enregistrementEnCours ? null : _valider,
            icon: widget.enregistrementEnCours
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              widget.enregistrementEnCours
                  ? 'Enregistrement...'
                  : widget.libelleBouton,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChampDateCompetition extends StatelessWidget {
  const _ChampDateCompetition({
    required this.dateSelectionnee,
    required this.actif,
    required this.onSelectionner,
  });

  final DateTime? dateSelectionnee;
  final bool actif;
  final VoidCallback onSelectionner;

  @override
  Widget build(BuildContext context) {
    final date = dateSelectionnee;

    return InkWell(
      onTap: actif ? onSelectionner : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date de la compétition',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: const OutlineInputBorder(),
          enabled: actif,
        ),
        child: Text(
          date == null ? 'Sélectionner une date' : _formaterDate(date),
          style: date == null
              ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
              : null,
        ),
      ),
    );
  }

  String _formaterDate(DateTime date) {
    const nomsMois = <String>[
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    return '${date.day} '
        '${nomsMois[date.month - 1]} '
        '${date.year}';
  }
}
