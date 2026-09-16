# CMEOLAB — Nouveau dépôt GitHub propre

Ce dossier est la base propre à envoyer UNE SEULE FOIS dans un nouveau dépôt GitHub.

## Nom de dépôt conseillé

`cmeolab-mobile-prof`

## Création du dépôt

1. Sur GitHub : New repository.
2. Nom : `cmeolab-mobile-prof` (ou un autre nom si souhaité).
3. Ne pas ajouter de README, .gitignore ou licence lors de la création : le dépôt doit être vide.
4. Créer le dépôt.
5. Décompresser ce ZIP sur le PC.
6. Ouvrir le dossier `CMEOLAB_MOBILE_PROF_GITHUB_CLEAN_V1`.
7. Envoyer le CONTENU du dossier dans le dépôt GitHub, en conservant l'arborescence.
8. Vérifier impérativement que le fichier suivant existe dans GitHub :
   `.github/workflows/build-android-apk.yml`
9. Commit directement sur `main`.
10. Ouvrir l'onglet Actions : `Construire APK Android` doit démarrer automatiquement.

## APK généré

Après succès, l'onglet Actions fournit l'artifact :
`CMEOLAB_PROF_ANDROID_TEST`
contenant `CMEOLAB_PROF_ANDROID_TEST.apk`.

## Important — confidentialité

Aucune donnée réelle d'élève, parent, professeur ou famille ne doit être envoyée dans ce dépôt.
Les fichiers Excel, CSV, bases, sauvegardes, logs, exports, documents et clés de signature sont exclus.

## Important — signature Android

La première APK est une APK de test. Avant distribution durable aux professeurs, mettre en place une clé de signature de production privée et stable. Cette clé ne doit jamais être commitée dans GitHub.
