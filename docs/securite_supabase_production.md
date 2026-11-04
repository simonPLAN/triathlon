# Durcissement Supabase — instruction de déploiement 202611040030

## Ce qui est livré

La migration `supabase/migrations/202611040030_policies_production.sql` active RLS et ajoute des plafonds restrictifs pour profils, compétitions, inscriptions, épreuves, manches et résultats. Les anciennes policies permissives ne peuvent pas élargir ces plafonds. Des policies permissives correspondantes fournissent les accès attendus lorsqu'aucune ancienne policy ne le faisait.

Les autres policies restrictives sont conservées, notamment celles du programme : elles peuvent encore réduire les accès. La migration ne prétend pas remplacer l'audit des policies et fonctions déjà déployées.

Aucune donnée ni compte n’est supprimé par cette migration. Elle ne contient aucune clé privilégiée. Elle ne représente pas un déploiement effectué sur le projet distant.

## Matrice prévue

| Ressource | Athlète connecté | Coach connecté |
|---|---|---|
| Profil complet | Son propre profil uniquement | Son profil et les participants inscrits à ses compétitions |
| Annuaire nominatif | Refusé | RPC retournant seulement id, prénom et nom des comptes athlètes ; invités de ses propres compétitions |
| Compétition | Ouverte, ou non brouillon lorsqu’il est inscrit | Ses compétitions |
| Inscription | Lire la sienne ; créer/supprimer la sienne si ouverte, sans choisir son dossard | Gérer celles de ses compétitions ; ajout/retrait seulement en brouillon/ouvert |
| Épreuves et manches | Programme autorisé, aucune écriture | Gestion de ses compétitions, avec les protections sportives complémentaires |
| Résultats | Manches terminées et publiées de ses compétitions inscrites | Lecture des siens ; écritures directes seulement si non publiés |
| Rôle et identité | Aucun changement de rôle/compte/invité/archive | Aucun changement de rôle/compte/invité/archive |

Les corrections de résultats publiés continuent de passer par leur RPC transactionnelle, qui retire la publication. Les RPC sportives et de suppression restent exécutées côté serveur ; elles ne doivent pas être appelables sans leurs contrôles propres.

L’annuaire nominatif conserve la recherche de comptes existants nécessaire au sélecteur coach. Il n’expose ni e-mail ni catégorie/coefficient ni invités d’un autre organisateur. Cette visibilité doit être expliquée dans la politique de confidentialité et validée selon l’organisation réelle du service.

## Pré-requis et sauvegarde

1. Exporter le schéma initial et les réglages RLS actuellement déployés, sans les inventer à partir des seules migrations.
2. Sauvegarder la base et vérifier la procédure de restauration. Tester ce jeu de migrations sur un projet staging distinct avant production.
3. Appliquer les migrations précédentes, notamment invités (001), suppression de compte (004), corrections (005), programme (006), et les nouvelles migrations sportives et catégories livrées avec cette version.
4. Examiner `supabase/audit_production.sql` en lecture seule sur la base réelle. Sauvegarder les résultats dans un emplacement d’administration sécurisé ; ne pas copier de secrets ni de données de comptes dans Git.
5. Vérifier les propriétaires des tables et fonctions SECURITY DEFINER. Les helpers doivent appartenir à un rôle serveur maîtrisé qui peut lire les tables sans récursion RLS. Ne pas les attribuer à un rôle client.
6. Examiner particulièrement les anciennes fonctions SECURITY DEFINER et leurs droits EXECUTE : un plafond RLS ne limite pas une fonction qui contourne RLS. Retirer ou corriger toute RPC ancienne autorisant des mutations sans contrôle.

La migration échoue si les tables/colonnes prérequises manquent ; ne pas contourner cette erreur par une reconstruction improvisée du schéma de production. Les anciens triggers et policies doivent être comparés à l’export avant correction.

## Application

Dans le SQL Editor du projet staging, exécuter le fichier complet en transaction. Vérifier le résultat, puis le plan de migration appliqué. Utiliser le mécanisme de migration habituel du projet pour l’environnement cible ; ne pas mélanger des versions de fichiers déjà appliqués.

L’application utilise désormais `annuaire_athletes_coach()` pour sa liste coach : déployer la migration avant cette version Flutter, sinon cet écran ne pourra pas charger son annuaire.

## Attribution contrôlée du rôle coach

Tout nouveau profil de compte naît avec le rôle athlete, indépendamment d’une valeur role injectée dans les métadonnées d’inscription. Aucun compte Flutter ne peut promouvoir son propre profil.

Après vérification humaine de la demande, un administrateur peut appeler côté serveur ou depuis SQL Editor :

```sql
select public.attribuer_role_coach('UUID_DU_PROFIL_VERIFIE'::uuid);
```

Cette fonction n’est accordée qu’à service_role, jamais à authenticated/anon. La clé service_role reste uniquement dans le service serveur autorisé ; ne pas l’intégrer à Flutter. Les comptes coach existants sont conservés. La fonction ne s’appuie pas sur une adresse e-mail de confiance saisie par le client ni sur les métadonnées utilisateur.

Un client ne peut pas changer id, compte_id, role, est_invite ou est_archive, y compris via une ancienne RPC utilisée avec un JWT client. Le serveur reste responsable de toute autre RPC privilégiée : auditer les fonctions externes au dépôt et les JWT administrateur.

## Recette minimale sur le projet réel

Utiliser un coach propriétaire, un autre coach, un athlète inscrit, un non inscrit et un accès anonyme. Réaliser chaque requête avec leurs vrais JWT, pas seulement dans SQL Editor sous rôle administrateur.

- Confirmer les lectures du tableau ci-dessus et l’impossibilité d’énumérer les profils complets.
- Tenter une modification directe du rôle, de compte_id, des dossards et des résultats avec un compte athlète ; vérifier le refus serveur.
- Vérifier l’absence de résultat provisoire par SELECT direct et RPC.
- Vérifier la gestion des épreuves/manches, participants, arrivées, corrections et publication par le propriétaire, puis leur refus pour un autre coach.
- Tester inscription/désinscription ouverte puis après démarrage, y compris après affichage périmé et avec deux appareils.
- Vérifier programme et classement publié de l’athlète, retrait de publication après correction, puis republication.
- Vérifier création de compte avec métadonnées role=coach, attribution serveur explicite et connexion selon le rôle obtenu.
- Tester la suppression complète du compte avec les nouveaux liens FK, les triggers et les données sportives existantes.
- Exécuter Security Advisor, vérifier index/performance et conserver un compte rendu sans secrets.

Les tests PGlite fournis exercent des schémas locaux et des policies volontairement trop permissives ; ils ne prouvent pas l’état du schéma initial, du projet Supabase ou de sa restauration. La MFA d’administration, le SMTP et la confirmation e-mail restent des réglages à vérifier séparément.
