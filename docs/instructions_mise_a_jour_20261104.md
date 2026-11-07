# Mise à jour Triathlon — 4 novembre 2026

## Avant installation

Cette version nécessite les nouvelles migrations Supabase. Ne pas considérer une compilation Flutter comme une preuve que la base distante est prête. Sauvegarder le schéma et les données, puis appliquer d'abord en staging avec des comptes de test.

## Ordre des migrations

Après les six migrations 202611020001 à 202611020006 existantes, appliquer dans cet ordre :

1. `202611040001_participants_manches.sql` : affectations, ordre de départ et délai individuel ; raccord du programme athlète ; protection de suppression de compte étendue aux participants.
2. `202611040002_cycle_manche_atomique.sql` : arrivée + chrono atomiques, abandons/DQ, clôture + hors délai + manche suivante.
3. `202611040003_validation_resultats.sql` : validation distincte de publication, révision contrôlée.
4. `202611040020_categories_athletes.sql` : catégories facultatives et accès contrôlés ; extension précise du vérificateur de suppression.
5. `202611040030_policies_production.sql` : droits et protection des rôles. Lire [sécurité Supabase](securite_supabase_production.md) avant application.

Ces scripts supposent le schéma historique utilisé par l'application. Exporter et comparer le vrai schéma avant exécution. Aucun déploiement distant n'a été effectué pendant ces développements.

## Clôture hors écran

La fonction privée `cloturer_delais_expires()` doit être planifiée côté serveur. Activer pg_cron dans Supabase et exécuter depuis SQL Editor avec le rôle administrateur, après validation en staging :

```sql
-- Vérifier les jobs existants avant de créer celui-ci (ne pas dupliquer).
select jobid, jobname, schedule from cron.job
where jobname = 'triathlon-cloture-delais';

select cron.schedule(
  'triathlon-cloture-delais',
  '* * * * *',
  'select public.cloturer_delais_expires();'
);
```

La fréquence ci-dessus est d'une minute : la clôture hors écran peut avoir jusqu'à environ une minute de retard. L'écran coach déclenche aussi la RPC à l'échéance. Ne pas annoncer une exécution serveur à la seconde avec cette planification. Vérifier les journaux `cron.job_run_details`, la reprise et l'absence de doublons avant production.

## Authentification

Suivre [confirmation_email.md](confirmation_email.md) et [recuperation_mot_de_passe.md](recuperation_mot_de_passe.md). Ajouter les URL de confirmation et de récupération des deux environnements dans leurs projets respectifs. Vérifier SMTP, e-mails réels et ouverture Android à froid/à chaud. L'application et les migrations ne configurent pas le fournisseur de courrier.

## Coefficients et statistiques

Voir [coefficients_athletes.md](coefficients_athletes.md). Le barème fourni est enregistré dans le domaine et les catégories sont déclaratives. La formule de pondération reste à confirmer ; aucun classement officiel n'est modifié par un coefficient à ce stade. Les graphiques reposent sur les résultats réels, publiés uniquement côté athlète.

## Publication et confidentialité

Préparer les URL publiques, le support et les durées avec [confidentialite_a_completer.md](confidentialite_a_completer.md), [fiche_play_store.md](fiche_play_store.md) et [android_release.md](android_release.md). L'écran Informations utilise les paramètres `PRIVACY_POLICY_URL`, `ACCOUNT_DELETION_URL` et `SUPPORT_EMAIL` ; ne pas fournir de liens fictifs pour une livraison.

L'identité Android, la clé d'upload, Play App Signing, l'hébergement des pages et les informations du responsable des données restent à renseigner par l'organisateur.

## Vérifications

```powershell
flutter pub get
flutter analyze
flutter test
deno test --allow-read --allow-env --allow-sys supabase/tests supabase/functions/supprimer-compte/handler_test.ts
flutter build apk --debug --flavor production
```

Le contrôle local complet a réussi : **119 tests Flutter et 46 tests serveur/SQL**. Le runtime Deno officiel 2.5.6 a été téléchargé localement dans `.outils-locaux/`, ignoré par Git et absent de l'application livrée. Pour relancer sans installation globale, utiliser `powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\tool\tester_sql.ps1` ; l'option concerne uniquement ce processus PowerShell. Le premier lancement télécharge le runtime depuis les releases officielles Deno. Les scénarios SQL utilisent PGlite et ne remplacent pas la recette sur Supabase réel.

Recetter au minimum : coach propriétaire/autre coach, athlète inscrit/non inscrit, invité ; configuration des participants, ordre, première arrivée, abandon, échéance, fermeture de l'application, reprise, pénalité/bonus, correction, validation/publication, retrait de publication, suppression d'un compte et isolation des données.

Ne passer en production qu'après recette de l'AAB signé via une piste interne Google Play. Le RAF distingue ce qui est fourni dans le dépôt des actions externes encore attendues.
