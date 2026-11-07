# Application de gestion de compétitions sportives

Application mobile Flutter destinée à organiser et suivre des compétitions composées de plusieurs
épreuves et manches.

Le projet distingue deux rôles :

- **Coach / arbitre** : crée les compétitions, configure les épreuves et les manches, attribue les
  dossards, démarre les manches, saisit les arrivées, corrige et publie les résultats.
- **Athlète** : consulte les compétitions ouvertes, s’inscrit ou se désinscrit, consulte son dossard
  et les résultats publiés.

Le projet cible d’abord **Android**. Une version iOS pourra être ajoutée ultérieurement grâce à
Flutter.

---

## 1. Technologies

- **Flutter** et **Dart** pour l’application mobile.
- **Supabase Authentication** pour les comptes utilisateurs.
- **Supabase PostgreSQL** pour les données.
- **Row Level Security**, ou RLS, pour les autorisations côté base.
- **Architecture hexagonale** pour séparer le domaine, les cas d’utilisation, l’infrastructure et
  l’interface.
- **Material 3** pour l’interface Flutter.

---

## 2. Objectifs fonctionnels

### Parcours coach

```text
Connexion coach
→ tableau de bord
→ création d’une compétition
→ configuration des épreuves
→ génération des manches
→ ouverture des inscriptions
→ consultation des athlètes inscrits
→ attribution des dossards
→ démarrage de la compétition
→ démarrage d’une manche
→ saisie directe des arrivées
→ déclenchement du délai après le premier arrivé
→ classement et calcul des points
→ gestion des hors délai
→ correction des résultats
→ publication des résultats
```

### Parcours athlète

```text
Création du compte athlète
→ connexion
→ consultation des compétitions ouvertes
→ inscription personnelle
→ consultation du statut d’inscription
→ consultation du dossard attribué par le coach
→ désinscription tant que la compétition est ouverte
→ consultation future des résultats publiés
```

---

## 3. Architecture

Le projet utilise une architecture hexagonale.

```text
lib/
├── application/
│   └── use_cases/
├── domain/
│   ├── entities/
│   ├── ports/
│   └── services/
├── infrastructure/
│   └── repositories/
│       └── supabase/
└── presentation/
    ├── controllers/
    ├── pages/
    ├── widgets/
    ├── navigation/
    └── theme/
```

### Domaine

Le dossier `domain` contient les règles métier et ne dépend ni de Flutter ni de Supabase.

### Application

Le dossier `application` orchestre les opérations métier avec des cas d’utilisation.

### Infrastructure

Le dossier `infrastructure` contient les implémentations Supabase, les requêtes et les conversions
de données.

### Présentation

Le dossier `presentation` contient les contrôleurs Flutter, les pages et les widgets.

Cette séparation permettra de refaire complètement l’interface sans réécrire le domaine ou les accès
Supabase.

---

## 4. Arborescence fonctionnelle

```text
lib/
├── application/
│   └── use_cases/
│       ├── auth/
│       ├── competition/
│       ├── inscription/
│       ├── epreuve/
│       ├── manche/
│       └── resultat/
│
├── domain/
│   ├── entities/
│   │   ├── athlete.dart
│   │   ├── profil_utilisateur.dart
│   │   ├── role_utilisateur.dart
│   │   ├── competition.dart
│   │   ├── statut_competition.dart
│   │   ├── inscription.dart
│   │   ├── epreuve.dart
│   │   ├── type_discipline.dart
│   │   ├── manche.dart
│   │   ├── statut_manche.dart
│   │   ├── resultat.dart
│   │   └── statut_resultat.dart
│   │
│   ├── ports/
│   │   ├── auth_repository.dart
│   │   ├── profil_repository.dart
│   │   ├── athlete_repository.dart
│   │   ├── competition_repository.dart
│   │   ├── inscription_repository.dart
│   │   ├── epreuve_repository.dart
│   │   ├── manche_repository.dart
│   │   └── resultat_repository.dart
│   │
│   └── services/
│       └── calcul_points.dart
│
├── infrastructure/
│   └── repositories/
│       └── supabase/
│           ├── auth_repository_supabase.dart
│           ├── profil_repository_supabase.dart
│           ├── athlete_repository_supabase.dart
│           ├── competition_repository_supabase.dart
│           ├── inscription_repository_supabase.dart
│           ├── epreuve_repository_supabase.dart
│           ├── manche_repository_supabase.dart
│           └── resultat_repository_supabase.dart
│
└── presentation/
    ├── controllers/
    │   ├── athlete_controller.dart
    │   ├── competition_controller.dart
    │   ├── competitions_ouvertes_controller.dart
    │   ├── inscription_controller.dart
    │   ├── epreuve_controller.dart
    │   ├── manche_controller.dart
    │   └── resultat_controller.dart
    │
    ├── pages/
    │   ├── auth/
    │   ├── athlete/
    │   ├── coach/
    │   ├── competition/
    │   ├── inscription/
    │   ├── epreuve/
    │   ├── manche/
    │   └── resultat/
    │
    └── widgets/
        ├── competition/
        ├── inscription/
        ├── epreuve/
        ├── manche/
        └── resultat/
```

