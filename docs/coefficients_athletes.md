# Catégories et coefficients athlètes

## Règles

Le barème vient de l'organisateur, sans revendication de norme fédérale :

| Catégorie | M | F |
|---|---:|---:|
| 18–24 | 0,9698 | 0,9543 |
| 25–29 | 0,9921 | 0,9982 |
| 30–34 | 1,0000 | 1,0000 |
| 40–44 | 0,9630 | 0,8671 |
| 50–54 | 0,8728 | 0,7839 |
| 60–64 | 0,8262 | 0,7210 |

Les tranches non fournies (notamment 35–39, 45–49, 55–59, moins de 18 et 65+) restent **non définies**. Aucune interpolation et aucun remplacement silencieux par 1. Le sexe n'est jamais déduit du prénom.

L'athlète renseigne volontairement sa catégorie dans « Mon coefficient ». Le coach peut consulter celle d'un athlète inscrit à sa compétition et modifier celle d'un invité inscrit à une de ses compétitions. La catégorie est déclarative, à actualiser ; aucune date de naissance supplémentaire n'est collectée. Une catégorie inconnue se conserve comme null.

La formule de pondération n'a pas encore été confirmée par l'organisateur. Les coefficients sont affichés mais ne changent donc ni les temps mesurés ni les points/classements officiels. Ne pas déployer un classement pondéré sans préciser sa formule, son périmètre et le traitement des catégories manquantes. Les graphiques affichent des mesures brutes.

## Instruction BDD

1. Sauvegarder le schéma et les données de staging.
2. Appliquer les migrations précédentes, notamment `202611040001_participants_manches.sql`, puis `202611040020_categories_athletes.sql` dans SQL Editor ou via les migrations Supabase.
3. Vérifier la table `categories_athletes`, ses contraintes et les deux RPC publiques. Aucune catégorie existante n'est inventée.
4. Les accès directs client à la table sont révoqués ; seules les RPC contrôlées permettent la consultation/modification.
5. Tester avec athlète propriétaire, autre athlète, coach responsable, autre coach et session absente. Un coach ne doit pas modifier un athlète possédant un compte.
6. Vérifier la suppression d'un compte : cette migration étend précisément la liste des FK reconnues par la protection de suppression. Les catégories personnelles sont supprimées en cascade sans affecter les autres résultats.
7. Recharger le cache API si nécessaire, puis utiliser l'application actualisée. Le module affiche une erreur explicite si la RPC manque.

L'application des migrations n'a pas été réalisée sur le projet distant. Pour revenir en arrière, retirer les accès dans l'application puis préparer une migration conservant les données nécessaires ; ne pas supprimer la table sans mettre à jour le vérificateur de suppression.

## Statistiques

Les statistiques sont calculées dans le domaine avec `CalculStatistiques`. Une paire athlète/manche n'est comptabilisée qu'une fois. Les moyennes, médianes et meilleurs temps excluent les abandons, disqualifications, hors délai, temps nuls ou négatifs. Un zéro mesuré est conservé ; une absence n'est pas convertie en zéro.

Les points sont cumulés selon le filtre sélectionné. Comparer des moyennes de deux épreuves de distances différentes ne représente pas une progression personnelle. Côté athlète, seules les données publiées fournies par la RPC sont utilisées.

Les graphiques utilisent [FL Chart](https://pub.dev/packages/fl_chart) 1.3.0 avec sélection tactile et données textuelles accessibles. Le thème bleu marine/orange/blanc est adapté des supports du [club Le Mans Triathlon](https://lemanstriathlon.fr/) ; les valeurs hexadécimales ne prétendent pas constituer sa charte officielle.
