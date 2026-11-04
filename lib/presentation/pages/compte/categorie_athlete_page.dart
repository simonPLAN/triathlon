import 'package:flutter/material.dart';

import '../../../application/use_cases/configurer_categorie_athlete.dart';
import '../../../domain/entities/categorie_athlete.dart';
import '../../../domain/ports/categorie_athlete_repository.dart';
import '../../../domain/services/coefficients_athletes.dart';
import '../../widgets/commun/message_erreur.dart';
import '../../widgets/commun/carte_section.dart';

class CategorieAthletePage extends StatefulWidget {
  const CategorieAthletePage({
    super.key,
    required this.repository,
    required this.athleteId,
    required this.nomAthlete,
  });
  final CategorieAthleteRepository repository;
  final String athleteId, nomAthlete;
  @override
  State<CategorieAthletePage> createState() => _CategorieAthletePageState();
}

class _CategorieAthletePageState extends State<CategorieAthletePage> {
  CategorieAthlete? _donnees;
  String? _categorie;
  bool _chargement = true, _enregistrement = false;
  String? _erreur;
  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final data = await widget.repository.obtenir(widget.athleteId);
      if (mounted) {
        setState(() {
          _donnees = data;
          _categorie = CoefficientsAthletes.bareme.containsKey(data.categorie)
              ? data.categorie
              : null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _erreur = 'Impossible de charger la catégorie. Vérifie ta connexion puis réessaie.',
        );
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _enregistrer() async {
    if (_enregistrement || _donnees?.modifiable != true) return;
    setState(() {
      _enregistrement = true;
      _erreur = null;
    });
    try {
      await ConfigurerCategorieAthlete(widget.repository)
          .executer(widget.athleteId, _categorie);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Catégorie enregistrée.')));
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _erreur = 'L’enregistrement n’a pas été confirmé. Réessaie.',
        );
      }
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coefficient = CoefficientsAthletes.pourCategorie(_categorie);
    return Scaffold(
      appBar: AppBar(title: const Text('Coefficient athlète')),
      body: SafeArea(
        child: _chargement
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_erreur != null)
                    MessageErreur(message: _erreur!, onReessayer: _charger),
                  if (_donnees != null)
                    CarteSection(
                      titre: widget.nomAthlete,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Renseigne uniquement la catégorie correspondant à la situation actuelle de l’athlète. Les tranches absentes du barème restent non définies.',
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _categorie,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Catégorie déclarée',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Non définie'),
                              ),
                              for (final categorie
                                  in CoefficientsAthletes.bareme.keys)
                                DropdownMenuItem(
                                  value: categorie,
                                  child: Text(categorie),
                                ),
                            ],
                            onChanged: _donnees!.modifiable && !_enregistrement
                                ? (v) => setState(() => _categorie = v)
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            coefficient == null
                                ? 'Coefficient non défini'
                                : 'Coefficient : ${coefficient.toStringAsFixed(4).replaceAll('.', ',')}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Barème fourni par l’organisateur. La catégorie est déclarative et doit être actualisée si nécessaire. Les temps mesurés et les points officiels ne sont pas modifiés automatiquement.',
                          ),
                          if (!_donnees!.modifiable)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                'Seul l’athlète ou un coach responsable d’une compétition de l’invité peut modifier sa catégorie.',
                              ),
                            ),
                          if (_donnees!.modifiable)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: FilledButton.icon(
                                onPressed: _enregistrement
                                    ? null
                                    : _enregistrer,
                                icon: _enregistrement
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: Text(
                                  _enregistrement
                                      ? 'Enregistrement…'
                                      : 'Enregistrer',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
