# APK Android automatique

Ce projet contient un workflow GitHub Actions qui génère automatiquement un APK Android installable.

## Résultat
Le fichier produit porte le nom :

`ECOLE_GESTION_PRO_ANDROID_V0_3_1.apk`

Il est signé avec une clé interne de test stable afin que les builds successifs puissent mettre à jour l'application sans devoir la désinstaller.

## Utilisation
1. Mettre le projet dans un dépôt GitHub privé.
2. Ouvrir **Actions** > **Construire APK Android**.
3. Lancer **Run workflow**.
4. Télécharger l'artifact `ECOLE_GESTION_PRO_ANDROID_V0_3_1`.
5. Copier l'APK sur le téléphone puis l'ouvrir pour l'installer.

Cette étape de compilation peut utiliser Internet, mais **l'application installée ne dépend pas d'Internet** : elle communique avec le PC Principal sur le réseau local.

## Important
La clé `ci/ecole_debug.keystore` est une clé de test interne, pas une clé de publication Play Store. Pour une diffusion publique ou définitive, remplacer cette clé par une clé de production conservée de manière sécurisée.

## Signature
La clé de signature n'est volontairement pas incluse dans ce paquet. Pour une APK de production permettant les mises à jour durables, Codex doit créer/configurer une clé release hors dépôt et la stocker dans un mécanisme de secrets sécurisé.
