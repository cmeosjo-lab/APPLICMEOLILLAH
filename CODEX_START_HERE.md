# TRANSFERT CODEX — ÉCOLE GESTION PROF MOBILE

## Objectif immédiat
Prendre ce projet Flutter existant, l'auditer, le réparer si nécessaire, puis produire une **APK Android réellement installable**. Ensuite préparer le projet pour des évolutions fréquentes sans casser les données locales ni la compatibilité avec le PC Principal.

## Règle absolue de confidentialité
- Ne jamais mettre dans GitHub, les logs, les fixtures, les captures ou les tests : nom/prénom réel, téléphone, adresse, e-mail, document, identifiant ou historique réel d'un élève, parent, professeur ou autre personne du logiciel/Excel.
- N'utiliser que des données fictives génériques (`ELEVE_TEST_01`, `PROF_TEST`, etc.).
- Les données réelles restent uniquement sur le PC Principal et sur les appareils autorisés du réseau local.
- Ne jamais committer de base de données, export CSV/Excel, sauvegarde, config locale, fichier `PROF_DATA`, clé de signature ou secret.

## Architecture attendue
- Le **PC Principal** est la source de vérité et conserve l'historique officiel.
- Le mobile est un client Prof Android/iOS avec cache local et file de saisies hors connexion.
- Le logiciel Prof Windows doit pouvoir coexister avec le téléphone pour le même professeur.
- Un nouveau téléphone doit pouvoir se reconnecter au Principal et récupérer l'état autorisé sans dépendre de l'ancien téléphone.
- Chaque appareil et chaque saisie doivent avoir des identifiants uniques afin d'éviter doublons et conflits.
- Le téléphone ne reçoit que les classes/élèves/historiques autorisés pour le professeur concerné.

## Protocole Principal existant
Le logiciel Principal utilise un protocole réseau local HTTP/JSON V6. Les routes connues sont :
- `GET /api/v1/ping`
- `GET /api/v1/sync?teacher=...&code=...`
- `POST /api/v1/events?teacher=...&code=...`

Extension prévue pour les listes dynamiques :
- `/api/v1/reference-data`

Le mobile ne doit pas maintenir sa propre vérité métier pour les référentiels qui existent dans le Principal.

## Fonctions mobiles attendues
1. Connexion au Principal par IP/port + professeur + code ; QR facultatif.
2. Titre de l'application repris du titre du logiciel Principal.
3. Synchronisation et travail hors ligne.
4. Classes et élèves du professeur.
5. Absence : date + justifiée/non justifiée.
6. Retard : date + heure d'arrivée + justifié/non justifié.
7. Suivi Coran : sourate, verset de/à, Hizb et Juz avec numéro + nom arabe reçus du Principal.
8. Suivi de leçon : matière + leçon via listes reçues du Principal.
9. Incident : nature via liste + priorité + description.
10. Historique élève autorisé.
11. File locale d'événements + accusés de réception du Principal.
12. Interface agréable, grands contrôles, Material 3, défilement fiable jusqu'au dernier bouton, respect du clavier et des Safe Areas.
13. Mise en page adaptative téléphone/tablette/Android desktop mode (ex. DeX).
14. Android + iOS à partir d'un socle commun ; priorité immédiate à l'APK Android.

## Sécurité / données
- Réseau local uniquement pour l'usage normal ; Internet ne doit pas être nécessaire après installation.
- Aucune télémétrie ou service cloud à ajouter sans demande explicite.
- Stockage local minimal et limité aux données nécessaires au professeur.
- Prévoir révocation/remplacement d'un appareil depuis le Principal.
- Ne jamais écrire une clé de signature dans le dépôt public.

## Tâche Codex — ordre d'exécution
1. Lire `README.md`, `PROTOCOLE_MOBILE_V0_3.md`, `ARCHITECTURE_MULTI_APPAREILS.md`, `PRINCIPAL_EXTENSION_REFERENTIEL.md` et le code `lib/`.
2. Exécuter `flutter doctor`, `flutter pub get`, `flutter analyze` et les tests disponibles.
3. Réparer toutes les erreurs de compilation ou de compatibilité sans supprimer les fonctions demandées.
4. Générer les fichiers natifs Android manquants avec `flutter create` si nécessaire, en conservant le code et les réglages réseau local.
5. Vérifier les permissions Android réseau local/caméra et la compatibilité des versions Android actuelles.
6. Construire une APK Android de test installable et vérifier le chemin de sortie.
7. Conserver un `applicationId` stable et une stratégie de `versionCode`/`versionName` compatible avec les mises à jour.
8. Pour la production, générer une **clé de signature release hors dépôt**, la conserver de façon durable et utiliser des secrets sécurisés dans la CI. Ne jamais la committer.
9. Mettre en place une CI qui produit l'APK en artefact à chaque version/tag, sans données personnelles.
10. Documenter exactement ce qui a été corrigé et où récupérer l'APK.

## Critère de réussite immédiat
La tâche n'est pas terminée tant qu'une APK Android installable n'a pas été produite, ou qu'un blocage externe précis et vérifiable n'a pas été identifié avec la correction minimale correspondante.
