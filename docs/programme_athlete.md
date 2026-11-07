# Programme des compétitions côté athlète

## Accès et affichage

« Voir le programme » est disponible sur les cartes des compétitions ouvertes et des compétitions auxquelles l'athlète est inscrit. Le programme est consultable avant publication de tout résultat, y compris sans résultat enregistré.

La page présente les épreuves dans l'ordre prévu, leur discipline, leur distance en mètres et leurs manches triées par numéro. Chaque manche affiche À venir, En cours, Terminée ou Annulée. Les épreuves sans manche et les compétitions sans épreuve ont un état vide explicite.

Le bouton Actualiser, le glissement de la liste et la reprise de l'application relisent le programme. Les lectures simultanées sont regroupées. Un chargement, une erreur avec nouvelle tentative et un délai maximal de lecture de 20 secondes sont gérés. La page ne contient aucune action de modification, départ, annulation ou publication.

## Affectations et ordre de départ : limite actuelle

Le projet ne possède pas encore de table d'affectation des participants aux manches ni de stockage de leur ordre de départ. La migration fournie n'invente donc aucune participation à partir d'une inscription ou d'un résultat :
- `affectations_disponibles` vaut false ;
- `participe` et `ordre_depart` restent null pour chaque manche ;
- l'interface affiche « Participation à cette manche non définie » et « Ordre de départ non défini ».

Les modèles, le mapping et les composants sont prêts pour les données futures :
- `participe=true` : « Tu participes à cette manche » ;
- `participe=false` : « Tu n’es pas affecté à cette manche » ;
- `participe=null` : participation inconnue ;
- `ordre_depart` fourni : affichage du numéro de départ personnel.

Ces branches sont testées avec des données simulées. Pour les activer réellement, il faudra implémenter l'affectation et l'ordre côté coach, les persister et adapter la RPC pour lire exclusivement les informations de l'athlète connecté. L'affichage conditionnel est fourni ; la gestion et la source de ces données restent à faire.

## Autorisations Supabase

Appliquer `supabase/migrations/202611020006_programme_athlete.sql` après les migrations précédentes, avant utilisation de cette version.

La RPC de lecture `programme_competition_athlete(p_competition_id)` :
- exige un athlète connecté possédant un profil lié à un vrai compte ;
- autorise les compétitions ouvertes même sans inscription ;
- autorise les compétitions en cours, terminées ou annulées si l'athlète est inscrit ;
- refuse les brouillons, même si une inscription existe ;
- refuse les utilisateurs anonymes, les profils invités sans compte et les identifiants inaccessibles ;
- retourne uniquement les données du programme, aucune identité d'un autre participant, aucun résultat, temps ou point.

La fonction est stable, SECURITY DEFINER avec search_path vide, et son exécution est accordée uniquement au rôle authenticated. Aucun identifiant d'athlète n'est accepté comme paramètre : l'identité provient de auth.uid().

La migration active RLS sur epreuves et manches et ajoute des policies restrictives :
- lecture limitée aux programmes accessibles ; le coach propriétaire garde ses accès ;
- insertion, modification et suppression interdites aux athlètes ;
- les restrictions s'appliquent également aux anciennes policies anonymes éventuelles ;
- seuls les coachs propriétaires satisfont le contrôle d'écriture, sans élargissement des policies permissives existantes.

Les helpers de policies accordés à anon ne renvoient que des booléens faux en l'absence d'identité et n'accordent aucun accès aux lignes. La RPC de programme reste inaccessible à anon. Les fonctions SQL privilégiées de gestion existantes et les autres tables restent à auditer dans la recette globale.

## Architecture

- Domaine : `ProgrammeCompetition`, `EpreuveProgramme`, `MancheProgramme` et port de lecture `ProgrammeCompetitionRepository`.
- Application : `ConsulterProgrammeCompetition`, validation de l'identifiant et tri déterministe.
- Infrastructure : adaptateur Supabase dédié et RPC à colonnes explicites, sans dépendance à la publication des résultats.
- Présentation : contrôleur de chargement propre à la page et cartes d'épreuve réutilisant les composants communs et les badges de statut.

La composition de production est dans main.dart. Le contrôleur de compétitions transmet le cas d'utilisation au nouvel écran ; les contrôleurs du coach ne sont pas utilisés pour charger ce programme.

## Vérifications et déploiement

Les tests Flutter couvrent le tri, les quatre statuts, les données inconnues, les futures affectations fournies, les erreurs/reprises, l'actualisation et l'ouverture depuis une compétition non inscrite. Les tests HTTP vérifient la RPC et son mapping. Les tests PostgreSQL embarqué exécutent la migration sur un schéma contractuel avec des policies permissives volontairement larges : accès avant publication, inscriptions, brouillons, anonymes, refus d'écriture athlète et maintien des droits du coach propriétaire.

```powershell
flutter analyze
flutter test
deno test --allow-read --allow-env --allow-sys supabase/tests/programme_athlete_test.ts
```

Sur staging puis avant release :
1. Appliquer la migration et contrôler les politiques et grants réellement installés.
2. Tester deux athlètes (inscrit et non inscrit), deux coachs et un accès anonyme.
3. Vérifier une compétition ouverte sans aucun résultat publié.
4. Changer un statut de manche côté coach puis actualiser côté athlète.
5. Fermer les inscriptions : le non-inscrit doit perdre l'accès au programme fermé lors de la prochaine lecture.
6. Vérifier que les accès coach à ses propres épreuves/manches restent opérationnels.
7. Tester des appels directs INSERT/UPDATE/DELETE avec le token athlète ; les restrictions doivent rester effectives.
8. Tester une erreur réseau, la reprise de l'application et une liste vide sur appareil réel.

Le schéma initial complet n'étant pas versionné, les tests locaux ne prouvent ni le déploiement ni les règles de toute la base Supabase. L'application des migrations et la recette multiappareil restent à effectuer.
