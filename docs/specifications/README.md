# Suivi des demandes et spécifications

Cette page centralise les nouvelles demandes fonctionnelles de **Le Mans
Triathlon Series**. Elle permet de voir ce qui est demandé, ce qui doit encore
être décidé et l'avancement réel de chaque fonctionnalité.

Dernière mise à jour : **13 novembre 2026**.

> Une spécification rédigée n'est pas une fonctionnalité implémentée. Les
> colonnes « Spécification », « Développement » et « Déploiement » sont suivies
> séparément.

## Tableau de suivi

| ID | Demande | Spécification | Décisions métier | Développement | BDD / Storage | Tests | Déploiement |
|---|---|---|---|---|---|---|---|
| DEM-001 | Séries à départs dégressifs | [Brouillon](series_departs_degressifs.md) | 9 ouvertes | Non commencé | À concevoir | Non commencés | Non déployé |
| DEM-002 | Compétition par équipes au cumul des places | [Brouillon](competition_equipes_cumul_places.md) | 12 ouvertes | Non commencé | À concevoir | Non commencés | Non déployé |
| DEM-003 | Jusqu'à deux affiches par épreuve | [Validée](affiches_epreuve.md) | 0 ouverte | À vérifier | Migration prête | 133 Flutter + 56 SQL réussis | Non déployé |
| DEM-004 | Tous les coachs voient toutes les épreuves | [Brouillon](visibilite_epreuves_coachs.md) | 8 ouvertes | Non commencé | Migration RLS à concevoir | Non commencés | Non déployé |
| DEM-005 | Image de couverture d’une compétition | Demande validée | 0 ouverte | À vérifier | [Migration prête](../image_competition.md) | 133 Flutter réussis | Non déployé |

## Détail des demandes

### DEM-001 — Séries à départs dégressifs

**Besoin résumé :** configurer des séries telles que 5 × 500 m ou 10 × 1 000 m,
avec un intervalle comprenant effort et récupération, puis une cadence qui
diminue à chaque répétition.

**Décisions prioritaires :**

- confirmer que « départ 3 min » signifie répétition 1 à T+0 et répétition 2 à
  T+3:00 ;
- choisir une dégression régulière ou des intervalles saisis individuellement ;
- définir le comportement lorsqu'un athlète dépasse l'intervalle ;
- confirmer si les départs sont collectifs ou individuels ;
- préciser s'il s'agit d'une compétition officielle ou d'un entraînement.

