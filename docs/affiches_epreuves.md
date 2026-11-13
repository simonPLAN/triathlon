# Instructions — Affiches privées des épreuves

## Objet

La migration
`supabase/migrations/202611130001_affiches_epreuves.sql` prépare DEM-003 :

- zéro à deux affiches par épreuve ;
- JPEG, PNG ou WebP ;
- 5 Mo et 4096 × 4096 maximum ;
- texte alternatif obligatoire de 3 à 300 caractères ;
- bucket privé ;
- lecture suivant le droit de consulter l'épreuve ;
- écriture réservée au coach responsable tant que la compétition est en
  brouillon ;
- conservation des affiches des compétitions terminées ou annulées ;
- remplacement sans écraser l'objet actuellement publié.

La migration n'est pas appliquée automatiquement à Supabase.

## Prérequis

Appliquer auparavant les migrations du projet, en particulier :

1. gestion des épreuves ;
2. programme athlète ;
3. participants de manches ;
4. catégories d'athlètes ;
5. politiques de production ;
6. groupes d'athlètes.

Avant la production :

- exporter le schéma et les policies réellement présents ;
- comparer la base distante aux migrations versionnées ;
- sauvegarder la base ;
- utiliser d'abord un projet staging ;
- vérifier que le bucket `affiches-epreuves` n'existe pas avec un usage
  différent.

## Objets créés

### Bucket privé

`affiches-epreuves` :

- `public = false` ;
- limite de 5 242 880 octets ;
- types autorisés : `image/jpeg`, `image/png`, `image/webp`.

### Table

`public.affiches_epreuve` conserve les métadonnées finalisées. La FK vers
`epreuves` est volontairement `ON DELETE RESTRICT` : une épreuve ne peut pas
être supprimée tant que ses affiches n'ont pas été retirées proprement via
l'API Storage.

La référence `cree_par` devient nulle si le compte coach est supprimé. Les
affiches restent rattachées à l'épreuve transférée au profil technique.

### Fonctions applicatives

- `enregistrer_affiche_epreuve` finalise un nouvel objet ou remplace une
  position ;
- `reordonner_affiches_epreuve` inverse les deux positions ;
- `supprimer_affiche_epreuve` retire les métadonnées et promeut la position 2 ;
- `modifier_texte_alternatif_affiche_epreuve` modifie uniquement le texte d’une affiche appartenant à l’épreuve contrôlée ;
- `lister_objets_affiches_orphelins` est réservée au `service_role`.

### Autorisations

Les métadonnées et objets finalisés sont lisibles uniquement par un utilisateur
authentifié autorisé à consulter l'épreuve. Aucun droit anonyme n'est ajouté.

L'insertion et la suppression d'objets sont permises uniquement dans un chemin
appartenant à une épreuve modifiable par le coach connecté. Aucun `UPDATE`
Storage n'est accordé.

## Convention de chemin

Chaque objet utilise un identifiant généré :

```text
<competition_uuid>/<epreuve_uuid>/<objet_uuid>.<extension>
```

Le nom de fichier local ne doit jamais être envoyé dans le chemin.

## Cycle d'envoi

### Nouvelle affiche

1. Le client valide localement le décodage, le format, la taille et les
   dimensions.
2. Il génère un nouvel UUID et envoie l'objet dans le bucket privé.
3. L'objet temporaire n'est pas lisible par les lecteurs, car aucune métadonnée
   finalisée ne le référence encore.
4. Il appelle `enregistrer_affiche_epreuve`.
5. La RPC compare le chemin, le MIME et la taille aux métadonnées Storage.
6. Après succès, l'objet devient lisible selon les droits de l'épreuve.

### Remplacement

1. Envoyer un nouvel objet avec un nouvel UUID.
2. Finaliser la même position.
3. La RPC retourne `ancien_objet_path`.
4. Supprimer l'ancien objet via l'API Storage seulement après la réussite.
5. Si l'envoi ou la finalisation échoue, l'affiche précédente reste publiée.

### Texte alternatif

