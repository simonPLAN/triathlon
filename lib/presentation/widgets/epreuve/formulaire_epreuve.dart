import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/type_discipline.dart';

class DonneesFormulaireEpreuve {
  const DonneesFormulaireEpreuve({
    required this.discipline,
    required this.nom,
    required this.distanceMetres,
    required this.nombreManches,
    required this.ordre,
    required this.dureeLimiteSecondes,
  });

  final TypeDiscipline discipline;
  final String nom;
  final int distanceMetres;
  final int nombreManches;
  final int ordre;
  final int dureeLimiteSecondes;
}

class FormulaireEpreuve extends StatefulWidget {
  const FormulaireEpreuve({
    super.key,
    required this.onValider,
    this.disciplineInitiale = TypeDiscipline.natation,
    this.nomInitial = '',
    this.distanceInitiale,
    this.nombreManchesInitial = 1,
    this.ordreInitial = 1,
    this.dureeLimiteInitiale = 60,
    this.enregistrementEnCours = false,
    this.libelleBouton = 'Créer l’épreuve',
  });

  final TypeDiscipline disciplineInitiale;
  final String nomInitial;
  final int? distanceInitiale;
  final int nombreManchesInitial;
  final int ordreInitial;
  final int dureeLimiteInitiale;

  final bool enregistrementEnCours;
  final String libelleBouton;

  final Future<void> Function(DonneesFormulaireEpreuve donnees) onValider;

  @override
  State<FormulaireEpreuve> createState() {
    return _FormulaireEpreuveState();
  }
}

class _FormulaireEpreuveState extends State<FormulaireEpreuve> {
  final _cleFormulaire = GlobalKey<FormState>();

  late final TextEditingController _nomController;
  late final TextEditingController _distanceController;
  late final TextEditingController _nombreManchesController;
  late final TextEditingController _ordreController;
  late final TextEditingController _dureeLimiteController;

  late TypeDiscipline _discipline;

  @override
  void initState() {
    super.initState();

    _discipline = widget.disciplineInitiale;

    _nomController = TextEditingController(text: widget.nomInitial);

    _distanceController = TextEditingController(
      text: widget.distanceInitiale?.toString() ?? '',
    );

    _nombreManchesController = TextEditingController(
      text: widget.nombreManchesInitial.toString(),
    );

    _ordreController = TextEditingController(
      text: widget.ordreInitial.toString(),
    );

    _dureeLimiteController = TextEditingController(
      text: widget.dureeLimiteInitiale.toString(),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _distanceController.dispose();
    _nombreManchesController.dispose();
    _ordreController.dispose();
    _dureeLimiteController.dispose();

    super.dispose();
  }

  Future<void> _valider() async {
    FocusScope.of(context).unfocus();

    final formulaireValide = _cleFormulaire.currentState?.validate() ?? false;

    if (!formulaireValide) {
      return;
    }

    final donnees = DonneesFormulaireEpreuve(
      discipline: _discipline,
      nom: _nomController.text.trim(),
      distanceMetres: int.parse(_distanceController.text),
      nombreManches: int.parse(_nombreManchesController.text),
      ordre: int.parse(_ordreController.text),
      dureeLimiteSecondes: int.parse(_dureeLimiteController.text),
    );

    await widget.onValider(donnees);
  }

  String? _validerEntierPositif(String? valeur, String nomChamp) {
    final texte = valeur?.trim() ?? '';
    final nombre = int.tryParse(texte);

    if (texte.isEmpty) {
      return '$nomChamp est obligatoire.';
    }

    if (nombre == null) {
      return '$nomChamp doit être un nombre entier.';
    }

    if (nombre <= 0) {
      return '$nomChamp doit être supérieur à zéro.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final desactive = widget.enregistrementEnCours;

    return Form(
      key: _cleFormulaire,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<TypeDiscipline>(
            initialValue: _discipline,
            decoration: const InputDecoration(
              labelText: 'Discipline',
              prefixIcon: Icon(Icons.sports_outlined),
              border: OutlineInputBorder(),
            ),
            items: TypeDiscipline.values.map((discipline) {
              return DropdownMenuItem<TypeDiscipline>(
                value: discipline,
                child: Text(_libelleDiscipline(discipline)),
              );
            }).toList(),
            onChanged: desactive
                ? null
                : (discipline) {
                    if (discipline == null) {
                      return;
                    }

                    setState(() {
                      _discipline = discipline;
                    });

                    if (_nomController.text.trim().isEmpty) {
                      _nomController.text = _nomParDefaut(discipline);
                    }
                  },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nomController,
            enabled: !desactive,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Nom de l’épreuve',
              hintText: 'Exemple : Natation 100 m',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (valeur) {
              final nom = valeur?.trim() ?? '';

              if (nom.isEmpty) {
                return 'Le nom de l’épreuve est obligatoire.';
              }

              if (nom.length < 3) {
                return 'Le nom doit contenir au moins 3 caractères.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _distanceController,
            enabled: !desactive,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Distance',
              hintText: 'Exemple : 100',
              suffixText: 'm',
              prefixIcon: Icon(Icons.straighten),
              border: OutlineInputBorder(),
            ),
            validator: (valeur) {
              return _validerEntierPositif(valeur, 'La distance');
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nombreManchesController,
            enabled: !desactive,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Nombre de manches',
              hintText: 'Exemple : 4',
              prefixIcon: Icon(Icons.repeat),
              border: OutlineInputBorder(),
            ),
            validator: (valeur) {
              return _validerEntierPositif(valeur, 'Le nombre de manches');
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ordreController,
            enabled: !desactive,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Ordre dans la compétition',
              hintText: 'Exemple : 1',
              prefixIcon: Icon(Icons.format_list_numbered),
              border: OutlineInputBorder(),
            ),
            validator: (valeur) {
              return _validerEntierPositif(valeur, 'L’ordre');
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dureeLimiteController,
            enabled: !desactive,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onFieldSubmitted: (_) {
              if (!desactive) {
                _valider();
              }
            },
            decoration: const InputDecoration(
              labelText: 'Durée limite après le premier',
              hintText: 'Exemple : 60',
              suffixText: 'secondes',
              prefixIcon: Icon(Icons.timer_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (valeur) {
              return _validerEntierPositif(valeur, 'La durée limite');
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: desactive ? null : _valider,
            icon: desactive
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(desactive ? 'Enregistrement...' : widget.libelleBouton),
          ),
        ],
      ),
    );
  }

  String _libelleDiscipline(TypeDiscipline discipline) {
    switch (discipline) {
      case TypeDiscipline.natation:
        return 'Natation';

      case TypeDiscipline.velo:
        return 'Vélo';

      case TypeDiscipline.courseAPied:
        return 'Course à pied';
    }
  }

  String _nomParDefaut(TypeDiscipline discipline) {
    switch (discipline) {
      case TypeDiscipline.natation:
        return 'Natation';

      case TypeDiscipline.velo:
        return 'Vélo';

      case TypeDiscipline.courseAPied:
        return 'Course à pied';
    }
  }
}
