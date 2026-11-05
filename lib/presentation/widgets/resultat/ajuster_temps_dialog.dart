import 'package:flutter/material.dart';

import '../../../domain/entities/manche.dart';
import '../../../domain/entities/resultat.dart';
import '../../formatters/temps_resultat.dart';

class AjustementTemps {
  const AjustementTemps(this.resultat, this.deltaMs, this.motif, this.accord);
  final Resultat resultat;
  final int deltaMs;
  final String motif;
  final bool accord;
}

class AjusterTempsDialog extends StatefulWidget {
  const AjusterTempsDialog({
    super.key,
    required this.manche,
    required this.resultats,
    required this.appliquer,
  });
  final Manche manche;
  final List<Resultat> resultats;

  /// null confirme le succès ; un message conserve le formulaire pour réessayer.
  final Future<String?> Function(AjustementTemps choix) appliquer;
  @override
  State<AjusterTempsDialog> createState() => _AjusterTempsDialogState();
}

class _AjusterTempsDialogState extends State<AjusterTempsDialog> {
  final _form = GlobalKey<FormState>();
  final _valeur = TextEditingController();
  final _motif = TextEditingController();
  Resultat? _resultat;
  bool _bonus = false;
  bool _accord = false;
  bool _enCours = false;
  String? _erreur;
  int get _delta {
    final valeur = double.tryParse(_valeur.text.replaceAll(',', '.'));
    if (valeur == null || !valeur.isFinite || valeur.abs() > 86400) return 0;
    return (valeur * 1000).round() * (_bonus ? -1 : 1);
  }

  @override
  void dispose() {
    _valeur.dispose();
    _motif.dispose();
    super.dispose();
  }

  Future<void> _confirmer() async {
    if (_enCours || !_form.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final erreur = await widget.appliquer(
        AjustementTemps(_resultat!, _delta, _motif.text.trim(), _accord),
      );
      if (!mounted) return;
      if (erreur == null) {
        Navigator.pop(context, true);
        return;
      }
      setState(() => _erreur = erreur);
    } catch (_) {
      if (mounted) {
        setState(
          () => _erreur = 'Ajustement non confirmé. Actualise la manche avant de réessayer.',
        );
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final temps = _resultat?.tempsTotalMillisecondes;
    return PopScope(
      canPop: !_enCours,
      child: AlertDialog(
        title: const Text('Ajuster le temps (bonus / pénalité)'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<Resultat>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Athlète arrivé',
                    ),
                    items: widget.resultats
                        .where((r) => r.estArrive)
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r.athlete.nomComplet,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _enCours
                        ? null
                        : (v) => setState(() => _resultat = v),
                    validator: (v) =>
                        v == null ? 'Choisis un résultat arrivé.' : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _bonus,
                    title: Text(
                      _bonus
                          ? 'Bonus : temps soustrait'
                          : 'Pénalité : temps ajouté',
                    ),
                    onChanged: _enCours
                        ? null
                        : (v) => setState(() => _bonus = v),
                  ),
                  TextFormField(
                    controller: _valeur,
                    enabled: !_enCours,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Durée en secondes',
                      hintText: 'Exemple : 5,5',
                    ),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                      if (n == null || !n.isFinite || n < 0.001 || n > 86400) {
                        return 'Saisis une durée de 0,001 à 86400 secondes.';
                      }
                      if (temps != null && temps + _delta < 0) {
                        return 'Le bonus ne peut pas rendre le temps négatif.';
                      }
                      return null;
                    },
                  ),
                  if (temps != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Avant : ${TempsResultat.formater(temps)}\nAprès : ${TempsResultat.formater(temps + _delta)}',
                      ),
                    ),
                  TextFormField(
                    controller: _motif,
                    enabled: !_enCours,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: 'Motif obligatoire',
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Explique cet ajustement.'
                        : null,
                  ),
                  const Text(
                    'Le classement par temps, les points et les écarts seront recalculés. Le motif sera conservé avec le résultat. Le temps corrigé doit respecter le délai de la manche.',
                  ),
                  if (widget.manche.resultatsValides ||
                      widget.manche.resultatsPublies)
                    CheckboxListTile(
                      value: _accord,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Retirer la validation et, si nécessaire, la publication de toute la manche.',
                      ),
                      onChanged: _enCours
                          ? null
                          : (v) => setState(() => _accord = v ?? false),
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
            onPressed: _enCours ? null : () => Navigator.pop(context),
            child: const Text('Retour'),
          ),
          FilledButton(
            onPressed:
                _enCours ||
                    ((widget.manche.resultatsValides ||
                            widget.manche.resultatsPublies) &&
                        !_accord)
                ? null
                : _confirmer,
            child: _enCours
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Appliquer et recalculer'),
          ),
        ],
      ),
    );
  }
}