---

## 5. Modèle de données

```text
profils
  ├── competitions créées par le coach
  └── inscriptions de l’athlète

competitions
  ├── inscriptions
  └── epreuves
        └── manches
              └── resultats
```

Relations principales :

```text
profils.id                 → auth.users.id
competitions.coach_id      → profils.id
inscriptions.competition_id→ competitions.id
inscriptions.athlete_id    → profils.id
epreuves.competition_id    → competitions.id
manches.epreuve_id         → epreuves.id
resultats.manche_id        → manches.id
resultats.athlete_id       → profils.id
```

---

## 6. Tables Supabase

### `profils`

Représente les comptes applicatifs.

Champs principaux :

```text
id
prenom
nom
role
created_at / date_creation
updated_at / date_modification
```

Rôles :

```text
coach
athlete
```

### `competitions`

```text
id
nom
description
lieu
date_competition
statut
coach_id
demarrage_automatique_manche_suivante
date_creation
date_modification
```

### `inscriptions`

```text
id
competition_id
athlete_id
numero_dossard
date_inscription
```

Contraintes attendues :

```sql
unique (competition_id, athlete_id)
unique (competition_id, numero_dossard)
```

### `epreuves`

```text
id
competition_id
discipline
nom
distance_metres
nombre_manches
ordre
duree_limite_secondes
date_creation
date_modification
```

### `manches`

```text
id
epreuve_id
numero
statut
heure_depart
heure_premiere_arrivee
heure_fin_delai
resultats_publies
date_creation
date_modification
```

### `resultats`

```text
id
manche_id
athlete_id
position
points
heure_arrivee
temps_total_millisecondes
ecart_premier_millisecondes
statut
commentaire
date_publication
date_creation
date_modification
```

Contraintes attendues :

```sql
unique (manche_id, athlete_id)
unique (manche_id, position)
```

---

## 7. Statuts et valeurs métier

### Statut d’une compétition

```dart
enum StatutCompetition {
  brouillon,
  ouverte,
  enCours,
  terminee,
  annulee,
}
```

Cycle principal :

```text
Brouillon
→ Ouverte
→ En cours
→ Terminée
```

Une compétition peut également être annulée.

### Discipline

```dart
enum TypeDiscipline {
  natation,
  velo,
  courseAPied,
}
```

Correspondance Supabase :

```text
natation    ↔ natation
velo        ↔ velo
courseAPied ↔ course_a_pied
```

### Statut d’une manche

```dart
enum StatutManche {
  aVenir,
  enCours,
  terminee,
  annulee,
}
```

### Statut d’un résultat

```dart
enum StatutResultat {
  arrive,
  horsDelai,
  abandon,
  disqualifie,
}
```

---

## 8. Authentification et rôles

### Création d’un compte athlète

Un compte créé depuis l’application reçoit les métadonnées :

```dart
data: {
'prenom': prenom,
'nom': nom,
}
```

Un trigger Supabase crée ensuite automatiquement une ligne dans `profils` avec :

```text
role = athlete
```

### Création d’un coach

L’inscription publique crée uniquement des athlètes. Le premier coach peut être créé en modifiant
son rôle depuis Supabase :

```sql
update public.profils
set role = 'coach'
where id = 'UUID_DU_COMPTE';
```

---

## 9. Gestion des compétitions

Le coach peut :

- créer une compétition ;
- modifier une compétition ;
- supprimer une compétition en brouillon ;
- ouvrir les inscriptions ;
- démarrer la compétition ;
- terminer la compétition ;
- annuler la compétition ;
- configurer le démarrage automatique de la manche suivante.

### Démarrage automatique de la manche suivante

Champ Supabase :

