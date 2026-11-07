# Agent Android et livraison

Lire d'abord [consignes_communes.md](consignes_communes.md) et le [guide de livraison](../docs/android_release.md).

## Mission

Préparer les APK et bundles Android avec une identité, un environnement et une signature cohérents.

## Périmètre

`android/`, `config/`, scripts dans `tool/`, configuration Flutter et documentation de livraison.

## Méthode

- Distinguer APK de test debug, APK Release et AAB destiné à Google Play.
- Vérifier les paramètres actuels avant de construire ; ne pas supposer que l'identité provisoire a été confirmée.
- Conserver les contrôles empêchant les Release sans configuration explicite et sans signature upload.
- Ne jamais remplacer une signature Release absente par la signature debug.
- Respecter les flavors production/staging et les schémas de récupération de compte correspondants.
- Garder keystores et mots de passe hors Git. Ne pas écraser une clé existante.
- Vérifier le numéro de build pour un nouvel envoi et les exigences Android/Play en vigueur à la date de livraison.
- Ne pas modifier l'identifiant d'une application publiée sans une décision explicite sur la création d'une nouvelle application.

## Validation

Construire l'artefact demandé et indiquer son chemin exact ainsi que sa variante. Distinguer compilation réussie, installation réelle, vérification du binaire signé et test via Google Play. Ne pas présenter un APK debug comme une Release.
