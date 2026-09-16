# Contrôles effectués — V0.3

## Réseau local / protocole

Test avec le serveur Principal simulé fourni dans `tools/mock_principal` :

- `/api/v1/ping` : OK, protocole 6 ;
- `/api/v1/sync` : OK, titre Principal + classes + élèves + historique ;
- `/api/v1/reference-data` : OK, Sourates/Hizb/Juz/leçons/natures d'incident ;
- `/api/v1/events` : OK, événement avec `deviceId` et accusé `acknowledgedIds` ;
- compilation Go Linux du serveur de test : OK ;
- compilation Go Windows x64 du serveur de test : OK ;
- `go vet` des outils Go : OK.

## Source mobile

- contrôle basique des délimiteurs Dart sur 21 fichiers : OK ;
- contrôle des imports relatifs : OK ;
- présence Android `ACCESS_LOCAL_NETWORK` : OK ;
- présence iOS `NSLocalNetworkUsageDescription` : OK ;
- absence/retard avec date : OK dans la source ;
- heure d'arrivée obligatoire pour retard : OK ;
- rideaux Sourate/versets/Hizb/Juz dynamiques : OK dans la source ;
- suivi matière/leçon en rideaux : OK ;
- incident/nature : OK ;
- titre Principal sur les écrans : OK ;
- cache local et file des événements : OK dans la source.

## Étape de compilation mobile

Ce paquet est la source V0.3. L'environnement de création utilisé ici ne contient pas le SDK Flutter ni Xcode : aucun APK/IPA signé n'est inclus dans cette archive. La compilation Android doit être faite avec un environnement Flutter/Android SDK récent ; la compilation iOS nécessite macOS/Xcode et la signature Apple.