```sql
demarrage_automatique_manche_suivante boolean
not null
default false
```

Ajout SQL :

```sql
alter table public.competitions
add column if not exists
demarrage_automatique_manche_suivante boolean
not null
default false;
```

Comportement :

- `false` : le coach démarre manuellement chaque manche ;
- `true` : lorsque la manche courante est terminée, la manche suivante de la même épreuve démarre
  automatiquement ;
- si aucune manche suivante n’existe, l’épreuve est terminée sans démarrage supplémentaire.

L’option est présentée au coach avec un `SwitchListTile.adaptive` dans le formulaire de compétition.

---

## 10. Gestion des inscriptions

### Côté athlète

L’athlète peut :

- consulter les compétitions ouvertes ;
- s’inscrire lui-même ;
- vérifier son inscription ;
- consulter son dossard ;
- se désinscrire tant que la compétition est ouverte.

L’identifiant de l’athlète vient de la session Supabase :

```dart

final utilisateur = client.auth.currentUser;
```

L’interface ne permet donc pas à un athlète de choisir l’identifiant d’un autre profil.

### Côté coach

Le coach peut :

- consulter les inscrits d’une compétition ;
- attribuer ou modifier les dossards ;
- retirer un dossard ;
- désinscrire un athlète selon les règles autorisées.

---

## 11. Gestion des épreuves

Une épreuve appartient à une compétition.

Exemples :

```text
Natation 100 m
Vélo 25 km
Course à pied 5 km
```

Configuration :

```text
discipline
distance
nombre de manches
ordre dans la compétition
durée limite après le premier arrivé
```

Règles principales :

```text
distanceMetres > 0
nombreManches > 0
ordre > 0
dureeLimiteSecondes > 0
```

La création et la modification des épreuves sont limitées à une compétition en brouillon.

---

## 12. Gestion des manches

Les manches sont générées à partir de :

```dart
epreuve.nombreManches
```

Exemple :

```text
nombreManches = 4
→ Manche 1
→ Manche 2
→ Manche 3
→ Manche 4
```

À la création :

```text
statut = a_venir
resultats_publies = false
```

### Cycle d’une manche

```text
À venir
→ En cours
→ Terminée
→ Résultats publiés
```

Une manche peut aussi être annulée.

### Règles

- seule une manche à venir peut être démarrée ;
- une seule manche d’une même épreuve peut être en cours ;
- les manches précédentes doivent être terminées ou annulées avant de démarrer une manche suivante ;
- l’heure d’arrivée ne peut pas précéder l’heure de départ ;
- les comparaisons temporelles sont réalisées en UTC ;
- l’affichage utilise l’heure locale ;
- les résultats ne peuvent être publiés qu’après la fin de la manche.

---

## 13. Interface de compétition en direct

Le parcours opérationnel est :

```text
Compétition
→ Épreuve
→ Manche
→ Démarrer la manche
→ Saisir les arrivées
```

La page de détail d’une manche affiche :

- le numéro de manche ;
- le statut ;
- l’heure de départ ;
- l’heure de la première arrivée ;
- l’heure de fin du délai ;
- le statut de publication ;
- le compte à rebours ;
- les actions disponibles ;
- le bouton de saisie des arrivées.

---

## 14. Saisie rapide des arrivées

L’objectif est d’éviter une succession de boutons et de fenêtres pendant une compétition.

### Interface cible

Tous les participants non arrivés sont visibles directement sous forme de cartes ou de boutons :

```text
[Dossard 12 - Maxime]
[Dossard 24 - Julie]
[Dossard 31 - Alex]
```

Un appui sur un participant :

```text
→ enregistre l’heure actuelle
→ attribue la prochaine position
→ calcule les points
→ retire le participant de la liste des non-arrivés
→ ajoute le participant au classement
```

Tri recommandé :

1. participants sans résultat, par numéro de dossard ;
2. participants arrivés, par position ;
3. hors délai, abandons et disqualifications à la fin.

Le premier athlète sélectionné devient automatiquement premier et déclenche le délai.

---

## 15. Première arrivée et compte à rebours

Au premier résultat enregistré :

```text
heure_premiere_arrivee = maintenant
heure_fin_delai = heure_premiere_arrivee + duree_limite_secondes
position = 1
écart avec le premier = 0
```

Le compte à rebours se met ensuite à jour chaque seconde.

À zéro :

