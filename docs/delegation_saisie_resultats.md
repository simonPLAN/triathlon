# Délégation de la saisie des résultats

## Fichier à appliquer

Exécuter dans l'éditeur SQL Supabase, après les migrations précédentes :

supabase/migrations/202611130007_delegation_saisie_resultats.sql

La migration crée la table d'autorisations, les fonctions de gestion et les
contrôles RLS nécessaires. Elle ne donne aucun droit de configuration, de
validation ou de publication au coach délégué.

## Vérification staging

Utiliser trois comptes coach et un athlète :

1. Le coach A ouvre une épreuve et ajoute le pseudo du coach B.
2. B actualise **Épreuves partagées** et ouvre l'épreuve.
3. B saisit une arrivée puis corrige un résultat non publié.
4. Vérifier que B ne peut pas configurer, démarrer, valider ou publier.
5. Vérifier que le coach C ne voit pas l'épreuve.
6. A retire B ; sans recréer sa session, B actualise et ne peut plus lire ni
   modifier les données.
7. Vérifier que les résultats déjà saisis restent présents.

## Test serveur local

Le test est fourni dans
supabase/tests/delegation_saisie_resultats_test.ts.

Commande :

    deno test --allow-read --allow-env --allow-sys supabase/tests/delegation_saisie_resultats_test.ts

Deno n'est pas installé dans l'environnement de développement actuel : ce test
reste à exécuter avant le déploiement. L'analyse Flutter et les tests Flutter
passent localement.
