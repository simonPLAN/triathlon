import 'package:flutter/material.dart';

import '../../../domain/entities/epreuve.dart';
import '../../controllers/epreuve_controller.dart';
import '../../widgets/commun/carte_section.dart';
import '../../widgets/epreuve/formulaire_epreuve.dart';
import '../../widgets/epreuve/gestion_affiches_epreuve.dart';

class ModifierEpreuvePage extends StatelessWidget {
  const ModifierEpreuvePage({
    super.key,
    required this.epreuve,
    required this.controller,
  });

  final Epreuve epreuve;
  final EpreuveController controller;

  Future<void> _enregistrer(
    BuildContext context,
    DonneesFormulaireEpreuve donnees,
  ) async {
    final succes = await controller.modifier(
      epreuve.copierAvec(
        discipline: donnees.discipline,
        nom: donnees.nom,
        distanceMetres: donnees.distanceMetres,
        nombreManches: donnees.nombreManches,
        ordre: donnees.ordre,
        dureeLimiteSecondes: donnees.dureeLimiteSecondes,
      ),
    );
    if (!context.mounted) return;
    if (succes) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.erreur ?? 'Modification impossible.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => PopScope(
      canPop:
          !controller.operationEnCours &&
          !(controller.affiches?.operationEnCours ?? false),
      child: Scaffold(
        appBar: AppBar(title: const Text('Modifier l’épreuve')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CarteSection(
                      titre: epreuve.nom,
                      sousTitre:
                          'Les manches à venir sont ajustées automatiquement au nombre choisi. '
                          'Les manches déjà commencées ou avec résultats sont protégées.',
                      child: FormulaireEpreuve(
                        disciplineInitiale: epreuve.discipline,
                        nomInitial: epreuve.nom,
                        distanceInitiale: epreuve.distanceMetres,
                        nombreManchesInitial: epreuve.nombreManches,
                        ordreInitial: epreuve.ordre,
                        dureeLimiteInitiale: epreuve.dureeLimiteSecondes,
                        enregistrementEnCours: controller.operationEnCours,
                        libelleBouton: 'Enregistrer les modifications',
                        onValider: (donnees) => _enregistrer(context, donnees),
                      ),
                    ),
                    if (controller.affiches != null) ...[
                      const SizedBox(height: 16),
                      CarteSection(
                        titre: 'Affiches de l’épreuve',
                        sousTitre: 'Les affiches sont modifiables tant que la compétition reste en brouillon.',
                        child: GestionAffichesEpreuve(
                          epreuveId: epreuve.id,
                          controller: controller.affiches!,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
