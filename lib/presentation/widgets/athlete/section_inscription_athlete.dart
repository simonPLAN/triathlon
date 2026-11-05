import 'package:flutter/material.dart';

import '../../../domain/entities/competition.dart';
import '../../../domain/entities/statut_competition.dart';
import '../../models/etat_inscription_utilisateur.dart';

class SectionInscriptionAthlete extends StatelessWidget {
  const SectionInscriptionAthlete({
    super.key,
    required this.competition,
    required this.etat,
    required this.inscriptionEnCours,
    required this.desinscriptionEnCours,
    required this.onReessayer,
    this.onInscrire,
    this.onDesinscrire,
  });
  final Competition competition;
  final EtatInscriptionUtilisateur etat;
  final bool inscriptionEnCours;
  final bool desinscriptionEnCours;
  final VoidCallback onReessayer;
  final VoidCallback? onInscrire;
  final VoidCallback? onDesinscrire;

  String get _raisonFermeture => switch (competition.statut) {
    StatutCompetition.brouillon => 'Cette compétition est en préparation. Les inscriptions ne sont pas encore ouvertes.',
    StatutCompetition.ouverte => '',
    StatutCompetition.enCours => 'La compétition a commencé. Il n’est plus possible de s’inscrire ou de se désinscrire.',
    StatutCompetition.terminee => 'La compétition est terminée. Il n’est plus possible de s’inscrire ou de se désinscrire.',
    StatutCompetition.annulee => 'La compétition est annulée. Il n’est plus possible de s’inscrire ou de se désinscrire.',
  };

  @override
  Widget build(BuildContext context) {
    final occupe = inscriptionEnCours || desinscriptionEnCours;
    final inscription = etat.inscription;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (etat.statut == StatutVerificationInscription.enCours)
          const Row(
            children: [
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Vérification de l’inscription…')),
            ],
          )
        else if (etat.statut == StatutVerificationInscription.erreur ||
            etat.statut == StatutVerificationInscription.nonVerifiee) ...[
          Text(
            etat.erreur ?? 'Inscription non vérifiée.',
            style: TextStyle(
              color: etat.erreur != null
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
          ),
          TextButton.icon(
            onPressed: occupe ? null : onReessayer,
            icon: const Icon(Icons.refresh),
            label: Text(
              etat.erreur != null
                  ? 'Réessayer la vérification'
                  : 'Vérifier mon inscription',
            ),
          ),
        ] else ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              inscription != null
                  ? Icons.check_circle_outline
                  : Icons.person_outline,
            ),
            title: Text(inscription != null ? 'Inscrit' : 'Non inscrit'),
            subtitle: inscription == null
                ? null
                : Text(
                    inscription.numeroDossard == null
                        ? 'Dossard en attente d’attribution'
                        : 'Dossard n°${inscription.numeroDossard}',
                  ),
          ),
          if (competition.estOuverte)
            inscription != null
                ? OutlinedButton.icon(
                    onPressed: occupe ? null : onDesinscrire,
                    icon: desinscriptionEnCours
                        ? _indicateur()
                        : const Icon(Icons.person_remove_outlined),
                    label: Text(
                      desinscriptionEnCours
                          ? 'Désinscription…'
                          : 'Se désinscrire',
                    ),
                  )
                : FilledButton.icon(
                    onPressed: occupe ? null : onInscrire,
                    icon: inscriptionEnCours
                        ? _indicateur()
                        : const Icon(Icons.how_to_reg),
                    label: Text(
                      inscriptionEnCours ? 'Inscription…' : 'S’inscrire',
                    ),
                  ),
        ],
        if (!competition.estOuverte) ...[
          const SizedBox(height: 8),
          const Text(
            'Inscriptions fermées',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(_raisonFermeture),
        ],
      ],
    );
  }

  Widget _indicateur() => const SizedBox.square(
    dimension: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
