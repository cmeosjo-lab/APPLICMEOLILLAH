# Architecture multi-appareils — Mobile + Prof Windows

## Règle fondamentale

Le **PC Principal est l'unique source de vérité**. Ni le téléphone Android, ni l'iPhone, ni le logiciel Prof Windows ne deviennent une base officielle séparée.

```
Android ─┐
iPhone ──┼── Réseau local Wi-Fi/LAN ── PC Principal
PC Prof ─┘
```

Aucun serveur Internet ou cloud n'est nécessaire au fonctionnement pédagogique.

## Changement de téléphone

1. Installer l'application sur le nouveau téléphone.
2. Choisir la connexion par **code professeur** ou, en option, scanner le **QR code** du Principal.
3. Faire une synchronisation complète.
4. Le téléphone reconstitue son cache depuis les données renvoyées par le Principal.

L'ancien téléphone n'est pas requis.

## Coexistence avec le logiciel Prof Windows

Le mobile et le logiciel Prof Windows parlent au même serveur Principal et utilisent le même professeur/code V6. Une saisie validée sur un appareil doit devenir visible sur les autres lors de la synchronisation suivante, dans la limite des données que le Principal renvoie dans son paquet de synchronisation.

## Historique

L'exécutable Principal V1.6.7 contient déjà le champ JSON `history`. La V0.3 sait lire `history` lorsqu'il est inclus pour un élève et l'afficher dans la fiche mobile.

Si certains types d'historique ne sont pas actuellement inclus dans `/api/v1/sync`, il faudra étendre le serveur Principal, tout en conservant les endpoints V6 existants afin de ne pas casser le logiciel Prof Windows.

## File hors connexion

Les saisies faites lorsque le Principal n'est pas joignable restent dans une file locale. Elles ne sont supprimées du téléphone qu'après accusé de réception du Principal.

## Prévention des doublons

Chaque saisie mobile reçoit un identifiant UUID (`MOB-...`) et un `deviceId` stable pour le téléphone. Le Principal V6 expose les notions `acknowledgedIds`, `duplicates`, `rejected` et `errors`, ce qui permet une synchronisation idempotente à consolider lors des tests réels.
