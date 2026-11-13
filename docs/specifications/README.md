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
| DEM-004 | Délégation de saisie par épreuve | [Validée](visibilite_epreuves_coachs.md) | 0 ouverte | À vérifier | [Migration prête](../delegation_saisie_resultats.md) | 138 Flutter réussis ; test SQL prêt | Non déployé |
| DEM-005 | Image de couverture d’une compétition | Demande validée | 0 ouverte | À vérifier | [Migration prête](../image_competition.md) | 133 Flutter réussis | Non déployé |

## Historique consolidé des demandes

Ce tableau reprend les demandes formulées depuis le début du projet. Il complète
les cinq spécifications détaillées ci-dessus. Le statut **Livré localement**
signifie que le dépôt contient une implémentation ; une recette sur la base
Supabase et sur des appareils réels peut rester nécessaire.

| ID | Domaine | Demande suivie | État constaté | Reste à faire / preuve attendue |
|---|---|---|---|---|
| DEM-006 | Compétitions | Créer et modifier une compétition | Livré localement | Recette staging multi-comptes |
| DEM-007 | Compétitions | Filtrer les compétitions par statut | Livré localement | Contrôle visuel téléphone et web |
| DEM-008 | Compétitions | Revenir d’un statut ouvert vers brouillon | Livré localement | Vérifier les règles métier sur Supabase |
| DEM-009 | Compétitions | Supprimer une compétition et ses données liées | Correctif prêt | Appliquer la migration 202611130008 et tester avec affiches |
| DEM-010 | Épreuves | Gestion complète : création, modification, ordre et suppression | Livré localement | Recette avec manches et résultats existants |
| DEM-011 | Manches | Générer automatiquement les manches | Livré localement | Recette selon chaque configuration d’épreuve |
| DEM-012 | Manches | Configurer durée, délai, ordre de départ et participants | Livré localement | Recette staging et concurrence |
| DEM-013 | Manches | Créer des groupes d’athlètes et les sélectionner dans une manche | Livré localement | Appliquer/vérifier la migration groupes et les droits |
| DEM-014 | Manches | Enchaîner automatiquement la manche suivante et changer d’interface | Livré localement, à fiabiliser | Clôture serveur hors écran et test multi-appareils |
| DEM-015 | Manches | Publier tous les résultats depuis le bas de la liste des manches | Livré localement | Recette publication groupée et reprise sur erreur |
| DEM-016 | Arrivées | Afficher tous les participants et enregistrer une arrivée par appui | Livré localement | Recette terrain sur téléphone |
| DEM-017 | Arrivées | Déclencher le compte à rebours au premier arrivé | Livré localement | Tester limites exactes, pause réseau et reprise |
| DEM-018 | Arrivées | À zéro, placer les autres athlètes hors délai | Livré localement, à fiabiliser | Exécution serveur quand l’application est fermée |
| DEM-019 | Résultats | Saisir manuellement un temps et corriger position/temps | Livré localement | Déployer la migration 202611020005 et tester la concurrence |
| DEM-020 | Résultats | Gérer pénalités, bonus, abandons et disqualifications | Livré localement | Recette complète et cohérence des classements |
| DEM-021 | Résultats | Validation, dépublication après correction et republication | Livré localement | Vérifier les révisions sur la base réelle |
| DEM-022 | Classements | Classements automatiques manche, épreuve et compétition | Partiel | Rendre les trois niveaux explicites et uniformes |
| DEM-023 | Statistiques | Dashboard avec graphiques interactifs coach et athlète | Livré localement | Recette données réelles, accessibilité et petits écrans |
| DEM-024 | Coefficients | Appliquer les coefficients par sexe et catégorie d’âge fournis | Partiel | Confirmer la formule officielle et les tranches absentes |
| DEM-025 | Athlète | Voir les compétitions disponibles et leur détail | Livré localement | Recette droits et états vides |
| DEM-026 | Athlète | S’inscrire, se désinscrire et voir clairement l’état | Livré localement | Tester fermeture, dossard, erreurs et doubles actions |
| DEM-027 | Athlète | Voir ses épreuves, manches, affectations et ordre de départ | Livré localement | Vérifier données personnelles sur staging |
| DEM-028 | Athlète | Consulter ses résultats et les actualiser sans changer d’onglet | Livré localement | Recette après publication/dépublication et coupure réseau |
| DEM-029 | Athlète | Voir le résultat global et les classements publiés | Livré localement | Comparer aux classements coach, ex aequo inclus |
| DEM-030 | Coach | Refaire l’accueil sans démarrage rapide ni accès Manches global | Livré localement | Revue UX finale sur appareils |
| DEM-031 | Coach | Améliorer le répertoire des athlètes | Livré localement | Recette recherche, groupes et états vides |
| DEM-032 | Inscriptions | Ajouter un athlète invité sans compte | Livré localement | Vérifier RLS, doublons, RGPD et devenir des données |
| DEM-033 | Comptes | Utiliser e-mail + mot de passe et remplacer nom/prénom par pseudo | Livré localement | Recette création, unicité et migration des anciens profils |
| DEM-034 | Comptes | Mot de passe oublié et lien de récupération Android/web | Livré localement, à vérifier | Tester les liens en Release, expirés et sans session |
| DEM-035 | Comptes | Confirmation de l’adresse e-mail | Livré localement, à vérifier | Configurer redirections et SMTP de production |
| DEM-036 | Comptes | Suppression du compte dans l’application et sur le web | Livré localement, non déployé | Déployer le serveur, publier l’URL et tester l’effacement |
| DEM-037 | Autorisations | Séparer réellement athlète, coach et éventuel administrateur | Partiel | Audit RLS complet et décision arbitre/administrateur |
| DEM-038 | Interface | Thème partagé, composants communs et couleurs Le Mans Triathlon | Livré localement | Valider contraste, thème sombre et identité finale |
| DEM-039 | Interface | Interface responsive, chargements, erreurs, vides et anti-double clic | Partiel | Revue écran par écran, TalkBack et tailles de téléphone |
| DEM-040 | Identité | Nom « Le Mans Triathlon Series », icône LMTS et splash | Livré localement, à vérifier | Valider droits graphiques et rendu Release/Store |
| DEM-041 | Architecture | Refactoriser tout le projet en architecture hexagonale | Partiel | Retirer les anciennes couches parallèles encore utilisées |
| DEM-042 | Sécurité | RLS Supabase sur toutes les données sensibles | Partiel, bloquant | Audit réel staging, Security Advisor et tests multi-comptes |
| DEM-043 | Android | Préparer signature, flavors, API 36, APK/AAB et version 1.0.1 | Livré localement, à vérifier | Installer depuis Play, contrôler bundle et Play App Signing |
| DEM-044 | Google Play | Fiche Store, confidentialité, Data Safety et pistes de test | Non terminé | Documents légaux, visuels, comptes démo et test fermé |
| DEM-045 | Web | Publier l’application Flutter Web avec GitHub Pages | Déployé à vérifier | Vérifier la branche publiée, secrets, routes et configuration Supabase |
| DEM-046 | Organisation | Agents spécialisés, orchestrateur et suivi des spécifications | Livré localement | Maintenir les profils et ce tableau |
| DEM-047 | Correctif manches | Refuser une arrivée antérieure au départ sans erreur de fuseau horaire | Livré localement | Recette avec horloges appareil/serveur |
| DEM-048 | Correctif manches | Interpréter correctement une durée saisie en secondes | Livré localement | Tester 60 s, limites et anciennes données |
| DEM-049 | Correctif interface | Supprimer les débordements verticaux sur détail et résultats | Livré localement | Refaire la recette avec texte agrandi |
| DEM-050 | Correctif comptes | Corriger création de profil pseudo, contraintes héritées et triggers en double | Correctifs SQL prêts/appliqués à confirmer | Tester une base migrée et une base neuve |
| DEM-051 | Correctif sécurité | Autoriser la création de compétition sans erreur RLS « production plafond » | Correctif SQL prêt/appliqué à confirmer | Test coach autorisé et utilisateur refusé |
| DEM-052 | Correctif médias | Autoriser l’envoi/remplacement d’images de compétition dans Storage | Correctifs SQL prêts/appliqués à confirmer | Recette upload, remplacement et suppression |
| DEM-053 | Correctif Web | Corriger le déploiement GitHub Pages et la source Flutter Web | Livré et déployé à vérifier | Contrôler le site après chaque merge sur master |
| DEM-054 | Documentation | Notes de version courtes pour la version 1.0.1 | Livré localement | Mettre à jour à chaque livraison |
| DEM-055 | Compatibilité | Documenter les versions Android prises en charge | Livré dans la configuration | Confirmer minSdk/targetSdk dans le bundle signé |

### Lecture rapide des priorités

1. **Bloquant sécurité :** appliquer et auditer les migrations/RLS sur un
   environnement staging avec plusieurs comptes.
2. **Fiabilité sportive :** déplacer la clôture du délai et l’enchaînement des
   manches côté serveur, puis tester les actions concurrentes.
3. **Cohérence métier :** terminer les niveaux de classement et décider de la
   formule des coefficients.
4. **Publication :** recette Release réelle, conformité, fiche Play et test
   fermé avant la production.
5. **Nouveaux modes sportifs :** valider DEM-001 et DEM-002 avant tout
   développement.

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

### DEM-004 — Délégation de saisie des résultats

**Besoin résumé :** le responsable d’une épreuve choisit par pseudo les autres
coachs autorisés à consulter ses manches et à saisir les résultats. Les autres
coachs ne voient rien sans autorisation.

**Implémentation locale :** gestion nominative des accès, écran « Épreuves
partagées », saisie et correction des résultats, révocation immédiate et RLS.
La configuration, les départs, la validation et la publication restent au
responsable.

**Prochaine étape :** appliquer la migration selon
[les instructions](../delegation_saisie_resultats.md), exécuter le test SQL avec
Deno et réaliser la recette staging avec trois comptes coach.

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
