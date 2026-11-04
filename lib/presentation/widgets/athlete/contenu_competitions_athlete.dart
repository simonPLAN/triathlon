import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../commun/etat_vide.dart';
import '../commun/message_erreur.dart';

class ContenuCompetitionsAthlete extends StatelessWidget {
  const ContenuCompetitionsAthlete({
    super.key,
    required this.entete,
    required this.competitions,
    required this.chargement,
    required this.mesCompetitions,
    required this.onRecharger,
    required this.onVoirOuvertes,
    required this.construireCarte,
    this.erreur,
  });
  final Widget entete;
  final List<Competition> competitions;
  final bool chargement, mesCompetitions;
  final String? erreur;
  final Future<void> Function() onRecharger;
  final VoidCallback onVoirOuvertes;
  final Widget Function(Competition) construireCarte;

  @override
  Widget build(BuildContext context) {
    final vides = competitions.isEmpty;
    return RefreshIndicator(
      onRefresh: onRecharger,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: entete),
          if (vides)
            SliverToBoxAdapter(
              child: chargement
                  ? const Center(child: CircularProgressIndicator())
                  : erreur != null
                  ? MessageErreur(message: erreur!, onReessayer: onRecharger)
                  : EtatVide(
                      icone: Icons.event_note_outlined,
                      titre: mesCompetitions
                          ? 'Tu n’es inscrit à aucune compétition.'
                          : 'Aucune compétition ouverte aux inscriptions.',
                      description: mesCompetitions
                          ? 'Retrouve ici le programme, ton dossard et les résultats de tes inscriptions.'
                          : 'Reviens plus tard ou actualise la liste.',
                      libelleAction: mesCompetitions
                          ? 'Voir les inscriptions ouvertes'
                          : null,
                      onAction: mesCompetitions ? onVoirOuvertes : null,
                    ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: competitions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) => construireCarte(competitions[index]),
              ),
            ),
        ],
      ),
    );
  }
}
