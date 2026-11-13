# Notes de version — 1.0.1 (build 2)

## Texte Google Play

<fr-FR>
Nouveau dans Le Mans Triathlon Series :
• Ajout d’une image de couverture pour chaque compétition.
• Jusqu’à deux affiches peuvent accompagner une épreuve.
• Les visuels sont accessibles aux coachs et aux athlètes autorisés.
• Une compétition ouverte peut revenir en brouillon pour corriger sa configuration.
• Amélioration des contrôles, des messages d’erreur et de la sécurité des images.
</fr-FR>

## Détail interne

### Compétitions

- sélection, aperçu, remplacement et suppression d’une image de couverture ;
- affichage panoramique de la couverture dans les listes coach et athlète ;
- possibilité de revenir du statut « ouverte » au statut « brouillon » ;
- conservation des inscriptions existantes lors du retour en brouillon ;
- fermeture des nouvelles inscriptions pendant ce retour.

### Épreuves

- ajout facultatif d’une ou deux affiches ;
- définition de l’affiche principale ;
- réorganisation, remplacement et suppression ;
- consultation en galerie et en plein écran ;
- texte alternatif obligatoire pour l’accessibilité.

### Sécurité et fiabilité

- stockage privé des images dans Supabase Storage ;
- formats JPEG, PNG et WebP, avec une limite de 5 Mio et 4096 × 4096 pixels ;
- autorisations séparées entre dépôt temporaire, publication et lecture ;
- amélioration des messages lors d’un refus Storage ;
- nouvelles validations métier et tests automatisés.

## Informations de livraison

- Version publique : **1.0.1**
- Numéro de build Android : **2**
- Application ID : **fr.lemanstriathlon.series**
- Artefact : `build/app/outputs/bundle/productionRelease/app-production-release.aab`

## Prérequis backend

Avant de distribuer cette version, appliquer et valider sur Supabase les migrations
relatives aux affiches d’épreuves et aux images de compétitions, jusqu’à
`202611130006_upload_temporaire_image_competition.sql`.