**Prochaine étape :** réponse métier aux questions de la section 13 de la
[spécification](series_departs_degressifs.md#13-questions-et-décisions-à-confirmer).

---

### DEM-002 — Compétition par équipes au cumul des places

**Besoin résumé :** créer des équipes manuellement ou aléatoirement, attribuer à
chaque participant autant de points que sa place, additionner les points par
équipe et classer en premier le plus petit total.

**Décisions prioritaires :**

- choisir le nombre ou la taille des équipes ;
- garantir l'équité lorsque les équipes n'ont pas le même effectif ;
- définir les points des abandons, absences, hors délai et disqualifications ;
- définir le départage des équipes à égalité ;
- confirmer la correspondance entre une boucle et une manche.

**Prochaine étape :** réponse métier aux questions de la section 14 de la
[spécification](competition_equipes_cumul_places.md#14-questions-et-décisions-à-confirmer).

---

### DEM-003 — Affiches d'une épreuve

**Besoin résumé :** permettre au coach d'ajouter zéro, une ou deux affiches lors
de la création ou de la modification d'une épreuve, puis les rendre visibles
aux lecteurs autorisés.

**Décisions validées :** accès authentifié selon les droits de l'épreuve,
JPEG/PNG/WebP, 5 Mio, 4096 × 4096 pixels, texte alternatif obligatoire,
modification en brouillon et conservation dans l'historique autorisé.

**Implémentation locale :** domaine, cas d'utilisation, sélecteur Android/web,
formulaires coach, galerie coach/athlète, bucket privé, RLS, RPC et nettoyage
des objets orphelins. Les instructions sont dans
[Affiches privées des épreuves](../affiches_epreuves.md).

**Prochaine étape :** appliquer la migration sur un projet Supabase staging,
puis réaliser la recette visuelle Android/web et multi-comptes avant la
production.

---

### DEM-005 — Image de couverture d’une compétition

**Besoin résumé :** permettre au coach de sélectionner une image principale et
l’afficher dans les listes de compétitions coach et athlète.

**Implémentation locale :** sélection dans les formulaires de création et de
modification, aperçu panoramique, remplacement/suppression en brouillon et
stockage privé par URL signée.

**Prochaine étape :** appliquer la migration selon
[les instructions](../image_competition.md), puis réaliser la recette staging
multi-comptes et le contrôle visuel sur téléphone.

---

### DEM-004 — Visibilité des épreuves entre coachs

**Besoin résumé :** tous les coachs actifs consultent les épreuves de tous les
autres coachs en lecture seule, sans obtenir de droit sur les inscriptions,
participants ou résultats provisoires.

**Décisions prioritaires :**

- décider si les épreuves en brouillon sont visibles ;
- définir le niveau de détail des manches consultables ;
- confirmer la visibilité des résultats publiés ;
- choisir comment identifier le coach responsable ;
- confirmer que les affiches suivent la même visibilité.

**Prochaine étape :** réponse métier aux questions de la section 13 de la
[spécification](visibilite_epreuves_coachs.md#13-questions-et-décisions-à-confirmer).

## États utilisés

### Spécification

- **À rédiger** : demande enregistrée, analyse non commencée.
- **Brouillon** : spécification rédigée avec des décisions ouvertes.
- **À valider** : les décisions importantes sont renseignées, validation finale
  attendue.
- **Validée** : le besoin et les critères d'acceptation ont été explicitement
  approuvés.
- **Remplacée** : une autre spécification fait foi.

### Développement

- **Non commencé** : aucun code produit pour la demande.
- **En cours** : implémentation commencée, pas encore complètement vérifiée.
- **À vérifier** : code terminé, contrôles ou recette encore incomplets.
- **Terminé** : code, analyse et tests prévus sont réussis.
- **Bloqué** : une décision ou une dépendance empêche de continuer.

### BDD / Storage

- **Sans changement** : aucune modification distante nécessaire.
- **À concevoir** : le schéma ou les règles ne sont pas encore rédigés.
- **Migration prête** : fichier local créé, non exécuté.
- **Staging appliqué** : migration appliquée et testée en environnement de test.
- **Production appliquée** : migration effectivement appliquée en production.

### Déploiement

- **Non déployé** : aucun service distant n'a été modifié.
- **Test interne** : disponible uniquement sur un environnement de test.
- **Test fermé** : distribué à un groupe de testeurs.
- **Production** : version effectivement publiée.

## Ajouter une nouvelle demande

Ajouter une ligne au tableau avec un identifiant stable, puis créer la
spécification correspondante dans ce dossier.

Modèle :

```markdown
### DEM-XXX — Titre court

**Demande d'origine :** formulation de l'utilisateur.

**Besoin résumé :** résultat attendu en une ou deux phrases.

**Utilisateurs concernés :** coach, athlète, administrateur ou public.

**Spécification :** [Brouillon](nom_du_fichier.md)

**Décisions prioritaires :**

- décision qui bloque le calcul ou les droits ;
- décision qui change le parcours ;
- décision qui change les données ou la publication.

**Prochaine étape :** action vérifiable attendue.
```

## Règles de mise à jour

- Ne jamais passer une spécification à **Validée** sans validation explicite.
- Ne jamais passer le développement à **Terminé** uniquement parce qu'un
  document ou une migration a été créé.
- Une migration locale reste **Migration prête** tant qu'elle n'a pas été
  réellement appliquée et testée.
- Conserver les identifiants `DEM-XXX`, même si le titre évolue.
- Ajouter les nouvelles décisions dans la spécification détaillée ; cette page
  n'en conserve qu'un résumé.
- Après une implémentation, lier les tests et les instructions de migration dans
  la ligne ou la section correspondante.
- Signaler séparément l'état Android, web et Supabase s'ils diffèrent.
