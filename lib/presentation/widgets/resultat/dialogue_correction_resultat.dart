import 'package:flutter/material.dart';

import 'champs_classement_resultat.dart';

import '../../../domain/entities/athlete.dart';
import '../../../domain/entities/edition_resultat.dart';
import '../../../domain/entities/manche.dart';
import '../../../domain/entities/resultat.dart';
import '../../../domain/entities/statut_resultat.dart';
import '../../formatters/temps_resultat.dart';

class CorrectionResultat {
  const CorrectionResultat({
    required this.statut,
    required this.mode,
    this.position,
    this.tempsMillisecondes,
    this.commentaire,
    required this.accepterDepublication,
  });
  final StatutResultat statut;
  final ModeReclassement mode;
  final int? position;
  final int? tempsMillisecondes;
  final String? commentaire;
  final bool accepterDepublication;
}

class DialogueCorrectionResultat extends StatefulWidget {
  const DialogueCorrectionResultat({
    super.key,
    required this.manche,
    required this.athlete,
    required this.nombreArrives,
    this.resultat,
  });
  final Manche manche;
  final Athlete athlete;
  final Resultat? resultat;
  final int nombreArrives;
  @override
  State<DialogueCorrectionResultat> createState() =>
      _DialogueCorrectionResultatState();
}

class _DialogueCorrectionResultatState
    extends State<DialogueCorrectionResultat> {
  final _form = GlobalKey<FormState>();
  late StatutResultat _statut;
  late ModeReclassement _mode;
  late final TextEditingController _position;
  late final TextEditingController _temps;
  late final TextEditingController _commentaire;
  bool _accord = false;
  bool _fermetureDemandee = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final resultat = widget.resultat;
    _statut = resultat?.statut ?? StatutResultat.arrive;
    _mode = resultat?.estArrive == true
        ? ModeReclassement.decaler
        : ModeReclassement.temps;
    _position = TextEditingController(
      text: resultat?.position?.toString() ?? '',
    );
    _temps = TextEditingController(
      text: resultat?.tempsTotalMillisecondes == null
          ? ''
          : TempsResultat.formater(resultat!.tempsTotalMillisecondes!),
    );
    _commentaire = TextEditingController(text: resultat?.commentaire ?? '');
  }

  @override
  void dispose() {
    _position.dispose();
    _temps.dispose();
    _commentaire.dispose();
    super.dispose();
  }

  void _confirmer() {
    if (_fermetureDemandee || !_form.currentState!.validate()) return;
    if ((widget.manche.resultatsPublies || widget.manche.resultatsValides) && !_accord) {
      setState(
        () => _erreur = 'Confirme le retrait de publication pour continuer.',
      );
      return;
    }
    _fermetureDemandee = true;
    final arrive = _statut == StatutResultat.arrive;
    Navigator.of(context).pop(
      CorrectionResultat(
        statut: _statut,
        mode: _mode,
        position: arrive && _mode != ModeReclassement.temps
            ? int.parse(_position.text.trim())
            : null,
        tempsMillisecondes: arrive ? TempsResultat.lire(_temps.text) : null,
        commentaire: _commentaire.text,
        accepterDepublication: _accord,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arrive = _statut == StatutResultat.arrive;
    final maximum =
        widget.nombreArrives + (widget.resultat?.estArrive == true ? 0 : 1);
    return AlertDialog(
      title: Text(
        widget.resultat == null
            ? 'Saisir un résultat manuel'
            : 'Corriger le résultat',
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.athlete.nomComplet),
                const SizedBox(height: 12),
                DropdownButtonFormField<StatutResultat>(
                  initialValue: _statut,
                  decoration: const InputDecoration(labelText: 'Statut'),
                  items: const [
                    DropdownMenuItem(
                      value: StatutResultat.arrive,
                      child: Text('Arrivé'),
                    ),
                    DropdownMenuItem(
                      value: StatutResultat.horsDelai,
                      child: Text('Hors délai'),
                    ),
                    DropdownMenuItem(
                      value: StatutResultat.abandon,
                      child: Text('Abandon'),
                    ),
                    DropdownMenuItem(
                      value: StatutResultat.disqualifie,
                      child: Text('Disqualifié'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _statut = value);
                  },
                ),
                if (arrive)
                  ChampsClassementResultat(
                    temps: _temps,
                    position: _position,
                    mode: _mode,
                    maximum: maximum,
                    echangeAutorise: widget.resultat?.estArrive == true,
                    onModeChanged: (value) => setState(() => _mode = value),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commentaire,
                  maxLines: 2,
                  maxLength: 1000,
                  decoration: const InputDecoration(labelText: 'Commentaire'),
                ),
                if (widget.manche.resultatsPublies || widget.manche.resultatsValides)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _accord,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(widget.manche.resultatsPublies
                      ? 'Retirer toute la manche des résultats publiés. Une nouvelle validation et publication seront nécessaires.'
                      : 'Retirer la validation de cette manche. Une nouvelle validation sera nécessaire.'),
                    onChanged: (value) => setState(() {
                      _accord = value ?? false;
                      _erreur = null;
                    }),
                  ),
                if (_erreur != null)
                  Text(
                    _erreur!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _confirmer, child: const Text('Enregistrer')),
      ],
    );
  }
}
