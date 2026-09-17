ÉCOLE GESTION PROF MOBILE — ANDROID — V0.3
============================================

Configuration de compilation recommandée :
- Flutter récent compatible Dart >= 3.9
- compileSdk Android 37 ou plus récent
- targetSdk selon la version Flutter/Android stable au moment de la compilation

Permissions nécessaires :
- INTERNET : communication HTTP avec le PC Principal sur le LAN
- CAMERA : uniquement pour le QR code facultatif
- ACCESS_LOCAL_NETWORK : accès direct au LAN sur Android 17 / API 37+

Le projet doit reprendre AndroidManifest_TEMPLATE.xml dans le manifeste généré par Flutter
et conserver android:usesCleartextTraffic="true" + network_security_config.xml pour le
protocole V6 HTTP local actuel.

IMPORTANT : l'application ne dépend pas d'Internet. INTERNET est le nom historique de la
permission Android permettant l'usage des sockets réseau, y compris sur le réseau local.