```text
Délai écoulé
→ possibilité de clôturer le délai
→ participants restants marqués hors délai
→ zéro point
→ manche terminée
```

---

## 16. Classement et points

Barème temporaire :

```text
1er → 5 points
2e  → 4 points
3e  → 3 points
4e  → 2 points
5e  → 1 point
6e et suivants → 0 point
```

Service métier :

```text
lib/domain/services/calcul_points.dart
```

Le barème pourra être rendu configurable ultérieurement.

### Calcul du temps

```text
temps total = heure d’arrivée - heure de départ
écart premier = heure d’arrivée - heure de première arrivée
```

Les valeurs sont stockées en millisecondes.

---

## 17. Hors délai

À l’expiration du délai, les athlètes inscrits sans résultat peuvent être enregistrés en groupe
avec :

```text
position = null
points = 0
statut = hors_delai
heure_arrivee = null
```

Le cas d’utilisation recharge les résultats existants et évite de créer des doublons.

---

## 18. Correction des résultats

Le coach doit pouvoir corriger :

- la position ;
- les points ;
- le statut ;
- le commentaire.

Règles :

### Arrivé

```text
position obligatoire
points >= 0
```

### Hors délai, abandon ou disqualification

```text
position = null
points = 0
```

La contrainte Supabase empêche deux résultats pour le même athlète dans une même manche.

---

## 19. Publication

Les résultats peuvent être publiés uniquement lorsque la manche est terminée.

```text
resultats_publies = true
```

Une évolution prévue permettra à l’athlète de consulter :

- ses résultats ;
- son classement par manche ;
- ses points ;
- le classement cumulé de la compétition.

---

## 20. Sécurité Supabase

Toutes les tables métier utilisent RLS.

Principes :

- les utilisateurs authentifiés peuvent lire les ressources autorisées ;
- un coach modifie uniquement ses compétitions et leurs données associées ;
- un athlète inscrit uniquement son propre profil ;
- un athlète ne choisit pas son dossard ;
- l’inscription et la désinscription sont limitées aux compétitions ouvertes ;
- les doublons sont protégés par des contraintes PostgreSQL.

Exemple d’auto-inscription :

```sql
create policy "Athlete inscrit son propre profil"
on public.inscriptions
for insert
to authenticated
with check (
  athlete_id = auth.uid()
  and numero_dossard is null
  and exists (
    select 1
    from public.profils
    where profils.id = auth.uid()
      and profils.role = 'athlete'
  )
  and exists (
    select 1
    from public.competitions
    where competitions.id = inscriptions.competition_id
      and competitions.statut = 'ouverte'
  )
);
```

---

## 21. Installation

### Prérequis

- Flutter stable ;
- Dart fourni avec Flutter ;
- Android Studio ;
- SDK Android ;
- compte Supabase ;
- appareil Android ou émulateur.

### Installer les dépendances

```powershell
flutter pub get
```

### Vérifier l’environnement

```powershell
flutter doctor
```

### Vérifier le code

```powershell
dart format lib
flutter analyze
```

### Lancer l’application

```powershell
flutter run
```

---

## 22. Configuration Supabase

L’initialisation se fait normalement dans `main.dart` :

```dart
await
Supabase.initialize
(
url: 'SUPABASE_URL',
anonKey: 'SUPABASE_ANON_KEY',
);
```

Ne jamais mettre la clé `service_role` dans l’application Flutter.

Une configuration plus sûre utilise `--dart-define` :

```powershell
flutter run `
  --dart-define=SUPABASE_URL=VOTRE_URL `
  --dart-define=SUPABASE_ANON_KEY=VOTRE_CLE_ANON
```

---

## 23. Commandes utiles

```powershell
# Formater
 dart format lib

# Analyser
 flutter analyze

# Nettoyer
 flutter clean

# Restaurer les dépendances
 flutter pub get

# Lancer
 flutter run

# Tester
 flutter test

# Construire un APK de test
 flutter build apk
```

---

## 24. Scénario de test complet

### Préparation

1. créer un compte coach ;
2. créer au moins deux comptes athlètes ;
3. créer une compétition en brouillon ;
4. choisir le démarrage automatique ou manuel des manches ;
5. créer une épreuve ;
6. générer les manches ;
7. ouvrir les inscriptions.

### Inscription

1. se connecter avec un compte athlète ;
2. ouvrir l’espace athlète ;
3. s’inscrire à la compétition ;
4. répéter avec les autres comptes ;
5. reconnecter le coach ;
6. attribuer les dossards.

