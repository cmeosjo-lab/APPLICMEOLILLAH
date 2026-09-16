# Compatibilité Android / iOS — V0.3

La V0.3 utilise Flutter + Material 3, `SafeArea`, `LayoutBuilder`, listes défilantes et composants adaptatifs. Elle n'utilise pas de page web pour l'interface métier et ne dépend pas d'Internet pour travailler ou synchroniser avec le PC Principal.

## Android

La base prévoit :

- `INTERNET` pour les sockets/HTTP locaux ;
- `CAMERA` uniquement pour le QR facultatif ;
- `ACCESS_LOCAL_NETWORK` pour Android 17 / API 37+ ;
- demande d'autorisation au moment de la première connexion locale via `permission_handler` ;
- HTTP local autorisé pour rester compatible avec le protocole V6 actuel.

Android 17 impose désormais une autorisation d'exécution spécifique pour l'accès LAN aux applications ciblant l'API 37+. La V0.3 intègre cette évolution afin d'éviter qu'une future mise à jour du téléphone coupe la synchronisation locale.

## iOS

La base prévoit `NSLocalNetworkUsageDescription` dans `Info.plist`. iOS demande à l'utilisateur l'autorisation la première fois que l'application contacte un hôte du réseau local. Le QR utilise séparément l'autorisation caméra.

## Pérennité des données

Même si un changement de version Android/iOS nécessite un nouvel APK/IPA, la base officielle et l'historique restent sur le PC Principal. Une réinstallation du mobile n'est donc pas une restauration de base : le téléphone se reconnecte au Principal et resynchronise son périmètre.
