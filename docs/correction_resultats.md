# Saisie manuelle et correction des résultats

## Parcours coach

Ouvrir les résultats d'une manche **terminée** :
- « Saisir un résultat manuel » permet de choisir un participant inscrit. Si son résultat existe, il est proposé en correction ; sinon un résultat est créé.
- Le crayon sur une ligne corrige directement son temps, sa place, son statut et son commentaire.
- Les arrivées en direct conservent leur grille tactile pendant la course. Les corrections sont différées à la fin pour ne pas rejouer le chronomètre ou l'enchaînement des manches.

Le temps se saisit en `minutes:secondes.millisecondes` : `05:23.450`, `120:01.200`. Les secondes seules sans fraction sont acceptées (`01:02`) ainsi que la virgule décimale. Les durées valides vont de zéro à sept jours ; les secondes doivent être entre 00 et 59. Le temps total produit une heure d'arrivée = départ + durée, en UTC côté stockage. Un temps atteignant ou dépassant l'heure limite de la manche impose le statut Hors délai.

Le coach choisit :
- **Décaler les autres places** : retirer l'athlète de son ancienne place puis l'insérer à la place demandée. Les athlètes entre ces places sont décalés.
- **Échanger deux places** : échanger l'athlète déjà classé avec le détenteur de la place demandée.
- **Classer par temps** : retrier toutes les arrivées selon le temps total. À temps égal, conserver l'ordre des places précédentes, puis départager par identifiant ; une nouvelle arrivée est placée après les arrivées existantes de même temps.

Les places sont renumérotées de 1 à N et le barème est recalculé : 5, 4, 3, 2, 1, puis zéro point. Les autres statuts ont zéro point et aucun temps/place/écart. Un changement de statut vers abandon, disqualification ou hors délai retire l'athlète du classement des arrivées et resserre les places.

Les temps des autres athlètes ne sont jamais échangés ou déplacés avec leur place. Le classement manuel est prioritaire sur l'ordre chronométrique. L'écart au premier **classé** est recalculé et peut donc être négatif si un athlète placé derrière a un temps plus court. C'est affiché explicitement dans le formulaire et les cartes. Les pénalités/bonus ne sont pas implémentés par cette correction.

Les anciens résultats arrivés sans temps peuvent être complétés un par un. Un écart reste inconnu si le temps concerné ou celui du premier manque ; la publication est refusée tant qu'une arrivée n'a pas de temps.

## Publication après correction

Une correction de résultats déjà publiés nécessite la confirmation explicite du retrait de **toute la manche**. La transaction :
1. Retire la publication de la manche.
2. Applique le reclassement et recalcule points et écarts.
3. Efface les dates de publication de tous les résultats de la manche.
4. Renvoie tout le classement corrigé au coach.

Aucune republication automatique. Le coach vérifie le classement puis utilise « Publier le classement » sur la page ou la publication individuelle/groupée existante. La publication passe désormais par une RPC qui vérifie le propriétaire, la révision, les places et les temps, et renseigne les dates de publication dans la même transaction.

Les athlètes ne retrouvent les résultats corrigés dans les requêtes de résultats publiés qu'après cette republication. Un écran déjà chargé sur un autre appareil doit être actualisé ; aucun effacement distant de son cache d'écran n'est annoncé.

Les classements d'épreuve et de compétition sont calculés à partir des points par manche, sans table de totaux persistés à corriger séparément. Les vues cumulées prennent en compte les nouveaux points au prochain chargement.

## Cohérence et concurrence

Installer `supabase/migrations/202611020005_corrections_resultats.sql` après les migrations précédentes, avant d'utiliser cette version de l'application.

La RPC `editer_resultat_manche` :
- vérifie auth.uid(), le rôle coach et la propriété de la compétition ;
- exige une manche terminée et un départ connu ;
- verrouille la manche et ses résultats ;
- refuse une révision devenue périmée ; l'interface demande alors une actualisation ;
- vérifie le participant, le statut, la place, le temps et le consentement de dépublication ;
- utilise une contrainte UNIQUE(manche_id, position) différable uniquement pendant le reclassement, vérifiée avant retour ;
- applique toutes les modifications dans une transaction PostgreSQL et renvoie le classement complet, sans lecture séparée après écriture.

Un trigger de révision s'applique également aux arrivées directes. Des policies restrictives empêchent les corrections directes des résultats de manches terminées avec le rôle authenticated ; elles n'accordent aucun droit supplémentaire aux policies existantes. La publication directe par un PATCH client est refusée au profit de la RPC vérifiée.

Les positions dupliquées déjà présentes font échouer la migration pour permettre une reprise contrôlée. Le contrôle simple « écart >= 0 » est remplacé par un écart signé borné. Si une contrainte CHECK inconnue mélange les écarts avec d'autres règles, la migration s'arrête : auditer cette contrainte plutôt que la supprimer aveuglément. Les index uniques ordinaires/partiels sur manche+position sont remplacés sans toucher à l'unique athlète/manche. Auditer aussi tout index ou trigger particulier du schéma initial, qui n'est pas entièrement versionné dans ce dépôt.

Une erreur de contrainte, de droit, de révision ou une panne annule le reclassement et la dépublication. Si la réponse réseau est perdue après commit, actualiser avant de réessayer : le contrôle de révision évite de rejouer une correction sur un ancien classement.

## Compatibilité avec la suppression de compte

La suppression d'un compte reste possible après publication de ses résultats. Lorsqu'un résultat publié est supprimé par le traitement serveur du compte, le trigger retire la publication de la manche et efface les dates de publication restantes, sans modifier les performances des autres participants. Le coach doit vérifier et reclasser les places restantes avant de republier. Les protections de suppression du compte et de résultats s'exécutent dans la même transaction.

## Vérifications

Les tests Flutter couvrent le format temporel, la validation métier, les confirmations, le classement complet renvoyé et les doubles soumissions. Les tests HTTP locaux vérifient les paramètres RPC, la révision et le traitement des conflits.

Les tests PostgreSQL embarqué PGlite exécutent la migration réelle sur un schéma contractuel : décalage, échange, temps manuel, disqualification, publication/correction/republication, droits, révision périmée, rollback, unicité, réexécution et compatibilité avec la suppression de compte. Ils ne remplacent pas les tests sur le schéma Supabase effectivement déployé.

```powershell
flutter analyze
flutter test
deno test --allow-read --allow-env --allow-sys supabase/tests/corrections_resultats_test.ts
```

Avant release, appliquer sur staging et vérifier :
- une correction concurrente depuis deux appareils coach : une ancienne révision doit être refusée ;
- l'accès direct par un athlète et par un autre coach ;
- les écarts signés avec les CHECK du schéma réel ;
- le retrait des résultats côté athlète, puis leur retour après republication ;
- les données historiques, temps manquants, ex aequo et comptes supprimés ;
- les RPC et policies de lecture existantes ne doivent pas exposer les résultats dépubliés.

Le déploiement Supabase et la recette multiappareil restent à réaliser.