### Compétition

1. démarrer la compétition ;
2. ouvrir une épreuve ;
3. ouvrir la première manche ;
4. démarrer la manche ;
5. ouvrir la saisie des arrivées ;
6. appuyer sur le premier participant ;
7. vérifier le déclenchement du délai ;
8. appuyer sur les autres participants ;
9. attendre la fin du délai ;
10. marquer les participants restants hors délai ;
11. terminer la manche ;
12. vérifier le démarrage automatique éventuel de la suivante ;
13. publier les résultats.

---

## 25. Tests métier recommandés

### Compétition

- impossible de supprimer une compétition non brouillon ;
- impossible de modifier la structure après l’ouverture ;
- inscription visible uniquement lorsque le statut est `ouverte` ;
- démarrage automatique conforme à la configuration.

### Inscription

- impossible de s’inscrire deux fois ;
- impossible d’utiliser deux fois le même dossard ;
- impossible pour un athlète d’inscrire un autre profil ;
- désinscription bloquée après le démarrage.

### Manche

- impossible de démarrer deux manches simultanément dans une épreuve ;
- impossible de démarrer une manche avant la précédente ;
- impossible d’enregistrer une arrivée avant le départ ;
- première arrivée enregistrée une seule fois ;
- délai strictement positif ;
- comparaison des heures en UTC.

### Résultat

- un seul résultat par athlète et par manche ;
- positions uniques ;
- position suivante calculée correctement ;
- points calculés correctement ;
- hors délai égal à zéro point ;
- correction cohérente avec le statut.

---

## 26. État des modules

### Fonctionnel ou largement implémenté

- authentification ;
- rôles coach et athlète ;
- compétitions ;
- inscriptions ;
- dossards ;
- épreuves ;
- génération des manches ;
- démarrage, fin et annulation des manches ;
- première arrivée ;
- compte à rebours ;
- résultats ;
- classement simple ;
- points ;
- hors délai ;
- publication ;
- correction métier des résultats.

### À finaliser

- grille tactile de tous les participants pour la saisie ultra-rapide ;
- démarrage automatique réel de la manche suivante ;
- correction rapide depuis chaque carte de résultat ;
- gestion explicite de l’abandon et de la disqualification depuis l’interface ;
- classement cumulé d’une compétition ;
- consultation des résultats côté athlète ;
- tests unitaires et tests d’intégration ;
- refonte globale de l’interface ;
- thème clair et sombre final ;
- icône et identité visuelle ;
- préparation Play Store.

---

## 27. Refonte future de l’interface

L’architecture permet de refaire l’interface sans modifier le domaine ni Supabase.

Structure cible possible :

```text
Coach
├── Accueil
├── Compétitions
├── Direct
├── Résultats
└── Profil

Athlète
├── Accueil
├── Compétitions
├── Mes inscriptions
├── Résultats
└── Profil
```

La refonte pourra inclure :

- navigation inférieure ;
- tableaux de bord ;
- cartes plus lisibles ;
- mode compétition plein écran ;
- boutons tactiles larges ;
- contraste renforcé ;
- animations courtes ;
- thème sombre ;
- design adaptatif tablette.

---

## 28. Principes de développement

- le domaine ne dépend pas de Flutter ;
- le domaine ne dépend pas de Supabase ;
- les règles métier sont centralisées dans les entités et cas d’utilisation ;
- la sécurité est aussi contrôlée par Supabase RLS ;
- l’interface ne fait pas confiance aux identifiants librement saisis ;
- les contrôleurs exposent les états de chargement et d’erreur ;
- les pages affichent des confirmations pour les actions destructrices ;
- les horaires sont enregistrés en UTC et affichés en heure locale ;
- les listes locales sont triées après chaque mutation.

---

## 29. Licence

Projet privé en cours de développement. Ajouter une licence explicite avant toute publication ou
diffusion publique.

---

## 30. Résumé

Cette application fournit un socle complet pour gérer une compétition sportive comprenant plusieurs
disciplines, épreuves et manches.

Le cœur du projet couvre :

```text
Créer
→ configurer
→ inscrire
→ démarrer
→ chronométrer
→ classer
→ corriger
→ publier
```

L’architecture hexagonale permet de poursuivre les fonctionnalités et de refaire entièrement
l’interface avant la publication Android, sans remettre en cause les règles métier ni l’intégration
Supabase.
