# ÉCOLE GESTION PROF MOBILE V0.3

## Correctif V0.3.1 — défilement mobile

Tous les écrans de saisie et de consultation sont maintenant explicitement défilables jusqu’au dernier élément. Le correctif ajoute une marge basse adaptée aux zones système Android/iOS, tient compte du clavier virtuel, autorise le défilement même lorsque le contenu tient presque dans l’écran et masque le clavier lors d’un glissement. Le bouton Enregistrer reste ainsi accessible sur les petits écrans.


Application Prof mobile locale **Android + iOS**, conçue pour fonctionner avec **ÉCOLE GESTION PRO** sans dépendre d'Internet.

## Fonctions intégrées dans la V0.3

- connexion au PC Principal par IP/port + professeur + code ;
- QR code facultatif ;
- titre affiché repris du PC Principal (`schoolTitle`, avec repli sur le nom de l'établissement) ;
- synchronisation protocole V6 et travail hors connexion ;
- classes et élèves du professeur ;
- historique renvoyé par le Principal ;
- absence / retard avec **date**, justifié ou non justifié ;
- heure d'arrivée obligatoire pour les retards ;
- suivi Coran par rideaux : **Sourate, verset de/à, Hizb, Juz** ;
- numéros et noms arabes fournis par le référentiel du **PC Principal**, puis mis en cache ;
- suivi de leçon par **matière + leçon** en rideaux ;
- incident avec nature en rideau, priorité et description ;
- identifiant d'appareil dans chaque saisie pour préparer la coexistence téléphone / PC Prof ;
- file locale des saisies avec accusé du Principal ;
- cache local pour continuer à saisir même si le PC Principal est momentanément indisponible.

## Source de vérité

Le **PC Principal reste la base officielle**. Android, iOS et le logiciel Prof Windows peuvent coexister. Un changement de téléphone ne doit pas emporter l'historique : après reconnexion, le nouveau téléphone resynchronise ce qui est autorisé depuis le Principal.

## Référentiel Coran / leçons

La V0.3 ne crée pas une deuxième liste de noms arabes. Elle utilise l'extension locale `/api/v1/reference-data`. Voir `PRINCIPAL_EXTENSION_REFERENTIEL.md`.

## Compatibilité téléphone

La base est mise à jour pour les exigences réseau local des versions mobiles récentes :

- Android : `ACCESS_LOCAL_NETWORK` prévu pour Android 17 / API 37+, en plus de la communication LAN ;
- iOS : `NSLocalNetworkUsageDescription` et autorisation caméra séparée pour le QR facultatif ;
- interface Flutter Material 3, SafeArea, mise en page responsive et grands contrôles tactiles.

Dépendances ciblées dans cette révision : Dart >= 3.9, `http 1.6`, `shared_preferences 2.5.5`, `mobile_scanner 7.4.2`, `permission_handler 13.0.2`, `uuid 4.6`.

## Test local

Le dossier `tools/mock_principal` contient un serveur de test V6 + référentiel afin de tester les rideaux sans toucher à la base réelle.
