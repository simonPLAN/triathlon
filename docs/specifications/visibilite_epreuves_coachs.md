# Spécification validée — Délégation de saisie des résultats par épreuve

## Statut

**Validée et implémentée localement le 13 novembre 2026.**

Cette version remplace la demande initiale « tous les coachs voient toutes les
épreuves ». Une épreuve n'est visible par un autre coach que si son responsable
l'autorise explicitement.

## Objectif

Le coach responsable choisit, pour chaque épreuve, les autres coachs autorisés
à consulter les manches et à saisir les résultats. L'autorisation est accordée
à un compte coach actif à partir de son pseudo.

## Droits

| Action | Responsable | Coach autorisé | Autre coach |
|---|---:|---:|---:|
| Voir l'épreuve et ses manches | Oui | Oui | Non |
| Voir les participants affectés | Oui | Oui | Non |
| Saisir une arrivée | Oui | Oui | Non |
| Déclarer abandon/disqualification | Oui | Oui | Non |
| Saisir ou corriger un résultat non publié | Oui | Oui | Non |
| Clôturer le délai écoulé | Oui | Oui | Non |
| Configurer participants et ordre | Oui | Non | Non |
| Démarrer, terminer ou annuler une manche | Oui | Non | Non |
| Valider ou publier le classement | Oui | Non | Non |
| Gérer les coachs autorisés | Oui | Non | Non |

Une révocation empêche immédiatement les nouvelles lectures et écritures. Les
résultats déjà saisis sont conservés.

## Parcours responsable

1. Ouvrir une compétition puis **Épreuves**.
2. Choisir **Coachs autorisés** sous l'épreuve.
3. Saisir le pseudo exact d'un compte coach actif.
4. Vérifier la liste des accès accordés.
5. Retirer un accès si nécessaire.

## Parcours coach autorisé

1. Ouvrir **Épreuves partagées** depuis l'espace coach.
2. Actualiser la liste des épreuves confiées.
3. Ouvrir une épreuve et une manche.
4. Saisir les arrivées, statuts ou corrections autorisées.
5. Laisser au responsable la validation et la publication.

## Sécurité

- Les autorisations sont stockées dans coachs_epreuve_autorises.
- Les RPC contrôlent le rôle actif, l'épreuve et l'autorisation à chaque appel.
- Les RLS ouvrent uniquement l'épreuve, ses manches, ses participants affectés
  et ses résultats au coach autorisé.
- Les inscriptions complètes, les autres épreuves et les autres compétitions ne
  sont pas exposées.
- Le responsable est le seul à ajouter ou retirer un coach.
- La validation et la publication vérifient toujours la propriété de l'épreuve.

## Critères d'acceptation

- Un responsable peut autoriser un coach existant par son pseudo.
- Un pseudo absent, un athlète, un invité ou un compte archivé est refusé.
- Le coach autorisé voit l'épreuve dans **Épreuves partagées**.
- Il peut enregistrer une arrivée et corriger un résultat non publié.
- Il ne peut ni configurer la manche, ni la démarrer, ni valider ou publier.
- Un troisième coach ne voit pas l'épreuve.
- Après révocation, une nouvelle opération du coach retiré est refusée.
- Les actions du responsable continuent de fonctionner.

## Livraison

La migration locale est
supabase/migrations/202611130007_delegation_saisie_resultats.sql.
Elle doit être appliquée et testée sur Supabase staging avant la production.
Les instructions sont dans docs/delegation_saisie_resultats.md.
