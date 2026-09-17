ÉCOLE GESTION PROF MOBILE — iOS — V0.3
========================================

L'application utilise le réseau local uniquement pour joindre le PC Principal.
Ajouter au Info.plist les clés présentes dans Info_LOCAL_NETWORK_TEMPLATE.plist :
- NSLocalNetworkUsageDescription
- NSCameraUsageDescription
- NSAppTransportSecurity / NSAllowsLocalNetworking

Le QR code reste facultatif. La connexion par code fonctionne sans caméra.

La compilation et la signature finale iOS doivent être réalisées avec Xcode/macOS et un
profil Apple adapté au mode de distribution retenu. Une fois installée, l'application peut
travailler sur le LAN de l'école sans Internet.
