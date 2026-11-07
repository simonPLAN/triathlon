# Fiche Google Play — préparation

Ce document prépare la fiche et les accès de validation. Aucun renseignement n’a été soumis à Google Play.

## Textes proposés

Nom : **à confirmer**, cohérent avec l’identité Android et le titre Flutter.

Description courte proposée : « Organisez vos compétitions et suivez inscriptions, manches et résultats. »

Description complète proposée :

> Organisez et suivez vos compétitions sportives depuis votre téléphone.
>
> Côté coach, préparez les épreuves et les manches, gérez les inscriptions et les dossards, enregistrez les arrivées puis publiez les résultats.
>
> Côté athlète, consultez les compétitions disponibles, gérez votre inscription, retrouvez le programme et consultez les classements publiés.
>
> Les fonctions disponibles dépendent du rôle du compte et de l’état de la compétition.

Adapter ces textes aux fonctions effectivement livrées et testées. Ne pas promettre de résultats « en direct » sans synchronisation continue vérifiée.

## Informations et ressources à fournir

- Nom public définitif, catégorie, coordonnées développeur et support.
- Icône haute résolution, visuel promotionnel et captures réelles coach/athlète prises sur la version distribuée.
- URL HTTPS publique de la politique de confidentialité complétée.
- URL HTTPS publique de la demande de suppression de compte déployée.
- Public cible, classification, déclaration publicités et formulaire Sécurité des données fondés sur l’inventaire réel des flux.
- Éventuelles mentions sur les données d’invités et des mineurs, selon le service réellement proposé.

## Accès à la validation

Créer deux comptes de démonstration sur l’environnement livré : un coach et un athlète, adresses confirmées et données représentatives. Fournir les identifiants uniquement dans le champ sécurisé d’accès à l’application de la Console, jamais dans Git.

Le coach doit pouvoir consulter une compétition, ses épreuves, ses manches et les résultats. L’athlète doit pouvoir consulter une compétition ouverte, son inscription, un programme et des résultats publiés. Vérifier les droits de ces comptes et maintenir leurs accès pendant la validation.

## Livraison

Suivre [android_release.md](android_release.md), tester le bundle signé via une piste interne puis la piste exigée par le compte développeur. Utiliser le prochain numéro de build disponible. Ne pas déclarer la fiche terminée avant les réglages réels, les URLs publiques et la recette sur appareils.