Appeler `modifier_texte_alternatif_affiche_epreuve` avec les identifiants de l’affiche et de l’épreuve. La RPC vérifie le propriétaire, le statut brouillon, la correspondance affiche/épreuve et la longueur de 3 à 300 caractères. Aucune policy `UPDATE` directe n’est accordée.

### Suppression

1. Appeler `supprimer_affiche_epreuve` et récupérer le chemin.
2. Supprimer cet objet via l'API Storage avant de supprimer l'épreuve.
3. En cas d'échec Storage, conserver le chemin dans la reprise locale ou laisser
   le traitement serveur des orphelins le nettoyer.

### Nettoyage

Un traitement serveur authentifié avec la clé privilégiée, jamais Flutter, doit
appeler `lister_objets_affiches_orphelins` puis supprimer les objets retournés
avec l'API Storage.

Le seuil par défaut est 24 heures. Ne jamais supprimer directement une ligne
`storage.objects` en SQL : cela ne garantit pas la suppression du fichier
physique.

## Limite de validation serveur

PostgreSQL peut contrôler le MIME et la taille enregistrés par Storage, mais ne
peut pas décoder le contenu binaire de l'objet.

Pour satisfaire complètement le refus d'un faux fichier image :

- le client doit décoder l'image avant envoi ;
- un traitement serveur/Edge Function doit vérifier la signature et le décodage
  avant d'appeler la finalisation si une validation indépendante du client est
  exigée.

La migration ne prétend pas réaliser ce décodage binaire.

## Application

Dans Supabase SQL Editor ou via la procédure de migration habituelle :

1. sélectionner le projet staging ;
2. appliquer `202611130001_affiches_epreuves.sql` ;
3. recharger le cache API si l'outil le demande ;
4. vérifier le bucket, la table, les fonctions et les policies ;
5. exécuter la recette multi-comptes ;
6. appliquer en production uniquement après validation.

## Vérifications

### Structure

- bucket privé, limite et MIME corrects ;
- RLS active sur `affiches_epreuve` ;
- aucune policy anonyme ;
- aucune policy Storage `UPDATE` ;
- contraintes de position, taille, dimensions et texte alternatif présentes ;
- `verifier_schema_suppression_compte()` réussit avec le schéma attendu.

### Comptes

Tester séparément :

- coach propriétaire, compétition brouillon : lecture et écriture ;
- coach propriétaire, compétition ouverte/terminée/annulée : lecture seule ;
- autre coach : lecture uniquement si les règles de visibilité de l'épreuve
  l'autorisent, jamais écriture ;
- athlète inscrit autorisé : lecture ;
- athlète non inscrit : aucun accès ;
- session absente : aucun accès ;
- service role : liste des orphelins uniquement depuis un traitement serveur.

### Cas fonctionnels

- aucune, une et deux affiches ;
- troisième position refusée ;
- remplacement réussi et échoué ;
- modification du texte alternatif par le propriétaire et refus des autres rôles ;
- promotion de la deuxième affiche ;
- inversion simultanée des positions ;
- MIME, extension, taille, dimensions et texte invalides ;
- double finalisation et concurrence ;
- suppression d'une épreuve avec affiches refusée ;
- nettoyage d'un objet temporaire ancien ;
- suppression du compte coach sans perte des affiches historiques.

## Retour arrière

Le retour arrière doit être préparé selon les données déjà utilisées :

1. désactiver l'ajout d'affiches dans les clients ;
2. exporter `affiches_epreuve` et la liste des objets ;
3. supprimer les objets via l'API Storage ;
4. supprimer les policies et fonctions propres aux affiches ;
5. supprimer la table ;
6. supprimer le bucket seulement lorsqu'il est vide ;
7. restaurer la version précédente de
   `verifier_schema_suppression_compte`.

Ne pas supprimer la table ou le bucket avant d'avoir vérifié les objets et les
références encore utilisés.

## État

- Migration locale : préparée.
- Tests SQL : 56 réussis, dont 8 dédiés aux affiches, le 13 novembre 2026.
- Tests Flutter : 133 réussis le 13 novembre 2026.
- Analyse Flutter : aucune anomalie le 13 novembre 2026.
- Recette visuelle Android/web : à effectuer.
- Staging : non appliqué.
- Production : non appliquée.
